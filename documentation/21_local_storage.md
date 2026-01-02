# Local Storage

## Overview

The Prometheus server implements a highly-optimized custom time series database (TSDB) that stores its data on the server's local filesystem. This TSDB needs to be optimized for the use case of systems monitoring: ingesting current samples for all active series at the same time, and reading many sequential samples from a small subset of those series.

The Prometheus TSDB holds the most recent 2-3 hours of samples entirely in memory and persists older data to local disk as blocks of two hours each. Prometheus later compacts multiple smaller blocks into larger ones.

Prometheus also ensures crash-resilience using a write-ahead log (WAL) uses a lock file to ensure that only one process is accessing the TSDB at the same time.

Each persisted block is stored in its own subdirectory of the storage directory and includes four components.

### meta.json

A meta.json metadata file in JSON format that describes the time range covered by this block and various statistics about the block.

### chunks

A chunks directory containing sequentially numbered chunk files that store the time series bulk data (timestamp/value samples) in a custom binary format. Each chunk file can grow up to 512MiB and holds interspersed data for all series of the block.

### index

An index file that indexes the label names, label values, and time ranges of the sample data in the chunks directory in a custom binary format. This enables efficient search and retrieval of sample data.

### tombstones

A tombstones file in a custom binary format. This is the only mutable part of a chunk directory and allows for the deletion of individual series via Prometheus's HTTP API. Instead of actually removing series data from a block's immutable chunk files and the index, series are recorded as "deleted" in the tombstones file and no longer returned in query results. When Prometheus compacts smaller blocks into larger ones, this series data is expunged for good and the tombstone entries removed.

## Compaction

While persisted blocks initially cover two hours of data each, Prometheus periodically compacts existing blocks into progressively larger blocks in the background. Compaction increases block time ranges by a factor of 3 for each level of compaction by combining the data of three existing smaller blocks and writing them out as a single larger one (the smaller source blocks are removed). The maximum block size that compaction can produce is limited to either 10% of the Prometheus server's configured data retention time or 1640.25 days (2 \* 3⁹ hours), whichever limit applies first.

Since every block has its own separate index, compaction lowers the total number of indexes that a query over older data has to consult. If series identities stay largely the same over time, compaction also means that each series has to be indexed fewer times.

## In-Memory Appends and Crash Resilience

Prometheus keeps recent data in memory before it can write it out into immutable two-hour blocks. This enables efficient in-memory appends of current incoming sample data to many series at once. However, it would mean losing multiple hours of monitoring data if the Prometheus server was shut down or it crashed. To protect against this, Prometheus also writes all samples that have not been fully persisted to a block yet into a write-ahead log (WAL). The WAL is stored in the wal subdirectory of the storage directory and consists of 128MiB-sized segments of incoming sample data. When the Prometheus server restarts after a shutdown or crash, it recovers by reading the WAL and rebuilding the previous in-memory representation of recent sample data from it. Data in the WAL can be purged when it has been fully persisted into a block.

## Locking

The Prometheus TSDB can only be safely accessed by one process at a time, as concurrent access would cause data corruption. To prevent concurrent access, a Prometheus server opening a TSDB directory attempts to acquire a file lock on an empty lock file in the storage directory. This only succeeds when no other process is currently holding this lock file.

## Active Queries

In the queries.active file, the Prometheus server keeps an up-to-date record of its currently running PromQL queries. This file is especially useful in case the server crashes due to running out of memory when processing an expensive query. When Prometheus restarts, it reads the queries.active file and logs information about any queries that didn't finish in the server's last run. This can help you find the potentially problematic queries that caused the server to crash.

## Limitations

An important limitation of Prometheus's local TSDB is that it is neither clustered nor automatically replicated onto other nodes. Each Prometheus server only stores data on its own local filesystem (although the storage directory may be a network-based volume). That means that if you lose a Prometheus server due to a faulty disk or other problem, you will lose all data associated with that node. It also means that the scalability of a Prometheus server is limited to the capacity of a single node.

The local storage subsystem relies on sensible default settings and only exposes a couple of tunables via command-line flags. The most important ones are:

- --storage.tsdb.path: The base directory in which the local TSDB should store its data. Defaults to "data/"
- --storage.tsdb.retention.time: How long Prometheus should keep samples in its TSDB. Defaults to 15 days
- --storage.tsdb.retention.size: The maximum number of bytes to store before deleting old data
- --storage.tsdb.no-lockfile: Allows switching off the use of a lock file for the TSDB, which is required for operating systems that don't support file locking
- --storage.tsdb.wal-compression: Turn on compression for the write-ahead log. This saves disk space in favor of a little more CPU usage.

An important thing to notice is that written-out block directories are completely self-contained and not referenced from other parts of the TSDB. It is completely safe to remove individual block directories (when the Prometheus server is not running). This will remove data for the time range of the block, but will not affect any other data. This can be helpful in case one block is corrupted or cannot be read.

---

## Write-Ahead Logging (WAL) in Prometheus

### What is Write-Ahead Logging (WAL)

**Write-Ahead Logging (WAL)** is a persistence technique used to guarantee **data durability and crash recovery**.

The core idea is simple:

> **Before** applying a change in memory,  
> **write it to disk in an append-only log (the WAL)**.

If the process crashes:

- the WAL is replayed at startup
- the in-memory state is reconstructed
- no acknowledged data is lost

This approach is widely used in databases (e.g. PostgreSQL) and time-series systems like **Prometheus**.

---

### Why Prometheus Uses WAL

Prometheus:

- ingests **time series samples**
- keeps recent data **in memory**
- periodically writes immutable **TSDB blocks** to disk

Problem:

- if Prometheus crashes before flushing in-memory data to blocks,
  recent samples would be lost

👉 **The WAL prevents this data loss.**

---

### How WAL Works in Prometheus

#### 1. Sample Ingestion

When Prometheus receives a metric sample:

1. The sample is **first appended to the WAL**
2. The in-memory data structures are updated

⚠️ A sample is considered **durable only after it is written to the WAL**.

---

#### 2. WAL Structure

The WAL is stored under:

/data/wal or /prometheus/wal (in our case)

It consists of:

- **numbered segment files** (e.g. `00000001`, `00000002`)
- append-only binary records

WAL records include:

- creation of new time series
- sample appends
- metadata updates

The WAL format is **binary and not human-readable**.

---

#### 3. Crash Recovery (WAL Replay)

If Prometheus crashes:

1. On restart, it loads existing **TSDB blocks**
2. Then it **replays the WAL** from the last checkpoint
3. In-memory state is rebuilt from the WAL records

Result:

- **no loss of recently ingested metrics**

This process is called **WAL replay**.

---

#### 4. Checkpointing and Compaction

To prevent unlimited WAL growth:

- Prometheus periodically creates **checkpoints**
- After a successful checkpoint:
  - old WAL segments are removed
- Stable data is compacted into **TSDB blocks**
  (directories containing `chunks`, `index`, and `meta.json`)

---

### WAL vs TSDB Blocks

| WAL                     | TSDB Blocks                 |
| ----------------------- | --------------------------- |
| Immediate writes        | Periodic writes             |
| Append-only log         | Structured immutable files  |
| Used for crash recovery | Used for historical queries |
| Hot / recent data       | Cold / persisted data       |

---

### Practical Considerations

#### Performance

- WAL writes are **very fast**
- sequential disk I/O
- minimal overhead

#### Disk Usage

- WAL size grows with:
  - high ingestion rate
  - high label cardinality
- Important metric to monitor:
  - `prometheus_tsdb_wal_size_bytes`

#### Useful Configuration Options

- `--storage.tsdb.path`
- `--storage.tsdb.retention.time`
- `--storage.tsdb.wal-compression` (reduces WAL disk usage)

---

### One-Sentence Summary

👉 **Prometheus uses Write-Ahead Logging to ensure that no ingested metrics are lost in case of a crash by writing data to disk before updating in-memory state.**

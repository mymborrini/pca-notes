# Write-Ahead Logging and Filesystem Interaction

## Prometheus, MySQL, PostgreSQL, Elasticsearch, MongoDB

This document explains how different systems implement **Write-Ahead Logging (WAL)** (or similar mechanisms)
and how they interact with the **filesystem** to guarantee durability and crash recovery.

---

## Common Principle: WAL and the Filesystem

Across databases and storage engines, the shared idea is:

> **Persist changes to disk before considering them committed.**

This is achieved by:

- writing sequentially to log files (WAL / redo log / translog / oplog)
- relying on filesystem guarantees (fsync)
- replaying logs on restart to restore in-memory state

---

## Prometheus (TSDB)

### WAL Behavior

- Uses a **WAL specific to time-series ingestion**
- Every sample is:
  1. appended to the WAL
  2. then applied to in-memory chunks

### Filesystem Interaction

- Sequential writes to: /data/wal
- Periodic compaction to immutable blocks: data/<block_id>/{chunks,index,meta.json}
- Uses `fsync` to ensure WAL durability

### Purpose of WAL

- Recover recent metrics after crash
- Not used for queries directly

---

## PostgreSQL (PSQL)

### WAL Behavior

- Uses a **classic database WAL**
- Every change (INSERT, UPDATE, DELETE) generates WAL records
- WAL is written **before** data pages are flushed

### Filesystem Interaction

- WAL files stored in: pg_wal/
- Data stored in: base/<db_oid>/<table_oid>
- Uses:
  - page cache
  - background writer
  - checkpoints

### Purpose of WAL

- Crash recovery
- Replication (streaming replicas)
- Point-in-time recovery (PITR)

PostgreSQL relies heavily on **filesystem atomicity and fsync correctness**.

---

## MySQL (InnoDB)

### WAL Behavior

- Uses **Redo Logs** (functionally WAL)
- Changes go to:

1. redo log (sequential)
2. buffer pool (memory)

- Data pages flushed later

### Filesystem Interaction

- Redo logs: ib_logfile0, ib_logfile1
- Data files: ibdata1 / \*.ibd
- Uses:
- doublewrite buffer
- fsync (configurable)

### Purpose of WAL

- Crash recovery
- Ensure ACID durability

⚠️ Durability depends strongly on:

- `innodb_flush_log_at_trx_commit`

---

## Elasticsearch (Lucene-based)

### WAL-like Mechanism

- Uses a **transaction log (translog)**
- Every indexing operation:

1. written to translog
2. indexed in memory

- Periodically flushed to Lucene segments

### Filesystem Interaction

- Translog: data/nodes//indices//translog/
- Lucene segments: data/nodes//indices//index/
- Segments are immutable
- Heavy use of mmap (memory-mapped files)

### Purpose of Translog

- Recover recent indexing operations
- Guarantee durability between refresh/flush cycles

Elasticsearch trusts the filesystem and OS cache extensively.

---

## MongoDB (WiredTiger)

### WAL Behavior

- Uses a **Write-Ahead Journal**
- Writes are:

1. journaled
2. applied to memory

- Periodic checkpoints persist data files

### Filesystem Interaction

- Journal: journal/
- Data files: \*.wt
- Uses:
- append-only journal
- group commit
- fsync

### Purpose of WAL

- Crash recovery
- Replica synchronization (oplog is separate but related)

MongoDB strongly depends on filesystem ordering guarantees.

---

## Comparison Table

| System         | WAL Name | Primary Goal      | Filesystem Pattern             |
| -------------- | -------- | ----------------- | ------------------------------ |
| Prometheus     | WAL      | Metric durability | Append-only + immutable blocks |
| PostgreSQL     | WAL      | ACID, replication | WAL + page files               |
| MySQL (InnoDB) | Redo Log | ACID recovery     | Redo + data files              |
| Elasticsearch  | Translog | Index durability  | Translog + immutable segments  |
| MongoDB        | Journal  | Crash recovery    | Journal + checkpoints          |

---

## How Databases "Talk" to the Filesystem

All systems rely on a similar low-level model:

1. **Append-only sequential writes**

- fastest disk operation

2. **fsync / fdatasync**

- ensure data reaches stable storage

3. **Page cache**

- OS buffers reads and writes

4. **Immutable files**

- simplify concurrency and recovery

5. **Checkpointing**

- limits WAL growth

### Why This Works Well

- Sequential I/O is fast
- Crash recovery is deterministic
- Filesystems are optimized for append workloads

---

## Key Insight

👉 **Databases do not trust memory.  
They trust the filesystem only after WAL + fsync.**

Everything else (buffers, caches, in-memory indexes) is disposable.

---

## Mental Model (Universal)

Client Write
↓
WAL / Log (fsync)
↓
In-Memory State
↓
Checkpoint / Compaction
↓
Stable Data Files

---

## Final Summary

- Prometheus uses WAL only for ingestion durability
- Relational DBs use WAL for full ACID guarantees
- Search engines use WAL to protect indexing
- All systems rely on:
  - sequential logs
  - immutable data files
  - filesystem correctness

The filesystem is not just storage:  
**it is part of the database design.**

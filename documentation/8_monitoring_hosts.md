# Monitoring Hosts

In this case we are not going to monitor an application but a machine through a node exporter. A node exporter is a process 
who monitor 

- Memory
- CPU
- Disk Usage

## Node Exporter
Prometheus provides an exporter called the Node Exporter, which exposes metrics about the Linux or Unix host it is running on. 
For example, it outputs metrics about the memory usage, CPU usage, disk usage, and network traffic of a host. 
It fetches most of its system information from the /proc and /sys virtual filesystems, but also executes system calls 
to retrieve statistics (the details vary by operating system).

The Node exporter has a variety of collector modules that can be configured or turned off and on via flags. However by default, it will
start up with a reasonable configuration without providing any flags. 


## 🧩 Node Exporter — How It Works and How to Install It

### 🧠 What Is Node Exporter

*Node Exporter* is a lightweight agent developed by Prometheus that runs on each host (VM, bare metal, or container).
It collects *system-level metrics* — CPU, memory, disk, network, and file system — and exposes them in Prometheus format at:

    http://<host>:9100/metrics

Prometheus scrapes this endpoint periodically to store time series data.

### ⚙️ How It Works at OS Level

Node Exporter does not hook into the kernel or require any driver.
It simply reads from existing Linux kernel interfaces such as:


| Subsystem      | Source Files / APIs               | Example Metrics                            |
| -------------- | --------------------------------- | ------------------------------------------ |
| **CPU**        | `/proc/stat`                      | `node_cpu_seconds_total`                   |
| **Memory**     | `/proc/meminfo`                   | `node_memory_MemAvailable_bytes`           |
| **Disk I/O**   | `/proc/diskstats`, `/sys/block/*` | `node_disk_io_time_seconds_total`          |
| **Filesystem** | `statvfs()` syscalls              | `node_filesystem_avail_bytes`              |
| **Network**    | `/proc/net/dev`                   | `node_network_receive_bytes_total`         |
| **Processes**  | `/proc/[pid]/`                    | `node_procs_running`, `node_procs_blocked` |

Essentially, Node Exporter acts as a read-only adapter between the Linux kernel and Prometheus.

---

### 🏗️ Installation Options 🐳 As a Docker Container

    docker run -d \
    --name node-exporter \
    --net="host" \
    --pid="host" \
    -v "/:/host:ro" \
    prom/node-exporter:v1.9.1 \
    --path.rootfs=/host

### 🧠 Summary

| Concept         | Description                                        |
| --------------- | -------------------------------------------------- |
| **Purpose**     | Expose hardware and OS metrics for Prometheus      |
| **Runs on**     | Each host (bare metal, VM, or container)           |
| **Data Source** | Linux kernel pseudo-files under `/proc` and `/sys` |
| **Port**        | Default: `9100`                                    |
| **Security**    | Read-only access; no kernel modifications          |
| **Scraped by**  | Prometheus server                                  |



## Some useful Node Exporter metrics

The metric node_cpu_seconds_total tracks how many CPU seconds have been used since boot time per core (cpu label) and per mode (mode label). 
To see how many cores are used in each code and mode calculate the rate over this counter:

    rate(node_cpu_seconds_total{job="node"}[1m])


To only see actual CPU usage, filter out the *idle* mode. To see the actual CPU usage over all cores, query for:

    sum without(cpu) (rate(node_cpu_seconds_total{job="node",mode!="idle"}[1m]))


To see how much (in GiB) is available on the machine, add the free, buffers and cached memory amounts

    (
    node_memory_MemFree_bytes{job="node"} + node_memory_Buffers_bytes{job="node"} + node_memory_Cached_bytes{job="node"} 
    ) / 1024^3


To see the free bytes on each filesystem, evaluate the following query:

    ( node_filesystem_free_bytes / node_filesystem_size_bytes ) * 100

You can also see the sum of the incoming and outgoing network traffic on the machine, grouped by network interface:

    rate(node_network_receive_bytes_total[1m]) + rate(node_network_transmit_bytes_total[1m])

The Node Exporter also exposes metrics that are not related to resource usage, but provide other kinds of information about the system.
For example, query system's boot time as a Unix timestamp:

    node_boot_time_seconds

You could use this to detect nodes that are rebooting frequently by detecting frequent changes in metric.
The following query finds nodes that have rebooted more than 3 times in the last 30 minutes:

    changes(node_boot_time_seconds[30m]) > 3

Another such metric provides the current system time of the monitored node:

    node_time_seconds

Using timestamp() function to get the scrape timestamp of a sample, you can compare Prometheus' idea of the current time with the 
scraped node's system time to debug potential time-related problems:

    node_time_seconds - timestamp(node_time_seconds)

---
### Idle Mode

The IDLE mode in a processor is the state in which the CPU has no instructions to execute for active processes and
therefore remains “inactive,” waiting for new tasks.

#### How it works

- When there are no processes ready to run, the operating system launches a special idle thread (a process that does nothing).
- In idle state, the CPU does not perform calculations but stays powered on and ready to resume as soon as a hardware or software interrupt arrives (e.g., keyboard input, network packet, timer, etc.).

#### Idle is different from Powered Off
Idle does not mean the CPU is off:

- It is in a state of waiting or light power saving.
- Some architectures use specific instructions (e.g., HLT on x86) that put the core into a low-power state until an interrupt wakes it up.

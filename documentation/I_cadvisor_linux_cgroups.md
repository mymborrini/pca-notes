# cAdvisor and Linux cgroups in Container Observability

## Role of cAdvisor in an Observability Stack

cAdvisor (Container Advisor) is a node-level agent that collects resource usage and performance metrics from running containers.  
It operates at the Linux kernel level by reading data from control groups (cgroups) and exposes these metrics in a format that can be scraped by Prometheus.

cAdvisor provides container-level observability and complements tools such as the Node Exporter, which focus on host-level metrics.

---

## Metrics Exposed by cAdvisor

cAdvisor exposes per-container metrics including:
- CPU usage
- Memory usage
- Filesystem usage
- Network I/O

These metrics describe how individual containers consume shared host resources, rather than providing aggregated system-wide values.

---

## Relationship Between cAdvisor and Node Exporter

The Node Exporter exposes metrics at the host level, such as total CPU usage, memory availability, and disk I/O for the entire node.

cAdvisor complements the Node Exporter by exposing metrics at the container level, allowing operators to understand how host resources are consumed by individual containers.

---

## Linux cgroups and the `id` Label

Linux control groups (cgroups) are a kernel feature used to isolate, limit, and account for resource usage such as CPU and memory.

Each container is associated with one or more cgroups created by the container runtime (e.g., Docker or containerd).  
cAdvisor reads metrics directly from these cgroups.

The `id` label exposed by cAdvisor represents the cgroup path from which the metrics are collected.  
It uniquely identifies the kernel-level cgroup and serves as the primary identifier for container metrics.

---

## cgroups v1 vs cgroups v2

In cgroups v1:
- Each resource controller (CPU, memory, I/O) has its own hierarchy
- cgroup paths are controller-specific
- Paths are often directly associated with container runtimes (e.g. `/docker/<container-id>`)

In cgroups v2:
- A unified hierarchy is used for all controllers
- Resource management is centralized under a single tree
- cgroup paths often appear under systemd-managed paths such as `/system.slice/`

The difference in hierarchy affects how cgroup paths appear in the `id` label.

---

## Mapping Containers Using the `id` Label

cAdvisor discovers and monitors all cgroups present on the node, without assuming that they belong to Docker containers.

When a cgroup path can be mapped to a container managed by a runtime:
- cAdvisor enriches the metrics with metadata labels such as `name` and `image`

When a cgroup cannot be mapped to a user-facing container:
- Metrics are still exposed
- The `name` and `image` labels may be empty

This commonly occurs for system cgroups, infrastructure containers, or sandbox processes.

---

## Importance for Monitoring and Query Design

Understanding how cAdvisor uses cgroups and the `id` label is critical for:
- Writing correct PromQL queries
- Aggregating metrics accurately
- Filtering out non-application containers
- Building reliable dashboards and alerts

Access to metric documentation strings on the `/metrics` endpoint helps clarify metric semantics, units, and intended usage, improving query design and correctness.

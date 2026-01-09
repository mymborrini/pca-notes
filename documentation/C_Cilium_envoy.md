# eBPF, Cilium, and Envoy — Overview

## eBPF (extended Berkeley Packet Filter)

eBPF is a Linux kernel technology that allows running small, safe programs directly inside the kernel without writing kernel modules or recompiling the kernel.

Key characteristics:

- Programs are verified for safety before execution
- No kernel crashes or infinite loops allowed
- Very high performance (no context switches)
- Programs are attached to kernel events (networking, syscalls, tracepoints)

eBPF is commonly used for:

- Networking (packet filtering, load balancing, NAT)
- Observability (metrics, tracing, latency)
- Security (runtime enforcement, syscall filtering)

eBPF programs communicate with user space through **BPF maps**, which are shared kernel data structures.

---

## Cilium

Cilium is a Kubernetes CNI (Container Network Interface) built on top of eBPF.

What Cilium provides:

- L3/L4 networking implemented in the Linux kernel via eBPF
- Kubernetes NetworkPolicies without iptables
- Identity-based security (not IP-based)
- High-performance load balancing
- Deep observability of network traffic

Because it runs in the kernel, Cilium:

- Reduces latency
- Avoids iptables complexity
- Scales efficiently with large clusters

Cilium can replace kube-proxy entirely using eBPF.

---

## Envoy

Envoy is a high-performance Layer 7 (L7) proxy.

Envoy capabilities include:

- HTTP and gRPC routing
- TLS and mTLS termination
- Retries, timeouts, and circuit breaking
- Rate limiting
- Detailed L7 metrics

Envoy is well-suited for application-level traffic control but introduces more overhead compared to kernel-level processing.

---

## Cilium + Envoy Integration

Cilium and Envoy are often used together using an **"eBPF first, proxy on demand"** model.

How this works:

- Cilium handles all L3/L4 traffic directly in the kernel using eBPF
- Envoy is invoked only when L7 features are required (e.g., HTTP routing, mTLS, rate limiting)

This approach:

- Avoids running an Envoy sidecar for every pod
- Reduces resource usage and latency
- Preserves advanced L7 capabilities when needed

Typical use cases:

- L7-aware NetworkPolicies
- Sidecar-less mTLS
- Gateway API implementations
- HTTP-level observability

---

## Comparison: Cilium + Envoy vs Istio + Envoy

| Aspect                 | Cilium + Envoy         | Istio + Envoy         |
| ---------------------- | ---------------------- | --------------------- |
| Architecture           | eBPF + selective proxy | Envoy sidecar per pod |
| L3/L4 handling         | Kernel (eBPF)          | Proxy                 |
| L7 handling            | Envoy on demand        | Envoy everywhere      |
| Performance            | Very high              | Lower due to sidecars |
| Operational complexity | Medium                 | High                  |
| mTLS                   | Yes (sidecar-less)     | Yes (sidecar-based)   |

Cilium focuses on **networking and security efficiency**, while Istio provides a **full-featured service mesh** with more operational overhead.

---

## Key Takeaways

- eBPF enables safe, high-performance kernel-level programmability
- Cilium uses eBPF to implement fast and scalable Kubernetes networking
- Envoy provides powerful L7 traffic management
- Cilium + Envoy combines kernel efficiency with application-level control
- This model is increasingly popular as a lightweight alternative to traditional service meshes

# Monitoring Container

To monitor containers the best way is to use _cAdvisor_
So we can run a docker container of _cAdvisor_ and pass it all the volumes and permissions

    docker run -d --name cadvisor -h cadvisor -v /:/rootfs:ro -v /var/run:/var/run:ro -v /sys:/sys:ro -v /var/lib/docker/:/var/lib/docker:ro -v /dev/disk/:/dev/disk:ro -p 42000:8080 gcr.io/cadvisor/cadvisor:v0.52.1
    curl http://localhost:42000/metrics
    

To visit *cAdvisor* UI just go to http://localhost:42000

## CAdvisor starter logs

Once I run the container if I check the log. I can see something like this

Registration of the podman container factory failed: failed to validate Podman info: response not present: Get "http://d/v1.0.0/info": dial unix /var/run/podman/podman.sock: connect: no such file or directory
Registering containerd factory
Registration of the containerd container factory successfully
Registering systemd factory
Registration of the systemd container factory successfully
Registration of the crio container factory failed: Get "http://%2Fvar%2Frun%2Fcrio%2Fcrio.sock/info": dial unix /var/run/crio/crio.sock: connect: no such file or directory
Registration of the mesos container factory failed: unable to create mesos agent client: failed to get version
Registering Docker factory
Registration of the docker container factory successfully
Registering Raw factory
Started watching for new ooms in manager
Could not configure a source for OOM detection, disabling OOM events: open /dev/kmsg: no such file or directory
Starting recovery of all containers
Recovery completed

What does it mean?
When cAdvisor starts, it automatically tries to register multiple “container runtime factories” — basically, plugins that connect to different container runtimes (Docker, Podman, containerd, CRI-O, Mesos, etc.).

| Log                                                   | Meaning                                                                                                                                       | Is It a Problem?                                  |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| `Registration of the podman container factory failed` | cAdvisor tried to connect to **Podman**, but the socket `/var/run/podman/podman.sock` wasn’t found.                                           | ❌ No — just a *warning*: Podman isn’t being used. |
| `Registering containerd factory` / `successfully`     | It detected **containerd** and registered it.                                                                                                 | ✅ OK                                              |
| `Registering systemd factory successfully`            | It detected **systemd-managed processes** (used for host-level metrics).                                                                      | ✅ OK                                              |
| `Registration of the crio container factory failed`   | It couldn’t find **CRI-O** (`/var/run/crio/crio.sock` missing).                                                                               | ❌ No problem                                      |
| `Registration of the mesos container factory failed`  | **Mesos** wasn’t found.                                                                                                                       | ❌ No problem                                      |
| `Registering Docker factory successfully`             | **Docker** was found and registered — this is the important part for you.                                                                     | ✅ OK                                              |
| `Registering Raw factory`                             | It also collects **host-level metrics** directly from the OS (CPU, memory, disks).                                                            | ✅ OK                                              |
| `Could not configure a source for OOM detection`      | It couldn’t access `/dev/kmsg` (kernel log), so it can’t report *out-of-memory* events. This is common when cAdvisor runs inside a container. | ⚠️ Not an issue for normal use.                   |
| `Recovery completed`                                  | cAdvisor finished scanning existing containers.                                                                                               | ✅ Everything’s ready                              |


### ✅ In Summary

- ✔️ cAdvisor is working correctly
- ✔️ It successfully detected Docker and the host system
- ⚠️ The warnings about Podman, CRI-O, and Mesos are purely informational — those runtimes just aren’t present
- ⚠️ The /dev/kmsg warning is normal inside Docker and can be safely ignored


## Let's see some metrics

Let’s have a look at some of the metrics that cAdvisor exposes.
Besides some metrics about cAdvisor itself, it exposes per-container resource usage metrics prefixed with container.

These metrics include CPU, memory, network, and disk usage, as well as others.
Each of these metrics has an id label that corresponds to the container's full path name in the host's virtual cgroups filesystem.

For example, an id value of
/docker/7230bbfcad8a1ca963822fb28a06c25df7ba17a801c3c13cf1790238e53cb630
would map to the cgroups v2 path:

/sys/fs/cgroup/docker/7230bbfcad8a1ca963822fb28a06c25df7ba17a801c3c13cf1790238e53cb630/
(with the cgroupfs driver)

On older systems with cgroups v1 these would be:

/sys/fs/cgroup/memory/docker/7230bbfcad8a1ca963822fb28a06c25df7ba17a801c3c13cf1790238e53cb630/
(with the cgroupfs driver)

For other cgroup resource types than memory, replace the word memory in this path with the appropriate cgroup resource name, like cpu or pids.

The per-container metrics also expose an image label, although this is only set in the case of Docker containers that have an image name (like image="gcr.io/cadvisor/cadvisor:v0.52.1").
The same is true for the name label.

Many of the per-container metrics will have empty image and name labels, as they correspond to cgroups that were created by the host's systemd init system, which does not provide this information.

For example, container_cpu_usage_seconds_total is a metric that exposes the number of CPU seconds used by each container (cgroup) on the machine, split out by CPU core.

### For example

Try querying for it: *container_cpu_usage_seconds_total*
Since it's counting the number of seconds that a container has used the CPU so far, you can calculate the per-second increase rate of this metric to arrive at a usage ratio between 0 and 1 per core:

rate(container_cpu_usage_seconds_total[1m])


To get the total CPU usage in number of cores for the Grafana container that you started earlier, you could limit this query to containers with the name "grafana" and sum the usage over all CPU cores:

sum without(cpu)(rate(container_cpu_usage_seconds_total{name="grafana"}[1m]))


To get this container's memory usage in bytes, you could query for:

container_memory_usage_bytes{name="grafana"}


cAdvisor outputs many more metrics about the containers running on a machine. The full list, including documentation strings, is available on its metrics endpoint at:

http://<container-ip>:8080/metrics

The result will be something like this:

    container_memory_usage_bytes{
        container_label_com_docker_compose_config_hash="9a6c3fb13730029108fc2219d847fd447a70a38a7ad40a71c6d961f9c3802a2c",
        container_label_com_docker_compose_container_number="1",
        container_label_com_docker_compose_image="sha256:c4b77829033937b2adce6fa38e5fd82c3ef6ea24d7304f2826e3a5008c8c1714",
        container_label_com_docker_compose_oneoff="False",
        container_label_com_docker_compose_project="prometheus-grafana",
        container_label_com_docker_compose_project_config_files="C:\Users\mattia.borrini\Development\Projects\PCA\pca-notes\local-environment\docker-compose\prometheus-grafana\docker-compose.yml",
        container_label_com_docker_compose_project_working_dir="C:\Users\mattia.borrini\Development\Projects\PCA\pca-notes\local-environment\docker-compose\prometheus-grafana",
        container_label_com_docker_compose_service="grafana",
        container_label_com_docker_compose_version="2.40.3",
        container_label_desktop_docker_io_binds_0_Source="C:\Users\mattia.borrini\Development\Projects\PCA\pca-notes\local-environment\docker-compose\prometheus-grafana\grafana-config\dashboard.json",
        container_label_desktop_docker_io_binds_0_SourceKind="hostFile",
        container_label_desktop_docker_io_binds_0_Target="/var/lib/grafana/dashboards/prometheus-stats/dashboard.json",
        container_label_desktop_docker_io_binds_1_Source="C:\Users\mattia.borrini\Development\Projects\PCA\pca-notes\local-environment\docker-compose\prometheus-grafana\grafana-config\demo-service-dashboard.json",
        container_label_desktop_docker_io_binds_1_SourceKind="hostFile",
        container_label_desktop_docker_io_binds_1_Target="/var/lib/grafana/dashboards/prometheus-stats/demo-service-dashboard.json",
        container_label_desktop_docker_io_binds_2_Source="C:\Users\mattia.borrini\Development\Projects\PCA\pca-notes\local-environment\docker-compose\prometheus-grafana\grafana-config\web-application-dashboard.json",
        container_label_desktop_docker_io_binds_2_SourceKind="hostFile",
        container_label_desktop_docker_io_binds_2_Target="/var/lib/grafana/dashboards/prometheus-stats/web-application-dashboard.json",
        container_label_desktop_docker_io_binds_3_Source="C:\Users\mattia.borrini\Development\Projects\PCA\pca-notes\local-environment\docker-compose\prometheus-grafana\grafana-config\datasources.yaml",
        container_label_desktop_docker_io_binds_3_SourceKind="hostFile",
        container_label_desktop_docker_io_binds_3_Target="/etc/grafana/provisioning/datasources/datasources.yaml",
        container_label_desktop_docker_io_binds_4_Source="C:\Users\mattia.borrini\Development\Projects\PCA\pca-notes\local-environment\docker-compose\prometheus-grafana\grafana-config\dashboards.yaml",
        container_label_desktop_docker_io_binds_4_SourceKind="hostFile",
        container_label_desktop_docker_io_binds_4_Target="/etc/grafana/provisioning/dashboards/dashboards.yaml",
        container_label_desktop_docker_io_ports_3000_tcp=":3001",
        container_label_desktop_docker_io_ports_scheme="v2",
        id="/docker/6d2c5b025b173cbaaf051517cecf6e8082f32b04b0283845e3aac32f83ff4695",
        image="grafana/grafana:9.0.0",
        instance="cadvisor:8080",
        job="cadvisor",
        name="grafana"
    }

You can see the id ="/docker/6d2c5b025b173cbaaf051517cecf6e8082f32b04b0283845e3aac32f83ff4695"



## 🧩 cGroups and cAdvisor

### 🧠 What Are cGroups (Control Groups)

#### 🔹 Definition
A **cGroup** (*Control Group*) is a **Linux kernel feature** that allows you to:
- **limit**
- **monitor**
- **isolate**
the resource usage of a group of processes.

They are the **low-level mechanism** used by Linux to manage:
- CPU usage and throttling
- Memory limits and OOM killing
- Disk I/O control
- Network bandwidth shaping
- Resource usage accounting

Each container (Docker or Kubernetes Pod) runs in its own **namespace** and is assigned to a **cGroup**,  
so the kernel can enforce resource limits and monitor usage accurately.

#### 🔧 Example
If Docker starts a container with a memory limit:
```bash
docker run -m 512m nginx
```
Docker is effectively telling the kernel:
> “Put this container’s processes in a cGroup that cannot use more than 512 MB of memory.”


### 📊 What Is cAdvisor

**cAdvisor** (short for *Container Advisor*) is a **daemon that collects, aggregates, and exposes resource usage and performance metrics** for containers.

It was originally developed by Google and is now built into **Kubelet** by default.  
cAdvisor reads metrics directly from **cGroups** created by Docker or Kubernetes, so it knows exactly how much CPU, memory, disk, and network resources each container uses.

#### 🧩 How It Works
1. **Docker or Kubernetes** creates containers → assigns them to cGroups.  
2. **cGroups** track the resource usage for those processes.  
3. **cAdvisor** reads that data from the kernel.  
4. **Prometheus** scrapes metrics exposed by cAdvisor (usually on port `:8080/metrics`).  

#### 📈 Example Metrics Exposed by cAdvisor
- `container_cpu_usage_seconds_total`
- `container_memory_usage_bytes`
- `container_fs_usage_bytes`
- `container_network_transmit_bytes_total`

These metrics are then used by **Prometheus** and **Grafana** to visualize and monitor system performance.

### 🔗 Relationship Between cGroups and cAdvisor

| Component     | Role                                                                 |
|----------------|----------------------------------------------------------------------|
| **cGroup**     | Kernel feature that limits and monitors resource usage per process   |
| **Container**  | Runs inside namespaces and is assigned to one or more cGroups        |
| **cAdvisor**   | Collects data from cGroups and exposes it as metrics                 |
| **Prometheus** | Scrapes metrics from cAdvisor and stores them for analysis           |

### 🧠 Summary Diagram

```
+----------------------+
|   Application Code   |
+----------+-----------+
           |
           v
+----------------------+
|     Docker / Pod     |
+----------+-----------+
           |
           v
+----------------------+
|     cGroup Layer     | <-- Kernel-level resource accounting
+----------+-----------+
           |
           v
+----------------------+
|       cAdvisor       | <-- Collects metrics from cGroups
+----------+-----------+
           |
           v
+----------------------+
|      Prometheus      | <-- Scrapes /metrics
+----------+-----------+
           |
           v
+----------------------+
|       Grafana        | <-- Visualization & Dashboards
+----------------------+
```

---

✅ **In short:**  
- **cGroups** handle *how much* resources a process can use.  
- **cAdvisor** observes *how those resources are used over time.*  
Together, they form the foundation of container performance monitoring.



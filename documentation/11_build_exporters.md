# Build Exporters

Generally you are not so lucky to have the opportunity to expose span in the code. So the exporter is a process that translates existing metrics exposed by a third party component into a prometheus metrics format.

While adding direct instrumentation to the codebase of an application gives you the best-possible insight, this is sometimes not possible: you may be running closed-source software (like an Oracle database server), open-source software where you do not control the development lifecycle (like a MySQL server), or you may be stuck with a hardware device that cannot be scraped directly by Prometheus. For these cases, Prometheus has the concept of an "exporter" that helps fetch and translate metrics from third-party systems. This works as long as the third-party system has some other way of retrieving metrics from it. You have already used several examples of exporters earlier on in this course (like the Node Exporter and cAdvisor).

In this chapter, you are going to learn more about how exporters work and how to create your own.

## Exporter Architecture

An exporter is a process that sits between Prometheus and a third-party component you want to monitor that does not have direct support for Prometheus metrics. Instead of scraping the third-party component directly, you configure Prometheus to scrape the exporter. During the scrape, the exporter synchronously gathers metrics from the backend system and translates them into Prometheus metrics on the fly. For example, in the case of the Node Exporter, the exporter gathers statistics from the host's /proc and /sys filesystems (among other sources) and translates those statistics into Prometheus metrics.

Sometimes, an exporter might have to perform expensive actions to gather metrics. Only in those cases, it may make sense to calculate the necessary metrics asynchronously, rather than at scrape time.

To benefit from Prometheus's fine-granular pull model, its service discovery, and the labeled metadata that it attaches to every scrape target, avoid "super" exporters that monitor multiple processes or services at once. Instead, a good rule of thumb is to run one exporter process (i.e. one pull target) for every monitored third-party process.

When you cannot instrument a software component directly and there is also no existing exporter for it, you may want to write your own exporter. In the best case, writing an exporter is simple, since it only requires translating existing metrics into the Prometheus metrics format. Doing a clean translation does require some understanding of the metrics in question though.

## cpu-exporter project

In this project, you will study and run a simple example exporter written in Python that exposes CPU metrics about the Linux machine it is running on. These metrics will be roughly equivalent to the CPU usage metrics of the Node Exporter, although they only split up CPU usage by mode, not additionally by CPU core. To retrieve the host's CPU metrics, the exporter uses the psutil Python library so that it does not need to parse the underlying virtual file (/proc/stat) on its own.

The Prometheus client library's HTTP server is started on port 8000 by calling start_http_server(8000). The HTTP server calls the collect() method of the CPUCollector class once per scrape, fetches the current CPU usage stats using the psutil library, and uses a CounterMetricFamily to translate those values into a "throw-away" Prometheus metric family (a group of series with the same metric name, but different labels) that is split out by the mode label dimension


You can now query CPU usage from your own exporter instead of using the Prometheus Node Exporter:
    
    rate(cpu_exporter_cpu_usage_seconds_total{job="cpu-exporter"}[1m])

Compare this with the equivalent expression based on the Node Exporter’s CPU metrics:

    sum without(cpu) (rate(node_cpu_seconds_total{job="node"}[1m]))
    
The CPU usage should look identical
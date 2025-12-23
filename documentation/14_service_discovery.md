# Service Discovery

So far, you have configured scrape targets statically using a static_configs section in your prometheus.yml configuration file. In dynamic cloud environments, this pattern no longer works, as scrape targets appear and disappear frequently without manual provisioning. This is especially true when using a cluster scheduler like Kubernetes. To address this, Prometheus integrates support for different service discovery mechanisms.

## Service discovery support

Prometheus has built-in support for discovering services and nodes on a variety of platforms:

- Cloud and VM providers (e.g. AWS EC2, Google GCE, Microsoft Azure)
- Cluster schedulers (e.g. Kubernetes, Docker)
- Generic mechanisms (e.g. DNS, Consul, Zookeeper)
- File-based custom service discovery

Each of these can be added to a scrape_config section to provide a dynamic list of targets that continuously updates during Prometheus’s run time. Prometheus will automatically stop scraping old instances and start scraping new ones, so that even highly dynamic environments such as Kubernetes are well-supported.

### Consul-Based Discovery

A common tool that organizations use to register and discover hosts and services is HashiCorp's Consul. You will use Prometheus's native support for Consul-based service discovery to monitor your existing three demo service instances.

In addition to the three demo service targets, the Consul agent will also register itself as a single-instance service with the name consul. We can add scrape config of consul

      - job_name: 'consul-sd-config'
        consul_sd_configs:
            - server: 'consul:8500'
        relabel_configs:
            - action: keep
              source_labels: [__meta_consul_service]
              regex: demo


Note that this is also adding a relabeling step to only keep targets where the Consul service name is demo. Otherwise, Prometheus would try to scrape the Consul agent itself as well, which doesn't have a /metrics endpoint.


Head to your Prometheus server's targets page at http://<machine-ip>:9090/targets and verify that the targets defined above are present and healthy under the consul-sd-condif job name.

### File Based Discovery

To make Prometheus read targets from a file named targets.yml, add the following scrape configuration to the scrape_configs stanza of your prometheus.yml file.

      - job_name: 'file-sd-config'
        file_sd_configs:
          - files:
            - 'targets.yml'

This "discovers" your existing three demo services under a second scrape job named file-sd-config and labels the first two instances with the env="production" label and the third one with env="staging"


Note: When updating a file_sd targets file of a production Prometheus server, ensure that you make any file changes atomically to avoid Prometheus seeing partially updated contents. The best way to ensure this is to create the updated file in a separate location and then rename it to the destination filename (using the mv shell command or the rename() system call). 

You now have a generic mechanism that lets you dynamically change the targets that Prometheus monitors without having to restart or explicitly reload the Prometheus server. Instead of making manual changes to the targets.yml file, you would now build an integration that reads target information from your infrastructure and updates the targets.yml file accordingly.
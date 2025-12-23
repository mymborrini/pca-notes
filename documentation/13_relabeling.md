# Relabeling Overview

Relabeling is implemented as a series of transformation steps that you can apply in different sections of the Prometheus configuration file to filter or modify a list of labeled objects
You can apply relabeling to the following labeled objects:

- Discovered scrape targets (relabel_configs section in a scrape_config section).
- Individual samples from scrape targets (metric_relabel_configs section in a scrape_config section).
- Alerts sent to the Alertmanager (alert_relabel_configs in the alerting section).
- Samples written to remote storage systems (write_relabel_configs in the remote_write section).

Relabeling consists of a list of rules that are applied one after another to each labeled object. For example, a relabeling rule may keep or drop an object based on a regular expression match, may modify its labels, or may map a whole set of labels to another set. Once a relabeling step decides to drop a labeled object, no further relabeling steps are executed for this object and it is deleted from the output list.

## Hidden Labels and metadata

A source of labeled objects (such as a service discovery mechanism producing labeled targets) may attach a set of hidden labels prefixed with a double underscore (__) that contain extra metadata. These labels will be removed after the relabeling phase, but can be used during relabeling to make decisions or changes to the object’s labels.

For targets, some of these hidden labels have a special meaning and control how a target should be scraped:

- __address__
- __scheme__
- __metrics_path__
- __param__

Each of these labels can be overwritten using relabeling rules to produce custom scrape behaviors for every target. For example in the mysql exporter you have to connect to the exporter not mysql server itself, so you can do something like this:

      - job_name: 'mysql'

        params:
        auth_module: [client]

        static_configs:
        - targets: ['mysql:3306']

        relabel_configs:
        - source_labels: [__address__]
            target_label: __param_target
        - source_labels: [__param_target]
            target_label: instance
        - target_label: __address__
            # The mysqld_exporter host:port
            replacement: mysql-exporter:9104

So prometheus will see the target as mysql but in the moment of the connection the address will be overridden 

## Relabeling Rule Structure

A single relabeling rule has the fields listed below. 

- action: The desired relabeling action to execute (replace, keep, drop, hashmod, labelmap, labeldrop, or labelkeep).
- source_labels: A list of label names that are concatenated using the configured separator string and matched against the provided regular expression.
- separator: A string with which to separate source labels when concatenating them. Defaults to ";".
- target_label: The name of the label that should be overwritten when using the replace or hashmod relabel actions.
- regex: The regular expression to match against the concatenated source labels. Defaults to "(.*)" to match any source labels.
- modulus: The modulus to take off the hash of the concatenated source labels. Useful for horizontal sharding of Prometheus setups.
- replacement: A replacement string that is written to the target_label label for replace relabel actions. It can refer to regular expression capture groups that were captured by regex.


### Samples

For now, let's try a simple example in which we will use relabeling to selectively drop some metrics of the demo service that we do not want to store. The demo service exposes four classes of metric.

- Application specific metrics, prefixed with *demo_*
- Go runtime specific metrics, prefixed with *go_*
- Generic process metrics, prefixed with *process_*
- Generic HTTP-level metrics, prefixed with *http_*

Let's say you only wanted to store the application-specific and HTTP-level metrics. We could then use metric relabeling to throw away any samples where the metric name does not start with either demo_ or http_ by matching a regular expression against the special __name__ label that contains a sample's metric name.

We can add the metric_relabel_configs section to the demo service's scrape_config section 

        relabel_configs:
            - action: keep
              source_labels: [__name__]
              regex: '(demo_|http_).*'

This keeps only the samples whose metric name matches the regular expression (demo_|http_).* and thus only stores application-level and HTTP-level metrics.

If now you go to the prometheus interface you can see that for job `lf-app` no metrics starts with go_ or process_ appear


## Appendix


### metric_relabel_configs VS relabel_configs


In Prometheus, both `relabel_configs` and `metric_relabel_configs` are used for relabeling, but they operate at **different stages of the scrape pipeline** and serve **different purposes**.

---

#### relabel_configs

##### When it runs
- **Before scraping**
- During **target discovery**

##### What it is used for
- Selecting which **targets** to scrape
- Modifying **target labels**
- Changing:
  - `job`
  - `instance`
  - `__address__`
- Dropping entire targets

##### Scope
- ✅ Targets
- ❌ Individual metrics

##### Common special labels
- `__address__`
- `__scheme__`
- `__metrics_path__`
- `__meta_*` (from service discovery)

##### Example
```yaml
relabel_configs:
  - source_labels: [__meta_kubernetes_pod_label_app]
    regex: demo
    action: keep
```

This configuration keeps only targets where app=demo.

#### metric_relabel_configs

##### When it runs
- **After scraping**
- Applied to **each individual metric**

##### What it is used for
- Filtering metrics
- Dropping unwanted metrics
- Renaming metrics
- Modifying or removing metric labels
- Reducing metric cardinality

##### Scope
- ✅ Individual metrics
- ❌ Targets

##### Common special labels
- `__name__`  (metric name)

##### Example
```yaml
metric_relabel_configs:
  - source_labels: [__name__]
    regex: '(demo_|http_).*'
    action: keep
``` 

This configuration keeps only metrics whose names start with demo_ or http_.

### Prometheus Scrape Pipeline

```
Service Discovery
   ↓
relabel_configs         (filter / modify TARGETS)
   ↓
Scrape /metrics
   ↓
metric_relabel_configs (filter / modify METRICS)
   ↓
TSDB Storage
```


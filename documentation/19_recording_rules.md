# Recording Rules

Recording rules allow evaluating a PromQL expression at regular intervals and recording the results into a new metric name. They are configured in a Prometheus server in the same way as alerting rules

Recording rules are useful for three use cases:

- Pre-recording expensive queries makes querying their results more efficient than computing the original expensive query every time.
- A recording rule stores its results as a new metric name, which can act as a convenient short-hand form for a long PromQL expression.
- In federated setups, recording rules allow a lower-level Prometheus server to save aggregated data under a new metric name that a higher-level Prometheus can then pull using federation (instead of pulling all underlying series of the original query).

The query efficiency gain is probably the more important aspect. However, only some queries can benefit from this substantially. The main condition is that it must be significantly cheaper to query the recorded result than to execute the original query. This is the case in a couple of cases:

- When a query aggregates many series into a few output series (the ratio is what matters here).
- When filtering or joining a set of series with another set series in such a way that the number of loaded series is much larger than the number of output series.
- When calculating rates or other range functions over very long time windows.

A good approach is to add recording rules as they become necessary. For example, if a given graph in a dashboard is regularly very slow, you might try to pre-record its expressions to improve its performance.

## Configure Recording Rules

Let us pretend that you are monitoring many demo service instances (not just three) and that it is expensive to calculate the total number of requests across all instances and other label sub-dimensions (path, method, etc.):

```promql
sum by(job) (rate(demo_api_request_duration_seconds_count[5m]))
```

You will create a recording rule to pre-record this expression into a new series with the name _job:demo_api_request_duration_seconds_count:rate5m_. The recording rule will be evaluated (and recorded) every 5 seconds, as per our initially configured global evaluation_interval setting.

Create a new file _recording_rules.yml_:

```yaml
groups:
  - name: demo-service
    rules:
      - record: job:demo_api_request_duration_seconds_count:rate5m
        expr: |
          sum by (job) (
            rate(demo_api_request_duration_seconds_count[5m])
          )
```

You then have to tell Prometheus to load this rule file by adding an entry to the rule_files list in the prometheus.yml file.

On the Prometheus server, run the following query:

```promql
job:demo_api_request_duration_seconds_count:rate5m
```

This should give you the same result as the original query, but only requires loading pre-computed series. In a large setup, this could now be much faster than running the original query.

_Note_: Recording rules only start writing out results starting from the time they were configured. They do not support back-filling of historical data with the results of an expression.

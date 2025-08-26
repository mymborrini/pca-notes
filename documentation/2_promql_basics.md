# 🧪 PromQL Basics

Prometheus scrapes metrics every minute and stores them as time series. **PromQL** lets you query them.

- **Instant vector:** snapshot at a single timestamp (e.g., typing `http_request_total`).
- **Range vector:** a series over a time window (e.g., `http_request_total[5m]`).
- **Functions:** `rate`, `increase`, `avg_over_time`, `histogram_quantile`, etc.
- **Aggregations:** `sum`, `avg`, `min`, `max`, `count`, optionally grouped with `by(...)` / collapsed with `without(...)`.


```promql
## The Simplest Query
http_request_total
```

Returns the latest value for each labeled time series under the metric.

---

# 🎯 Filtering and Label Selection

Select time series with label matchers inside `{}`:

- **Exact match**: `label="value"`
- **Negative match**: `label!="value"`
- **Regex match**: `label=~"regex"`
- **Negative regex**: `label!~"regex"`

## Examples

```promql
# All GET requests
http_request_total{method="GET"}

# Requests to "/" OR "/metrics"
http_request_total{path=~"/(|metrics)"}

# Exclude 5xx responses
http_request_total{status!~"5.."}

# Combine multiple matchers
http_request_total{method="GET", path="/metrics", status="200"}
```

---

# 🚀 Working with Counters (rates, errors, throughput)

Use `rate()` over a range vector to get per-second rates.  
Use `increase()` to get totals over a period.


```promql
## Global request rate (per-second) over last 5 minutes
sum(rate(http_request_total[5m]))

# Request rate by path
sum by (path)(rate(http_request_total[5m]))

# Error rate (5xx)
sum(rate(http_request_total{status=~"5.."}[5m]))

# Success rate (2xx) by path
sum by (path)(rate(http_request_total{status=~"2.."}[5m]))

# Error percentage (share of errors over all requests)
sum(rate(http_request_total{status=~"5.."}[5m])) / sum(rate(http_request_total[5m]))
```

⚠️ Counter resets: if the application restarts, counters drop to zero.
rate() and increase() handle this if the reset happens inside the range window.
Choose a window (e.g., [5m]) that smooths noise but reacts quickly.

---

# 📈 Working with Gauges (CPU, memory, etc.)


```promql
## Current CPU usage
process_cpu_usage

# 5-minute average CPU usage
avg_over_time(process_cpu_usage[5m])

# Peak CPU usage in the last 15 minutes
max_over_time(process_cpu_usage[15m])
```

🧭 For spiky gauges, prefer avg_over_time or quantile_over_time(0.95, …) in dashboards.

---

# ⏱ Working with Histograms (latency, sizes)

To compute quantiles (e.g., p95 latency):

1. Convert histogram buckets to rates.
2. Aggregate by `le`.
3. Use `histogram_quantile()`.


```promql
## p95 latency across all labels (5 minutes)
histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

## p95 latency per path
histogram_quantile(0.95, sum by (path, le) (rate(http_request_duration_seconds_bucket[5m])))

## p99 latency per path & status
histogram_quantile(0.99, sum by (path, status, le) (rate(http_request_duration_seconds_bucket[5m])))

## Average (mean) latency over 5 minutes
sum(rate(http_request_duration_seconds_sum[5m])) / sum(rate(http_request_duration_seconds_count[5m]))

## SLO checks: share of requests under a threshold (≤ 250ms)
sum(rate(http_request_duration_seconds_bucket{le="0.25"}[5m])) / sum(rate(http_request_duration_seconds_count[5m]))
```

---

# 🧱 Useful Aggregations


```promql
## Requests per status code
sum by (status)(rate(http_request_total[5m]))

## Top 5 paths by request rate
topk(5, sum by (path)(rate(http_request_total[5m])))

## Distinguish by instance (when scraping multiple pods/hosts)
sum by (instance)(rate(http_request_total[5m]))

```
🏷️ Keep labels meaningful and low-cardinality (method, path, status, instance, job).
Exploding label cardinality (e.g., user IDs) will hurt Prometheus performance.

---

# 🗂️ Recording Rules (optional but recommended)

Precompute frequently used expressions for efficiency and consistency:

```yaml
groups:
  - name: http.rules
    interval: 30s
    rules:
      - record: job:http_requests:rate5m
        expr: sum by (job)(rate(http_request_total[5m]))

      - record: job:path:http_request_duration_seconds:p95
        expr: |
          histogram_quantile(
            0.95,
            sum by (job, path, le)(rate(http_request_duration_seconds_bucket[5m]))
          )
```

These recorded series can then be queried directly (e.g., `job:http_requests:rate5m`).

---

# 📟 Grafana Tips

- Use panel units: ops/s, seconds (ms), percent.
- For rate graphs, set a sensible **Min step** (e.g., equal to or a multiple of your scrape interval, 60s).
- For histograms, plot **p50, p95, p99** together and annotate **SLO thresholds**.
- Prefer concise legends like `{{path}} {{status}}`.

---

# 🧰 Quick Reference (cheat sheet) ✨

- **Exact/regex filters**: `{label="x"}`, `{label=~"re"}`
- **Rates/totals**: `rate(counter[5m])`, `increase(counter[1h])`
- **Gauges over time**: `avg_over_time(gauge[5m])`
- **Quantiles from histograms**: `histogram_quantile(Q, sum by (le)(rate(<metric>_bucket[5m])))`
- **Mean from histograms**: `sum(rate(_sum[5m])) / sum(rate(_count[5m]))`
- **Group aggregations**: `sum by (label)(...)`, `avg by (label)(...)`

---

# ✅ Summary

- **Counter** → ever-increasing; use `rate()` / `increase()`.
- **Gauge** → goes up/down; use `avg_over_time()`, `max_over_time()`.
- **Histogram** → cumulative buckets; use `rate()` + `sum by (le)` + `histogram_quantile()`.

- Use labels to filter and aggregate meaningfully; watch out for **resets** and **cardinality**.
- Scrape interval here is 1 minute — choose PromQL windows (e.g., `[5m]`) accordingly.


## Filtering and Label Selection

If we want to include the metrics that match specific labels, we filter
using curly braces.

     http_requests_total{path="/"}

This will return a subset of the `http_requests_total` metric with only
the series where the label `path` equals `/`.

If we want to receive all of the requests that start with `/items`, we
can use a regex like:

     http_requests_total{path=~"/items.*"}

To do the opposite (anti-regex), we can exclude them like this:

     http_requests_total{path!~"/items.*"}

If you need to include multiple values for the same label (OR
condition), you can use a regex with alternatives:

     http_requests_total{status=~"200|500"}

👉 **Note:** You cannot use `AND` on multiple values of the same label.
A label can only have one value per series.

------------------------------------------------------------------------

## Time Series Data

Prometheus is known as a time-series database. Behind the scenes,
Prometheus scrapes metrics at intervals (e.g. every 15s, 30s, 1m). Each
metric is stored as one or more **time series**, uniquely identified by
its metric name and label set.

Each sample in a series is a pair `(timestamp, value)`.

You can imagine it as a table view for explanation purposes:

**Metric:** `http_requests_total`

Timestamp    Method   Path    Value
  ------------ -------- ------- -------
1683000075   GET      /       1
1683000075   POST     /item   23
1683000075   PUT      /item   2
1683000090   GET      /       2
...          ...      ...     ...

Or equivalently, one table per label combination:

**Metric:** `http_requests_total{method="GET", path="/"}`

Timestamp    Value
  ------------ -------
1683000075   1
1683000090   2
...          ...

**Metric:** `http_requests_total{method="POST", path="/item"}`

Timestamp    Value
  ------------ -------
1683000075   23
1683000090   24
...          ...

------------------------------------------------------------------------

## Instant Vectors vs Range Vectors

If we query a metric without a range selector, Prometheus returns the
**most recent value** of each series, called an **Instant Vector**:

     http_requests_total

Might return:

-   1683000195 GET / → 5\
-   1683000195 POST /item → 42\
-   1683000195 PUT /item → 14

If we query with a time range selector, Prometheus returns a **Range
Vector**, which contains all values in that time window:

     http_requests_total[30s]

This might include:

-   1683000165 GET / → 4\
-   1683000165 POST /item → 35\
-   1683000180 GET / → 5\
-   1683000180 POST /item → 39\
-   1683000195 GET / → 5\
-   1683000195 POST /item → 42

We can also combine range selectors with filters:

     http_requests_total{path!~"/items.*"}[30s]

------------------------------------------------------------------------

### Summary

-   **Instant Vector** → one sample per series (typically the most
    recent one).\
-   **Range Vector** → multiple samples per series over a time window.

------------------------------------------------------------------------


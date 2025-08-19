# 📊 Introduction to Prometheus Metrics and PromQL

We have a backend application exposing metrics, which are scraped by **Prometheus** once every minute.  
The metrics come in different types, as shown in the examples below.

---

## 🧩 Prometheus Metric Samples

```txt
# HELP http_request_total Total HTTP Requests
# TYPE http_request_total counter
http_request_total{method="GET",path="/",status="200"} 1.0
http_request_total{method="GET",path="/metrics",status="200"} 119.0

# HELP process_cpu_usage Current CPU usage in percent
# TYPE process_cpu_usage gauge
process_cpu_usage 0.6

# HELP http_request_duration_seconds HTTP Request Duration
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.005",method="GET",path="/",status="200"} 2.0
http_request_duration_seconds_bucket{le="0.01",method="GET",path="/",status="200"} 3.0
http_request_duration_seconds_bucket{le="0.025",method="GET",path="/",status="200"} 3.0
http_request_duration_seconds_bucket{le="0.05",method="GET",path="/",status="200"} 4.0
http_request_duration_seconds_bucket{le="0.075",method="GET",path="/",status="200"} 5.0
http_request_duration_seconds_bucket{le="0.1",method="GET",path="/",status="200"} 6.0
http_request_duration_seconds_bucket{le="0.25",method="GET",path="/",status="200"} 6.0
http_request_duration_seconds_bucket{le="0.5",method="GET",path="/",status="200"} 7.0
http_request_duration_seconds_bucket{le="0.75",method="GET",path="/",status="200"} 8.0
http_request_duration_seconds_bucket{le="1.0",method="GET",path="/",status="200"} 8.0
http_request_duration_seconds_bucket{le="2.5",method="GET",path="/",status="200"} 8.0
http_request_duration_seconds_bucket{le="5.0",method="GET",path="/",status="200"} 8.0
http_request_duration_seconds_bucket{le="7.5",method="GET",path="/",status="200"} 8.0
http_request_duration_seconds_bucket{le="10.0",method="GET",path="/",status="200"} 8.0
http_request_duration_seconds_bucket{le="+Inf",method="GET",path="/",status="200"} 8.0
http_request_duration_seconds_count{method="GET",path="/",status="200"} 8.0
http_request_duration_seconds_sum{method="GET",path="/",status="200"} 0.008018255233764648
```

# 🔍 Understanding Metric Types

Each metric is preceded by two comments:

- `# HELP` → describes the metric.
- `# TYPE` → indicates the metric type.

The three most common types are **Counter**, **Gauge**, and **Histogram**.

---

## ➕ Counter

**Example:** `http_request_total`  
A **counter** only goes up (it can reset to zero on process restarts). Use it for events such as requests, errors, jobs processed.

In the sample above, you see multiple **time series** under the same metric name, differentiated by labels like `method`, `path`, `status`.

Counters are ideal for **rates over time** with `rate()`/`irate()` and for **totals** with `increase()`.

---

## 📉 Gauge

**Example:** `process_cpu_usage`  
A **gauge** goes up and down—CPU usage, queue depth, temperature, free memory, etc.

You can use range-vector functions like `avg_over_time`, `max_over_time`, `min_over_time` to summarize gauges.

---

## ⏱ Histogram

**Example:** `http_request_duration_seconds`  
A **histogram** captures distributions using **cumulative buckets**:

- Each `_bucket{le="X"}` contains all observations `≤ X`.

Histograms also export:
- `_count` → total observations
- `_sum` → sum of all observed values (useful for averages)

In the example, of the 8 requests:
- 2 took `< 5ms`, 3 `< 10ms`, 3 `< 25ms`, 4 `< 50ms`, 5 `< 75ms`, 6 `< 100ms`, 8 `< 750ms` …

Because buckets are **cumulative**, once you look at `le="0.75"`, you already include everything below it.

> 🧠 **Tip:** Prometheus also has **summaries** (client-side quantiles). Histograms are preferred when you need server-side aggregation across instances, because you can combine buckets and compute quantiles with `histogram_quantile()`.

---

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


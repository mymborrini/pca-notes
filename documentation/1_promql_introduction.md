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

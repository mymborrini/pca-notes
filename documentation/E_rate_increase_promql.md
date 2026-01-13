# PromQL Counters: rate(), irate(), and increase()

This document explains **mathematically and conceptually** how Prometheus computes
`rate()`, `irate()`, and `increase()` for counter metrics, including proper handling
of counter resets.

The content is aligned with the actual Prometheus implementation and with the
**Prometheus Certified Associate (PCA)** exam expectations.

---

## 1. Counter metrics

A **counter** is a metric that:
- can only increase
- may reset when the monitored process restarts

The absolute value of a counter is usually **not useful for observability** because
it depends on how long the process has been running.

What matters instead is **how fast the counter is increasing over time**.

---

## 2. Why raw counters are not useful in graphs

Graphing a raw counter produces a monotonically increasing line.
From such a graph it is hard to understand:
- current system load
- traffic spikes
- short-term behavior changes

For observability, we are interested in **rates of change**, not cumulative totals.

---

## 3. The rate() function

### Conceptual definition

`rate()` computes the **average per-second increase** of a counter over a given time
range.

Important:  
`rate()` **does not** compute a simple average of differences, and it is **not**
equal to `(last - first) / time`.

Instead, it uses **linear regression**.

---

## 4. Mathematical definition of rate()

Given a set of samples `(x, y)` where:
- `x` is time in seconds
- `y` is the counter value

Prometheus fits a line:

y = a·x + b

The function returns the slope `a`, which represents the rate of increase per second.

The slope is computed as:

a = (N·Σ(xy) − Σx·Σy) / (N·Σ(x²) − (Σx)²)

Where `N` is the number of samples.

---

## 5. Example without counter reset

Scrape interval: 15 seconds

Sample values:
{} 4 5 6 9 23

| Time (s) | Value |
|---------:|------:|
| 0  | 4 |
| 15 | 5 |
| 30 | 6 |
| 45 | 9 |
| 60 | 23 |

Applying linear regression to these points results in:

rate ≈ 0.28 increments per second

This value is different from `(23 − 4) / 60`, because regression smooths spikes and
handles irregularities more robustly.

---

## 6. Counter resets

Counters may reset when the process exposing them restarts.

Example series:
{} 4 5 10 2 15

The decrease from 10 to 2 indicates a **counter reset**.

---

## 7. Counter unwrapping (reset handling)

When a reset is detected, Prometheus reconstructs a **monotonically increasing**
series by adding the last value before the reset to subsequent samples.

| Time (s) | Original value | Corrected value |
|---------:|---------------:|----------------:|
| 0  | 4  | 4 |
| 15 | 5  | 5 |
| 30 | 10 | 10 |
| 45 | 2  | 12 |
| 60 | 15 | 25 |

This corrected series is used for all further calculations.

---

## 8. rate() with a reset

Using the corrected series:

(0, 4)  
(15, 5)  
(30, 10)  
(45, 12)  
(60, 25)

Applying the same regression formula results in:

rate ≈ 0.33 increments per second

The reset does not distort the result.

---

## 9. irate(): difference from rate()

`irate()` computes the per-second increase using **only the last two valid samples**
in the selected range.

Formula:

irate = (last − previous) / Δt

Using the last two corrected points:

(45, 12) → (60, 25)

irate ≈ (25 − 12) / 15 ≈ 0.87

### Comparison

- `rate()` is stable and smooth
- `irate()` is highly reactive but noisy

---

## 10. The increase() function

`increase()` returns the **total estimated increase** of a counter over a time
interval.

Internally, it uses the same regression as `rate()`.

Conceptually:

increase(range) = rate(range) × range_duration_in_seconds

---

## 11. increase() example with reset

Using the previous example:

rate ≈ 0.327 increments per second  
range duration = 60 seconds

increase ≈ 0.327 × 60 ≈ 19.6

This value is not equal to `25 − 4 = 21` because Prometheus estimates the trend
rather than relying on raw endpoints.

---

## 12. rate() vs increase()

| Function  | Meaning | Unit |
|----------|--------|------|
| rate()   | Average speed of increase | units per second |
| increase() | Total estimated increase | units |

---

## 13. Best practices for counter metrics

- Do not graph raw counter values
- Use `rate()` for:
  - alerting
  - aggregations
  - long-term analysis
- Use `increase()` for:
  - “How many events occurred in the last X minutes?”
- Avoid `irate()` in alerts
- Aggregate **after** computing the rate, for example:
  sum(rate(http_requests_total[5m]))

---

## 14. Exam key takeaways (PCA)

- `rate()` uses linear regression, not simple differences
- Counter resets are automatically handled
- `increase()` is equivalent to `rate() × time_range`
- Per-second units are preferred for alerting and composition

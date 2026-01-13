# Understanding delta() and deriv() for Gauge Metrics in PromQL

This document explains the behavior of the PromQL functions `delta()` and `deriv()`
when applied to **gauge metrics**, using a concrete example time series.

The goal is to clearly show **what information each function provides** and
**what information is lost**, which is a key concept for the
Prometheus Certified Associate (PCA) exam.

---

## Example gauge time series

Consider the following gauge metric sampled every 15 seconds:

{} 4 5 6 9 23

| Time (s) | Value |
|---------:|------:|
| 0  | 4 |
| 15 | 5 |
| 30 | 6 |
| 45 | 9 |
| 60 | 23 |

This metric is a **gauge**, meaning its value is allowed to increase or decrease
naturally over time.

---

## The delta() function

### Purpose

`delta()` measures the **raw change** of a gauge metric over a given time window.

It answers the question:

“How much did the value change between the beginning and the end of the range?”

---

### How delta() works

`delta()` considers only:
- the **first sample** in the range
- the **last sample** in the range

All intermediate samples are **ignored**.

Mathematically:

delta = last_value − first_value

---

### delta() applied to the example series

First value: 4  
Last value: 23  

Result:

delta = 23 − 4 = 19

This is the value returned by:

delta(gauge_metric[1m])

---

### What delta() does NOT tell you

From the result 19, `delta()` does not reveal:
- whether the increase was gradual or sudden
- whether the value spiked or fluctuated
- how the value behaved between the start and the end

It only reports the **net change**.

---

## Limitations of delta()

Because intermediate values are ignored, `delta()` can be misleading.

For example, a gauge could:
- spike to a very high value
- then return to its original value

In that case, `delta()` would return zero, even though a significant event occurred.

For this reason, `delta()` is best suited for simple change detection, not trend analysis.

---

## The deriv() function

### Purpose

`deriv()` measures the **rate of change per second** of a gauge metric over time.

It answers the question:

“At what speed is this gauge increasing or decreasing?”

---

### How deriv() works

`deriv()` applies a **linear regression** to all samples in the selected time range
and returns the **slope** of the best-fit line.

Conceptually, it fits:

value = a · time + b

and returns the coefficient `a`.

---

### deriv() applied to the example series

Using all samples:

(0, 4)  
(15, 5)  
(30, 6)  
(45, 9)  
(60, 23)

The linear regression produces a positive slope.

Result (approximately):

deriv ≈ 0.28 units per second

This value represents the **average speed of increase** of the gauge.

---

## What deriv() captures that delta() does not

Unlike `delta()`, `deriv()`:
- considers **all intermediate samples**
- smooths short-term fluctuations
- represents the **overall trend** of the data

While `delta()` only knows where the series started and ended,
`deriv()` captures **how it evolved over time**.

---

## delta() vs deriv(): comparison

| Function | What it measures | Method | Unit |
|--------|------------------|--------|------|
| delta() | Total change | Last − first sample | Same as metric |
| deriv() | Rate of change | Linear regression | Metric units / second |

---

## Key exam takeaway (PCA)

- `delta()` returns a raw difference and ignores intermediate behavior
- `deriv()` uses linear regression to describe the trend over time
- `delta()` is simple but potentially misleading
- `deriv()` is better suited for understanding how a gauge evolves

Understanding this distinction is essential for choosing the correct function
when working with gauge metrics in PromQL.

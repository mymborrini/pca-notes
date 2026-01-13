# PromQL Aggregation Functions: topk, bottomk, quantile, stddev, and stderr

This document provides a concrete, numeric example of how several PromQL aggregation functions work:
topk, bottomk, quantile, stddev, and stderr.

All examples operate on an instant vector, which is the input type required by aggregation operators.

---

## Example Scenario

Metric: request rate per instance, derived from a counter

rate(http_requests_total[5m])

Resulting instant vector:

- instance="a" → 120 requests/second
- instance="b" → 80 requests/second
- instance="c" → 200 requests/second
- instance="d" → 60 requests/second
- instance="e" → 140 requests/second

This represents five pods handling HTTP traffic, each with a different current load.

---

## topk(k, vector)

Purpose:
Selects the k time series with the highest values.

Example:
topk(2, rate(http_requests_total[5m]))

Result:
- instance="c" → 200
- instance="e" → 140

Typical use cases:
- identifying the most heavily loaded instances
- hotspot analysis
- debugging uneven load distribution

Important note:
topk filters time series; it does not aggregate them into a single value.

---

## bottomk(k, vector)

Purpose:
Selects the k time series with the lowest values.

Example:
bottomk(2, rate(http_requests_total[5m]))

Result:
- instance="d" → 60
- instance="b" → 80

Typical use cases:
- detecting underutilized instances
- identifying routing or load balancing issues
- finding replicas that receive little or no traffic

---

## quantile(φ, vector)

Purpose:
Computes the φ-quantile across the values of the instant vector.

Important:
This quantile is calculated across time series, not over time.

Example:
quantile(0.5, rate(http_requests_total[5m]))

Ordered values:
60, 80, 120, 140, 200

Result:
120

This corresponds to the median request rate across instances.

Another example:
quantile(0.9, rate(http_requests_total[5m]))

Result:
Approximately 200

Typical use cases:
- understanding the distribution of load across instances
- comparing median behavior to worst-case behavior
- capacity planning

---

## stddev(vector)

Purpose:
Calculates the standard deviation of the values in the vector, measuring how spread out the values are.

Formula:
The standard deviation is the square root of the average squared deviation from the mean.

For the example values:
60, 80, 120, 140, 200

Mean value:
(60 + 80 + 120 + 140 + 200) / 5 = 120

The resulting standard deviation is approximately:
49 requests/second

Example query:
stddev(rate(http_requests_total[5m]))

Typical use cases:
- evaluating load imbalance
- detecting uneven traffic distribution
- identifying anomalies

---

## stderr(vector)

Purpose:
Calculates the standard error of the mean, indicating how reliable the average value is.

Definition:
The standard error is the standard deviation divided by the square root of the number of samples.

Using the previous example:
- standard deviation ≈ 49
- number of series = 5

Standard error:
49 / sqrt(5) ≈ 21.9 requests/second

Example query:
stderr(rate(http_requests_total[5m]))

Typical use cases:
- assessing the stability of the mean
- evaluating confidence in aggregated averages
- statistical analysis (less common, but relevant for understanding aggregation behavior)

---

## Summary Table

Function:
- topk → returns the highest k time series
- bottomk → returns the lowest k time series
- quantile → returns a single value representing the distribution across series
- stddev → measures dispersion of values
- stderr → measures confidence in the mean

Key distinctions:
- topk and bottomk filter time series
- quantile, stddev, and stderr reduce the vector to a single value
- quantile in PromQL operates across series, not across time

---

## Exam-Oriented Takeaways

- Aggregation operators work on instant vectors
- topk and bottomk do not aggregate values; they select series
- quantile is not equivalent to histogram_quantile
- stddev measures variability, while stderr measures confidence in the average

Understanding these differences is essential for correct query design, dashboards, and alerting.

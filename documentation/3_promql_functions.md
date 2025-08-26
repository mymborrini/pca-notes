
# PromQL Functions

Some PromQL functions only work on **range vectors**, others on
**instant vectors**.

### `rate()`

     rate(http_requests_total{path="/hello"}[30s])

`rate(v range-vector)` calculates the per-second average rate of
increase of a counter. Aka is the discrete derivative

Example dataset (scraped every 15s):

-   1683000165 → 24\
-   1683000180 → 33\
-   1683000195 → 46

Rate = (46 - 24) / 30s = 22 / 30 ≈ **0.73 req/s**

------------------------------------------------------------------------

### `irate()`

     irate(http_requests_total{path="/hello"}[30s])

`irate(v range-vector)` calculates the **instantaneous** per-second rate
of increase, using only the last two samples in the range.

From the same dataset:

-   1683000180 → 33\
-   1683000195 → 46

Irate = (46 - 33) / 15s = 13 / 15 ≈ **0.86 req/s**

------------------------------------------------------------------------

### When to Use

-   `rate()` → better for **long-term trends** (smoothing).\
-   `irate()` → better for **short-term spikes** (volatility).

👉 Both functions should only be applied to **counters**, since they
assume monotonically increasing values.

## DELTA

Consider a gauge, for example `process_cpu_usage`.  
If you query it over a time range of 5 minutes, the result will be a range vector:

	process_cpu_usage[5m]  
	3.9 @@1683000165  
	4.2 @@1683000180  
	2.4 @@1683000195  
	5.5 @@1683000210  

If you want to see the change between the first and the last value in the time range, you can use the `delta` function:

	delta(process_cpu_usage[5m]) = 5.5 - 3.9 = 1.6

This number can be positive or negative, since gauges can both increase and decrease.


## AGGREGATION OPERATIONS

Aggregator functions combine multiple time series values into a single result:

- `sum(<vector>)` → scalar
- `avg(<vector>)` → scalar
- `max(<vector>)` → scalar
- `min(<vector>)` → scalar

For example, the `rate` function produces a per-second average increase over a range vector. Applied to a counter:

	rate(http_request_total[5m])  
	{method=DELETE path="/items/1" status=200} 0  
	{method=DELETE path="/items/4" status=200} 0  
	{method=GET path="/" status=200} 0.0105  
	{method=GET path="/items/1" status=200} 0  
	{method=GET path="/items/1" status=404} 0.007  
	{method=POST path="/items" status=200} 0.010  

Aggregating all values into a single scalar:

	sum(rate(http_request_total[5m])) = 0.0275  

The same logic applies for `min`, `max`, and `avg`.

### Aggregation by Label

Instead of collapsing into a scalar, you can group by a label:

- `sum by(<label>)(<vector>)` → vector
- `avg by(<label>)(<vector>)` → vector
- `max by(<label>)(<vector>)` → vector
- `min by(<label>)(<vector>)` → vector

Example:

	sum by(method)(rate(http_request_total[5m]))  

Result:

	{method=DELETE} = 0  
	{method=GET} = 0.0175  
	{method=POST} = 0.010  

So the final result vector is `[0, 0.0175, 0.010]`.

And you can aggregate further:

	sum(sum by(method)(rate(http_request_total[5m]))) = 0.0275


## AGGREGATION OVER TIME

These functions aggregate values inside a range vector:

- `sum_over_time(<range-vector>)`
- `avg_over_time(<range-vector>)`
- `min_over_time(<range-vector>)`
- `max_over_time(<range-vector>)`

For example, `sum_over_time` sums all values of a series within the window and produces a scalar for that time series.

Business-wise, `avg_over_time` is often the most useful for counters.


## HISTOGRAM QUERIES

Histograms are stored as `_bucket` series, for example:

	http_request_duration_seconds_bucket{le="0.005",method="GET",path="/",status="200"} 2.0  
	http_request_duration_seconds_bucket{le="0.01",method="GET",path="/",status="200"} 3.0  
	...  
	http_request_duration_seconds_bucket{le="+Inf",method="GET",path="/",status="200"} 8.0  

### Histogram Quantiles

The function:

	histogram_quantile(φ, <histogram-data>)  

computes the φ-quantile (0 ≤ φ ≤ 1). For example:

	histogram_quantile(0.95, sum by(le)(http_request_duration_seconds_bucket{method="GET",path="/",status="200"})) = 0.023  

This means 95% of GET `/` requests completed in under ~0.023s.


## AVERAGES AND TOTALS

To compute the average request duration, divide the rate of the total duration sum by the rate of the count:

	rate(http_request_duration_seconds_sum{...}[2m]) / rate(http_request_duration_seconds_count{...}[2m])  

This gives the average time per request.

Example:

- `rate(http_request_duration_seconds_sum[2m]) = 0.167 sec/sec`
- `rate(http_request_duration_seconds_count[2m]) = 0.333 req/sec`

Average request duration = `0.167 / 0.333 = 0.5 seconds/request`.


## INCREASE

The `increase` function calculates how much a counter increased in the range. It should **only be used with counters**.

Example:

	http_request_total{path="/"}[3m]  

	66 @@1683000165  
	66 @@1683000180  
	66 @@1683000195  
	77 @@1683000210  

increase(http_request_total{path="/"}[3m]) = 11

Unlike `delta`, `increase` properly accounts for counter resets:

Example: `100 → 150 → reset → 10 → 40`

increase = (150 - 100) + (40 - 10) = 80

Prometheus may return fractional values due to extrapolation, especially for small ranges. Longer ranges stabilize the result.


## DELTA vs INCREASE vs RATE

| Function   | Input Type | Output | Handles Reset? | Use Case |
|------------|-----------|--------|----------------|----------|
| `delta`    | Gauge or Counter | Difference (last - first) | ❌ No | Track change over time for gauges |
| `increase` | Counter | Total increase over range | ✅ Yes | Count events occurred in a time window |
| `rate`     | Counter | Per-second average rate | ✅ Yes | Monitor speed of events (req/s, err/s) |
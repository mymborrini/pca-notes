# Prometheus & Grafana

There are two methodologies to create meaningful dashboards:

 - RED (Request Errors Duration)
 - USE (Utilization Saturation Errors)

The RED methodology are the ones that expose metrics that affect the *user experience* and the USE methodology are the one that
related to the *System performance*.
Creating a dashboard that combines both methodology we provide a dashboard that monitor both user experience and system performance

Is a good idea to first create a query in prometheus using promql and then moving to the grafana dashboard.


## Web Application monitoring dashboard. How to build it?

This dashboard is gonna show the best practice to monitor an application.

### When the application started up? (USE)

#### PROMQL
The metric is called *process_start_time_seconds* it's a count and it shows the timestamp of when the application starts up.
So since we need the difference in time the promql query should be something like the following:

    time() - process_start_time_seconds{job="skynet-app"}

#### Grafana

For this type of dashboard we can use a *Stat*. Stat are really useful to display a single value that acts as indicator
Once we typed the promql query in grafana we can see that probably the value is displayed in RED. The reason for that is that grafana set
a default *threshold* to 80. If we simply remove this, it will return to the base color (green by default). We can remove the *Graph mode*,
no need in this case in order to see only the number. Since this value is expressed in Seconds we need to tell grafana about this unit of measure. \
We can do this in the *Standard Options*. One general fact is that we generally don't want to hardcode value into labels, because they
can change in the future. In the *Dashboard Settings* we can add variables. In the variable editing form you can specify the type *Query* 
you will have a Section called *Query Options* where you can specify a query. The query can be something like this

    label_values(job)

*label_values($label_name)* is a build in grafana function that will scrape every labels inside the datasource and will offer a selection upon this labels.
The PromQL query should be change like this:

    time() - skynet_process_start_time_seconds{job="$job"}

### How many requests are happening within a particular time frame (RED)

Too many requests may slow the application down, this may effect performance so we need to plot it. We can use the http_request_total metric to check it

#### PromQL

    skynet_http_request_total{job="$job"}

But I need fresh data, in the past 5 minutes (excluding metrics or not... maybe not)

    sum(increase(skynet_http_request_total{job="skynet-app"}[5m]))

The increase is extrapolated to cover the full time range as specified in the range vector selector, 
so that it is possible to get a non-integer result even if a counter increases only by integer increments.

#### Grafana

So as before we can use the Stat graph and we can use the PromQl query we created before to get some data. 

    sum(increase(skynet_http_request_total{job="$job"}[5m]))

The problem with that is that whenever I change the time-range in grafana it will only display the last 5 minutes

    sum(increase(skynet_http_request_total{job="$job"}[$__range]))

Since increase (like we said before) add some decimals during the extrapolation process, we don't need those decimals.
We can tell grafana to ignore them. So *Standard Options/Decimals* we can set this value to 0.




---

## Difference between $__range and $__interval

$__interval and $__range are dynamic variables used in Grafana when building PromQL queries.
They define how much historical data each Prometheus function should look at — but in very different ways.

### 🕐 $__interval

- Represents the step size (sampling interval) Grafana chooses automatically based on:
    - The selected time range in the dashboard, and
    - The width/resolution of the graph panel.
- It adapts dynamically — larger time ranges get larger intervals.

Example:
        
    rate(http_requests_total[$__interval])

Grafana might replace $__interval with:

- 30s if you’re viewing the last 10 minutes
- 5m if you’re viewing the last 24 hours
- 1h if you’re viewing the last 10 days

This keeps the graph smooth and efficient without overwhelming Prometheus with data points.

✅ Use when you want continuous, time-dependent charts.

### 🕓 $__range

- Represents the entire visible time range selected in Grafana (e.g., last 5m, 1h, 7d).
- Using it in a function like: rate(http_requests_total[$__range]) tells Prometheus to compute the rate over the whole selected range.

This gives you one averaged value over that period — not a dynamic curve.

✅ Use when you want a single summary or average metric (e.g., “average requests/sec in the last hour”).

### 💡 In short:

- $__interval adjusts the query resolution to the zoom level of your dashboard.
- $__range covers the whole visible period, giving a single aggregated view.





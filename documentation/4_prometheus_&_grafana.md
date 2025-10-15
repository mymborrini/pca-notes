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

### When the application started up? (Use)

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

### How many requests are happening within a particular time frame (Red)

Too many requests may slow the application down, this may effect performance so we need to plot it. We can use the http_request_total metric to check it

#### PromQL

    skynet_http_request_total{job="skynet-app"}

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


### The error rate (rEd)


#### Promql

A promql query could be something like this

    sum(increase(skynet_http_request_total{job="skynet-app", status=~"(4..|5..)"}[3m]))/sum(increase(skynet_http_request_total{job="skynet-app"}[3m]))
  
Consider that of course even if in the request compare the rate word, it doesn't mean you have to use the rate 

N.B Another way we could create this query is writing something like this:

    ( sum(increase(skynet_http_request_total{job="skynet-app", status=~"4.."}[3m])) + sum(increase(skynet_http_request_total{job="skynet-app", status=~"5.."}[3m])))/sum(increase(skynet_http_request_total{job="skynet-app"}[3m]))

If we run this query we got a `Empty query result`. WHY? Because this query 

    sum(increase(skynet_http_request_total{job="skynet-app", status=~"5.."}[3m]))

Returns   `Empty query result` and in promql

>> THE SUM OF AN EMPTY VECTOR AND AN INSTANT/RANGE VECTOR WILL RETURN AN EMPTY VECTOR


So we have to change this query like the following 

    sum(increase(skynet_http_request_total{job="skynet-app", status=~"5.."}[3m])) or vector(0)

Adding or vector(0) will return a vector with a single value of 0 and this could be sum. Why this behaviour? 
Because prometheus always works with vector and in math *YOU CANNOT SUM TWO VECTOR WITH DIFFERENT DIMENSIONS*

    [16] + []  = makes no sense!
    [16] + [0] = [16]

The final query could be 

    ( 
      sum(increase(skynet_http_request_total{job="skynet-app", status=~"4.."}[3m])) or vector(0) + 
      sum(increase(skynet_http_request_total{job="skynet-app", status=~"5.."}[3m])) or vector(0)
    ) /
       sum(increase(skynet_http_request_total{job="skynet-app"}[3m])) or vector(0) 

#### Grafana

To show in grafana we can add a new Panel (always Stat), the query could be something like this:

    ( 
      sum(increase(skynet_http_request_total{job="$job", status=~"4.."}[$__range])) or vector(0) + 
      sum(increase(skynet_http_request_total{job="$job", status=~"5.."}[$__range])) or vector(0)
    ) /
       sum(increase(skynet_http_request_total{job="$job"}[$__range])) or vector(0) 

In this case the threshold make sense and we can set it at 0.1 for example. If 10% of requests returns error display the Stat 
red (or the color you like). Then we specify that the unit is a percentage between 0 and 1. We set the name as well  *Error Rate* for example

### The average request duration (reD)

#### Promql

How long is each request take on average? We need to take the rate of request duration over time and divided by rate of the number of requests  
The first one will give us seconds/second the second one requests/second. So if we divide the first one for the other we obtain seconds/requests

So in our case it could be something like this:

    rate(skynet_http_request_duration_seconds_sum[5m]) / rate(skynet_http_request_duration_seconds_count[5m])

For each request in the same semantic domain. If we want to sum to get the average request duration of the total request divided by the total number of requests 

    sum(rate(skynet_http_request_duration_seconds_sum[5m])) / sum(rate(skynet_http_request_duration_seconds_count[5m]))

>> 
> This will change the semantic domain since when you sum prometheus will delete all the semantic domain


#### Grafana

In grafana we can create another Stat for that

    sum(rate(skynet_http_request_duration_seconds_sum{job="$job"}[$__range])) / sum(rate(skynet_http_request_duration_seconds_count{job="$job"}[$__range]))

We can set the threshold for example at 0.1. 0.1 is really lot of time for an average requests. We can set the unit as second and the name 
of the panel as Average Request Duration

### How many requests are in progress

Consider that it doesn't ask in the last 5 or 10 minutes. So we can assume it is in this right moment, therefore is not necessary to add a time range and 
a rate but we have to consider that the metrics endpoint is always called so we gave to remove it otherwise it can generate confusion. 

#### Promql

A possible query could be like this

    sum(skynet_http_requests_in_progress{path!="/metrics"}[5m])

#### Grafana

As before we can use a *Stat* panel, if there are more than 10 request in progress we can reach the threshold. 
THe query could be something like this

    sum(skynet_http_requests_in_progress{path!='/metrics', job="$job"})


### Organize Dashboards for new roles

We can isolate all this metrics in grafana by creating. And we can create a new rows for further metrics.
a new row called *Requests*, A new Row called *Errors* a new one called *Duration* and another one called *System Metrics*

### Requests Row

### API throughput for evey single path

I want to measure the requests per seconds for every single path

#### Promql

A possible query could be:

    sum by (path,method) (rate(skynet_http_request_total{job="skynet-app"}[10m]))

If we want something a little more cleaner we can regroup all the path like items/d with a query like this:

    sum by (normalized_path,method) (
      label_replace(
        rate(skynet_http_request_total{job="skynet-app"}[10m]),
        "normalized_path",
        "${1}${2}${3}",
        "path",
        "^(/)(items)?(/)?(.*)?"
      )
    )

#### Grafana

This time is gonna be a Time Series Panel. The legends is verbose, we can set a custom legend like the following "{{path}}:{{method}}"
The unit is a specific one in grafana *rps* (request per second). We can put this panel under the requests rows

The query in Grafana could be something like this

    sum by (normalized_path,method) (
      label_replace(
        rate(skynet_http_request_total{job="$job"}[$__range]),
        "normalized_path",
        "${1}${2}${3}",
        "path",
        "^(/)(items)?(/)?(.*)?"
      )
    )


### Error Rate Requests by Status Code

#### Promql

A possible promql query could be something like this

    sum by(status) (rate(skynet_http_request_total{job="skynet-app"}[5m]))


#### Grafana 

The best way to display this two values is to use a pie chart. The query could be something like the following:

    sum by(status) (rate(skynet_http_request_total{job="$job"}[$__range]))

Of course we can customize the legend, something like this `Status: {{status}}`. The piechart could be of type donut, and we can set properties
like the percentage 


### Api Latency percentiles

We can use the `http_request_duration_seconds_bucket`. They are a histogram metric and we can use to compute latency.

#### Promql

If we want to group by the latency we could execute a query like this:

    sum by(le) (rate(skynet_http_request_duration_seconds_bucket{job="skynet-app"}[5m]))

But we can also do something like the following. How long does 95% of the requests take? In this case we can make a query by using
the functions histogram_quantile. So something like this:

    histogram_quantile(0.95, sum by(le) (rate(skynet_http_request_duration_seconds_bucket{job="skynet-app"}[5m])))

The result could be something like this:

    {} 0.0047728

Which means that 0.95 % of our request took less than 0.0047728 seconds. Consider that for how histogram_quantile works you can substitute rate with increase, 
because histogram_quantile works with proportion
    
#### Grafana

In Grafana we can represents this as a time series, the panel could be named as *API Latency Percentiles*. This panel will have 4 queries
the first one will measure how long 50% of requests took, the second one is 75%, the third one 90% and the last one 95%

    histogram_quantile(0.5, sum by(le) (rate(skynet_http_request_duration_seconds_bucket{job="$job"}[$__range])))
    histogram_quantile(0.75, sum by(le) (rate(skynet_http_request_duration_seconds_bucket{job="$job"}[$__range])))
    histogram_quantile(0.9, sum by(le) (rate(skynet_http_request_duration_seconds_bucket{job="$job"}[$__range])))
    histogram_quantile(0.95, sum by(le) (rate(skynet_http_request_duration_seconds_bucket{job="$job"}[$__range])))
   
We can change the legends as p50, p75, p90, p95. We can change the Unit to Seconds and we can move this panel under the `Duration` row.

### Average duration of requests

Another panel that we can use to measure duration is the average duration of request. It means for every path, statusCode etc... how is the average duration?
Remember to not sum the skynet_http_request_duration_seconds_bucket because we already have the right metric for it `skynet_http_request_duration_seconds_sum`

#### Promql

So to get the number of seconds the requests take in the last 1 minutes

    rate(skynet_http_request_duration_seconds_sum{job="skynet-app"}[1m])

And to get the number of requests in the last 1 minute

    rate(skynet_http_request_duration_seconds_count{job="skynet-app"}[1m])

Then to get the average we can simply divide them

    rate(skynet_http_request_duration_seconds_sum{job="$job"}[1m]) / rate(skynet_http_request_duration_seconds_count{job="$job"}[1m])


#### Grafana

So in grafana the query could be something like this:

        sum(rate(skynet_http_request_duration_seconds_bucket{job="$job"}[1m])) / sum(rate(skynet_http_request_duration_seconds_count{job="$job"}[1m]))

In this case I want to take 1m as interval, so grab the average request every minutes and be able to view it across any range that we choose.
THe legend could be something like {{method}}:{{path}}:{{status}}. And the unit of measure could be seconds.


### CPU Usage

We can measure the CPU Usage

#### Promql

    skynet_process_cpu_usage{job="skynet-app"}

#### Grafana

And in grafana we can have something like this:

    skynet_process_cpu_usage{job="$job"}

We are going to display a stat and we can say as a unit of measure, a percentage.

### Open file descriptor

Another important metrics to expose is to describe how many open connections the application currently has to different files socket and types

#### Promql

So we will use the `process_open_fds` and the `process_max_fds` so that 

    skynet_process_open_fds{job="skynet-app"} / skynet_process_max_fds{job="skynet-app"}

This will give us the percentage that we can display

#### Grafana

In grafana the query could be something like this:

    skynet_process_open_fds{job="$job"} / skynet_process_max_fds{job="$job"}

We can set the graph as a Stat and we name it `Open File Descriptors`


### Memory Usage

Almost evey app expose this metrics process_resident_memory_bytes which describe the memory in bytes used by the application

#### Promql 

A possible query could be the following

    skynet_process_resident_memory_bytes{job="skynet-app"}

Another one is the virtual memory which includes both the real one and the swap space

    skynet_process_virtual_memory_bytes{job="skynet-app"}

And the last one the memory usage

    skynet_process_memory_usage_bytes{job="skynet-app"}

#### Grafana

We can set three queries in grafana

    skynet_process_resident_memory_bytes{job="$job"}
    skynet_process_virtual_memory_bytes{job="$job"}
    skynet_process_memory_usage_bytes{job="$job"}

We can change the Panel title as `Memory Usage` and the legend as 
- Resident Memory
- Virtual Memory
- Memory Usage

### Garbage collection activity

We can do this through the metric `python_gc_objects_uncollectable_total`. In this case we are interested in the rate at which 
objects are being collected per second


#### Promql

An interesting query in promql could be

    rate(skynet_python_gc_objects_collected_total{job="skynet-app"}[5m])

The generation 0 should have the highest rate, means that most of the objects is deleted after few gc cycle

#### Grafana

In Grafana the query is similar

    rate(skynet_python_gc_objects_collected_total{job="$job"}[$__range])

In this case if I change the timerange in grafana it won't affect the promql query 


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


--- 

## What is a semantic dimension?

### 💡 1️⃣ Each label defines a semantic dimension

Every time you add a label to a metric, you’re implicitly saying:

“I want to measure this phenomenon as a function of this variable.”

Example:

```
http_request_duration_seconds{method="GET", path="/users"}
```

is not just a measurement of response time —  it’s a parameterized function:

    D[method, path](t)

where method and path become *coordinates of the domain*.

If you define another metric without the same labels, you’re effectively creating a function with a different domain

    N[status](t)

→ and mathematically, those two functions are not pointwise comparable.

### 💡 2️⃣ What happens when you mix different domains

When you write something like:

```promql
rate(D[5m]) / rate(N[5m])
```

Prometheus tries to join the two families of time series based on their common labels.

If the label sets don’t match perfectly:
- some series won’t find a “partner” and will disappear, 
- others may be aggregated in unexpected ways, 
- and the final result becomes semantically ambiguous.

This is the classic case where “the graph looks right, but the numbers don’t make sense.”

### 💡 3️⃣ Best practice: maintain label consistency

✅ All metrics describing the same logical event should share the same key labels.
For example, for HTTP requests:
- http_requests_total{method, path, status}
- http_request_duration_seconds_sum{method, path, status}
- http_request_duration_seconds_count{method, path, status}

This consistency ensures you can safely combine them (divide, sum, aggregate) in PromQL without losing semantic meaning.

### 💡 4️⃣ What not to do

Avoid definitions like:

```promql
# ❌ Missing "status"
http_requests_total{method, path}
# ❌ Missing "path"
http_request_duration_seconds_sum{method, status}
```

Because queries such as:

```
rate(http_request_duration_seconds_sum[5m]) / rate(http_requests_total[5m])
```
will fail or return incomplete data.

### 💡 5️⃣ The mathematical view

All metrics belonging to the same semantic domain should share the same label space:

    ∀Mi,  Mi:L1|L2|...|Ln | T→R

That is:
>>
> each metric Mi must be a function of the same labels L1,L2 and time T

Only then can you combine their derivatives, sums, or ratios in a mathematically consistent way.


### 💡 6️⃣ Summary

| Best Practice                                                          | Why                                      |
| ---------------------------------------------------------------------- | ---------------------------------------- |
| Always use the same labels for related metrics                         | Ensures consistent joins and aggregation |
| Avoid pre-aggregated metrics in code                                   | Preserves granularity and flexibility    |
| Let Prometheus perform averages/sums                                   | Keeps the model uniform                  |
| Define a clear semantic level for labels (e.g., app, endpoint, status) | Prevents conceptual confusion            |


---

## What is Process Open FDS

The metric process_open_fds is a gauge (a value that can go up or down over time), and it indicates:
> The number of file descriptors (FDs) that the application process currently has open.

### 📘 What is a file descriptor (FD)?

In Unix/Linux systems, everything is a file:

- a real file on the filesystem,
- a TCP or UDP socket,
- a pipe,
- a device,
- or even a log stream.

Each time a process opens one of these objects, the kernel assigns it a file descriptor.
When the process closes it, the FD is released.

### What process_open_fds shows

This metric shows, in real time, how many of these FDs are currently in use.
Practical examples:

| Case                                            | Effect on metric                |
| ----------------------------------------------- | ------------------------------- |
| The app opens new TCP connections               | 🔺 `process_open_fds` increases |
| The app writes to many log files simultaneously | 🔺 increases                    |
| The app closes files or connections             | 🔻 decreases                    |
| The app has a file or socket leak               | 📈 keeps increasing steadily    |

### ⚠️ Why it matters

A high or constantly increasing number of open FDs can indicate:

- resource leaks (files or sockets not properly closed),
- stale connections,
- misconfiguration (low ulimit -n).

If the process exceeds the maximum allowed number of FDs, it will start failing with errors like: `EMFILE: too many open files`

### 💡 Related metrics

| Metric             | Meaning                                                       |
| ------------------ | ------------------------------------------------------------- |
| `process_max_fds`  | Maximum number of FDs the process *can* open (system limit)   |
| `process_open_fds` | Current number of open FDs                                    |
| → Useful ratio     | `process_open_fds / process_max_fds` → percentage of FD usage |

---

## 🧠 Understanding Memory Metrics in Prometheus

When monitoring applications with Prometheus, you may encounter different memory-related metrics.  
Although they sound similar, they describe **different aspects of memory usage**.


### 1. `process_resident_memory_bytes`

**Definition:**
> Physical memory (RAM) actually used by the process.

This represents the **real RAM** currently occupied by your application — the amount of memory physically held in use.

**Includes:**
- Stack and heap memory
- Code segments
- Shared memory (only the used parts)

**Analogy:**  
Think of it as “how much RAM the process is truly using right now”.

**Used for:**
- Detecting real memory pressure
- Spotting memory leaks
- Setting alert thresholds


### 2. `process_virtual_memory_bytes`

**Definition:**
> Total virtual memory address space allocated by the process.

This measures **how much memory address space** the OS has reserved for the process — **not all of it is actually in use**.

**Includes:**
- Used memory (resident)
- Reserved but untouched memory
- Memory-mapped files and libraries

**Analogy:**  
It’s like the floor plan of your apartment — even if you have 10 rooms, you might only be using 3.

**Used for:**
- Debugging virtual memory fragmentation
- Detecting excessive memory reservations


### 3. `process_memory_usage_bytes`

**Definition:**
> Total memory used by the process, including runtime allocations.

⚠️ This metric is **not standard** in Prometheus. It usually comes from **language-specific exporters** or **custom instrumentation**.  
Depending on the exporter, it may represent:
- Heap + stack memory,
- Or only heap memory managed by the runtime (e.g., Go, Python, Node.js).

**Examples:**
- Go: `runtime.MemStats.Alloc`
- Node.js: `process.memoryUsage().rss`
- Python: `psutil.Process().memory_info().rss`

**Used for:**
- Runtime-level memory analysis
- Language-specific debugging


### 🧩 Comparison Table

| Metric | Meaning | Includes | Typical Use | Analogy |
|--------|----------|-----------|--------------|----------|
| `process_resident_memory_bytes` | Physical RAM actually used | Heap, stack, code, shared libs (used part only) | Detect real memory pressure | “RAM currently occupied” |
| `process_virtual_memory_bytes` | Total virtual address space reserved | Used + reserved + mapped memory | Debug virtual memory usage | “All rooms reserved, used or not” |
| `process_memory_usage_bytes` | Depends on exporter (usually runtime memory) | Runtime-managed memory | Runtime or language diagnostics | “Memory seen by the runtime” |

### 🧭 Summary

- 🟢 **Use `process_resident_memory_bytes`** for tracking *real physical RAM* usage.
- 🟡 **Use `process_virtual_memory_bytes`** to detect *oversized memory reservations*.
- 🔵 **Use `process_memory_usage_bytes`** only if you know *how your exporter defines it*.

---

## ♻️ Garbage Collector Metrics: `gc_objects_collected_total`

When monitoring applications that use automatic memory management (like Python, Java, or .NET),  
you may find metrics related to the **Garbage Collector (GC)** such as:

	gc_objects_collected_total{generation="0"}
	gc_objects_collected_total{generation="1"}
	gc_objects_collected_total{generation="2"}


### 🧠 What This Metric Means

`gc_objects_collected_total` counts the **total number of objects that have been freed by the garbage collector** since the process started.

It is a **counter metric** — the value only increases every time the GC runs and successfully reclaims memory from unused objects.


### ⚙️ Why There Are “Generations”

Most modern garbage collectors are **generational**, based on the idea that:

> “Most objects die young.”

This means that most temporary objects (e.g., request buffers, local variables) are created and destroyed quickly,  
while only a few long-lived objects (e.g., caches, global configurations) persist over time.

To optimize performance, the GC divides objects into **three generations**:

| Generation | Typical Contents | Collection Frequency | Description |
|-------------|------------------|----------------------|--------------|
| **0 (Young)** | Newly created, short-lived objects | Very frequent | Small, fast GC cycles. Most objects die here. |
| **1 (Intermediate)** | Objects that survived a few GCs | Less frequent | Used for objects with a medium lifespan. |
| **2 (Old / Tenured)** | Long-lived objects | Rare | Expensive GC cycle that scans a larger part of memory. |

### 🔍 Example

If you see metrics like:

	gc_objects_collected_total{generation="0"}  150000
	gc_objects_collected_total{generation="1"}   50000
	gc_objects_collected_total{generation="2"}   2000

It means:

- **150,000** short-lived objects were freed during young-generation GC runs
- **50,000** medium-lived objects were collected in intermediate GCs
- **2,000** long-lived objects were reclaimed during major GCs

---

### ⚡ Why Generational GC Improves Performance

A generational collector avoids scanning all memory on every cycle.  
Instead, it performs:
- **Frequent, lightweight collections** on new objects (generation 0)
- **Infrequent, deeper collections** on long-lived objects (generation 2)

This reduces CPU load and pause times, improving application responsiveness.

### 📊 Useful PromQL Queries

| Goal | PromQL Example | Description |
|------|----------------|--------------|
| Rate of collected objects per generation | `rate(gc_objects_collected_total[5m])` | Shows how many objects per second are being freed |
| Compare collection frequency by generation | `sum by (generation) (rate(gc_objects_collected_total[5m]))` | Reveals where most GC activity occurs |
| Detect GC anomalies | `increase(gc_objects_collected_total{generation="2"}[10m])` | Detects unusual growth in old-generation collections |


### 🔬 Related Metrics

You can correlate `gc_objects_collected_total` with other GC metrics to get deeper insights:

| Metric | Description |
|---------|-------------|
| `gc_collections_total{generation="..."}` | Number of GC runs per generation |
| `gc_duration_seconds` | Total time spent in GC pauses |
| `process_resident_memory_bytes` | Real memory usage after GC cycles |


### 🧭 Summary

| Concept | Meaning |
|----------|----------|
| `gc_objects_collected_total` | Total number of freed objects since process start |
| `generation="0"` | Young objects — collected often, cheap operation |
| `generation="1"` | Medium-lived objects — collected occasionally |
| `generation="2"` | Long-lived objects — collected rarely, high cost |
| Why 3 generations? | To optimize performance: collect small areas often, big areas rarely |

### ✅ Key Takeaways

- High **generation 0** collection rate → normal (many short-lived objects)
- Frequent **generation 2** collections → may indicate memory leaks or retention issues
- Combine with `gc_duration_seconds` and `process_resident_memory_bytes` for full memory behavior analysis.

---

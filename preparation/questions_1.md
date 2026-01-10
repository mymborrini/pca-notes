## 1 Exam Question – Prometheus Expression Browser and Observability

You are given access to a running Prometheus instance and its web UI.

1. Explain the purpose and differences between the Table, Graph, and Explain tabs in the Prometheus expression browser. In your answer, discuss why graphing certain queries can be computationally expensive and describe a recommended workflow for safely testing potentially expensive PromQL expressions.

2. Using the Prometheus expression browser, explore metrics related to data ingestion in the Prometheus TSDB:

   - Identify a metric that represents the total number of samples ingested into Prometheus local storage since the process started.
   - Write a PromQL query that calculates the rate of sample ingestion per second, averaged over a short time window.

3. Investigate target health monitoring in Prometheus:

   - Identify the synthetic metric used by Prometheus to represent whether a scrape target is reachable.
   - Write a PromQL expression that retrieves the value of this metric specifically for the Prometheus server itself.
   - Briefly explain how the values of this metric should be interpreted in the context of successful or failed scrapes.

You may use the Prometheus UI to validate your queries, but focus on clearly explaining your reasoning and the intent behind each query

## 2 Exam Question – Selecting Time Series Data in PromQL

You are working with a Prometheus server that stores time series data in its TSDB. Before performing advanced analysis, you need to understand how to select and filter series using PromQL.

1. Explain how time series are selected in PromQL using only a metric name. Describe what information is displayed when executing such a query in:

   - the Table view
   - the Graph view of the Prometheus expression browser.

2. Consider a counter metric that represents the total number of handled API requests and is generated as part of a histogram tracking request durations.

   - Describe the purpose of this metric and explain why its name includes the suffix related to request duration.
   - Discuss why, in some cases, a differently named standalone counter metric might be preferable.

3. Demonstrate how to narrow down the selected time series by applying label-based filters:

   - Write a PromQL query that selects only requests resulting in a specific HTTP status code.- Write a query that filters the same metric using multiple label conditions (for example, HTTP method and status code).
   - Explain how multiple label matchers are combined when selecting time series.

4. Prometheus supports several types of label matchers beyond simple equality.

   - Describe the different label matcher operators available in PromQL.
   - Provide an example use case where a regular expression matcher would be more appropriate than exact matching.
   - Explain how regular expression matching works in Prometheus, including how full anchoring affects matching behavior.

5. Internally, Prometheus represents metric names as a special label.

   - Explain how metric names are represented internally and how this knowledge can be used to select time series.
   - Describe a scenario where selecting multiple metric names using regular expressions could be useful.

6. In larger environments, multiple services may expose metrics with the same name.

   - Explain why this can lead to ambiguity or errors in queries.
   - Describe best practices for avoiding metric name collisions, including how to use the job label in PromQL selectors.

## 3 Exam Question – Counter Metrics and Rate Functions in PromQL

In Prometheus, many metrics are exposed as counters that continuously increase over time, such as the total number of HTTP requests handled by a service.

1. Explain why graphing raw counter metrics is generally not very useful for observability purposes. In your answer, discuss why the absolute value of a counter is usually less relevant than its rate of change.

2. Describe how PromQL can be used to analyze how fast a counter is increasing:

   - Explain the purpose of the rate() function and how it calculates values over time
   - Describe the role of a range selector and how it affects the calculation performed by rate().

3. Write a PromQL query that calculates the per-second rate of increase of an HTTP request counter metric for a specific job, averaged over a multi-minute time window. Explain why the resulting graph is typically more informative than graphing the raw counter values.

4. Counter metrics may reset when a monitored process restarts.

   - Explain how counter resets occur.
   - Describe how the rate() function handles counter resets and why this behavior is important for accurate analysis.

5. PromQL provides multiple functions for calculating counter rates.

   - Explain the difference between rate() and irate(), including how each function uses the provided time window.
   - Discuss scenarios where irate() is more appropriate than rate(), and vice versa.

6. In addition to per-second rates, PromQL allows querying the total increase of a counter over a time window.

   - Explain the purpose of the increase() function.
   - Compare increase() with rate() in terms of use cases and interpretability.

7. Discuss best practices for working with counter metrics in PromQL, including why using per-second units is generally recommended for long-term analysis, alerting, and expression composition.

# 4 Exam Question – Working with Gauge Metrics in PromQL

Prometheus supports different metric types, including counters and gauges. Unlike counters, gauge metrics represent values that may increase or decrease over time.

1. Explain why the PromQL functions rate(), irate(), and increase() are only applicable to counter metrics. In your answer, describe how these functions interpret decreases in metric values and why this behavior is incompatible with gauge metrics.

2. Describe the characteristics of gauge metrics and provide examples of real-world measurements that are typically modeled as gauges.

3. PromQL provides specific functions to analyze changes in gauge metrics over time:

   - Explain the purpose of the delta() function and how it calculates changes over a specified time window.
   - Write a PromQL query that calculates the raw change in disk usage over a fixed time window for a given job.
   - Explain what information this query would return when viewed in the Table view.

4. Discuss the limitations of the delta() function:

   - Explain how delta() treats intermediate data points within the selected time window.
   - Describe a scenario where ignoring intermediate trends could lead to misleading conclusions.

5. To analyze trends more accurately, PromQL offers the deriv() function.

   - Explain how deriv() differs from delta() in terms of the calculation method.
   - Describe how linear regression is used to compute the per-second rate of change for gauge metrics.

6. PromQL also supports basic prediction of future values.

   - Explain the purpose of the predict_linear() function.
   - Write a PromQL query that predicts the future value of a gauge metric based on its recent behavior.
   - Discuss the assumptions and limitations of using linear prediction for observability data.

Your answers should demonstrate a clear understanding of metric types and appropriate function usage in PromQL.

# 5 Exam Question – Aggregation and Dimensionality in PromQL

Prometheus time series data is often highly dimensional, allowing detailed analysis across many labels. However, for observability and reporting purposes, it is frequently necessary to aggregate data across selected dimensions.

1. Explain what is meant by high-dimensional time series data in Prometheus and discuss why aggregation is often required to obtain meaningful, high-level insights.
2. Describe how aggregation can be used to calculate the overall request rate for a service:

   - Explain the role of the sum() aggregation operator when applied to per-series rate calculations.
   - Describe the characteristics of the output when aggregating across all dimensions.

3. In many cases, it is desirable to preserve some dimensions while aggregating over others.

   - Explain how the without() modifier can be used with aggregation operators.
   - Write a PromQL query that aggregates request rates while excluding specific labels from the result.
   - Explain how this approach affects the grouping of the resulting time series.

4. The by() modifier provides an alternative way to control aggregation behavior.

   - Explain the relationship between by() and without() modifiers.
   - Describe how to determine which labels should be included in a by() clause to achieve a desired grouping.

5. PromQL supports a variety of aggregation operators beyond simple summation.

   - Describe the purpose and typical use cases of at least four different aggregation operators.
   - Explain which aggregation operators require additional parameters and what those parameters represent.

6. Discuss best practices for choosing aggregation dimensions in PromQL queries, including how aggregation decisions can impact:

   - dashboard readability
   - query performance
   - interpretability of results

Your answers should demonstrate a solid understanding of PromQL aggregation mechanics and dimensional analysis.

# 6 Exam Question – Arithmetic and Vector Matching in PromQL

PromQL provides powerful capabilities for performing arithmetic operations on scalars and entire sets of time series, enabling advanced analysis and derived metrics.

1. Explain how PromQL handles scalar arithmetic.

   - Describe how basic mathematical expressions involving only scalar values are evaluated
   - Explain the type of result returned by such expressions.

2. Describe how scalar-to-vector arithmetic works in PromQL.

   - Explain how a scalar operation is applied to a vector of time series.
   - Provide an example use case where converting metric units using scalar arithmetic would be useful.

3. One of PromQL’s key features is its ability to perform arithmetic between two vectors of time series.

   - Explain how PromQL matches time series between the left-hand side and right-hand side of a binary operation.
   - Describe which labels are considered for vector matching and which are ignored.

4. Histogram metrics often expose multiple related series.

   - Explain how binary operations can be used to calculate the average request duration from histogram \_count and \_sum series.
   - Describe how PromQL preserves label dimensions in the output of such vector-to-vector operations.

5. Vector matching may fail when label sets do not align.

   - Explain why directly dividing a subset of time series (for example, error responses only) by a superset of time series may produce incomplete or incorrect results.
   - Describe how aggregation can be used to align vectors before performing a binary operation.

6. Explain how the by() and without() modifiers can be used to control label dimensions when preparing vectors for arithmetic operations.

   - Discuss how these modifiers influence which dimensions are preserved in the result.

7. In some cases, one side of a binary operation contains additional label dimensions that should be preserved.

   - Explain the purpose of the group_left and group_right modifiers.
   - Describe how the on() modifier is used to explicitly define matching labels in such scenarios.

8. Compare the on() and ignoring() matching modifiers.

   - Explain when each should be used.
   - Discuss how incorrect matching criteria can affect the correctness of query results.

Your answers should demonstrate a clear understanding of PromQL arithmetic, vector matching rules, and advanced binary operation modifiers.

# 7 Exam Question – Node Exporter Setup and System Observability with Prometheus

The Prometheus Node Exporter exposes a wide range of system-level metrics that can be used to monitor resource usage and system behavior.

1. Explain the role of the Node Exporter in the Prometheus ecosystem.

   - Describe what collector modules are and how they can be enabled or disabled.
   - Explain why the default Node Exporter configuration is often sufficient for most use cases.

2. You are asked to deploy the Node Exporter using Docker.

   - Describe the purpose of mounting the host’s root filesystem into the container.
   - Explain why the --path.rootfs flag is required and what problem it solves.
   - Discuss the implications of running the Node Exporter container with host networking and PID namespace access.

3. After starting the Node Exporter, you need to configure Prometheus to scrape it.

   - Describe the steps required to add a new scrape configuration for the Node Exporter in prometheus.yml.
   - Explain why the host’s IP address must be used as the scrape target in this setup
   - Describe how you would verify that Prometheus is successfully scraping the Node Exporter.

4. The Node Exporter exposes detailed CPU metrics.

   - Explain what the node_cpu_seconds_total metric represents and how it is labeled.
   - Describe how to calculate CPU usage rates from this counter metric.
   - Explain how to filter out idle CPU time and aggregate CPU usage across all cores.

5. Memory usage can be analyzed using multiple Node Exporter metrics.

   - Identify the metrics that represent free, buffered, and cached memory.
   - Describe how these metrics can be combined to estimate available memory.
   - Explain why converting memory values into GiB may be useful for dashboards.

6. Filesystem metrics provide insight into disk usage.

   - Describe the purpose of the node_filesystem_free_bytes and node_filesystem_size_bytes metrics.
   - Explain how to calculate filesystem usage as a percentage.
   - Discuss why filesystem-level visibility is important for system observability.

7. Network metrics are also exposed by the Node Exporter.

   - Describe how incoming and outgoing network traffic can be measured.
   - Explain how to aggregate network traffic metrics by network interface.

8. Some Node Exporter metrics provide system-level metadata rather than resource usage.

   - Explain how the system boot time metric can be used to detect frequent reboots.
   - Describe how the changes() function can help identify unstable nodes.
   - Explain how comparing the node’s system time with Prometheus scrape timestamps can help diagnose time synchronization issues.

Finally, discuss why it is important to explore and understand the full set of metrics exposed by the Node Exporter when building a comprehensive observability solution.

# 8 Exam Question – Container Observability with cAdvisor and Prometheus

cAdvisor exposes detailed metrics about resource usage of containers running on a host and integrates with Prometheus for container-level observability.

1. Explain the role of cAdvisor in a containerized observability stack.

   - Describe the types of metrics cAdvisor exposes.
   - Explain how these metrics complement those provided by the Node Exporter.

2. You are asked to deploy and scrape cAdvisor metrics with Prometheus.

   - Describe how to verify that the cAdvisor metrics endpoint is reachable.
   - Explain the steps required to configure Prometheus to scrape cAdvisor.
   - Describe how to confirm that Prometheus is successfully scraping the cAdvisor target.

3. cAdvisor exposes per-container metrics that include several identifying labels.

   - Explain the purpose of the id label and how it relates to Linux cgroups.
   - Describe how cgroup paths differ between cgroups v1 and cgroups v2.
   - Explain why some container metrics may have empty name or image labels.

4. CPU usage metrics are exposed on a per-container basis.

   - Explain what the container_cpu_usage_seconds_total metric represents.
   - Describe why this metric is modeled as a counter.
   - Explain how to calculate the per-second CPU usage rate for a container.

5. Demonstrate how to aggregate CPU usage metrics:

   - Describe how to calculate total CPU usage (in cores) for a specific container.
   - Explain why aggregating over the CPU label is necessary.

6. Memory usage metrics are also available for containers.

   - Explain what the container_memory_usage_bytes metric represents.
   - Describe how this metric can be used to monitor container memory consumption.

7. Discuss why exploring the full set of cAdvisor metrics is important when building container-level dashboards and alerts.

   - Explain how access to documentation strings on the metrics endpoint can help with query design.

Your answers should demonstrate practical understanding of container observability concepts, Prometheus scraping configuration, and PromQL usage.

# 9 Exam Question – Building a Custom Python Exporter for Prometheus

In this exercise, you will study and run a simple Python exporter that exposes CPU metrics for the Linux host it is running on.

1. Explain the purpose of writing a custom Prometheus exporter.

   - Compare it conceptually with using the Node Exporter.
   - Discuss scenarios where a custom exporter may be preferable.

2. The provided Python exporter uses the psutil library.

   - Describe how psutil is used to retrieve CPU usage metrics.
   - Explain why using psutil can be advantageous compared to parsing /proc/stat directly.

3. Examine the CPUCollector class and its collect() method:

   - Explain how the exporter translates CPU usage data into a Prometheus metric.
   - Describe the role of CounterMetricFamily and the use of labels (in this case, the mode label).
   - Explain what is meant by a “throw-away” metric family in this context.

4. You are asked to containerize the exporter:

   - Describe the key steps in the Dockerfile and their purpose.
   - Explain why the exporter container is run with --pid=host and --net flags when measuring CPU usage of the host.

5. Prometheus configuration:

   - Explain how to configure Prometheus to scrape metrics from the custom CPU exporter.
   - Describe how to verify that the custom exporter target is being scraped successfully.

6. PromQL usage:

   - Write a PromQL expression to calculate the per-second CPU usage rate from your custom exporter.
   - Compare this expression with the equivalent expression using the Node Exporter’s CPU metrics.
   - Discuss why the results should be identical and what this demonstrates about exporter metrics design.

7. Generalization:

   - Discuss how the principles illustrated with this Python exporter can be applied to build exporters for other third-party systems.
   - Highlight the benefits of exporting metrics in a standardized Prometheus format for observability

# 10 Exam Question – Working with Prometheus Histograms and Quantiles

Prometheus supports histograms to track the distribution of observed values, such as request durations, using cumulative buckets.

1. Explain the purpose of a histogram metric in Prometheus.

   - Describe how histogram buckets are defined and how cumulative counts work.
   - Explain why histograms are useful for monitoring operation durations (e.g., HTTP request latencies).

2. In Prometheus, each histogram is exposed as multiple time series:

   - Explain the role of the \_bucket suffix and the le (less-than-or-equal) label.
   - Describe how additional labels (e.g., instance, method, path, status) affect the structure of sub-histograms.

3. Using the Prometheus expression browser, query the sub-histogram for a specific combination of labels:

   - Describe what information you would expect to see in the Table view.
   - Explain why there may be multiple output series even for a single histogram.

4. Quantiles are a common way to summarize histogram distributions.

   - Explain the purpose of the histogram_quantile() function.
   - Write a PromQL query to calculate the 90th percentile (0.9 quantile) of request latencies over the last 5 minutes for a demo service.

5. Explain why it is important to apply rate() to histogram buckets before calculating quantiles.

   - Describe the difference between taking the rate over a recent window versus using cumulative bucket counts over the entire lifetime.

6. Aggregating histograms across dimensions:

   - Explain how to sum the rates of corresponding buckets to aggregate over unwanted label dimensions while preserving the le label.
   - Write a PromQL query that calculates the 90th percentile latency aggregated over status and method labels.

7. Discuss potential limitations and sources of error when converting histograms into quantile values.

   - Explain why limited bucket granularity can affect quantile accuracy.
   - Describe best practices for selecting aggregation levels and averaging windows when computing quantiles from histograms.

# 11 Exam Question – Filtering Time Series by Value in PromQL (Thresholding & Alerting)

In addition to selecting series by metric name and labels, PromQL allows filtering by the sample value of a time series. This is particularly useful for alerting and threshold-based queries.

1. Explain how binary comparison operators can be used to filter series by value in PromQL.

   - List the common comparison operators (>, <, >=, <=, !=, ==) and their meaning.
   - Describe a scenario where filtering by value is useful for alerting purposes.

2. Write a PromQL query to select request rates for HTTP 500 errors that exceed a threshold of 0.2 requests per second.

   - Explain the expected result and how it would appear in the Table or Graph view.

3. PromQL also allows vector-to-vector comparisons with the same label-matching behavior as arithmetic operations.

   - Explain how comparing entire vectors can be used to correlate commonly labeled series.
   - Describe the role of the ignoring() and on() modifiers in value-based comparisons.

4. Write a PromQL query that selects all HTTP 500 error rates that are at least 50 times larger than the total request rate for a given combination of path, method, and instance.

   - Explain why this type of query is useful for identifying abnormal error spikes relative to total traffic.
   - Discuss what you would expect the output to look like and how it could change over time.

5. Discuss best practices for designing threshold-based Prometheus queries:

   - Choosing appropriate thresholds for alerts.
   - Combining label selection with value-based filtering.
   - Understanding the difference between absolute thresholds and ratios relative to other series.

# 12 Exam Question – Using Set Operators in PromQL (and, or, unless)

PromQL provides set operators to correlate and filter series based on label sets rather than just sample values. The three primary set operators are and, or, and unless.

1. Explain the purpose of set operators in PromQL and how they differ from binary arithmetic or value-based comparisons.

   - Discuss why correlating series based on label presence can be useful in observability queries.

2. The and operator:

   - Describe how the and operator works (set intersection of label sets).
   - Write a PromQL query to select HTTP 500 error rates only for those path, method, and instance combinations that have a total request rate above 10 requests per second.
   - Explain the expected behavior of the output and why this operator is useful for complex filter conditions.

3. The or operator:

   - Explain how the or operator works (set union of label sets).
   - Describe a scenario where you want to include series that may be missing in one vector but present in another.
   - Write a PromQL query that reports HTTP 500 error rates for all paths that have ever received requests, even if they never had a 500 error, setting the rate to 0 for paths with no errors.

4. The unless operator:

   - Explain how the unless operator works (set complement).
   - Describe a use case where it is helpful to propagate series only if a label set does not exist in a second vector.

5. Discuss best practices for using set operators in PromQL:

   - Understanding the difference between correlating series by labels versus filtering by values.
   - Avoiding unexpected results when some label combinations are missing.
   - Combining set operators with aggregation and rate functions to build meaningful observability queries.

# 13 Exam Question – Working with Timestamp Metrics and Age Calculation in PromQL

Many services and exporters expose metrics that encode a Unix timestamp in the sample value (not the Prometheus scrape timestamp) to indicate when an event last occurred. Examples include system boot time, last successful batch job, or last garbage collection cycle.

1. Explain the difference between a sample value timestamp and the Prometheus scrape timestamp.

   - Provide examples of metrics where the sample value is a Unix timestamp.

2. When graphing a timestamp metric directly, the graph often appears as a staircase:

   - Explain why this staircase pattern occurs.
   - Describe what the jumps in the graph represent.

3. Calculating the age of an event is often more useful than the absolute timestamp:

   - Explain how to compute the age of a timestamp metric using the time() function in PromQL.
   - Write a query to calculate the number of seconds since the last successful run of a batch job (demo_batch_last_success_timestamp_seconds).

4. Describe how the resulting sawtooth graph can be interpreted:

   - What do rising lines indicate about the batch job status?
   - What do drops to 0 indicate?

5. Combining age calculations with thresholds:

   - Write a PromQL query to detect batch jobs that have not completed successfully within the last 1.5 minutes.
   - Explain how this type of query can be used for alerting purposes.

6. Discuss best practices when using timestamp-based metrics in Prometheus:

   - Choosing appropriate thresholds for alerting.
   - Understanding the implications of scrape intervals on age calculations.
   - Combining age metrics with other observability data for actionable insights.

# 14 Exam Question – Using offset, Sorting, and topk/bottomk in PromQL

PromQL allows you to compare current system behavior to past behavior, sort results, and select the top or bottom values from a query.

1. The offset modifier:

   - Explain how the offset <duration> modifier works in PromQL.
   - Write a query to calculate the request rate of a demo service one hour ago.
   - Using this, write a query to calculate the ratio between the current request rate and the request rate one hour ago.
   - Discuss why the offset modifier can only be applied directly to instant or range vector selectors.

2. Sorting series by value:

   - Explain the purpose of the sort() and sort_desc() functions in PromQL.
   - Write a query to show the total memory usage of every service in a cluster, sorted descendingly.
   - Explain why sorting does not affect graphs and only influences the Table view.

3. Selecting top or bottom series:

   - Explain how the topk(k, ...) and bottomk(k, ...) aggregation operators work.
   - Write a PromQL query to show the top 3 request rates for each path and method combination in the demo service.
   - Discuss potential caveats when graphing topk() or bottomk(), such as why the total number of series displayed may differ from k.

4. Combine concepts:

   - Describe a scenario where you might use offset with topk() or sort_desc() to detect anomalies or trends compared to past performance.
   - Discuss best practices for using these functions in dashboards or alerting queries.

# 15 Exam Question – Monitoring Target Availability Using the up Metric in Prometheus

Prometheus is a pull-based system, and it tracks whether it can successfully scrape each target. For every scrape, Prometheus sets a synthetic up metric with labels of the target:

- up = 1 if the scrape succeeded
- up = 0 if the scrape failed

1. Explain the purpose of the up metric in Prometheus.

   - How can it be used to monitor target availability?
   - What information does it provide about each job’s targets?

2. Using the demo service as an example:

   - Write a query to verify that all instances of the demo service are up.
   - Explain what the expected sample values should be if all instances are reachable.

3. Simulating a failure:

   - Describe what happens if you stop one instance of the demo service.
   - Write a query to show only the down instances using the up metric.

4. Formulating availability alerts:

   - Write a PromQL expression to alert if more than half of all demo instances are down.
   - Explain why you could alternatively use a simpler expression using avg_by(job)(up{job="demo"}).

5. Handling no matching series:

   - Explain what happens if the count() operator is used and there are no matching series.
   - Why is it important to understand this behavior when building alerting expressions?

6. Best practices:

   - Discuss how the up metric can be combined with other metrics to improve alert reliability.
   - Describe any considerations when scaling this approach to large numbers of targets or jobs.

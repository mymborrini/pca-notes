# PromQL queries responses

## Count Queries
1. Select *demo_api_request_duration_seconds_count* requests that resulted in a 200 HTTP Status code

    demo_api_request_duration_seconds_count{status="200", job="demo"}

2. Select *demo_api_request_duration_seconds_count* requests that resulted in a 200 HTTP Status code and using the GET method

    demo_api_request_duration_seconds_count{status="200", method="GET", job="demo"}

3. Select *demo_api_request_duration_seconds_count* requests that has one of this two paths */api/foo* or */api/bar*

    demo_api_request_duration_seconds_count{job="demo", path~="/api/(foo|bar)"}

4. Select the per-second increase of all the *demo_api_request_duration_seconds_count* series as averaged over a 5 minute

    rate(demo_api_request_duration_seconds_count{job="demo"}[5m])

5. Query the total increase of *demo_api_request_duration_seconds_count* over a given time window ( 1 hour )

    increase(demo_api_request_duration_seconds_count{job="demo"}[1h])

6. Select total number of requests our demo service is handling per second in 5 minutes.  *demo_api_request_duration_seconds_count*

    sum(rate(demo_api_request_duration_seconds_count{job="demo"}[5m]))

7. Calculate total *demo_api_request_duration_seconds_count* rates per instance and path, but not care about individual method or status results.

    sum without(status,method) (rate(demo_api_request_duration_seconds_count{job="demo"}[5m]))

8. Calculate total *demo_api_request_duration_seconds_count* rates per instance and path, but write the query considering all other labels (instance,path,job)

    sum by(instance, path, job)  (rate(demo_api_request_duration_seconds_count{job="demo"}[5m]))

## Gauge Queries
1. Get the raw increase of *demo_disk_usage_bytes* over 15 minutes

   delta(demo_disk_usage_bytes{job="demo"}[15m])

2. Calculate by how much the *demo_disk_usage_bytes* is going up or down per-second when looking at a 15 minute window

   deriv(demo_disk_usage_bytes{job="demo"}[15m])

3. Try to predict what the *demo_disk_usage_bytes* is in one hour, based on its development in the last 15 minutes

   predict_linear(demo_disk_usage_bytes{job="demo"}[15m],3600)

4. Calculate over *demo_batch_last_run_processed_bytes*, display the number of bytes in GiB instead of raw bytes

   demo_batch_last_run_processed_bytes{job="demo"} / 1024^3

5. The *demo_num_cpus* metric tells you the number of CPU cores of each instance, while the *demo_cpu_usage_seconds_total* metric has an additional mode label dimension that splits up the CPUusagepermode(idle,system,user,etc.). Calculate the per-mode CPU usage divided by the number of cores

   rate(demo_cpu_usage_seconds_total{job="demo"}[5m]) / on(job,instance) group_left demo_num_cpus{job="demo"}

## Histogram Queries
1. Calculates the average response time as averaged over the last 5 minutes. The average response time is stored into *demo_api_request_duration_seconds*

   rate(demo_api_request_duration_seconds_count{job="demo"}[5m]) / rate(demo_api_request_duration_seconds_sum{job="demo"}[5m])

2. Try to calculate the ratio  the status="500" error rate vs the total rate of all handled requests. As before *demo_api_request_duration_seconds*

   rate(demo_api_request_duration_seconds_count{job="demo",status="500"}[5m]) / rate(demo_api_request_duration_seconds_count{job="demo"}[5m])
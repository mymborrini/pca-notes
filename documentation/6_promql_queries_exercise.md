# Promql Query exercise

All the queries works on a prometheus job named *demo*

## Count Queries
1. Select *demo_api_request_duration_seconds_count* requests that resulted in a 200 HTTP Status code
2. Select *demo_api_request_duration_seconds_count* requests that resulted in a 200 HTTP Status code and using the GET method
3. Select *demo_api_request_duration_seconds_count* requests that has one of this two paths */api/foo* or */api/bar*
4. Select the per-second increase of all the *demo_api_request_duration_seconds_count* series as averaged over a 5 minute
5. Query the total increase of *demo_api_request_duration_seconds_count* over a given time window ( 1 hour )
6. Select total number of requests our demo service is handling per second in 5 minutes.  *demo_api_request_duration_seconds_count*
7. Calculate total *demo_api_request_duration_seconds_count* rates per instance and path, but not care about individual method or status results.
8. Calculate total *demo_api_request_duration_seconds_count* rates per instance and path, but write the query considering all other labels (instance,path,job)
9. Calculate total error rate, broken up by method ans status code


## Gauge Queries
1. Get the raw increase of *demo_disk_usage_bytes* over 15 minutes
2. Calculate by how much the *demo_disk_usage_bytes* is going up or down per-second when looking at a 15 minute window
3. Try to predict what the *demo_disk_usage_bytes* is in one hour, based on its development in the last 15 minutes
4. Calculate over *demo_batch_last_run_processed_bytes*, display the number of bytes in GiB instead of raw bytes
5. The *demo_num_cpus* metric tells you the number of CPU cores of each instance, while the *demo_cpu_usage_seconds_total* metric has an additional mode label dimension that splits up the CPUusagepermode(idle,system,user,etc.). Calculate the per-mode CPU usage divided by the number of cores
6. Show all service instances in a table whose internal batch job hasn't completed successfully in over 60 seconds

## Histogram Queries
1. Calculates the average response time as averaged over the last 5 minutes. The average response time is stored into *demo_api_request_duration_seconds*
2. Try to calculate the ratio  the status="500" error rate vs the total rate of all handled requests. As before *demo_api_request_duration_seconds*
3. Calculate the 90th-percentile latency, broken up by path and method

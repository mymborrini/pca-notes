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
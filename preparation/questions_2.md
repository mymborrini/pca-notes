# 16 Exam Question – Metric Relabeling in Prometheus

Prometheus allows you to relabel metrics during scraping to selectively keep or drop samples based on labels, including the special **name** label that stores the metric name.

1. Explain the purpose of metric relabeling in Prometheus.

   - How does it differ from relabeling used for service discovery?
   - Why might you want to drop certain metrics before storing them?

2. Consider a demo service that exposes four classes of metrics:

   - Application-specific metrics, prefixed with demo\_
   - Go runtime metrics, prefixed with go\_
   - Generic process metrics, prefixed with process\_
   - Generic HTTP-level metrics, prefixed with http\_

   Write a metric*relabel_configs snippet that keeps only application-level (demo*) and HTTP-level (http\_) metrics while dropping the rest.

3. Explain how the regex in metric_relabel_configs interacts with the **name** label.

   - Give an example of a regular expression that matches the desired metric prefixes.
   - Describe what happens to samples that do not match the regex.

4. After applying the relabeling configuration, write a PromQL query to verify that only the selected metric series are now stored.

   - Explain what you would expect to see in the expression browser.

5. Discuss considerations when using metric relabeling for large sets of metrics:

   - Why does relabeling happen after scraping?
   - Why might it be preferable to fix the metric source to only expose the metrics you care about?

6. ptional discussion:

   - Provide a brief scenario where metric relabeling can help reduce storage usage or improve query performance in a production Prometheus setup.

# 17 Exam Question – Service Discovery with Prometheus (Consul and File-based)

Prometheus supports dynamic service discovery to automatically find targets without manually specifying them in the configuration file. Two common methods are Consul-based service discovery and file-based service discovery.

---

## Part 1 – Consul-based Service Discovery

1. Explain the purpose of service discovery in Prometheus.

   - Why is it preferable to manually defining static targets in large or dynamic environments?

2. Consider a setup with three demo service instances running on hosts d1, d2, and d3, all exposing metrics on port 8080.

   - Write a Consul service definition JSON file to register all three demo services.
   - Describe how to start a Consul agent in development mode using this configuration.

3. Configure Prometheus to scrape the demo service targets from Consul:

   - Write a scrape configuration for Prometheus to discover only the demo services (excluding the Consul agent itself).
   - Explain the purpose of relabel_configs with source_labels: [__meta_consul_service] and the regex filter.

4. Describe how to verify that Prometheus is successfully scraping all Consul-discovered targets.

   - What page would you use, and what status should you expect?

--

## Part 2 – File-based Service Discovery

1. Explain how file-based service discovery works in Prometheus.

   - How does Prometheus detect changes in the file?

2. Create a targets.yml file to define the same three demo services:

   - Label the first two instances with env: production and the third with env: staging.
   - Show the YAML structure that Prometheus expects for file-based service discovery.

3. Configure Prometheus to read targets from targets.yml:

   - Write the scrape configuration for the file-sd-demo job.
   - Explain how Prometheus automatically picks up changes when the targets.yml file is updated.

4. Best practices for production:

   - Why should updates to targets.yml be done atomically?
   - Suggest a safe method to update the file without risking partial reads.

5. Discussion:

   - Compare and contrast Consul-based and file-based service discovery.
   - When might one be preferred over the other?

# 18 Exam Question – Monitoring Services via the Blackbox Exporter

Prometheus allows probing external services using the Blackbox Exporter, which supports different protocols such as HTTP, HTTPS, TCP, and ICMP. In this exercise, you will configure the Blackbox Exporter to probe websites via HTTP(S) and integrate it with Prometheus.

---

## Part 1 – Blackbox Exporter Setup

1. Write a Blackbox Exporter configuration file (blackbox.yml) that defines an HTTP probing module named http_2xx with the following properties:

   - HTTP GET method
   - 2-second timeout
   - Prefer IPv4 (ip4)

2. Explain the purpose of the module name in the Blackbox Exporter. How does Prometheus use this value when scraping the exporter?

3. Start the Blackbox Exporter container using Docker:

   - Map the configuration file correctly into the container.
   - Set it to listen on port 9115.
   - Explain why the probe timeout in the exporter must be smaller than Prometheus’s scrape timeout.

---

## Part 2 – Testing the Blackbox Exporter

1. Using a web browser or curl, test the HTTP probe against https://prometheus.io using your new http_2xx module.

   - What metrics does the Blackbox Exporter return for this probe?
   - Explain the meaning of the following metrics:

     - probe_duration_seconds
     - probe_success
     - probe_http_status_code
     - probe_ssl_earliest_cert_expiry

2. Write a Prometheus query to calculate in how many days the SSL certificate for https://prometheus.io will expire.

---

## Part 3 – Integrating with Prometheus

1. Add a scrape configuration to Prometheus to scrape the Blackbox Exporter:

   - Include three example targets:

     - http://prometheus.io
     - https://prometheus.io
     - http://example.com:8080

   - Use relabeling rules to:

     - Pass the original target URL to the exporter via the target parameter.
     - Set the instance label to the target address.
     - Replace the **address** label with the Blackbox Exporter’s host and port (bb-exporter:9115).

2. Explain why all three targets appear “UP” in Prometheus even if one of the probes fails.

3. Query Prometheus for probe_success{job="blackbox"}.

   - What value do you expect for each target?
   - How can this information be used for alerting?

---

## Part 4 – Analysis

1. Discuss additional probe-related metrics returned by the HTTP module (e.g., probe_http_content_length, probe_http_redirects, probe_ip_protocol) and how they could be useful in monitoring and alerting scenarios.

2. Explain how the Blackbox Exporter can be used for SSL certificate expiry monitoring, and why this is important for reliability and security.

# 19 Exam Question - Monitoring Batch Jobs with Pushgateway

Objective: Learn how to use the Prometheus Pushgateway to expose metrics from batch jobs and query them in Prometheus.

Instructions:

1. Run the Pushgateway

   - Start a Pushgateway instance using Docker.
   - Access the web interface at port 9091 and verify it is running.

2. Configure Prometheus to Scrape the Pushgateway

   - Update your prometheus.yml to add a scrape job for the Pushgateway.
   - Make sure that pushed job labels are preserved using the appropriate scrape configuration option.
   - Reload or restart Prometheus and verify that the Pushgateway target is UP.

3. Simulate a Batch Job

   - Instead of running a real batch job, simulate one by pushing metrics to the Pushgateway using curl.
   - Push the following metrics for a job named demo_batch_job:

     - demo_batch_job_last_successful_run_timestamp_seconds (Unix timestamp of the last successful run)
     - demo_batch_job_last_run_timestamp_seconds (Unix timestamp of the last run, successful or not)
     - demo_batch_job_users_deleted (number of users deleted in the last run, random value)

   - Run the simulated batch job multiple times and observe how the metrics update in the Pushgateway interface.

4. Query the Metrics in Prometheus

   - Determine how many seconds have passed since the last successful batch job run.
   - Write a query to alert if a batch job has not run successfully in the last hour.

5. Clean Up Metrics

   - Remove the batch job metrics from the Pushgateway using the appropriate HTTP API method.
   - Verify that the metrics are no longer visible in the Pushgateway.

Deliverables / Questions:

- Provide the Prometheus query to calculate the time since the last successful batch job run.
- Provide the Prometheus query that would alert if a batch job has not run successfully in the last hour.
- Explain why the honor_labels option is necessary when scraping the Pushgateway.
- Describe how the Pushgateway differs from a regular Prometheus-exported metric endpoint.

# 20 Exam Question: Configuring Alertmanager with a Webhook Receiver

Objective: Learn how to configure Alertmanager to receive alerts from Prometheus and send notifications to a custom webhook.

Instructions:

1. Create an Alertmanager Configuration

   - Create a file named alertmanager.yml in your home directory.
   - Define a top-level route that:

     - Groups incoming alerts by alertname and job.
     - Waits 30s (group_wait) before sending notifications for a group.
     - Sends notifications for new alerts in the same group after 5m (group_interval).
     - Resends notifications if any alerts are still firing after 3h (repeat_interval).

   - Add a single receiver called test-receiver.

2. Implement a Webhook Receiver

   - Create a Python program (webhook_receiver.py) that runs an HTTP server on port 9595.
   - The program should:

     - Accept incoming POST requests from Alertmanager.
     - Parse the JSON payload.
     - Print the number of alerts, group labels, common labels, common annotations, and details of each alert to the terminal.

3. Containerize the Webhook Receiver

   - Write a Dockerfile that:

     - Uses Python 3.13 as the base image.
     - Copies the webhook_receiver.py file.
     - Exposes port 9595.
     - Runs the Python program.

   - Build and run the Docker container in the lab network.

4. Configure Alertmanager to Use the Webhook Receiver

   - Update alertmanager.yml to configure the test-receiver to send webhook notifications to your webhook receiver container at http://<container_name>:9595/.
   - Reload or restart Alertmanager to apply the configuration.

5. Testing the Setup

   - Generate a test alert in Prometheus (or simulate one).
   - Verify that Alertmanager routes the alert to the webhook receiver.
   - Check the webhook receiver container logs to confirm the alert details are printed correctly.

Deliverables / Questions:

- Show the contents of your alertmanager.yml with the configured test-receiver.
- Explain how group_wait, group_interval, and repeat_interval affect alert notifications.
- Describe the purpose of the honor_labels option when routing alerts to receivers.
- Explain what information the webhook receiver prints for each alert and why it might be useful.

# 21 Exam Question: Prometheus Alerting Rules

Objective: Configure Prometheus alerting rules to detect high HTTP 5xx error rates in a monitored service and verify alerts in Alertmanager.

Instructions:

1. Explore the HTTP metrics of the demo service in Prometheus. Identify paths, instances, and jobs that report HTTP 5xx status codes.

2. Configure Prometheus to load alerting rules from a separate file named alerting_rules.yml.

3. Create an alerting rule that triggers when the 5xx error rate exceeds 0.5% for a sustained period. Include appropriate labels and annotations for alert severity and description.

4. Configure Prometheus to send alerts to Alertmanager. Ensure that the connection between Prometheus and Alertmanager is properly defined.

5. Reload Prometheus to apply your configuration changes.

6. Verify that alerts are firing in Prometheus when the 5xx error rate condition is met.

7. Open the Alertmanager web interface and confirm that the alerts appear as expected.

Deliverables / Tasks:

- Submit the alerting_rules.yml file and the relevant prometheus.yml configuration.
- Report which paths and instances triggered alerts during your testing.
- Explain how the for field in an alert rule affects when alerts are fired.
- Describe the role of labels and annotations in alerts and how they affect Alertmanager routing.

# 22 Exam Question: Setting Up Alertmanager in High Availability (HA) Mode

Objective: Configure Alertmanager in a highly available (HA) setup and verify that alerts, silences, and notifications are replicated across multiple instances.

Instructions:

1. Stop any existing Alertmanager container that may be running.

2. In two separate terminals, start two Alertmanager instances (A and B) in HA mode. Configure them to form a cluster by setting each instance’s peer to the other instance.

3. Modify the alerting section in your Prometheus configuration (prometheus.yml) to send alerts to both Alertmanager instances.

4. Reload Prometheus so that the new alerting configuration takes effect.

5. Verify that alerts are visible in both Alertmanager web interfaces, but that only one notification is sent per alert group.

6. Test HA behavior by:

   - Creating a silence in one Alertmanager instance and checking that it replicates to the second instance.
   - Taking down one Alertmanager instance and confirming that alerting still works with the remaining node.
   - Restarting the stopped Alertmanager instance and verifying that notification states and silences are re-replicated.

Deliverables / Tasks:

- Submit the updated prometheus.yml showing the two Alertmanager targets.
- Document the steps you performed to start both Alertmanager instances in HA mode.
- Provide screenshots or a short description demonstrating that:
  - Alerts appear in both instances.
  - Silences replicate between instances.
  - Alerts continue firing when one instance is down.

# 23 Exam Question: Creating a Prometheus Recording Rule

Objective: Learn how to precompute frequently used Prometheus expressions using recording rules to improve query performance and reduce computation load.

Instructions:

1. Assume you are monitoring a large number of demo service instances. Calculating the total number of requests across all instances and label sub-dimensions (like path and method) is computationally expensive.

2. Create a recording rule that precomputes the sum of request rates for each job into a new metric called:

```promql
job:demo_api_request_duration_seconds_count:rate5m
```

3. Configure the recording rule to be evaluated at a regular interval (for example, every 5 seconds, according to the Prometheus evaluation_interval).

4. Add the recording rule to a rule file (for example, recording_rules.yml) in the same directory as your prometheus.yml.

5. Ensure Prometheus is configured to load the recording rule file along with any existing alerting rules.

6. Reload Prometheus to apply the new recording rule configuration.

7. Verify that the new precomputed series exists and produces the same results as the original expression, but using the pre-recorded series.

Deliverables / Tasks:

- Submit the recording_rules.yml file with your recording rule.
- Update your prometheus.yml to reference the new recording rule file.
- Document how you verified that the recorded series returns the correct values.
- (Optional) Discuss the advantages of using recording rules in large-scale Prometheus deployments and how they could be used in federation scenarios.

# 24 Exam Question: Prometheus Hierarchical Federation

Objective: Learn how to set up a hierarchical Prometheus federation where a global Prometheus server aggregates metrics from multiple per-cluster Prometheus servers.

Scenario:
You are simulating two clusters, Cluster A and Cluster B, each with a Prometheus server monitoring three demo service instances. Each per-cluster Prometheus server uses recording rules to create precomputed metrics. A global Prometheus server then federates the metrics from both clusters.

Instructions:

1. Create a workspace for the federation lab.

2. Prepare per-cluster Prometheus configuration:

   - Create configuration files prometheus-cluster-a.yml and prometheus-cluster-b.yml.
   - Include global settings (scrape_interval, evaluation_interval) and assign an external_labels: cluster for each cluster (a or b).
   - Configure scraping of three demo service instances per cluster (d1:8080, d2:8080, d3:8080).
   - Reference a recording rules file (recording_rules.yml) for precomputing the per-job aggregated metric job:demo_api_request_duration_seconds_count:rate5m.

3. Copy or create the recording rules file in your federation workspace. Ensure it contains a group with a rule to precompute the sum of request rates per job.

4. Start both per-cluster Prometheus servers with their respective configuration and recording rules files.

5. Prepare a global Prometheus configuration:

   - Create a file prometheus-global.yml.
   - Configure it to federate metrics from the two per-cluster Prometheus servers.
   - Use the /federate endpoint and select metrics matching the name pattern for your recording rule (job:.\*).
   - Set honor_labels: true to preserve the original job and instance labels from the per-cluster servers.

6. Start the global Prometheus server using its configuration file.

7. Verify the federation setup:

   - In the global Prometheus server’s web interface, confirm that the metric job:demo_api_request_duration_seconds_count:rate5m is available from both clusters.
   - Ensure that metrics are distinguishable by the cluster label.

8. Cleanup:

   - When done, remove all three Prometheus containers to avoid resource conflicts.

Deliverables / Tasks:

- Submit the three configuration files: prometheus-cluster-a.yml, prometheus-cluster-b.yml, prometheus-global.yml.
- Include the recording_rules.yml used by the per-cluster servers.
- Document your verification steps in the global Prometheus interface.

# 25 Exam Question: Prometheus Integration with Cortex

Objective:
Learn how to configure Prometheus to store metrics in Cortex and query them back via remote read.

Scenario:
You have a local Prometheus server and a Cortex deployment running in single-process mode. Cortex will act as a scalable backend for storing metrics and serving queries. You will configure Prometheus to write all received samples to Cortex and read them back using PromQL.

Instructions / Tasks:

1. Prepare Cortex environment:

   - Clone the Cortex repository locally.
   - Navigate to the "Getting Started" guide directory.

2. Simulate object storage:

   - Start SeaweedFS to emulate S3 storage for Cortex.
   - Create the required buckets for Cortex blocks, rules, and Alertmanager storage.

3. Start Cortex:

   - Launch Cortex in single-process mode using Docker Compose.
   - Ensure Cortex services are ready to accept remote write and read requests.

4. Configure Prometheus to integrate with Cortex:

   - Add remote_write and remote_read sections to the top-level prometheus.yml.
   - Include multiple tenants (e.g., cortex, tenant-a, tenant-b, tenant-c, tenant-d) in the configuration.
   - Ensure headers are set appropriately for multi-tenant identification.

5. Reload Prometheus configuration:

   - Apply the new configuration by restarting Prometheus.

6. Verify integration:

   - Query Prometheus’ expression browser to ensure you can retrieve data stored in Cortex.
   - Optionally, stop and remove the Prometheus container, start a new one with the same configuration, and verify that historical data is still accessible via Cortex.

7. Cleanup:

   - Remove or comment out the remote_write and remote_read sections in prometheus.yml.
   - Stop the Cortex Docker Compose environment.
   - Return to your home directory for the next exercise.

Deliverables / Tasks for Submission:

- Submit the modified prometheus.yml with remote read/write configured.
- Document steps taken to verify that metrics were successfully written to and read from Cortex.
- Optionally include screenshots of query results from Prometheus showing metrics retrieved from Cortex.

# 26 Exam Question: Long-Term Storage and Integrated Query with Thanos and MinIO

Objective:
Configure Prometheus to ship its time series data to MinIO using Thanos and query both the local Prometheus data and the uploaded data in an integrated view.

Scenario:
You are running a Prometheus server that collects metrics from your environment. You want to enable long-term storage using Thanos, which will ship Prometheus TSDB blocks to MinIO (an S3-compatible object store). You will also configure Thanos Query to provide a unified view of both local and remote data.

Instructions / Tasks:

1. Configure external labels for Prometheus:

   - Add an external_labels entry to identify this Prometheus server in Thanos queries.

2. Prepare Prometheus for shipping TSDB blocks:

   - Disable background compaction in the local TSDB.
   - Share the Prometheus data directory via a Docker volume.
   - Start a new Prometheus instance with the modified TSDB configuration.

3. Set up MinIO for object storage:

   - Start a MinIO instance with the web console enabled.
   - Create a bucket named thanos to store Prometheus TSDB blocks.
   - Create a configuration file for Thanos containing the MinIO bucket and credentials.

4. Run Thanos Sidecar:

   - Start Thanos in sidecar mode, pointing it to both the Prometheus instance and the MinIO configuration.
   - Verify that the sidecar exposes a gRPC StoreAPI for queries.

5. Run Thanos Query:

   - Start the Thanos Query component and connect it to the Sidecar.
   - Navigate to the web interface and verify that you can query the same metrics as in Prometheus.
   - Confirm that all returned series include the external label configured in Prometheus.

6. Verify block uploads:

   - Leave the setup running for some time to allow Thanos to upload existing TSDB blocks to MinIO.
   - Check the MinIO web interface for new block objects.
   - Optionally, inspect Thanos Sidecar logs for confirmation of block uploads.

Deliverables / Tasks for Submission:

- Screenshot or documentation showing Thanos Query returning metrics with the correct external label.
- Confirmation that TSDB blocks were uploaded to the MinIO bucket.
- Summary of the components started (Prometheus, Thanos Sidecar, Thanos Query, MinIO) and their roles in long-term storage.

# 27 Exam Question: Understanding Prometheus Logs

Objective:
Investigate how Prometheus logs errors and warnings, and explore how logging verbosity can be configured.

Scenario:
Prometheus writes important warnings and errors to stderr. In most environments (Docker, Kubernetes, or other process supervisors), these logs are visible through standard logging mechanisms. Prometheus logs errors, for example, when it fails to load its configuration.

Instructions / Tasks:

1. Simulate a configuration error:

   - Modify the Prometheus configuration file (prometheus.yml) to include an invalid entry.
   - Reload Prometheus to apply the configuration changes.

2. Verify the error log:

   - Check that Prometheus logs an error to stderr indicating it failed to parse the configuration file.
   - Identify the timestamp, log level, source file, and error message in the log entry.

3. Explore logging verbosity:

   - Investigate how to increase the logging verbosity of Prometheus.
   - Determine the effect of setting the log level to debug.
   - Discuss why it is generally not recommended to rely on logs for monitoring Prometheus servers.

4. Reflection / Discussion:

   - Explain the difference between metrics-based monitoring and log-based monitoring in the context of Prometheus.
   - Describe scenarios where examining logs could be useful versus when metrics should be used.

Deliverables / Tasks for Submission:

- Screenshot or copy of the Prometheus error log after reloading with the invalid configuration.
- Short explanation of what the log entry indicates.
- Summary of how log verbosity can be configured and why metrics are preferred for monitoring.

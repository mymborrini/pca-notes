#!/bin/bash

echo "Start batch job"
# Name of the job in Pushgateway
JOB_NAME="demo_batch_job"

# Generate random values
RANDOM_USERS_DELETED=$((RANDOM % 100))  # Numero casuale di utenti eliminati
CURRENT_TIMESTAMP=$(date +%s)           # Timestamp attuale

# Send metrics to pushgateway
curl --data-binary @- http://localhost:8018/metrics/job/$JOB_NAME <<EOF
# TYPE demo_batch_job_last_successful_run_timestamp_seconds gauge
# HELP demo_batch_job_last_successful_run_timestamp_seconds The Unix timestamp in seconds of the last successful batch job run.
demo_batch_job_last_successful_run_timestamp_seconds $CURRENT_TIMESTAMP

# TYPE demo_batch_job_last_run_timestamp_seconds gauge
# HELP demo_batch_job_last_run_timestamp_seconds The Unix timestamp in seconds of the last batch job run (successful or not).
demo_batch_job_last_run_timestamp_seconds $CURRENT_TIMESTAMP

# TYPE demo_batch_job_users_deleted gauge
# HELP demo_batch_job_users_deleted How many users were deleted in the last batch job run.
demo_batch_job_users_deleted $RANDOM_USERS_DELETED
EOF

echo "Metrics pushed to Pushgateway: $RANDOM_USERS_DELETED users deleted, timestamp $CURRENT_TIMESTAMP"
echo "Finish batch job"
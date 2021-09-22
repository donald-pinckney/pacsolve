#!/bin/bash

num_jobs=4

for ((my_job=0;my_job<num_jobs;my_job++)); do
  echo ""
  echo "Starting job $my_job"
  gcloud compute ssh instance-$my_job \
    --zone=us-central1-a \
    --command "cd dependency-runner/Experiments/package-downloader/ && nohup python3 main.py all_packages.json $num_jobs $my_job > $my_job.output 2> $my_job.error" &
done

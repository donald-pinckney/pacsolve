#!/bin/bash

sleep 60

while true
do
    num_jobs_left=$(squeue -u $USER -h | wc -l)
    if [ "$num_jobs_left" -eq "0" ]; then
        echo "No jobs left:"
        squeue -u $USER
        sleep 60
        echo "Killing python3"
        pkill -9 "python3"
        exit;
    fi
    echo "$num_jobs_left jobs left."

    sleep 60
done
#!/bin/bash

module load python/3.8.1
pip install --upgrade tqdm --user

num_jobs='10'

for ((my_job_id=0;my_job_id<num_jobs;my_job_id++)); do
  sbatch --export=num_jobs=$num_jobs,my_job_id=$my_job_id job.bash
done

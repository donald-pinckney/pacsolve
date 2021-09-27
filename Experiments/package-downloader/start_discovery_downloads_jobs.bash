#!/bin/bash


module load python/3.8.1
pip install --upgrade tqdm --user

num_jobs='1000'


mkdir -p downloads-outputs/
mkdir -p downloads-logs/


for ((my_job_id=0;my_job_id<num_jobs;my_job_id++)); do
  sbatch --export=ALL,raw_json='all_packages.json',num_jobs=$num_jobs,my_job_id=$my_job_id downloads_job.bash
done

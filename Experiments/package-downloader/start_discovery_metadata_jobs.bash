#!/bin/bash


module load python/3.8.1
pip install --upgrade tqdm --user

num_jobs='1000'


mkdir -p outputs/
mkdir -p logs/

# wget -O all_packages_raw.json https://replicate.npmjs.com/_all_docs

for ((my_job_id=0;my_job_id<num_jobs;my_job_id++)); do
  sbatch --export=ALL,raw_json='all_packages.json',num_jobs=$num_jobs,my_job_id=$my_job_id job.bash
done

#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --job-name=package-downloader
#SBATCH --partition=short
#SBATCH --mem=16G
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --output=outputs/%j.output
#SBATCH --error=logs/%j.error

python metadata.py "$raw_json" $num_jobs $my_job_id
sleep 30


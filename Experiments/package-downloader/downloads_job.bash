#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --job-name=package-downloader
#SBATCH --partition=short
#SBATCH --mem=1G
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --output=downloads-outputs/%j.json
#SBATCH --error=downloads-logs/%j.error

python downloads.py "$raw_json" $num_jobs $my_job_id
sleep 30


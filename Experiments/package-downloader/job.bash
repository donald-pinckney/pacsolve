#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --job-name=package-downloader
#SBATCH --partition=short
#SBATCH --mem=64G
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --output=%j.output
#SBATCH --error=%j.error

python main.py "$raw_json" $num_jobs $my_job_id


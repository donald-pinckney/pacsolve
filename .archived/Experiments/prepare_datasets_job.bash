#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --job-name=prepare_datasets_job
#SBATCH --partition=short
#SBATCH --mem=16G

module load python/3.8.1
time python DatasetSetup/main.py --sqlite-path /work/arjunguha-research-group/packages/npm_db.sqlite3 > prepare_datasets_job.log 2> prepare_datasets_job.err
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --job-name=prepare_datasets_job
#SBATCH --partition=short
#SBATCH --mem=16G

time python3 DatasetSetup/main.py --sqlite-path /work/arjunguha-research-group/packages/npm_db.sqlite3
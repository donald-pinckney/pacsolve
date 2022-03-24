#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --job-name=prepare_datasets_job
#SBATCH --partition=short
#SBATCH --mem=16G

module load python/3.8.1
./experiment_compare_prod_sizes

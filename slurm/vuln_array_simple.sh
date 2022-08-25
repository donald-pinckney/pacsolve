#!/bin/bash
#SBATCH --mem=2G
#SBATCH --export=ALL
#SBATCH --cpus-per-task=2
#SBATCH --time=0:30:00
#SBATCH --job-name=maxnpm_vuln_gather_simple
#SBATCH --partition=express
#SBATCH -o vuln_array_logs_simple/slurm-%A_%a.out

mkdir -p vuln_array_logs_simple/
LINE=`sed -n ${SLURM_ARRAY_TASK_ID}p vuln_array_jobs_simple_chunk.01`
echo "*** $LINE ***"
safe_f=`echo $LINE | tr / _`
./lockfile_metric_task.sh $LINE &> vuln_array_logs_simple/$safe_f.log
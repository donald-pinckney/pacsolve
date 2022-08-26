#!/bin/bash
#SBATCH --mem=2G
#SBATCH --export=ALL
#SBATCH --cpus-per-task=2
#SBATCH --time=0:30:00
#SBATCH --job-name=maxnpm
#SBATCH --partition=express
#SBATCH -o slurm_logs/slurm-%A_%a.out

LINE=`sed -n ${SLURM_ARRAY_TASK_ID}p ${ARRAY_ARGS_FILE}`
echo "*** $LINE ***"
safe_f=`echo $LINE | tr / _`
./task.sh $LINE &> task_logs/$ARRAY_ARGS_FILE/$safe_f.log

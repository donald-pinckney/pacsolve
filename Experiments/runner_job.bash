#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --job-name=npm-rosette-experiment
#SBATCH --partition=short
#SBATCH --mem=32G
#SBATCH -N 1
#SBATCH -n 1

module load nodejs
module load python/3.8.1

python Runner/main.py --dataset nontesting --only supports-color --cleanup --configs npm '~/.npm-packages/bin/npm install --production' rosette '~/.npm-packages/bin/npm install --rosette'
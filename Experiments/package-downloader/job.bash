#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=00:05:00
#SBATCH --job-name=package-downloader
#SBATCH --partition=short
#SBATCH --mem=32G
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --output=%j.output
#SBATCH --error=%j.error

python main.py

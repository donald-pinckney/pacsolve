#!/bin/bash

module load python/3.8.1
pip install --upgrade tqdm --user
sbatch job.bash

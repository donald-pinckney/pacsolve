#!/bin/bash

echo "This will delete everything in logs/"
read -p "Press enter to continue"
rm -rf logs/
mkdir logs/

export EXP=/scratch/$USER/`date +"%Y-%M-%d-%H%M"`
mkdir -p $EXP/vanilla
mkdir -p $EXP/rosette/npm/min_oldness,min_num_deps
mkdir -p $EXP/rosette/npm/min_num_deps,min_oldness
mkdir -p $EXP/rosette/npm/min_duplicates,min_oldness
mkdir -p $EXP/rosette/npm/min_oldness,min_duplicates
mkdir -p $EXP/rosette/pip/min_oldness,min_num_deps
mkdir -p $EXP/rosette/pip/min_num_deps,min_oldness
echo "Experiment directory: $EXP"

echo "Preparing directory"
./main.py prepare \
  --source /work/arjunguha-research-group/minnpm-slurm/tarballs \
  --target $EXP/vanilla
  
./main.py prepare \
  --source /work/arjunguha-research-group/minnpm-slurm/tarballs \
  --target $EXP/rosette/npm/min_oldness,min_num_deps
./main.py prepare \
  --source /work/arjunguha-research-group/minnpm-slurm/tarballs \
  --target $EXP/rosette/npm/min_num_deps,min_oldness
./main.py prepare \
  --source /work/arjunguha-research-group/minnpm-slurm/tarballs \
  --target $EXP/rosette/npm/min_duplicates,min_oldness
./main.py prepare \
  --source /work/arjunguha-research-group/minnpm-slurm/tarballs \
  --target $EXP/rosette/npm/min_oldness,min_duplicates
  
./main.py prepare \
  --source /work/arjunguha-research-group/minnpm-slurm/tarballs \
  --target $EXP/rosette/pip/min_oldness,min_num_deps
./main.py prepare \
  --source /work/arjunguha-research-group/minnpm-slurm/tarballs \
  --target $EXP/rosette/pip/min_num_deps,min_oldness


echo "Running experiments"

command0='for i in {1..4}; do (./main.py run --target $EXP/vanilla; ./main.py run --target $EXP/rosette/npm/min_oldness,min_num_deps; ./main.py run --target $EXP/rosette/npm/min_num_deps,min_oldness; ./main.py run --target $EXP/rosette/npm/min_duplicates,min_oldness) >> logs/session0run$i.log; done; sleep infinity'

command1='for i in {1..4}; do (./main.py run --target $EXP/rosette/npm/min_oldness,min_duplicates; ./main.py run --target $EXP/rosette/pip/min_oldness,min_num_deps; ./main.py run --target $EXP/rosette/pip/min_num_deps,min_oldness) >> logs/session1run$i.log; done; sleep infinity'


tmux new-session -d -s experiment_sess0 "$command0"
tmux new-session -d -s experiment_sess1 "$command1"




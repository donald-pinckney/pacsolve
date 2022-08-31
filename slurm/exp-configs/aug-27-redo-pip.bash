#!/bin/bash

export EXPERIMENT_TYPE=top1000_comparison
export EXPERIMENT_DIR=$HOME/exp/aug-27-redo-pip
export TARBALL_DIR=/home/donald/pacsolve/slurm/top1000tarballs

export Z3_LOC=/mnt/data/donald/pacsolve/z3/build/z3
#export Z3_LOC=/home/donald/pacsolve/z3/more_builds/z3-4.8.8-x64-ubuntu-16.04/bin/z3
export Z3_MODEL_OPTION=True

mkdir -p $EXPERIMENT_DIR
#./main.py run --cpus-per-task 16 --use-slurm False --tarball-dir $TARBALL_DIR --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR --which-experiment $EXPERIMENT_TYPE
./main.py gather --which-experiment $EXPERIMENT_TYPE $EXPERIMENT_DIR

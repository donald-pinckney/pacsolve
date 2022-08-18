#!/bin/bash
# This experiment is my attempt to test if experiment scripts work on Ripley


export EXPERIMENT_TYPE=top1000_comparison
export EXPERIMENT_DIR=/proj/pinckney/experiments/aug-18-ripley-reproduce-results/
export TARBALL_DIR=/proj/pinckney/pacsolve/slurm/top1000tarballs

export Z3_LOC=/proj/pinckney/pacsolve/z3/build/z3
export Z3_MODEL_OPTION=True

mkdir -p $EXPERIMENT_DIR
./main.py run --cpus-per-task 4 --max-groups 250 --on-ripley --tarball-dir $TARBALL_DIR --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR --which-experiment $EXPERIMENT_TYPE


#!/bin/bash

export EXPERIMENT_TYPE=vuln_tarballs
export EXPERIMENT_DIR=$HOME/scratch/aug-3-arjun-jquery-revdeps/
export TARBALL_DIR=/mnt/data/donald/pacsolve/slurm/tarballs_arjun_jquery_revdeps_aug3

export Z3_LOC=/mnt/data/donald/pacsolve/z3/build/z3
export Z3_MODEL_OPTION=True

mkdir -p $EXPERIMENT_DIR
./main.py run --use-slurm False --tarball-dir $TARBALL_DIR --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR --which-experiment $EXPERIMENT_TYP
./main.py gather --which-experiment $EXPERIMENT_TYPE $EXPERIMENT_DIR

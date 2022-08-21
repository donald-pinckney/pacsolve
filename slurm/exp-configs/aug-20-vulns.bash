#!/bin/bash
# This experiment is to compare NPM audit fix vs MaxNPM


export EXPERIMENT_TYPE=vuln_tarballs
export EXPERIMENT_DIR=/proj/pinckney/experiments/aug-20-vulns/
export TARBALL_DIR=/proj/pinckney/pacsolve/slurm/vuln_tarballs

export Z3_LOC=/proj/pinckney/pacsolve/z3/build/z3
export Z3_MODEL_OPTION=True

mkdir -p $EXPERIMENT_DIR
./main.py run --cpus-per-task 1 --max-groups -1 --on-ripley --tarball-dir $TARBALL_DIR --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR --which-experiment $EXPERIMENT_TYPE
./main.py run --cpus-per-task 1 --max-groups -1 --on-ripley --tarball-dir $TARBALL_DIR --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR --which-experiment $EXPERIMENT_TYPE
./main.py gather --which-experiment $EXPERIMENT_TYPE $EXPERIMENT_DIR

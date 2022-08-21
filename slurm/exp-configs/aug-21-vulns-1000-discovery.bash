#!/bin/bash
# This experiment is to compare NPM audit fix vs MaxNPM


export EXPERIMENT_TYPE=vuln_tarballs
export EXPERIMENT_DIR=/scratch/pinckney.d/aug-21-vulns-1000/
export TARBALL_DIR=/work/arjunguha-research-group/pacsolve/slurm/vuln_tarballs1000

export Z3_LOC=/work/arjunguha-research-group/pacsolve/z3/build/z3
export Z3_MODEL_OPTION=True

mkdir -p $EXPERIMENT_DIR
./main.py run --tarball-dir $TARBALL_DIR --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR --which-experiment $EXPERIMENT_TYPE
./main.py run --tarball-dir $TARBALL_DIR --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR --which-experiment $EXPERIMENT_TYPE
./main.py gather --which-experiment $EXPERIMENT_TYPE $EXPERIMENT_DIR

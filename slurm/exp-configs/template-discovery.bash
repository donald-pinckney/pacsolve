#!/bin/bash
# A template for running experiments on discovery

export EXPERIMENT_TYPE=vuln_tarballs # either: vuln_tarballs or top1000_comparison
export EXPERIMENT_DIR=/scratch/pinckney.d/aug-21-vulns-1000/ # Set this to be the main work directory for the experiment
export TARBALL_DIR=/work/arjunguha-research-group/pacsolve/slurm/vuln_tarballs1000 # Set this to be the directory of tarballs to use

export Z3_LOC=/work/arjunguha-research-group/pacsolve/z3/build/z3
export Z3_MODEL_OPTION=True

mkdir -p $EXPERIMENT_DIR
./main.py run --tarball-dir $TARBALL_DIR --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR --which-experiment $EXPERIMENT_TYPE

# You can choose to run ./main.py more than once to resolve transient failures
# ./main.py run --tarball-dir $TARBALL_DIR --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR --which-experiment $EXPERIMENT_TYPE

./main.py gather --which-experiment $EXPERIMENT_TYPE $EXPERIMENT_DIR

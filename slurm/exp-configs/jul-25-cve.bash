export EXPERIMENT_DIR=/scratch/pinckney.d/jul-25-cve/
export Z3_LOC=/work/arjunguha-research-group/pacsolve/z3/build/z3
export Z3_MODEL_OPTION=True

mkdir -p $EXPERIMENT_DIR
./main.py run --tarball-dir /work/arjunguha-research-group/pacsolve/slurm/top1000tarballs --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR

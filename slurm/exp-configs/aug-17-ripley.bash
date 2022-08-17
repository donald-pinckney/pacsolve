# This experiment is my attempt to test if experiment scripts work on Ripley


export EXPERIMENT_DIR=/proj/pinckney/experiments/aug-17-ripley-test/
export Z3_LOC=/proj/pinckney/pacsolve/z3/build/z3
export Z3_MODEL_OPTION=True
export TARBALL_DIR=/proj/pinckney/pacsolve/slurm/68_tarballs

mkdir -p $EXPERIMENT_DIR
./main.py run --cpus-per-task 4 --on-ripley --tarball-dir $TARBALL_DIR --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR


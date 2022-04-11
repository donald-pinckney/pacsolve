export EXPERIMENT_DIR=/scratch/pinckney.d/apr-7-refactor-minnpm-exp-old-z3/
export Z3_LOC=/home/pinckney.d/spack/opt/spack/linux-centos7-broadwell/gcc-9.2.0/z3-4.8.9-vkfdhu5c3vo3eslba7evhfrweihz2cyd/bin/z3
export Z3_MODEL_OPTION=False

mkdir -p $EXPERIMENT_DIR
./main.py run --tarball-dir /work/arjunguha-research-group/minnpm-slurm/tarballs --z3-abs-path $Z3_LOC --z3-add-model-option $Z3_MODEL_OPTION --target $EXPERIMENT_DIR

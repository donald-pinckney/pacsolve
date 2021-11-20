# Prerequisites

1. `minnpm` should be on your path.
2. You should have z3 compiled with Spack.

# Usage

1. Start an interactive job for an experiment. Alternatively, I prefer this
   sbatch hack. Use a script like this to reserve resources on a node:

   ```
   #!/bin/bash
   #SBATCH --nodes=1
   #SBATCH --mem=8G
   #SBATCH --cpus-per-task=4
   #SBATCH --time=4:00:00
   #SBATCH --job-name=vscode
   #SBATCH --partition=short
   sleep infinity
   ```

   You can check the host that this job maps to with `squeue -u $USER`. Then,
   you can SSH into it and start tmux. If you get disconnected, reconnect to
   tmux.

2. Create a directory to hold your experiment, with subdirectories based on what 
experiments you want to run. Each subdirectory should be either of the form `vanilla` or 
`rosette/<consistency>/<minimize>` where `<consistency>` and `<minimize>` are the command line flags
that should be passed to MinNPM. For example:   
   ```
   export EXP=/scratch/$USER/`date +"%Y-%M-%d-%H%M"`
   mkdir -p $EXP/vanilla
   mkdir -p $EXP/rosette/npm/min_oldness,min_num_deps
   mkdir -p $EXP/rosette/npm/min_num_deps,min_oldness
   mkdir -p $EXP/rosette/npm/min_duplicates,min_oldness
   mkdir -p $EXP/rosette/npm/min_oldness,min_duplicates
   mkdir -p $EXP/rosette/pip/min_oldness,min_num_deps
   mkdir -p $EXP/rosette/pip/min_num_deps,min_oldness
   ```

3. Unpack all the projects to these directories. Continuing the example:

   ```
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
   ```

   These don't take very long, and should present no output.

4. Run the experiments:

   ```
   ./main.py run --target $EXP/vanilla
   ./main.py run --target $EXP/rosette/npm/min_oldness,min_num_deps
   ./main.py run --target $EXP/rosette/npm/min_num_deps,min_oldness
   ./main.py run --target $EXP/rosette/npm/min_duplicates,min_oldness
   ./main.py run --target $EXP/rosette/npm/min_oldness,min_duplicates
   ./main.py run --target $EXP/rosette/pip/min_oldness,min_num_deps
   ./main.py run --target $EXP/rosette/pip/min_num_deps,min_oldness
   ```

   These commands will take some time (nearly 30 mins each). You will see some
   failures. Re-running won't repeat successful experiments, but will make
   transient errors go away. *There will be transient errors on Discovery.*

5. Gather the data from these experiments:

   ```
   ./main.py gather $EXP
   ```

6. See `analysis.Rmd` for data analysis.

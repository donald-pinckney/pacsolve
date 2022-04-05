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
   you can SSH into it and start tmux. If you get discon/nected, reconnect to
   tmux.

2. Create a directory to hold your experiment.
   ```
   mkdir /scratch/$USER/minnpm-exp
   ```

3. Run the experiment:

   ```
   ./main.py run \
     --tarball-dir /work/arjunguha-research-group/minnpm-slurm/tarballs \
     --z3-abs-path /work/arjunguha-research-group/pacsolve/z3/build/z3 \
     --target /scratch/$USER/minnpm-exp
   ```

   This command will take some time (nearly 30 mins total). You will see some
   failures. Re-running won't repeat successful experiments, but will make
   transient errors go away. *There will be transient errors on Discovery.*

5. Gather the data from these experiments:

   ```
   ./main.py gather /scratch/$USER/minnpm-exp
   ```

6. See `analysis.Rmd` for data analysis (*Stale*)


# Alternative Usage using Janky Automation Script (*stale*)

1. Reserve a compute node for the experiments, same as step 1. above. 4 hours should be sufficient, but not less.
2. When SSH'd into the compute node, run: `. run_full_experiment.sh`. This will prepare the experiment directory, and kick off 7 different experiment configurations parallelized with 2 tmux sessions.
3. Monitor the experiments to see when they finish. You can do this in several ways:
   a. Read the logs in `logs/`
   b. See if the 2 tmux sessions are still alive (they will die when the experiments are complete): `tmux ls`
   c. Check if there are still active jobs: `squeue -u <USER>`
4. When everything is all done, run `./main.py gather $EXP`.

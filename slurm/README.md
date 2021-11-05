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

2. Create a directory to hold your experiment, with subdirectories "vanilla"
   and "rosette":
   
   ```
   export EXP=/scratch/$USER/`date +"%Y-%M-%d-%H%M`"
   mkdir $EXP/rosette
   mkdir $EXP/vanilla
   ```

3. Unpack all the projects to these directories:

   ```
   ./main.py prepare \
     --source /work/arjunguha-research-group/minnpm-slurm/tarballs \
     --target $EXP/rosette
   ./main.py prepare \
     --source /work/arjunguha-research-group/minnpm-slurm/tarballs \
     --target $EXP/vanilla
   ```

   These don't take very long, and should present no output.

4. Run the experiments:

   ```
   ./main.py run --target $EXP/vanilla
   ./main.py run --target $EXP/rosette
   ```

   These commands will take some time (nearly 30 mins each). You will see some
   failures. Re-running won't repeat successful experiments, and may make
   transient errors go away.

5. Gather the data from these experiments:

   ```
   ./main.py gather $EXP
   ```

6. See `analysis.Rmd` for data analysis.

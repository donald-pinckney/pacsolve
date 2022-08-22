# How to Run Experiments

## Prerequisites

You *must* follow all build instructions in the README at the root of the repo. This includes building the rosette solver into an executable, and creating a symlink called `minnpm` which points to `npm`.

## Preparing a Tarball Directory

All inputs to `main.py` are via a directory which consists of **multiple tarballs**, each of which contains a `package/package.json` file.

If you have a directory of many package JSONS, such as `a-123.json`, `b-456.json`, etc, you should use the script at `REPO_ROOT/vuln-analysis/dir_of_jsons_to_tarballs.sh` to create a directory of many tarballs each of which contains one of your JSONs. You use it as:

```
dir_of_jsons_to_tarballs.sh [src dir of json files] [target dir to put tarballs (must exist)]
```

Note that I've already prepared several directories of tarballs:

1. `REPO_ROOT/slurm/68_tarballs`: a small sample of 68 from the top 1000 set. Useful for doing test runs before a real experiment
2. `REPO_ROOT/slurm/top1000tarballs`: the original top 1000 set
3. `REPO_ROOT/slurm/top1000tarball_repos`: Repos harvested from the top 1000 set, since those include unit tests, etc.
4. `REPO_ROOT/slurm/vuln_tarballs`: The set of package JSONs Federico had recently prepared.
5. `REPO_ROOT/slurm/vuln_tarballs-small`: A small sample of that to quickly test scripts
6. `REPO_ROOT/slurm/vuln_tarballs1000`: A sample of 1000 of those
7. `REPO_ROOT/slurm/vuln_tarballs5000`: A sample of 5000 of those
8. `REPO_ROOT/slurm/vuln_tarballs10000`: A sample of 10000 of those
9. `REPO_ROOT/slurm/tarballs_arjun_jquery_revdeps_aug3`: The package JSONs Arjun had originally colleted based on jquery.




## Preparing an Experiment Config

Experiments are configured via an experiment config bash file, and are checked in at `REPO_ROOT/slurm/exp-configs/`. To run an experiment:

1. Copy either `exp-configs/template-discovery.bash`, `exp-configs/template-ripley.bash`, or `exp-configs/template-rtx.bash`, to a unique name for your experiment, such as `exp-configs/apr-1-test-if-maxnpm-ends-cancer.bash`. 

2. Then, in that bash file adjust the parameters, in particular `EXPERIMENT_TYPE`, `EXPERIMENT_DIR`, and `TARBALL_DIR`.
   - `EXPERIMENT_TYPE` can be either `vuln_tarballs` or `top1000_comparison`, depending on which experiment you want to run.
   - `EXPERIMENT_DIR` should be uniquely named.
   - `TARBALL_DIR` should be the directory of tarballs you produced in the last step.
You might want / need to adjust more parameters. There are lots of command line options to main.py, check the source.

## Running the experiment.

If you are on Discovery, make sure to be on a compute node and start tmux (see below for how to reserve a compute node).
There is no need to reserve a node on Ripley, the login VM is fine to use for compute.

Regardless, please use tmux.

Then, just run `./exp-configs/apr-1-test-if-maxnpm-ends-cancer.bash` of whatever the name of your experiment config is.

You can monitor progress with `squeue -u $USER | wc -l`.

**IMPORTANT NOTE:** If jobs timeout (30 minutes), then the `main.py` script will hang and never terminate. If you notice all jobs are gone (except your reserved node), then Ctrl-C `main.py`. You can look at `kill_if_no_jobs_left.bash` as a partial bit of automation for this, but I've only tested it on Ripley, not Discovery.

You may wish to re-run the experiment script to resolve transient errors / timeouts.


## Data Analysis

After the gather script has also been run, then see either `REPO_ROOT/slurm/analysis_vuln/analysis.Rmd` or `REPO_ROOT/slurm/analysis_top1000/analysis.Rmd`, depending on which experiment type you ran. Adjust the `data_root` value in the 2nd cell.

## Note: reserving a compute node on discovery

Start an interactive job for an experiment. Alternatively, I prefer this
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



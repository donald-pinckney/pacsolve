# Artifact for Dependency Solvers à la Carte

## Welcome and Preface

Welcome to the virtual machine which we have prepared to illustrate the functionality of PacSolve / MinNPM, the artifact for *Dependency Solvers à la Carte*.

**General layout of the artifact**: All of the code for PacSolve / MinNPM is in the directory `~/Desktop/pacsolve`. Within that directory, the following sub-directories are of interest:

- `artifact/` contains this README, as well as a series of examples illustrating the functionality of MinNPM.
- `arborist/` and `npm/` contain the source code of our forks of NPM, which have been modified to solve dependencies by invoking PacSolve.
- `RosetteSolver/` contains the source code of PacSolve, which implements a flexible depenendency solving backend via translate to Max-SMT.

*Organization:* The rest of this README will proceed by following the series of examples contained in `artifact/`, to gain an understanding of how MinNPM functions on examples. **Every single command** which you are required to run will be annotated with a Step Number and command, like so:

**Step 0:**

```bash
echo "example"
```

## Getting to the Right Directory

**Step 1:**
On the Desktop of the virtual machine, double click QTerminal, and then run:

```bash
cd ~/Desktop/pacsolve/artifact
```

From here on out, all commands will be run inside this terminal.

# Example #1: Checking that MinNPM Runs Correctly

...
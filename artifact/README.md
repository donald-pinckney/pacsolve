# Artifact for Dependency Solvers à la Carte

## Welcome and Preface

Welcome to the virtual machine which we have prepared to illustrate the functionality of PacSolve / MinNPM, the artifact for *Dependency Solvers à la Carte*.

**General layout of the artifact**: All of the code for PacSolve / MinNPM is in the directory `~/Desktop/pacsolve`. Within that directory, the following sub-directories are of interest:

- `artifact/` contains this document, as well as a series of examples illustrating the functionality of MinNPM.
- `arborist/` and `npm/` contain the source code of our forks of NPM, which have been modified to solve dependencies by invoking PacSolve.
- `RosetteSolver/` contains the source code of PacSolve, which implements a flexible depenendency solving backend via translate to Max-SMT.

*How to read this document:* The rest of this document will proceed by following the series of examples contained in `artifact/`, to gain an understanding of how MinNPM functions on examples. **Every single command** which you are required to run will be annotated with a Step Number, some shell commands, and possible a box describing the expected command results, like so:

**Step 0:**

```bash
echo "example"
```

> Expected result: should print 'example' to the terminal


## Getting to the Right Directory

**Step 1:**
On the Desktop of the virtual machine, double click QTerminal, and then run:

```bash
cd ~/Desktop/pacsolve/artifact
```

From here on out, all commands will be run inside this shell.

## Example #1: Checking that MinNPM Runs Correctly

As a first example, we solve a trivial dependency example to verify that everything runs as expected, 
and to introduce the basic concepts for how to run MinNPM and how to compare outputs with vanilla NPM.

The scenario of the first example is described in this table:

| Package      | Dep 1 |
|--------------|-------|
| root context | `a: *`  |
| `a@1.0.0`      |       |

meaning that the root solving context has a single dependency on any version of `a`, and `a` version 1.0.0 (the only version) has no dependencies.
For your reference, the directories inside `ex1_minnpm_runs/` encode this scenario with NPM packages which have already been uploaded to `npmjs.com`. 
As an example, package `a` version `1.0.0` is described by `ex1_minnpm_runs/a@1.0.0/package.json`, and has already been published as 
`@minnpm-artifact-examples/ex1-a` ([link](https://www.npmjs.com/package/@minnpm-artifact-examples/ex1-a)).

There is only one possible solution for this example, which is:

![](_images/ex1.png)

Let's check that both vanilla NPM and MinNPM find this solution.

**Step 2:**
```bash
pushd ex1_minnpm_runs/root_context
```

**Step 3:**
```bash
# Install packages with vanilla NPM
npm install
# Save the resulting lockfile, then clear solve results
cp node_modules/.package-lock.json result-vanilla.json; rm -rf node_modules package-lock.json
```

> Expected result: the install command should succeed. If not, please verify internet connectivity within the VM.

**Step 4:**
```bash
# Install packages with MinNPM
npm install --minnpm
# Save the resulting lockfile, then clear solve results
cp node_modules/.package-lock.json result-minnpm.json; rm -rf node_modules package-lock.json
```

> Expected result: the install command should succeed.

**Step 5:**
```bash
# Look at both results
cat result-vanilla.json result-minnpm.json
```

> Expected result: both result files should describe the solution graph drawn above, but
> there may be small differences in the result files, including possibly missing tarball URLs. 
> This does not affect functionality.

Running both the `npm` commands and the `cp` and `rm` commands each time is tedious, so we have included a script to automate this.
Let's repeat the above example by using the `compare_solvers` script:

**Step 6:**
```bash
compare_solvers vanilla minnpm='--minnpm'
```

> Expected result: both install commands should succeed, and `result-vanilla.json` and `result-minnpm.json` should be produced just as when done manually.

**Step 7:**
```bash
popd
```


## Example #2: Using MinNPM With Different Consistency Criteria


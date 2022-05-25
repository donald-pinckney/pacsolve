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

| Package      |  Dep 1  |
|--------------|---------|
| root context | `a: *`  |
| `a@1.0.0`    |         |

meaning that the root solving context has a single dependency on any version of `a`, and `a` version 1.0.0 (the only version) has no dependencies.
For your reference, the directories inside `ex1_minnpm_runs/` encode this scenario with NPM packages which have already been uploaded to `npmjs.com`. 
As an example, package `a` version `1.0.0` is described by `ex1_minnpm_runs/a@1.0.0/package.json`, and has already been published as 
`@minnpm-artifact-examples/ex1-a` ([link](https://www.npmjs.com/package/@minnpm-artifact-examples/ex1-a)).

There is only one possible solution for this example, which is:

![root context depends on a@1.0.0](_images/ex1.png)

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
tail -n +1 result-*.json
```

> Expected result: both result files should describe the solution graph drawn above, but
> there may be small differences in the result files, including possibly missing tarball URLs. 
> This does not affect functionality.

Running both the `npm` commands and the `cp` and `rm` commands each time is tedious, so we have included a script to automate this.
Let's repeat the above example by using the `compare_solvers` script:

**Step 6:**
```bash
compare_solvers vanilla minnpm='--minnpm'
tail -n +1 result-*.json
```

> Expected result: both install commands should succeed, and `result-vanilla.json` and `result-minnpm.json` should be produced just as when done manually.

**Step 7:**
```bash
popd
```


## Example #2: Using MinNPM With Different Consistency Criteria

We now demonstrate that MinNPM can be configured to use 3 different consistency policies (NPM, Cargo, and PIP-style).

The scenario to solve in this example is precisely that of Figure 1 in the paper, which is summarized in the following table:


| Package       |    Dep 1    |     Dep 2     |
|---------------|-------------|---------------|
| root context  | `debug: *`  | `ms: < 2.1.2` |
| `debug@4.3.4` | `ms: 2.1.2` |               |
| `ms@1.0.0`    |             |               |
| `ms@2.1.0`    |             |               |
| `ms@2.1.2`    |             |               |

There is a potential conflict because `root context` and `debug@4.3.4` cannot agree on a version of `ms`.
MinNPM exposes 3 different polices for conflicts:

1. (NPM's policy): Freely allow co-installation of multiple versions, yielding this solution graph:

    ![root context depends on debug@4.3.4 and ms@2.1.0, debug@4.3.4 depends on ms@2.1.0](_images/ex2_npm.png)

2. (Cargo's policy): Allow co-installation of versions which are **not** SemVer compatible. In this case, `ms@2.1.2` can be co-installed with `ms@1.0.0` but **not** `ms@2.1.0`, yielding this solution graph:

    ![root context depends on debug@4.3.4 and ms@2.1.0, debug@4.3.4 depends on ms@1.0.0](_images/ex2_cargo.png)

3. (PIP's policy): Disallow co-installation of multiple versions, yielding unsatisfiable constraints in this example.

Let's now observe MinNPM performing these solves in practice.

**Step 8:**
```bash
pushd ex2_consistency_criteria/root_context
```

**Step 9:**
```bash
# As a reminder, the minnpm-cargo line is equivalent to manually running
# npm install --minnpm --consistency cargo
compare_solvers \
    vanilla \
    minnpm-npm='--minnpm --consistency npm' \
    minnpm-cargo='--minnpm --consistency cargo' \
    minnpm-pip='--minnpm --consistency pip'
tail -n +1 result-*.json
```

> Expected result: All solves except `minnpm-pip` should succeed. 
`result-vanilla.json` and `result-minnpm-npm.json` should match the solution graph of policy (1) above, 
and `result-cargo.json` should match the solution graph of policy (2) above.


**Step 10:**
```bash
popd
```
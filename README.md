# PacSolve

## Setup / Dependencies

### Clone Repo

- Make sure to also `git submodule init` and `git submodule update` to fetch the submodules. (Or do the clone recursively thing, can't remember the flag)
- After cloning repo / submodules, make sure that each submodule is pointing to the right remote / branch:
  - `cd npm/; git remote -v; git status; cd ..` should show the remote is `https://github.com/donald-pinckney/cli/`, and the branch is `latest`
  - `cd arborist/; git remote -v; git status; cd ..` should show the remote is `https://github.com/donald-pinckney/arborist`, and the branch is `main`
  - If either of these are wrong, change remotes / checkout branches appropriately.

## Native Setup

### Setup Dependencies

- You need to have installed:
  - node (I have `v15.2.1`)
  - any somewhat recent npm (the version really shouldn't matter)
  - Racket (I have `Racket v8.4 [cs]`)

### Installing My Custom Npm

**Run all the following on a compute node if on discovery!**

- `pushd arborist/; npm install; popd`
- `pushd npm/; npm install -g; popd`
- `pushd rosette/; raco pkg remove rosette; raco pkg install; popd`
- `pushd z3/; python3 scripts/mk_make.py --staticbin; cd build/; make -j12; popd`
- `pushd version-oldness/; npm install; popd`
- `pushd version-cve-badness/; npm install; popd`
- Find the location of the installed NPM binary, and symlink it to someplace in your PATH under the name `minnpm`. E.g.: `ln -s $(which npm) ~/.local/bin/minnpm`.
- Then probably restart your terminal
- From anywhere, run `minnpm install --help`. You should see `--rosette` listed as an option.

## Docker Image Setup

### Setup Dependencies

- You need to have installed:
  - Docker (version should not matter)

### Installing The Docker Image

- `pushd dockerfile/; ./build.sh minnpm.Dockerfile; popd`
- Now, you will have the docker image installed as `pacsolve:latest`

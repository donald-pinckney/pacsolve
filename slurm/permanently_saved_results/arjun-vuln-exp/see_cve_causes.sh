#!/bin/bash

name=$1
commit=$2
solver=$3

if [ "$solver" = "vanilla" ]; then
    lock_name="vanilla"
elif [ "$solver" = "audit fix" ]; then
    lock_name="auditfix"
elif [ "$solver" = "audit fix force" ]; then
    lock_name="auditfixforce"
elif [ "$solver" = "maxnpm_cve_oldness" ]; then
    lock_name="maxnpmcveoldness"
elif [ "$solver" = "maxnpm_cve_oldness_pip_else_npm" ]; then
    lock_name="maxnpmcveoldness_pip-else-npm"
fi

python3 ../../lockfile_metrics.py /scratch/a.guha/exp/package-$name-$commit.tgz/package/$lock_name-lockfile.json

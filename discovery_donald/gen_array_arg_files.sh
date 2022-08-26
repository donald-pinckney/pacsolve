#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <exp_dir> <task_name>"
    exit 1
fi

exp_dir=$1
task_name=$2

unchunked_array_jobs="${task_name}_array_jobs"

rm -f "${unchunked_array_jobs}_vanilla"
touch "${unchunked_array_jobs}_vanilla"

rm -f "${unchunked_array_jobs}_auditfix"
touch "${unchunked_array_jobs}_auditfix"

rm -f "${unchunked_array_jobs}_auditfixforce"
touch "${unchunked_array_jobs}_auditfixforce"

rm -f "${unchunked_array_jobs}_maxnpmcveoldness"
touch "${unchunked_array_jobs}_maxnpmcveoldness"

rm -f "${unchunked_array_jobs}_maxnpmcveoldness_pip-else-npm"
touch "${unchunked_array_jobs}_maxnpmcveoldness_pip-else-npm"


for F in $exp_dir/*; do
    echo "$F/package/vanilla-lockfile.json" >> "${unchunked_array_jobs}_vanilla"
done

for F in $exp_dir/*; do
    echo "$F/package/auditfix-lockfile.json" >> "${unchunked_array_jobs}_auditfix"
done

for F in $exp_dir/*; do
    echo "$F/package/auditfixforce-lockfile.json" >> "${unchunked_array_jobs}_auditfixforce"
done

for F in $exp_dir/*; do
    echo "$F/package/maxnpmcveoldness-lockfile.json" >> "${unchunked_array_jobs}_maxnpmcveoldness"
done

for F in $exp_dir/*; do
    echo "$F/package/maxnpmcveoldness_pip-else-npm-lockfile.json" >> "${unchunked_array_jobs}_maxnpmcveoldness_pip-else-npm"
done


#split -d -l1000 --verbose "$unchunked_array_jobs" "$unchunked_array_jobs.chunk."
#rm "$unchunked_array_jobs"

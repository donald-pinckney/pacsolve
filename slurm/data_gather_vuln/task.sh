#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <task_name>"
    exit 1
fi


module load discovery nodejs

LOCKPATH=$1

set -x
set -e

CSVPATH="$LOCKPATH.csv"

echo "Starting task. LOCKPATH=$LOCKPATH, CSVPATH=$CSVPATH"

if [ ! -f "$LOCKPATH" ]; then
    echo "LOCKPATH $LOCKPATH does not exist!"
    echo "Nothing to evaluate"
    exit 0
fi

if [ ! -f "$CSVPATH" ]; then
    echo "Running Python (1)"
    python3 ../lockfile_metrics.py "$LOCKPATH" > "$CSVPATH"
else
    num_lines=`cat $CSVPATH | wc -l`
    if [ "$num_lines" = "2" ]; then
        echo "skipping"
    else
        echo "Running Python (2)"
        python3 ../lockfile_metrics.py "$LOCKPATH" > "$CSVPATH"
    fi
fi
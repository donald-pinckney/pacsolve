#!/bin/bash
args_list_file=$1
num_lines=`cat $args_list_file | wc -l`
mkdir -p task_logs/
mkdir -p package_logs/$args_list_file/
ARRAY_ARGS_FILE=$args_list_file sbatch --mail-user=$USER@northeastern.edu --mail-type=END --array=1-$num_lines ./simple_array.sh

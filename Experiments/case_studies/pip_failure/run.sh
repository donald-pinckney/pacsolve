#!/bin/bash

here=$(dirname "$0")

python3 Runner/main.py \
  --dataset nontesting_most_downloads --only $(cat $here/projects.txt) --timeout 60 --configs \
  npm 'npm install --omit dev --omit optional --omit peer --ignore-scripts' \
  minnpm_pip 'npm install --rosette --ignore-scripts --consistency pip --minimize min_oldness,min_num_deps' \
  minnpm_npm 'npm install --rosette --ignore-scripts --consistency npm --minimize min_oldness,min_num_deps' \
  minnpm_min_dups 'npm install --rosette --ignore-scripts --consistency npm --minimize min_duplicates'
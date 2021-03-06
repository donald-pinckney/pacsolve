#!/bin/bash

here=$(dirname "$0")

python3 Runner/main.py \
  --dataset nontesting_most_downloads --only $(cat $here/projects.txt) --timeout 800 --configs \
  npm 'npm install --omit dev --omit optional --omit peer --ignore-scripts' \
  minnpm_min_deps 'npm install --rosette --ignore-scripts --consistency npm --minimize min_num_deps,min_oldness' > $here/log.txt

python3 Runner/main.py \
  --dataset nontesting_most_downloads --only $(cat $here/projects2.txt) --timeout 800 --configs \
  npm 'npm install --omit dev --omit optional --omit peer --ignore-scripts' \
  minnpm_min_deps 'npm install --rosette --ignore-scripts --consistency npm --minimize min_num_deps,min_oldness' >> $here/log.txt
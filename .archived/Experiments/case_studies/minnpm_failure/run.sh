#!/bin/bash

here=$(dirname "$0")

python3 Runner/main.py \
  --dataset nontesting_most_downloads --only $(cat $here/projects.txt) --timeout 800 --configs \
  npm 'npm install --omit dev --omit optional --omit peer --ignore-scripts' \
  minnpm_npm 'npm install --rosette --ignore-scripts --consistency npm --minimize min_oldness,min_num_deps' > $here/log.txt

python3 Runner/main.py \
  --dataset nontesting_most_downloads --only $(cat $here/projects2.txt) --timeout 800 --configs \
  npm 'npm install --omit dev --omit optional --omit peer --ignore-scripts' \
  minnpm_npm 'npm install --rosette --ignore-scripts --consistency npm --minimize min_oldness,min_num_deps' >> $here/log.txt

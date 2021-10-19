#!/bin/bash
python3 Runner/main.py \
  --dataset nontesting \
  --all \
  --configs \
  npm 'npm install --omit dev --omit optional --omit peer --ignore-scripts' \
  rosette 'npm install --rosette --ignore-scripts'
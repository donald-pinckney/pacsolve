#!/bin/bash
python3 Runner/main.py \
  --dataset nontesting \
  --all \
  --configs \
  npm 'minnpm install --omit dev --omit optional --omit peer --ignore-scripts' \
  rosette 'minnpm install --rosette --ignore-scripts'
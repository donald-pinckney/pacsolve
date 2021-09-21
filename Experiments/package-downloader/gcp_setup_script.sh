#!/bin/bash

sudo apt-get install -y git
sudo apt install -y python3-pip

pip3 install --upgrade tqdm

git clone https://github.com/donald-pinckney/dependency-runner
gsutil cp gs://nom-bucket/all-packages.json ~/dependency-runner/Experiments/package-downloader/all_packages.json


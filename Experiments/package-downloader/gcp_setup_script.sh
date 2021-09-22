#!/bin/bash

sudo apt-get -qq install -y git > /dev/null 2>&1
sudo apt-get -qq install -y python3-pip > /dev/null 2>&1

pip3 install -q --upgrade tqdm > /dev/null 2>&1

git clone https://github.com/donald-pinckney/dependency-runner
gsutil cp gs://testing-npm-bucket/all_packages.json ~/dependency-runner/Experiments/package-downloader/all_packages.json


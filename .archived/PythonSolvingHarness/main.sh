#!/bin/bash

# Just a dumb wrapper to activate the virtual environment
# Probably there is a good and easy way to build a python executable .pex thingy
# But I don't know offhand

source PythonSolvingHarness/.venv/bin/activate
python PythonSolvingHarness/main.py $@

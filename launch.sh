#!/bin/bash
# Unix sucks bad.
trap 'kill -HUP 0' EXIT

cd "$( dirname "${BASH_SOURCE[0]}" )"
export PYTHONPATH=$PWD:$PYTHONPATH

./pipeline/main.py

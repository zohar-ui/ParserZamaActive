#!/bin/bash

# Simple test to confirm bash script execution works
echo "Script is running"
echo "Python version:"
python3 --version
echo ""
echo "Current directory:"
pwd
echo ""
echo "Golden set files:"
ls -1 /workspaces/ParserZamaActive/data/golden_set/*.json | wc -l

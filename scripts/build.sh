#!/bin/bash


# This script is only used for building OstrichDB. To run, either use the build_run.sh script or build with this script then run it manually.
#Author: Marshall A Burns
#GitHub: @SchoolyB
#License: Apache License 2.0 (see LICENSE file for details)
#Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the project root directory
cd "$DIR/.."


# Print the current directory
# echo "Current directory: $(pwd)"
# Build the project in the src directory
odin build main

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "$(tput setaf 2)Build successful$(tput sgr0)"

    # Try to create bin directory and move the executable
    if mkdir -p ./bin 2>/dev/null && mv main.bin ./bin/ 2>/dev/null; then
        echo "$(tput setaf 2)Successfully moved executable to bin directory$(tput sgr0)"
    else
        echo "$(tput setaf 1)Could not move executable to bin directory$(tput sgr0)"
        exit 1
    fi
else
    echo "$(tput setaf 1)Build failed$(tput sgr0)"
    exit 1
fi
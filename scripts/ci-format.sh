#!/bin/bash

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the project root directory
cd "$DIR/.."

# Run the formatter
odin fmt

# Check if formatting was successful
if [ $? -eq 0 ]; then
    echo "$(tput setaf 2)Code formatting successful$(tput sgr0)"
else
    echo "$(tput setaf 1)Code formatting issues found$(tput sgr0)"
    exit 1
fi

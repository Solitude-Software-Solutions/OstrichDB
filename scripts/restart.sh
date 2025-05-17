#!/bin/bash

#Author: Marshall A Burns
#GitHub: @SchoolyB
#License: Apache License 2.0 (see LICENSE file for details)
#Copyright (c) 2024-2025 Marshall A Burns and Solitude Software Solutions LLC
#Copyright (c) 2025-Present Archetype Dynamics, Inc.


# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the project root directory
cd "$DIR/.."

# Change to the bin directory
cd bin

# Check if the executable exists
if [ -f "main.bin" ]; then
    echo -e "$(tput setaf 3)Restarting OstrichDB...$(tput sgr0)"
    # Kill the current process if it's running
    pkill -f "main.bin"
    # Run the program
    ./main.bin


    # Capture the exit code
    exit_code=$?

    # Check the exit code
    if [ $exit_code -ne 0 ]; then
        echo "$(tput setaf 1)Program exited with code $exit_code$(tput sgr0)"
    fi

    # Return to the project root directory
    cd "$DIR/.."


else
    echo "$(tput setaf 1)Executable not found. Please build the project first.$(tput sgr0)"
fi
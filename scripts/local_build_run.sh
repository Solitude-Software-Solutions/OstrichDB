#!/bin/bash

#Author: Marshall A Burns
#GitHub: @SchoolyB
#License: Apache License 2.0 (see LICENSE file for details)
#Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

# Use this script to build and run the project locally. Only used for development purposes.

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the project root directory
cd "$DIR/.."


# Build the project, if DEV_MODE is false then shit breaks so LEAVE IT THE FUCK ALONE - Marshall
odin build main -define:DEV_MODE=true

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "$(tput setaf 2)Build successful$(tput sgr0)"

    # Try to create bin directory and move the executable
    if mkdir -p ./bin 2>/dev/null && mv main.bin ./bin/ 2>/dev/null; then
        cd bin
    else
        echo "$(tput setaf 1)Could not move executable to bin directory. Running from src.$(tput sgr0)"
    fi

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
    echo "$(tput setaf 1)Build failed$(tput sgr0)"
fi

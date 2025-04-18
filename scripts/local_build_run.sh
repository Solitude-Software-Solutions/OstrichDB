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

# Check if nlp.dylib already exists
if [ -f "src/core/nlp/nlp.dylib" ]; then
    echo "$(tput setaf 3)NLP library already exists, skipping build$(tput sgr0)"
else
    # Go into nlp package and build NLP Go library
    cd "src/core/nlp"
    go mod init main
    go mod tidy
    go build -buildmode c-shared -o nlp.dylib
    # Go back to root dir
    cd "$DIR/.."
fi

# Check if nlp.dylib exists in bin directory and remove it
if [ -f "./bin/nlp.dylib" ]; then
    echo "$(tput setaf 3)Removing existing NLP library$(tput sgr0)"
    rm "./bin/nlp.dylib"
fi

# Go back to root dir
cd "$DIR/.."
# Build the project, if DEV_MODE is false then shit breaks so LEAVE IT THE FUCK ALONE - Marshall
odin build main -define:DEV_MODE=true

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "$(tput setaf 2)Build successful$(tput sgr0)"
    # Create bin directory if it doesn't exist
    mkdir -p ./bin
    # Move the NLP library from src/core/nlp to the bin dir
    cp src/core/nlp/nlp.dylib ./bin/
    # Try to move the executable
    if mv main.bin ./bin/ 2>/dev/null; then
        cd bin
    else
        echo "$(tput setaf 1)Could not move executable to bin directory. Running from src.$(tput sgr0)"
    fi
    # Run the program
    ./main.bin
    # Capture the exit code
    exitCode=$?
    # Check the exit code
    if [ $exitCode -ne 0 ]; then
        echo "$(tput setaf 1)Program exited with code $exitCode$(tput sgr0)"
    fi
    # Return to the project root directory
    cd "$DIR/.."
else
    echo "$(tput setaf 1)Build failed$(tput sgr0)"
fi
#!/bin/bash

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the project root directory
cd "$DIR/.."

# Change to the src directory
cd src

# Determine the executable extension based on the operating system
if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win"* ]]; then
    # Windows (Git Bash or Windows Subsystem)
    EXECUTABLE_EXT=".exe"
else
    # Mac or Linux
    EXECUTABLE_EXT=".bin"
fi

# Build the project in the src directory
odin build main

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "$(tput setaf 2)Build successful$(tput sgr0)"
    
    # Try to create bin directory and move the executable
    if mkdir -p ../bin 2>/dev/null && mv "main$EXECUTABLE_EXT" ../bin/ 2>/dev/null; then
        cd ../bin
    else
        echo "$(tput setaf 1)Could not move executable to bin directory. Running from src.$(tput sgr0)"
    fi
    
    # Run the program
    ./main$EXECUTABLE_EXT

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
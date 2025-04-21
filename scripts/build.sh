#!/bin/bash

#Author: Marshall A Burns
#GitHub: @SchoolyB
#License: Apache License 2.0 (see LICENSE file for details)
#Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

# Note: The OstrichDB program itself does not actually use this script in the codebase.
# This script is only to be used by CI/CD processes and the terminal thats installing OstrichDB
# If you are a developer use the `local_build.sh` or `local_build_run.sh` scripts

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the project root directory
cd "$DIR/.."

OS_TYPE="$(uname)"
case "$OS_TYPE" in
    "Linux")
        LIB_EXT="so"
        ;;
    "Darwin")
        LIB_EXT="dylib"
        ;;
    *)
        echo "Unsupported OS: $OS_TYPE"
        exit 1
        ;;
esac

# Check if nlp dynamic library already exists
if [ -f "src/core/nlp/nlp.${LIB_EXT}" ]; then
    echo "$(tput setaf 3)NLP library already exists, skipping build$(tput sgr0)"
else
    # Go into nlp package and build NLP Go library
    cd "src/core/nlp"
    go mod init main
    go mod tidy
    go build -buildmode c-shared -o nlp.${LIB_EXT}
    # Go back to root dir
    cd "$DIR/.."
fi

# Check if nlp dynamic library exists in bin directory and remove it
if [ -f "./bin/nlp.${LIB_EXT}" ]; then
    echo "$(tput setaf 3)Removing existing NLP library$(tput sgr0)"
    rm "./bin/nlp.${LIB_EXT}"
fi

# Go back to root dir
cd "$DIR/.."

# Build the project, if DEV_MODE is true then shit breaks so LEAVE IT THE FUCK ALONE - Marshall
odin build main -define:DEV_MODE=false

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "$(tput setaf 2)Build successful$(tput sgr0)"
    # Create bin directory if it doesn't exist
    mkdir -p ./bin
    # Move the NLP library from src/core/nlp to the bin dir
    cp src/core/nlp/nlp.${LIB_EXT} ./bin/
    # Try to move the executable
    if mv main.bin ./bin/ 2>/dev/null; then
        echo "$(tput setaf 2)Successfully moved executable to bin directory$(tput sgr0)"
    else
        echo "$(tput setaf 1)Could not move executable to bin directory$(tput sgr0)"
        exit 1
    fi
    # Return to the project root directory
    cd "$DIR/.."
else
    echo "$(tput setaf 1)Build failed$(tput sgr0)"
    exit 1
fi

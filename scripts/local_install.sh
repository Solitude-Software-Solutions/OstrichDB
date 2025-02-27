#!/bin/bash

# This file does the same thing as the other install.sh file
# but it only installs the current local version of OstrichDB
# Todo: remove this later




PROGRAM_NAME="OstrichDB"
BUILD_SCRIPT="scripts/build.sh"

echo "============== OstrichDB Installer =============="

# Detect the operating system
OS=$(uname -s)
ARCH=$(uname -m)
echo "Detected system: $OS $ARCH"

# Setup installation directory
LOCAL_OSTRICH_DIR="$HOME/code/OstrichDB"
INSTALL_DIR="$HOME/.ostrichdb/"
mkdir -p "$INSTALL_DIR"


export PATH="$INSTALL_DIR:$PATH"


cd "$HOME/code/OstrichDB"

# Copy the contents of the scripts directory to the installation directory



cp -r scripts/ "$INSTALL_DIR"

mkdir -p "scripts"
cd "&INSTALL_DIR/scripts"
cp -r * "$LOCAL_OSTRICH_DIR/scripts"




# Check if build script exists
if [ ! -f "$BUILD_SCRIPT" ]; then
    echo "Error: Build script not found at expected path: $BUILD_SCRIPT"
    echo "The release structure may have changed. Please check the repository."
    exit 1
fi

echo "Building $PROGRAM_NAME..."
# Change to the src directory and build
# cd src #TODO: this is removed once 0.7 is released
odin build main

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "$(tput setaf 2)Build successful$(tput sgr0)"

    # Create bin directory and move the executable
    mkdir -p ../bin && mv main.bin ../bin/

    # Copy the binary to installation directory
    echo "Installing OstrichDB to $INSTALL_DIR/ostrichdb"
    cp "../bin/main.bin" "$INSTALL_DIR/ostrichdb"
    chmod +x "$INSTALL_DIR/ostrichdb"
else
    echo "$(tput setaf 1)Build failed$(tput sgr0)"
    exit 1
fi

# Cleanup
cd
rm -rf "$TMP_DIR"

if command -v ostrichdb >/dev/null 2>&1; then
    echo "✅ Installation successful!"
    echo "OstrichDB has been installed to $INSTALL_DIR/ostrichdb"
    echo ""
    echo "To start using OstrichDB, open a new terminal and run:"
    echo "    ostrichdb"
else
    echo "Warning: Installation complete, but the 'ostrichdb' command is not in your PATH."
    echo "Please restart your terminal or run:"
    echo "    source $SHELL_CONFIG"
    echo ""
    echo "Then you can start OstrichDB by running:"
    echo "    ostrichdb"
fi

echo ""
echo "Thank you for installing OstrichDB!"
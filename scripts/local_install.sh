# #!/bin/bash

#Author: Marshall A Burns
#GitHub: @SchoolyB
#License: Apache License 2.0 (see LICENSE file for details)
#Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

# STEP 1: Uncomment all lines witin this file
# STEP 2: Jump to lines: 16, and 63 to make your changes for your local installation.
# STEP 3: Save the file and run the script in your terminal


# PROGRAM_NAME="OstrichDB"
# BUILD_SCRIPT="scripts/build.sh" # Uncomment then leave as is


# echo "============== OstrichDB Installer =============="
# # Detect the operating system
# OS=$(uname -s)
# ARCH=$(uname -m)
# echo "Detected system: $OS $ARCH"

# # Setup installation directory
# LOCAL_OSTRICH_DIR="$HOME/path_to/OstrichDB"  #Replace the "path_to" with the actual path to your OstrichDB clone/download
# INSTALL_DIR="$HOME/.ostrichdb/"
# mkdir -p "$INSTALL_DIR"


# export PATH="$INSTALL_DIR:$PATH"



# UNCOMMENT THE REMAINING CODE BELOW  THEN JUMP TO LINE #63 TO CONTINUE
# # Ensure that installation directory is in the PATH permanently
# if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
#     echo "Adding $INSTALL_DIR to PATH permanently"

#     # Determine shell config file
#     if [[ "$SHELL" == *"bash"* ]]; then
#         SHELL_CONFIG="$HOME/.bashrc"
#     elif [[ "$SHELL" == *"zsh"* ]]; then
#         SHELL_CONFIG="$HOME/.zshrc"
#     fi

#     # Add to shell config if not already present
#     if [[ -f "$SHELL_CONFIG" ]]; then
#         if ! grep -q "export PATH=\"$INSTALL_DIR:\$PATH\"" "$SHELL_CONFIG"; then
#             echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
#             echo "Updated $SHELL_CONFIG with PATH information"
#         fi
#     else
#         echo "Warning: Could not determine your shell configuration file."
#         echo "Please manually add $INSTALL_DIR to your PATH."
#     fi
# fi


# # Check for Odin compiler
# if ! command -v odin &> /dev/null; then
#     echo "Error: Odin compiler not found in PATH."
#     echo "Please install Odin first. You can install it via:"
#     if [[ "$OS" == "Darwin" ]]; then
#         echo "  - Homebrew: brew install odin"
#     elif [[ "$OS" == "Linux" ]]; then
#         echo "  - Check your distribution's package manager"
#     fi
#     echo "  - Or from source: https://github.com/odin-lang/Odin"
#     exit 1
# fi

# echo "✓ Odin compiler found"

# cd "$HOME/path_to/OstrichDB" #Replace the "path_to" with the actual path to your OstrichDB clone/download

# # Check if build script exists
# if [ ! -f "$BUILD_SCRIPT" ]; then
#     echo "Error: Build script not found at expected path: $BUILD_SCRIPT"
#     echo "The release structure may have changed. Please check the repository."
#     exit 1
# fi

# echo "Building $PROGRAM_NAME..."
# # Change to the src directory and build

# odin build main

# # Check if build was successful
# if [ $? -eq 0 ]; then
#     echo "$(tput setaf 2)Build successful$(tput sgr0)"

#     # Create bin directory and move the executable
#     mkdir -p ../bin && mv main.bin ../bin/

#     # Copy the binary to installation directory
#     echo "Installing OstrichDB to $INSTALL_DIR/ostrichdb"
#     cp "../bin/main.bin" "$INSTALL_DIR/ostrichdb"
#     chmod +x "$INSTALL_DIR/ostrichdb"
# else
#     echo "$(tput setaf 1)Build failed$(tput sgr0)"
#     exit 1
# fi

# # Cleanup
# cd
# rm -rf "$TMP_DIR"

# if command -v ostrichdb >/dev/null 2>&1; then
#     echo "✅ Installation successful!"
#     echo "OstrichDB has been installed to $INSTALL_DIR/"
#     echo ""
#     echo "To start using OstrichDB, open a new terminal and run:"
#     echo "    ostrichdb"
# else
#     echo "Warning: Installation complete, but the 'ostrichdb' command is not in your PATH."
#     echo "Please restart your terminal or run:"
#     echo "    source $SHELL_CONFIG"
#     echo ""
#     echo "Then you can start OstrichDB by running:"
#     echo "    ostrichdb"
# fi

# echo ""
# echo "Thank you for installing OstrichDB!"
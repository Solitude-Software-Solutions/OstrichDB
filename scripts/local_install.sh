#!/bin/bash

# Author: Marshall A Burns
# GitHub: @SchoolyB
# License: Apache License 2.0 (see LICENSE file for details)
# Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

# STEP 1: Jump to line 24 then update the path
# STEP 2: Save the script then run it!


PROGRAM_NAME="OstrichDB"
BUILD_SCRIPT="scripts/build.sh"


echo "============== OstrichDB Installer =============="
# Detect the operating system
OS=$(uname -s)
ARCH=$(uname -m)
echo "Detected system: $OS $ARCH"

# Setup installation directory
# LOCAL_OSTRICH_DIR="$HOME/your_path_to/OstrichDB"  #Uncomment then: Change the 'path_to' to the location of you local OstrichDB directory. e.g $HOME/code/OstrichDB
INSTALL_DIR="$HOME/.ostrichdb/"
mkdir -p "$INSTALL_DIR"


export PATH="$INSTALL_DIR:$PATH"

# Ensure that installation directory is in the PATH permanently
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Adding $INSTALL_DIR to PATH permanently"

    # Determine shell config file
    if [[ "$SHELL" == *"bash"* ]]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi

    # Add to shell config if not already present
    if [[ -f "$SHELL_CONFIG" ]]; then
        if ! grep -q "export PATH=\"$INSTALL_DIR:\$PATH\"" "$SHELL_CONFIG"; then
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
            echo "Updated $SHELL_CONFIG with PATH information"
        fi
    else
        echo "Warning: Could not determine your shell configuration file."
        echo "Please manually add $INSTALL_DIR to your PATH."
    fi
fi


# Check for Odin compiler
if ! command -v odin &> /dev/null; then
    echo "Error: Odin compiler not found in PATH."
    echo "Please install Odin first. You can install it via:"
    if [[ "$OS" == "Darwin" ]]; then
        echo "  - Homebrew: brew install odin"
    elif [[ "$OS" == "Linux" ]]; then
        echo "  - Check your distribution's package manager"
    fi
    echo "  - Or from source: https://github.com/odin-lang/Odin"
    exit 1
fi

echo "✓ Odin compiler found"

cd "$LOCAL_OSTRICH_DIR"

# Check if build script exists
if [ ! -f "$BUILD_SCRIPT" ]; then
    echo "Error: Build script not found at expected path: $BUILD_SCRIPT"
    echo "The release structure may have changed. Please check the repository."
    exit 1
fi

echo "Building $PROGRAM_NAME..."
# Change to the src directory and build

odin build main

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "$(tput setaf 2)Build successful$(tput sgr0)"

    # Create bin directory and move the executable
    mkdir -p ../bin && mv main.bin ../bin/

    # Copy the binary to installation directory
    cp "../bin/main.bin" "$INSTALL_DIR/ostrichdb"
    chmod +x "$INSTALL_DIR/ostrichdb"

    # Create a launcher script that preserves all paths
    echo "Creating launcher script..."
    cat > "$INSTALL_DIR/ostrichdb_launcher" << 'EOF'
#!/bin/bash
# Launcher script for OstrichDB
exec "$HOME/.ostrichdb/ostrichdb" "$@"
EOF
    chmod +x "$INSTALL_DIR/ostrichdb_launcher"

    # Create a symlink to the launcher (not the actual binary)
    if [[ "$OS" == "Darwin" || "$OS" == "Linux" ]]; then
        if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
            ln -sf "$INSTALL_DIR/ostrichdb_launcher" "/usr/local/bin/ostrichdb"
            echo "Command: 'ostrichdb' is now available system-wide"
        else
            mkdir -p "$HOME/bin"
            ln -sf "$INSTALL_DIR/ostrichdb_launcher" "$HOME/bin/ostrichdb"
            echo "Command: 'ostrichdb' is available in $HOME/bin"
            echo "Make sure $HOME/bin is in your PATH"
        fi
    fi
else
    echo "$(tput setaf 1)Build failed$(tput sgr0)"
    exit 1
fi


cd "$HOME"

# Verify the installation
echo "Verifying installation..."
if [ -x "$INSTALL_DIR/ostrichdb" ]; then
    echo "✓ Executable found at $INSTALL_DIR/ostrichdb"
else
    echo "⚠️ Executable not found or not executable at $INSTALL_DIR/ostrichdb"
fi

# Force PATH update for current session
export PATH="$INSTALL_DIR:$PATH"

if command -v ostrichdb >/dev/null 2>&1; then
    echo "✅ Installation successful!"
    echo "OstrichDB has been installed to $INSTALL_DIR/"
    echo ""
    echo "To start using OstrichDB, open a new terminal and run:"
    echo "ostrichdb"
    echo "Note: Ensure your terminals current working directory is your home directory."
else
    echo "Warning: Installation complete, but the 'ostrichdb' command is not in your PATH."
    echo "Please restart your terminal or run:"
    echo "    source $SHELL_CONFIG"
    echo ""
    echo "Then you can start OstrichDB by running:"
    echo "    ostrichdb"

    echo ""
    echo "Troubleshooting:"
    echo "1. Try running the command with the full path: $INSTALL_DIR/ostrichdb"
    echo "2. Check if the file exists and is executable:"
    echo "   ls -la $INSTALL_DIR/ostrichdb"
    echo "3. Verify your PATH includes $INSTALL_DIR:"
    echo "   echo \$PATH"
    echo "4. Manually add to PATH for this session:"
    echo "   export PATH=\"$INSTALL_DIR:\$PATH\""
fi

echo ""
echo "Thank you for installing OstrichDB!"

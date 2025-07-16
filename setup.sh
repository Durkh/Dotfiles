#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Make install.sh and configure.sh executable
chmod +x "$SCRIPT_DIR/install.sh"
chmod +x "$SCRIPT_DIR/configure.sh"

echo "Starting setup..."

# Run installation script
echo "Running install.sh..."
"$SCRIPT_DIR/install.sh"

# Run configuration script
echo "Running configure.sh..."
"$SCRIPT_DIR/configure.sh"

echo "Setup complete!"
echo "You may need to log out and log back in or reboot for all changes to take full effect."

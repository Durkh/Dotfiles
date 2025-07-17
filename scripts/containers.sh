#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check for podman and toolbox, then create the base container
if command -v podman &> /dev/null && command -v toolbox &> /dev/null; then
    #TODO create eza container

    cd toolbox 
    podman build -t arch-base-toolbox .
else
    echo "toolbox not installed"
    exit 1
fi


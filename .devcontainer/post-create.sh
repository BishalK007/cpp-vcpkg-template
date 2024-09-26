#!/bin/bash

# Check if the ./vcpkg directory exists as a git submodule
if [ -d "./vcpkg" ]; then
    echo "Removing contents of the existing ./vcpkg directory..."
    # List files inside vcpkg directory
    ls -la ./vcpkg/
    # Remove all files and directories, including hidden ones
    find ./vcpkg -mindepth 1 -delete
    echo "FILES inside ./vcpkg -"
    ls -la ./vcpkg/
    echo "FILES inside ./vcpkg -"
fi

# Update the vcpkg submodule
echo "Fetching and updating vcpkg submodule..."
git submodule update --init --recursive
git submodule foreach git fetch


# Bootstrap vcpkg
echo "Bootstrapping vcpkg..."
./vcpkg/bootstrap-vcpkg.sh

# Integrate vcpkg with the environment
echo "Integrating vcpkg..."
./vcpkg/vcpkg integrate install

echo "vcpkg setup complete."

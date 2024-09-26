#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

BUILD_DIR="build"
EXECUTABLE_NAME="MyExecutable" # Default executable name

# Function to display usage
usage() {
    echo "Usage: $0 [--conf|-c] [--build|-b] [--run|-r] [--zip|-z] [--exe|-e EXECUTABLE_NAME]"
    echo
    echo "Options:"
    echo "  --conf, -c   Configure the CMake project"
    echo "  --build, -b  Build the project"
    echo "  --run, -r    Run the executable after building"
    echo "  --zip, -z    Zip all files in the current directory, excluding certain files"
    echo "  --exe, -e    Specify the name of the executable to run"
    exit 1
}

# Function to configure the CMake project
configure_project() {
    echo "----------------------------------------"
    echo "Configuring CMake project..."
    echo "----------------------------------------"

    # Create build directory if it doesn't exist
    mkdir -p "$BUILD_DIR"

    # Run CMake configuration
    cmake -B "$BUILD_DIR" -S .

    echo "Configuration complete."
}

# Function to build the CMake project
build_project() {
    echo "----------------------------------------"
    echo "Building CMake project..."
    echo "----------------------------------------"

    cmake --build "$BUILD_DIR"

    echo "Build complete."
}

# Function to run the executable
run_executable() {
    echo "----------------------------------------"
    echo "Running the executable..."
    echo "----------------------------------------"

    EXECUTABLE_PATH="$BUILD_DIR/$EXECUTABLE_NAME"

    if [ -f "$EXECUTABLE_PATH" ]; then
        ./"$EXECUTABLE_PATH"
    else
        echo "Executable $EXECUTABLE_NAME not found. Please build the project first."
        exit 1
    fi
}

# Function to zip files
zip_files() {
    echo "----------------------------------------"
    echo "Zipping files..."
    echo "----------------------------------------"

    # Create the zip file excluding the specified directories and files
    zip -r files.zip . -x "files.zip" ".*" "build/*" "vcpkg/*"

    echo "Zipping complete. Created files.zip."
}

# Check if no arguments were provided
if [ "$#" -eq 0 ]; then
    usage
fi

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --conf|-c)
            configure_project
            shift
            ;;
        --build|-b)
            build_project
            shift
            ;;
        --run|-r)
            run_executable
            shift
            ;;
        --zip|-z)
            zip_files
            shift
            ;;
        --exe|-e)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                EXECUTABLE_NAME="$2"
                shift 2
            else
                echo "Error: --exe requires a valid executable name."
                exit 1
            fi
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Default configuration
BUILD_DIR="build"
PROJECT_NAME="MyProject"
EXECUTABLE_NAME="myproject"
USE_VCPKG=ON
ENTER_NIX_SHELL=0

# ----------- VERSION CONFIGURATION ------------- #
# Read version from VERSION file unless overridden
if [ -z "$PROJECT_VERSION" ]; then
    if [ -f "VERSION" ]; then
        PROJECT_VERSION=$(cat VERSION | tr -d '[:space:]')
    else
        PROJECT_VERSION="1.0.0"
    fi
fi

# ----------- GLOBAL CONFIGURATION ------------- #
# Set these values as desired for your global configuration
GLOBAL_PROJECT_NAME="MyProjectGlobal"
GLOBAL_EXECUTABLE_NAME="myprojectglobal"
GLOBAL_PROJECT_VERSION="$PROJECT_VERSION" # Uses the global version from the VERSION file
IS_SET_CONFIG_GLOBAL=false  # Default to false; can be set via --conf-glob

# Variables for overlay update
OVERLAY_FILE=".nix/overlays/repototxt-overlay.nix"
OWNER="BishalK007"
REPO="cpp-vcpkg-template"
BRANCH="main"
GITHUB_REPO_URL="https://github.com/${OWNER}/${REPO}.git"

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --conf, -c         Configure the CMake project"
    echo "  --build, -b        Build the project"
    echo "  --run, -r          Run the executable after building"
    echo "  --zip, -z          Zip project files, excluding certain directories"
    echo "  --exe, -e NAME     Specify the name of the executable"
    echo "  --proj, -p NAME    Specify the project name"
    echo "  --ver, -v VER      Specify the project version"
    echo "  --use-nix          Build without using Vcpkg (for Nix environment)"
    echo "  --nix-shell        Enter Nix shell environment"
    echo "  --conf-glob        Use global configuration settings"
    echo "  --update-overlay   Update the overlay file with the latest commit and SHA256"
    echo "  --help, -h         Display this help message"
    exit 1
}

# Function to configure the CMake project
configure_project() {
    echo "----------------------------------------"
    echo "Configuring CMake project..."
    echo "----------------------------------------"

    # Create build directory if it doesn't exist
    mkdir -p "$BUILD_DIR"

    if [ "$USE_VCPKG" = "OFF" ]; then
        echo "Using Nix environment for configuration."
        # Assume Nix environment is already set up
        cmake -B "$BUILD_DIR" -S . \
            -DUSE_VCPKG="$USE_VCPKG" \
            -DEXECUTABLE_NAME="$EXECUTABLE_NAME" \
            -DPROJECT_NAME="$PROJECT_NAME" \
            -DPROJECT_VERSION="$PROJECT_VERSION"
    else
        cmake -B "$BUILD_DIR" -S . \
            -DUSE_VCPKG="$USE_VCPKG" \
            -DEXECUTABLE_NAME="$EXECUTABLE_NAME" \
            -DPROJECT_NAME="$PROJECT_NAME" \
            -DPROJECT_VERSION="$PROJECT_VERSION"
    fi

    echo "Configuration complete."
}

# Function to build the project
build_project() {
    echo "----------------------------------------"
    echo "Building project..."
    echo "----------------------------------------"

    if [ "$USE_VCPKG" = "OFF" ]; then
        echo "Building using Nix environment."

        # Remove existing build-nix symlink if it exists to prevent conflicts
        if [ -L "build-nix" ] || [ -e "build-nix" ]; then
            echo "Removing existing build-nix symlink or directory..."
            rm -rf build-nix
        fi

        # Run nix-build with custom output symlink name
        nix-build .nix/default.nix -o build-nix --argstr pname_arg "${PROJECT_NAME}" --argstr exename_arg "${EXECUTABLE_NAME}" --argstr version_arg "${PROJECT_VERSION}"
    else
        echo "Building using Vcpkg and CMake."

        # Ensure the project is configured before building
        if [ ! -d "$BUILD_DIR" ]; then
            echo "Build directory not found. Configuring project..."
            configure_project
        fi

        # Build the project using CMake
        cmake --build "$BUILD_DIR"
    fi

    echo "Build complete."
}

# Function to run the executable
run_executable() {
    echo "----------------------------------------"
    echo "Running the executable..."
    echo "----------------------------------------"

    if [ "$USE_VCPKG" = "OFF" ]; then
        # Path to the executable in the Nix build output
        EXECUTABLE_PATH="./${BUILD_DIR}/bin/${EXECUTABLE_NAME}"

        if [ -f "$EXECUTABLE_PATH" ]; then
            echo "Executing $EXECUTABLE_PATH"
            "$EXECUTABLE_PATH"
        else
            echo "Executable $EXECUTABLE_NAME not found in ${BUILD_DIR}/bin/. Please build the project first."
            exit 1
        fi
    else
        EXECUTABLE_PATH="$BUILD_DIR/$EXECUTABLE_NAME"

        if [ -f "$EXECUTABLE_PATH" ]; then
            echo "Executing $EXECUTABLE_PATH"
            ./"$EXECUTABLE_PATH"
        else
            echo "Executable $EXECUTABLE_NAME not found in $BUILD_DIR. Please build the project first."
            exit 1
        fi
    fi
}

# Function to zip files
zip_files() {
    echo "----------------------------------------"
    echo "Zipping files..."
    echo "----------------------------------------"

    # Create the zip file excluding the specified directories and files
    zip -r files.zip . -x "files.zip" ".*" "build/*" "build-nix"  "vcpkg/*" "ReadME.md"

    echo "Zipping complete. Created files.zip."
}

# Function to enter Nix shell
enter_nix_shell() {
    echo "----------------------------------------"
    echo "Entering Nix shell environment..."
    echo "----------------------------------------"
    nix-shell .nix/shell.nix
}

# Function to update the overlay file
update_overlay() {
    echo "----------------------------------------"
    echo "Updating overlay file..."
    echo "----------------------------------------"

    # Check if the overlay file exists
    if [ ! -f "$OVERLAY_FILE" ]; then
        echo "Overlay file not found at $OVERLAY_FILE."
        exit 1
    fi

    # Check for required commands
    if ! command -v nix-prefetch-git &> /dev/null; then
        echo "Error: nix-prefetch-git is not installed or not in PATH."
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed or not in PATH."
        exit 1
    fi

    # Fetch the latest commit hash from the remote repository
    echo "Fetching latest commit hash from remote repository..."
    LATEST_COMMIT_HASH=$(git ls-remote "$GITHUB_REPO_URL" "refs/heads/${BRANCH}" | cut -f1)

    if [ -z "$LATEST_COMMIT_HASH" ]; then
        echo "Error: Could not fetch the latest commit hash from the remote repository."
        exit 1
    fi

    echo "Latest remote commit hash: $LATEST_COMMIT_HASH"

    # Get the sha256 hash of the source at that commit
    echo "Fetching the repository and computing SHA256..."
    PREFETCH_OUTPUT=$(nix-prefetch-git --quiet --url "$GITHUB_REPO_URL" --rev "${LATEST_COMMIT_HASH}")
    BASE32_HASH=$(echo "$PREFETCH_OUTPUT" | jq -r '.sha256')
    echo "Base32 SHA256: $BASE32_HASH"

    # Convert the base32 hash to SRI format (base64 with sha256- prefix)
    SRI_HASH=$(nix --extra-experimental-features nix-command hash to-sri --type sha256 "$BASE32_HASH")
    echo "SRI-formatted SHA256: $SRI_HASH"

    # Update the overlay file
    # Escape slashes and other special characters for sed
    ESCAPED_COMMIT_HASH=$(echo "$LATEST_COMMIT_HASH" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_SRI_HASH=$(echo "$SRI_HASH" | sed -e 's/[\/&]/\\&/g')

    # Escape variables for pname_arg, exename_arg, version_arg
    ESCAPED_PROJECT_NAME=$(echo "$PROJECT_NAME" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_EXECUTABLE_NAME=$(echo "$EXECUTABLE_NAME" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_PROJECT_VERSION=$(echo "$PROJECT_VERSION" | sed -e 's/[\/&]/\\&/g')

    # Use sed to replace the rev and sha256 lines
    sed -i "s/rev = \".*\";/rev = \"${ESCAPED_COMMIT_HASH}\";/g" "$OVERLAY_FILE"
    sed -i "s/sha256 = \".*\";/sha256 = \"${ESCAPED_SRI_HASH}\";/g" "$OVERLAY_FILE"

    # Use sed to replace the pname_arg, exename_arg, version_arg lines
    sed -i "s/pname_arg = \".*\";/pname_arg = \"${ESCAPED_PROJECT_NAME}\";/g" "$OVERLAY_FILE"
    sed -i "s/exename_arg = \".*\";/exename_arg = \"${ESCAPED_EXECUTABLE_NAME}\";/g" "$OVERLAY_FILE"
    sed -i "s/version_arg = \".*\";/version_arg = \"${ESCAPED_PROJECT_VERSION}\";/g" "$OVERLAY_FILE"

    echo "Overlay file updated successfully."
}

# Check if no arguments were provided
if [ "$#" -eq 0 ]; then
    usage
fi

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --conf|-c)
            CONFIGURE_PROJECT=1
            shift
            ;;
        --build|-b)
            BUILD_PROJECT=1
            shift
            ;;
        --run|-r)
            RUN_EXECUTABLE=1
            shift
            ;;
        --zip|-z)
            ZIP_FILES=1
            shift
            ;;
        --exe|-e)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                if [ "$IS_SET_CONFIG_GLOBAL" = false ]; then
                    EXECUTABLE_NAME="$2"
                fi
                shift 2
            else
                echo "Error: --exe requires a valid executable name."
                exit 1
            fi
            ;;
        --proj|-p)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                if [ "$IS_SET_CONFIG_GLOBAL" = false ]; then
                    PROJECT_NAME="$2"
                fi
                shift 2
            else
                echo "Error: --proj requires a valid project name."
                exit 1
            fi
            ;;
        --ver|-v)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                if [ "$IS_SET_CONFIG_GLOBAL" = false ]; then
                    PROJECT_VERSION="$2"
                fi
                shift 2
            else
                echo "Error: --ver requires a valid project version."
                exit 1
            fi
            ;;
        --use-nix)
            USE_VCPKG=OFF
            BUILD_DIR="build-nix"
            shift
            ;;
        --nix-shell)
            ENTER_NIX_SHELL=1
            shift
            ;;
        --conf-glob)
            IS_SET_CONFIG_GLOBAL=true
            shift
            ;;
        --update-overlay)
            UPDATE_OVERLAY=1
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Apply global configuration if IS_SET_CONFIG_GLOBAL is true
if [ "$IS_SET_CONFIG_GLOBAL" = true ]; then
    PROJECT_NAME="$GLOBAL_PROJECT_NAME"
    EXECUTABLE_NAME="$GLOBAL_EXECUTABLE_NAME"
    PROJECT_VERSION="$GLOBAL_PROJECT_VERSION"
fi

# Enter Nix shell if requested
if [ "$ENTER_NIX_SHELL" == "1" ]; then
    enter_nix_shell
    exit 0
fi

# Execute the requested actions
if [ "$CONFIGURE_PROJECT" == "1" ]; then
    configure_project
fi

if [ "$BUILD_PROJECT" == "1" ]; then
    build_project
fi

if [ "$RUN_EXECUTABLE" == "1" ]; then
    run_executable
fi

if [ "$ZIP_FILES" == "1" ]; then
    zip_files
fi

if [ "$UPDATE_OVERLAY" == "1" ]; then
    update_overlay
fi

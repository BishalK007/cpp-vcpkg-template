#!/bin/bash

ENTER_NIX_SHELL="0"
USE_VCPKG=ON
BUILD_DIR="build"

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log information
log_info() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

# Function to log errors
log_error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
}
# Function to sanitize the project name
sanitize_package_name() {
    local name="$1"
    
    
    # Replace uppercase-lowercase boundaries with hyphens (e.g., "abcDef" -> "abc-def")
    name=$(echo "$name" | sed 's/\([a-z0-9]\)\([A-Z]\)/\1-\2/g')
    
    # Convert to lowercase
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    # Replace any non-alphanumeric characters (except '-') with hyphens
    name=$(echo "$name" | sed 's/[^a-z0-9-]/-/g')
    
    # Replace multiple hyphens with a single hyphen
    name=$(echo "$name" | sed 's/-\{2,\}/-/g')
    
    # Remove leading or trailing hyphens
    name=$(echo "$name" | sed 's/^-*//; s/-*$//')
    
    echo "$name"
}

# Function to read metadata from META.json
read_meta() {
    if [ ! -f "META.json" ]; then
        log_error "META.json file not found."
        exit 1
    fi

    PROJECT_NAME=$(jq -r '.project_name' META.json)
    EXECUTABLE_NAME=$(jq -r '.executable_name' META.json)
    DESCRIPTION=$(jq -r '.description' META.json)
    MAINTAINER_NAME=$(jq -r '.maintainer.name' META.json)
    MAINTAINER_EMAIL=$(jq -r '.maintainer.email' META.json)
    GITHUB_USERNAME=$(jq -r '.maintainer.githubUsername' META.json)
    GITHUB_REPO_URL=$(jq -r '.githubRepoUrl' META.json)
    OVERLAY_BRANCH=$(jq -r '.overlay_branch' META.json)
    NIX_OVERLAY_FILE=$(jq -r '.NIX_OVERLAY_FILE' META.json)
    NIX_DEFAULT_FILE=$(jq -r '.NIX_DEFAULT_FILE' META.json)
    NIX_SHELL_FILE=$(jq -r '.NIX_SHELL_FILE' META.json)

    # Sanitize the project name
    PROJECT_NAME=$(sanitize_package_name "$PROJECT_NAME")

    if [ ! -f "VERSION" ]; then
        log_error "VERSION file not found."
        exit 1
    fi
    # get version from VERSION file
    PROJECT_VERSION=$(cat VERSION | tr -d '[:space:]')

    if [ -z "$PROJECT_NAME" ]; then
        log_error "Sanitized PROJECT_NAME is empty. Please check META.json."
        exit 1
    fi

    log_info "Sanitized Project Name: $PROJECT_NAME"
}

# Function to check dependencies
check_dependencies() {
    # Initialize the list of required commands
    REQUIRED_COMMANDS=("jq" "cmake" "ninja" "git" "pkg-config" "bash" "zip")

    # If not using Vcpkg, add 'nix' to the required commands
    if [ "$USE_VCPKG" = "OFF" ]; then
        REQUIRED_COMMANDS+=("nix")
    fi

    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command '$cmd' is not installed or not in PATH."
            exit 1
        fi
    done
}

# Function to generate vcpkg.json using sed
generate_vcpkg_json() {
    log_info "UPDATING vcpkg.json from META.json and VERSION..."
    
    TEMPLATE_FILE="vcpkg.json.template"
    OUTPUT_FILE="vcpkg.json"

    touch "${TEMPLATE_FILE}"
    cat "${OUTPUT_FILE}" > "${TEMPLATE_FILE}"
    
    if [ ! -f "$TEMPLATE_FILE" ]; then
        log_error "$TEMPLATE_FILE file not found."
        exit 1
    fi


    # Use sed to replace only the "name" and "version-string" fields
    sed -e "s/\"name\": \".*\"/\"name\": \"${PROJECT_NAME}\"/" \
        -e "s/\"version-string\": \".*\"/\"version-string\": \"${PROJECT_VERSION}\"/" \
        "$TEMPLATE_FILE" > "$OUTPUT_FILE"
    rm -f "${TEMPLATE_FILE}"
    log_info "$OUTPUT_FILE has been UPDATED."
}


# Function to configure the CMake project
configure_project() {
    log_info "Configuring CMake project..."

    # Generate vcpkg.json
    generate_vcpkg_json

    # Configure CMake
    cmake -B "$BUILD_DIR" -S . \
        -DUSE_VCPKG="$USE_VCPKG" \
        -DPROJECT_NAME="$PROJECT_NAME" \
        -DEXECUTABLE_NAME="$EXECUTABLE_NAME" \
        -DPROJECT_VERSION="$PROJECT_VERSION"

    log_info "CMake configuration complete."
}

# Function to build the project
build_project() {
    log_info "Building project..."

    if [ "$USE_VCPKG" = "OFF" ]; then
        log_info "Building using Nix environment."

        # Remove existing build-nix symlink or directory to prevent conflicts
        if [ -L "build-nix" ] || [ -e "build-nix" ]; then
            log_info "Removing existing build-nix symlink or directory..."
            rm -rf build-nix
        fi

        # Run nix-build with passed arguments
        nix-build "$NIX_DEFAULT_FILE" -o build-nix --argstr pname_arg "$PROJECT_NAME" \
            --argstr exename_arg "$EXECUTABLE_NAME" \
            --argstr description "$DESCRIPTION" \
            --argstr maintainer_name "$MAINTAINER_NAME" \
            --argstr maintainer_email "$MAINTAINER_EMAIL" \
            --argstr maintainer_github "$GITHUB_USERNAME" \
            --argstr homepage "$GITHUB_REPO_URL" \
            --argstr version_arg "$PROJECT_VERSION"

    else
        log_info "Building using Vcpkg and CMake."

        # Ensure the project is configured before building
        if [ ! -d "$BUILD_DIR" ]; then
            log_info "Build directory not found. Configuring project..."
            configure_project
        fi

        # Build the project using CMake
        cmake --build "$BUILD_DIR"

    fi

    log_info "Build complete."
}

# Function to run the executable
run_executable() {
    log_info "Running the executable..."

    if [ "$USE_VCPKG" = "OFF" ]; then
        # Path to the executable in the Nix build output
        EXECUTABLE_PATH="./build-nix/bin/${EXECUTABLE_NAME}"

        if [ -f "$EXECUTABLE_PATH" ]; then
            log_info "Executing $EXECUTABLE_PATH"
            "$EXECUTABLE_PATH"
        else
            log_error "Executable $EXECUTABLE_NAME not found in build-nix/bin/. Please build the project first."
            exit 1
        fi
    else
        EXECUTABLE_PATH="$BUILD_DIR/${EXECUTABLE_NAME}"

        if [ -f "$EXECUTABLE_PATH" ]; then
            log_info "Executing $EXECUTABLE_PATH"
            ./"$EXECUTABLE_PATH"
        else
            log_error "Executable $EXECUTABLE_NAME not found in $BUILD_DIR. Please build the project first."
            exit 1
        fi
    fi
}

# Function to zip files
zip_files() {
    log_info "Zipping files..."

    # Create the zip file excluding the specified directories and files
    zip -r files.zip . -x "files.zip" ".*" "build/*" "build-nix" "vcpkg/*" "Readme.md"

    log_info "Zipping complete. Created files.zip."
}

# Function to enter Nix shell
enter_nix_shell() {
    log_info "Entering Nix shell environment..."
    echo ${NIX_SHELL_FILE}
    nix-shell "${NIX_SHELL_FILE}"
}

# Function to fetch latest commit hash and sha256 for overlay
fetch_latest_commit_and_hash() {
    log_info "Fetching latest commit hash from remote repository..."
    LATEST_COMMIT_HASH=$(git ls-remote "$GITHUB_REPO_URL" "refs/heads/${OVERLAY_BRANCH}" | cut -f1)

    if [ -z "$LATEST_COMMIT_HASH" ]; then
        log_error "Could not fetch the latest commit hash from the remote repository."
        exit 1
    fi

    log_info "Latest remote commit hash: $LATEST_COMMIT_HASH"

    log_info "Fetching the repository and computing SHA256..."
    PREFETCH_OUTPUT=$(nix-prefetch-git --quiet --url "$GITHUB_REPO_URL" --rev "${LATEST_COMMIT_HASH}")
    BASE32_HASH=$(echo "$PREFETCH_OUTPUT" | jq -r '.sha256')
    log_info "Base32 SHA256: $BASE32_HASH"

    # Convert the base32 hash to SRI format (base64 with sha256- prefix)
    SRI_HASH=$(nix --extra-experimental-features nix-command hash to-sri --type sha256 "$BASE32_HASH")
    log_info "SRI-formatted SHA256: $SRI_HASH"
}

# Function to update the overlay file
# Function to update the overlay file
update_overlay() {
    log_info "Updating overlay file..."

    # Ensure build is not in progress
    if [ "$USE_VCPKG" = "OFF" ] && [ ! -f "$NIX_OVERLAY_FILE" ]; then
        log_error "Overlay file not found at $NIX_OVERLAY_FILE."
        exit 1
    fi

    # Fetch latest commit and sha256
    fetch_latest_commit_and_hash

    # Read current version from VERSION file
    if [ ! -f "VERSION" ]; then
        log_error "VERSION file not found."
        exit 1
    fi

    CURRENT_VERSION=$(cat VERSION | tr -d '[:space:]')
    log_info "Current version: $CURRENT_VERSION"

    # Update the project version
    PROJECT_VERSION="$CURRENT_VERSION"

    # Escape slashes and other special characters for sed
    ESCAPED_COMMIT_HASH=$(echo "$LATEST_COMMIT_HASH" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_SRI_HASH=$(echo "$SRI_HASH" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_PROJECT_VERSION=$(echo "$PROJECT_VERSION" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_PROJECT_NAME=$(echo "$PROJECT_NAME" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_EXECUTABLE_NAME=$(echo "$EXECUTABLE_NAME" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_DESCRIPTION=$(echo "$DESCRIPTION" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_MAINTAINER_NAME=$(echo "$MAINTAINER_NAME" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_MAINTAINER_EMAIL=$(echo "$MAINTAINER_EMAIL" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_MAINTAINER_GITHUB=$(echo "$GITHUB_USERNAME" | sed -e 's/[\/&]/\\&/g')
    ESCAPED_HOMEPAGE=$(echo "$GITHUB_REPO_URL" | sed -e 's/[\/&]/\\&/g')

    log_info "Updating fields in $NIX_OVERLAY_FILE..."

    # Update rev
    sed -i "s/rev = \".*\";/rev = \"${ESCAPED_COMMIT_HASH}\";/g" "$NIX_OVERLAY_FILE"

    # Update sha256
    sed -i "s/sha256 = \".*\";/sha256 = \"${ESCAPED_SRI_HASH}\";/g" "$NIX_OVERLAY_FILE"

    # Update pname_arg
    sed -i "s/pname_arg = \".*\";/pname_arg = \"${ESCAPED_PROJECT_NAME}\";/g" "$NIX_OVERLAY_FILE"

    # Update exename_arg
    sed -i "s/exename_arg = \".*\";/exename_arg = \"${ESCAPED_EXECUTABLE_NAME}\";/g" "$NIX_OVERLAY_FILE"

    # Update version_arg
    sed -i "s/version_arg = \".*\";/version_arg = \"${ESCAPED_PROJECT_VERSION}\";/g" "$NIX_OVERLAY_FILE"

    # Update description
    sed -i "s/description = \".*\";/description = \"${ESCAPED_DESCRIPTION}\";/g" "$NIX_OVERLAY_FILE"

    # Update maintainer_name
    sed -i "s/maintainer_name = \".*\";/maintainer_name = \"${ESCAPED_MAINTAINER_NAME}\";/g" "$NIX_OVERLAY_FILE"

    # Update maintainer_email
    sed -i "s/maintainer_email = \".*\";/maintainer_email = \"${ESCAPED_MAINTAINER_EMAIL}\";/g" "$NIX_OVERLAY_FILE"

    # Update maintainer_github
    sed -i "s/maintainer_github = \".*\";/maintainer_github = \"${ESCAPED_MAINTAINER_GITHUB}\";/g" "$NIX_OVERLAY_FILE"

    # Update homepage
    sed -i "s/homepage = \".*\";/homepage = \"${ESCAPED_HOMEPAGE}\";/g" "$NIX_OVERLAY_FILE"

    log_info "Overlay file updated successfully."
}

# Function to build the Debian package using CPack
build_deb_package() {
    log_info "Building .deb package using CPack..."

    # Ensure the project is configured
    if [ "$USE_VCPKG" = "OFF" ] && [ ! -d "build-nix" ]; then
        log_error "Nix build directory 'build-nix' not found. Please build the project first."
        exit 1
    fi

    if [ "$USE_VCPKG" = "ON" ] && [ ! -d "$BUILD_DIR" ]; then
        log_info "Build directory not found. Configuring project..."
        configure_project
    fi

    # Navigate to the build directory
    if [ "$USE_VCPKG" = "OFF" ]; then
        cd build-nix
    else
        cd "$BUILD_DIR"
    fi

    # Run CPack to generate the .deb package
    cpack -G DEB

    log_info ".deb package built successfully."
}

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
    echo "  --build-deb        Build a .deb package using CPack"
    echo "  --help, -h         Display this help message"
    exit 1
}

# Function to parse command line arguments
parse_args() {
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
                    EXECUTABLE_NAME="$2"
                    shift 2
                else
                    log_error "--exe requires a valid executable name."
                    exit 1
                fi
                ;;
            --proj|-p)
                if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                    PROJECT_NAME="$2"
                    shift 2
                else
                    log_error "--proj requires a valid project name."
                    exit 1
                fi
                ;;
            --ver|-v)
                if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                    PROJECT_VERSION="$2"
                    shift 2
                else
                    log_error "--ver requires a valid project version."
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
            --build-deb)
                BUILD_DEB=1
                shift
                ;;
            --help|-h)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Main execution starts here

# Read metadata
read_meta
# Parse command line arguments
parse_args "$@"

# Check dependencies Except getting inside NIX SHELL
if [ "$ENTER_NIX_SHELL" = "0" ]; then
    check_dependencies
elif [ "$ENTER_NIX_SHELL" = "1" ]; then
    enter_nix_shell
    check_dependencies
    exit 0
fi



# if IS_SET_CONFIG_GLOBAL is true read meta from file again
if [ "$IS_SET_CONFIG_GLOBAL" = true ]; then
    read_meta
fi


# Execute the requested actions
if [ "$CONFIGURE_PROJECT" = "1" ]; then
    configure_project
fi

if [ "$BUILD_PROJECT" = "1" ]; then
    build_project
fi

if [ "$RUN_EXECUTABLE" = "1" ]; then
    run_executable
fi

if [ "$ZIP_FILES" = "1" ]; then
    zip_files
fi

if [ "$UPDATE_OVERLAY" = "1" ]; then
    update_overlay
fi

if [ "$BUILD_DEB" = "1" ]; then
    build_deb_package
fi

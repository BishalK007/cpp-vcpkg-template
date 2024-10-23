# C++ Vcpkg & Nix Template

![C++](https://img.shields.io/badge/C%2B%2B-17-blue.svg)
![Vcpkg](https://img.shields.io/badge/vcpkg-Enabled-green.svg)
![Nix](https://img.shields.io/badge/Nix-Enabled-orange.svg)
![Docker](https://img.shields.io/badge/Docker-Enabled-blue.svg)

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
  - [For Ubuntu Users (vcpkg)](#for-ubuntu-users-vcpkg)
  - [For NixOS Users (Nix)](#for-nixos-users-nix)
- [Getting Started](#getting-started)
  - [Clone the Repository](#clone-the-repository)
  - [Initialize Submodules](#initialize-submodules)
- [Development Environment](#development-environment)
  - [Using Docker Dev Container](#using-docker-dev-container)
- [Building the Project](#building-the-project)
  - [Using `builder.sh`](#using-buildersh)
  - [Using Nix](#using-nix)
- [Running the Executable](#running-the-executable)
- [Managing Dependencies](#managing-dependencies)
  - [With vcpkg (Ubuntu)](#with-vcpkg-ubuntu)
  - [With Nix (NixOS)](#with-nix-nixos)
- [Project Structure](#project-structure)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

This repository serves as a template for C++ projects, providing a robust setup for dependency management and development environments using both **vcpkg** on Ubuntu and **Nix** on NixOS. It leverages Docker for a consistent development environment with Visual Studio Code's Dev Containers, ensuring that your development setup is reproducible and isolated.

## Features

- **Cross-Platform Support**: Tested on Ubuntu (with vcpkg) and NixOS (with Nix).
- **Dependency Management**: Uses vcpkg for managing C++ libraries on Ubuntu and Nix for NixOS.
- **Dev Containers**: Docker-based development environment configured for VS Code.
- **Build Automation**: `builder.sh` script to streamline configuration, building, and running.
- **Modern C++**: Utilizes C++17 with libraries like Boost, fmt, and spdlog.
- **Nix Integration**: Seamless integration with Nix for reproducible builds on NixOS.

## Prerequisites

### For Ubuntu Users (vcpkg)

- **Operating System**: Ubuntu 22.04 LTS or later.
- **Docker**: Installed and configured.
- **Git**: Version control.
- **VS Code**: Optional, for using Dev Containers.

### For NixOS Users (Nix)

- **Operating System**: NixOS.
- **Nix Package Manager**: Installed and configured.
- **Git**: Version control.
- **VS Code**: Optional, for using Dev Containers.

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/BishalK007/cpp-vcpkg-template.git
cd cpp-vcpkg-template
```

### Initialize Submodules

The project uses `vcpkg` as a git submodule. Initialize and update submodules:

```bash
git submodule update --init --recursive
```

## Development Environment

### Using Docker Dev Container

This template includes a Docker-based development environment configured for Visual Studio Code's Dev Containers. This ensures a consistent and isolated environment regardless of your host system.

1. **Install Docker**: Follow the [official Docker installation guide](https://docs.docker.com/engine/install/).

2. **Install VS Code**: Download and install [Visual Studio Code](https://code.visualstudio.com/).

3. **Install Dev Containers Extension**:
   - Open VS Code.
   - Go to Extensions (`Ctrl+Shift+X`).
   - Search for `Dev Containers` and install the extension by Microsoft.

4. **Open the Project in Dev Container**:
   - Open the cloned repository in VS Code.
   - Press `F1` and select `Remote-Containers: Reopen in Container`.
   - VS Code will build the Docker image based on `.devcontainer/Dockerfile` and set up the environment.

## Building the Project

### Using `builder.sh`

The `builder.sh` script simplifies the process of configuring, building, and running the project. It supports both vcpkg and Nix environments.

#### Configuration

Configure the project with default settings:

```bash
./builder.sh --conf
```

Configure with custom project name, executable name, and version:

```bash
./builder.sh --conf --proj MyCustomProject --exe MyExecutable --ver 2.0
```

#### Building

Build the project:

```bash
./builder.sh --build
```

Build with custom settings:

```bash
./builder.sh --build --proj MyCustomProject --exe MyExecutable --ver 2.0
```

#### Running

Run the executable after building:

```bash
./builder.sh --run
```

#### Full Workflow

Configure, build, and run in one command:

```bash
./builder.sh --conf --build --run
```

#### Additional Options

- **Zip Project Files**:

  ```bash
  ./builder.sh --zip
  ```

- **Enter Nix Shell**:

  ```bash
  ./builder.sh --nix-shell
  ```

- **Global Configuration**:

  Use global configuration settings:

  ```bash
  ./builder.sh --conf --conf-glob
  ```

- **Help**:

  Display help message:

  ```bash
  ./builder.sh --help
  ```

### Using Nix

For NixOS users, you can build the project using Nix:

1. **Enter Nix Shell**:

   ```bash
   ./builder.sh --nix-shell
   ```
   OR
   ```bash
   nix-shell .nix/shell.nix
   ```

2. **Build with Nix**:

   ```bash
   ./builder.sh --use-nix --build
   ```
   OR
   ```bash
   ./builder.sh --use-nix --build --proj MyCustomProject --exe MyExecutable --ver 2.0
   ```

   The executable will be available in the `result/bin/` directory.

## Running the Executable

After building the project, you can run the executable as follows:

### Using `builder.sh`
- on ubuntu
    ```bash
    ./builder.sh --run
    ```
- on nixos
    ```bash
    ./builder.sh --run --use-nix
    ```

### Directly

Navigate to the build directory and execute:

```bash
./build/MyExecutable
```

Or for Nix builds:

```bash
./build-nix/bin/MyExecutable
```

## Managing Dependencies

### With vcpkg (Ubuntu)

This template uses vcpkg for managing C++ dependencies on Ubuntu.

#### Installing Dependencies

1. **Bootstrap vcpkg**:

   ```bash
   ./vcpkg/bootstrap-vcpkg.sh 
   ```

2. **Integrate vcpkg with the environment**:

   ```bash
   ./vcpkg/vcpkg integrate install
   ```

3. **Install Dependencies**:

   Dependencies are specified in `vcpkg.json`. Install them using cmake sutomatically do not manually.


#### Adding New Dependencies

1. Add the dependency to `vcpkg.json`:

   ```json
   "dependencies": [
     "fmt",
     "spdlog",
     "boost-math",
     "new-library"
   ]
   ```

2. Install the new dependency:
    - Do not do vcpkg install cmake handels that automatically during configure phase. 

### With Nix (NixOS)

For NixOS users, dependencies are managed via Nix expressions.

#### Adding New Dependencies

1. Edit `.nix/default.nix` and add the desired packages to `buildInputs` or `nativeBuildInputs`.

   ```nix
   buildInputs = [
     pkgs.boost
     pkgs.fmt
     pkgs.new-library
   ];
   ```

2. Rebuild the project:

   ```bash
   bash builder.sh -b --use-nix
   ```

## Project Structure

```
cpp-vcpkg-template (root)
├── .devcontainer
│   ├── Dockerfile
│   ├── devcontainer.json
│   └── post-create.sh
├── .nix
│   ├── default.nix
│   └── shell.nix
├── builder.sh
├── include
│   ├── <Include Files>
├── src
│   ├── <Src Files>
│   └── main.cpp
└── vcpkg.json
```

- **.devcontainer/**: Configuration for Docker Dev Container.
- **.nix/**: Nix expressions for building the project on NixOS.
- **builder.sh**: Script to configure, build, and run the project.
- **include/**: Header files.
- **src/**: Source files.
- **vcpkg.json**: vcpkg manifest for dependencies.

## Usage Examples

### Example 1: Basic Build and Run on Ubuntu

1. **Initialize Submodules**:

   ```bash
   git submodule update --init --recursive
   ```

2. **Bootstrap and Integrate vcpkg**:

   ```bash
   ./vcpkg/bootstrap-vcpkg.sh
   ./vcpkg/vcpkg integrate install
   ```

3. **Configure and Build**:

   ```bash
   ./builder.sh --conf --build
   ```

4. **Run the Executable**:

   ```bash
   ./builder.sh --run
   ```

### Example 2: Using Nix on NixOS

1. **Enter Nix Shell**:

   ```bash
   ./builder.sh --nix-shell
   ```

2. **Configure and Build with Nix**:

   ```bash
   ./builder.sh --conf --build --use-nix
   ```

3. **Run the Executable**:

   ```bash
   ./builder.sh --run --use-nix
   ```

## Troubleshooting

- **vcpkg Issues**: Ensure that `vcpkg` is properly bootstrapped and integrated. Re-run the bootstrap script if necessary.
- **Nix Build Failures**: Verify that all dependencies are correctly specified in `.nix/default.nix`.
- **Docker Dev Container Errors**: Ensure Docker is running and you have sufficient permissions. Check Dockerfile logs for errors.
- **Missing Dependencies**: Make sure all dependencies are listed in `vcpkg.json` or `.nix/default.nix` and installed correctly.

## Contributing

Contributions are welcome! Please follow these steps:

1. **Fork the Repository**
2. **Create a Feature Branch**

   ```bash
   git checkout -b feature/YourFeature
   ```

3. **Commit Your Changes**

   ```bash
   git commit -m "Add your message"
   ```

4. **Push to the Branch**

   ```bash
   git push origin feature/YourFeature
   ```

5. **Open a Pull Request**

## License

This project is licensed under the [MIT License](LICENSE).

---

*Happy Coding! 🚀*
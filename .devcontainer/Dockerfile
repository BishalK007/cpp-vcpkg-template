# Use the official Ubuntu 22.04 LTS as the base image
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list
RUN apt-get update

# Install essential build tools and dependencies
RUN apt-get install -y build-essential curl tar unzip zip wget ninja-build pkg-config libssl-dev sudo
RUN apt-get install -y git
RUN apt-get install -y jq

# Clean up the apt cache to reduce image size
RUN rm -rf /var/lib/apt/lists/*

# Download and install CMake 3.30.0 manually
RUN CMAKE_VERSION=3.30.0 && \
    CMAKE_DIR=cmake-${CMAKE_VERSION}-linux-x86_64 && \
    curl -L https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_DIR}.tar.gz -o /tmp/cmake.tar.gz && \
    tar -xzvf /tmp/cmake.tar.gz -C /opt && \
    ln -s /opt/${CMAKE_DIR}/bin/cmake /usr/local/bin/cmake && \
    rm /tmp/cmake.tar.gz

# Create a non-root user to run the container
RUN useradd -m -s /bin/bash vscode

# Add 'vscode' to the 'sudo' group
RUN usermod -aG sudo vscode

# Ensure that /etc/sudoers.d exists
RUN mkdir -p /etc/sudoers.d

# Configure passwordless sudo for 'vscode'
RUN echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode

# Switch to the non-root user
USER vscode
WORKDIR /home/vscode

# Add vcpkg to PATH for convenience
ENV PATH="/vcpkg:${PATH}"

# (Optional) Remove the SHELL directive to avoid overriding default shell settings
# SHELL ["/bin/bash", "-c"]

# This Dockerfile sets up a development environment with CMake 3.30.0 installed from source.

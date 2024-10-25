{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.cmake
    pkgs.ninja
    pkgs.gcc
    pkgs.git
    pkgs.boost
    pkgs.fmt
    pkgs.jq
  ];

  # Ensure the host's Git config is used
  shellHook = ''
    export CC=gcc
    export CXX=g++
    # Unset Vcpkg environment variables if they are set
    unset VCPKG_ROOT
    unset VCPKG_DEFAULT_TRIPLET

    # Link host Git configuration files
    export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
  '';
}

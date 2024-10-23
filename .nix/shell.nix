{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.cmake
    pkgs.ninja
    pkgs.gcc
    pkgs.git
    pkgs.boost
    pkgs.fmt
  ];

  shellHook = ''
    export CC=gcc
    export CXX=g++
    # Unset Vcpkg environment variables if they are set
    unset VCPKG_ROOT
    unset VCPKG_DEFAULT_TRIPLET
  '';
}

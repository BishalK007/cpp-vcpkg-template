{ pkgs ? import <nixpkgs> {}, pname_arg ? "MyProject", exename_arg ? "MyExecutable", version_arg ? null }:

let
  # Read version from VERSION file if version_arg is null
  version_from_file = builtins.readFile ../VERSION;
  # Strip any whitespace or newlines from the version string
  version_clean = builtins.replaceStrings ["\n" "\r" "\t" " "] [""] version_from_file;
  final_version = if version_arg == null then version_clean else version_arg;
in
pkgs.stdenv.mkDerivation rec {
  pname = pname_arg;
  exename = exename_arg;
  version = version_arg;

  src = pkgs.lib.cleanSource ../.;

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
    pkgs.git
    pkgs.pkg-config
    pkgs.bash
  ];

  buildInputs = [
    pkgs.boost
    pkgs.fmt
  ];

  cmakeFlags = [
    "-DUSE_VCPKG=OFF"
    "-DPROJECT_NAME=${pname}"
    "-DEXECUTABLE_NAME=${exename}"
    "-DPROJECT_VERSION=${version}"
  ];

  # Set build directory
  cmakeBuildDir = "build-nix";

  configurePhase = ''
    bash builder.sh -c --use-nix --proj ${pname} --exe ${exename} --ver ${version}
  '';

  buildPhase = ''
    cmake --build ${cmakeBuildDir}
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ${cmakeBuildDir}/${exename} $out/bin/
  '';

  meta = with pkgs.lib; {
    description = "My C++ VCPKG template Project built with Nix";
    homepage = "https://github.com/BishalK007/cpp-vcpkg-template";
    license = licenses.mit;
    maintainers = [ 
      {
        name = "Bishal Karmakar";
        email = "bishal@bishal.pro";
        github = "bishalk007";
      }
    ];
  };
}

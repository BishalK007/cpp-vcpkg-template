{ pkgs ? import <nixpkgs> {},
  pname_arg,
  exename_arg,
  description,
  maintainer_name,
  maintainer_email,
  maintainer_github,
  homepage,
  version_arg
}:

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
    pkgs.zip
    pkgs.jq
    pkgs.nix
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
    echo -e "\033[1;33m[NOTICE !!!]\033[0m NOTE below will show vcpkg.json being updated but nix does not work on repo dir for builds"
    echo -e "\033[1;33m[NOTICE !!!]\033[0m Hence it'll not update vcpkg.json. Run \`bash builder.sh -c --use-nix\` to generate manually"
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
    description = description;
    homepage = homepage;
    license = licenses.mit;
    maintainers = [ 
      {
        name = maintainer_name;
        email = maintainer_email;
        github = maintainer_github;
      }
    ];
  };
}

self: super: let
  cpp-vcpkg-template-src = super.fetchFromGitHub {
    owner = "BishalK007";
    repo = "cpp-vcpkg-template";
    rev = "6703322b920be983400a26d722c74282b19cba3d"; # Use a specific tag or commit hash
    sha256 = "sha256-ztN1K0jRmuk1frncLLzjholnU2zhrzZHXj3SFVaF4Ag="; # Placeholder, will be updated
  };
in {
  cpp-vcpkg-template = super.callPackage "${repototxt-src}/.nix/default.nix" {
    pname_arg = "cpp-vcpkg-template";
    exename_arg = "cppvcpkgtemplate";
    version_arg = "1.0.0";
    description = "A template for smooth cpp vcpkg cmake development.";
    maintainer_name = "Bishal Karmakar";
    maintainer_email = "bishal@bishal.pro";
    maintainer_github = "BishalK007";
    homepage = "https://github.com/BishalK007/cpp-vcpkg-template";
  };
}

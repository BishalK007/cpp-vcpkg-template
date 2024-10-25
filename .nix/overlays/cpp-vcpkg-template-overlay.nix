self: super: let
  repototxt-src = super.fetchFromGitHub {
    owner = "BishalK007";
    repo = "cpp-vcpkg-template";
    rev = "59042a6fa0e9b464ced96f1ece9338e458952d0d"; # Use a specific tag or commit hash
    sha256 = "sha256-OhEBkZtSKUxBio98H4PTkUul3drBVRHSjZ8XwYMjzeM="; # Placeholder, will be updated
  };
in {
  repototxt = super.callPackage "${repototxt-src}/.nix/default.nix" {
    pname_arg = "MyProject";
    exename_arg = "myproject";
    version_arg = "1.0.0";
  };
}

{
  description = "Bevy minimal project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-21.11";
    flake-utils.url = "github:numtide/flake-utils";
    cargo2nix.url = "github:cargo2nix/cargo2nix";
  };

  outputs = { self, nixpkgs, flake-utils, cargo2nix, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ cargo2nix.overlay ];
        };

        rustPkgs = pkgs.rustBuilder.makePackageSet {
          rustChannel = "1.60.0";
          packageFun = import ./Cargo.nix;

          packageOverrides = pkgs: pkgs.rustBuilder.overrides.all ++ [
            (pkgs.rustBuilder.rustLib.makeOverride {
              name = "alsa-sys";
              overrideAttrs = drv: {
                propagatedBuildInputs = drv.propagatedBuildInputs or [ ] ++ [
                  pkgs.alsa-lib
                ];
              };
            })
          ];
        };
        workspaceShell = rustPkgs.workspaceShell { };
      in
      rec {
        inherit rustPkgs;
        packages = builtins.mapAttrs (name: value: value { }) rustPkgs.workspace;
        defaultPackage = packages.hello.bin;
        devShell = workspaceShell;
      });
}

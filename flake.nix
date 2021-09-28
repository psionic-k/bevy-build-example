{
  description = "Yliaster";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay.url = "github:oxalica/rust-overlay";
    cargo2nix.url = "github:cargo2nix/cargo2nix";
    cargo2nix.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, cargo2nix, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (import "${cargo2nix}/overlay")
            rust-overlay.overlay
          ];
        };

        rustChannel = "1.55.0";

        rust = pkgs.rust-bin.stable.${rustChannel}.default;
        rustPkgs = pkgs.rustBuilder.makePackageSet' {
          inherit rustChannel;
          packageFun = import ./Cargo.nix;
        };
      in
      rec {
        inherit rustPkgs;
        packages = {
          cargo2nix = (import cargo2nix { inherit system; }).package;
        } // builtins.mapAttrs (name: value: value { }) rustPkgs.workspace;
        defaultPackage = packages.hello;
        devShell = pkgs.mkShell {
          buildInputs = [
            packages.cargo2nix
            rust
          ];
        };
      });
}

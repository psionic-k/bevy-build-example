{
  description = "A very basic flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rustpkgs.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rustpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rustpkgs.overlay ];
        };
        rust = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
        rustPlatform = with pkgs; makeRustPlatform {
          rustc = rust;
          cargo = rust;
        };
      in
      rec {
         packages = {
           hello = rustPlatform.buildRustPackage {
             name = "hello";
             cargoLock = {
               lockFile = ./Cargo.lock;
             };
             src = ./.;
             nativeBuildInputs = with pkgs; [
               pkgconfig
             ];
             buildInputs = with pkgs; [
               alsa-lib
               udev
             ];
           };
         };
         defaultPackage = packages.hello;
         devShell = with pkgs; mkShell {
          buildInputs = [
            rust
            rust-analyzer
          ];
        };
        hydraJobs = {
          build = defaultPackage;
        };
      });
}

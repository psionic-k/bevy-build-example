{
  description = "A very basic flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rustpkgs.url = "github:oxalica/rust-overlay";
    cargo2nix.url = "github:cargo2nix/cargo2nix";
    cargo2nix.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, rustpkgs, ... }@inputs:
    let
      systems = [
        "x86_64-linux"
        "i686-linux"
      ];
    in
    flake-utils.lib.eachSystem systems
      (system:
        let
          cargo2nix = import inputs.cargo2nix { inherit system; };
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              rustpkgs.overlay
              (import "${inputs.cargo2nix}/overlay")
            ];
          };

          rust = pkgs.rust-bin.stable."1.55.0".default;

          mkOverride = name: { buildInputs ? [ ], nativeBuildInputs ? [ ] }:
            pkgs.rustBuilder.rustLib.makeOverride {
              name = name;
              overrideAttrs = drv: {
                propagatedNativeBuildInputs = drv.propagatedNativeBuildInputs or [ ] ++
                  nativeBuildInputs;
                propagatedBuildInputs = drv.buildInputs or [ ] ++
                  buildInputs;
              };
            };

          mkOverrides = f: pkgs:
            let
              overrides = f pkgs;
            in
            pkgs.rustBuilder.overrides.all ++
            (nixpkgs.lib.mapAttrsToList (mkOverride) overrides);

          rustPkgs = pkgs.rustBuilder.makePackageSet' {
            packageOverrides = mkOverrides (pkgs: {
              alsa-sys = {
                buildInputs = [
                  pkgs.alsa-lib
                ];
                nativeBuildInputs = [
                  pkgs.pkgconfig
                ];
              };
            });

            rustChannel = "1.55.0";
            packageFun = import ./Cargo.nix;
          };
        in
        rec {
          packages = nixpkgs.lib.mapAttrs (name: value: value {}) rustPkgs.workspace;
          defaultPackage = packages.hello;
          devShell = pkgs.mkShell {
            buildInputs = [
              (import inputs.cargo2nix {inherit system;}).package
              rust
            ];
          };
          hydraJobs = {
            build = defaultPackage;
          };
        });
}

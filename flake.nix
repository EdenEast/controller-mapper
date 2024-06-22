{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
    };
    crane = {
      url = "github:ipetkov/crane";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, crane }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        manifest = builtins.fromTOML (builtins.readFile ./Cargo.toml);
        version = manifest.package.version;
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" ];
        };

        inherit (pkgs) lib;
        craneLib = crane.lib.${system};

        # Common configuration needed for crane to build the rust project
        args = {
          src = ./.;

          # This is not required as this would just compile the project again
          doCheck = false;
          buildInputs = with pkgs; [
            pkg-config
            udev
            xdotool
            # xorg.libX11
          ];
        };

        # Build *just* the cargo dependencies, so we can reuse all of that work between runs
        # This also makes sure that the `build.rs` file is built. If buildPackage is just called
        # the build.rs file was not being executed.
        cargoArtifacts = craneLib.buildDepsOnly args;

        controller-mapper = craneLib.buildPackage (args // {
          inherit cargoArtifacts;
        });

      in
      rec
      {
        checks = {
          clippy = craneLib.cargoClippy (args // {
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "--all-targets -- -D warnings";
            doCheck = true;
          });
          tests = craneLib.cargoTest (args // {
            inherit cargoArtifacts;
            doCheck = true;
          });

        };

        apps = {
          controller-mapper = flake-utils.lib.mkApp {
            dev = controller-mapper;
          };
          default = apps.controller-mapper;
        };

        packages = {
          inherit controller-mapper;
          default = controller-mapper;
        };

        devShells.default = pkgs.mkShell {
          name = "controller-mapper";
          inputsFrom = builtins.attrValues checks;
          nativeBuildInputs = with pkgs; [
            rustToolchain
          ];
          packages = with pkgs; [
            asciinema
            asciinema-agg
          ];
        };
      });
}

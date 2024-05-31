{
  description = "A flake providing a reproducible environment for arbitrage";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    cosmos-nix.url = "github:informalsystems/cosmos.nix";
  };

  outputs = { self, nixpkgs, flake-utils, cosmos-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ cosmos-nix.overlays.cosmosNixPackages ]; };
        packageOverrides = pkgs.callPackage ./python-packages.nix { };
        skipCheckTests = drv:
          drv.overridePythonAttrs (old: { doCheck = false; });
        python = pkgs.python3.override { inherit packageOverrides; };
        pythonWithPackages = python.withPackages (ps:
          with ps; [
            cosmpy
            schedule
            python-dotenv
            (skipCheckTests aiohttp)
            (skipCheckTests aiodns)
          ]);
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs.buildPackages; [
            gnumake
            protobuf
            protoc-gen-go
            protoc-gen-go-grpc
            mypy-protobuf
            mypy
            black
            osmosis
            neutron
            jq
            lz4
          ];

          packages = [ pythonWithPackages ];

          shellHook = ''
            export PYTHONPATH=src:build/gen
            make proto
            make genesis
          '';
        };
      });
}

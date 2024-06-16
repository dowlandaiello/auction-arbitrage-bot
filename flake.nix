{
  description = "A flake providing a reproducible environment for arbitrage";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ rust-overlay.overlays.default ]; };
        packageOverrides = pkgs.callPackage ./python-packages.nix { };
        skipCheckTests = drv:
          drv.overridePythonAttrs (old: { doCheck = false; });
        python = pkgs.python312.override { inherit packageOverrides; };
        pythonWithPackages = python.withPackages (ps:
          with ps; [
            cosmpy
            schedule
            python-dotenv
            aiostream
            pytest
            pytest-asyncio
            types-protobuf
            types-pytz
            types-setuptools
            mypy
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
            black
            grpc
            grpc_cli
            ruff
            rust-bin.stable.latest.default
            pkg-config
          ];

          buildInputs = with pkgs; [ openssl ];

          packages = [ pythonWithPackages ];

          shellHook = ''
            export PYTHONPATH=src:build/gen
          '';
        };
      });
}

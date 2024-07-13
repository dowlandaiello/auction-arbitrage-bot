{
  description = "A flake providing a reproducible environment for arbitrage";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=24.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    local-ic = {
      url = "path:local-interchaintest/flake.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    local-interchaintest = {
      url = "path:local-interchaintest/flake.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, local-ic
    , local-interchaintest }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
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
        apps.default = {
          type = "app";
          program = "${pkgs.python3}/bin/python3 main.py";
        };

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
            pkgs.deploy-rs
          ];
          buildInputs = with pkgs; [ openssl ];
          packages = [ pythonWithPackages local-ic ];
          shellHook = ''
            export PYTHONPATH=src:build/gen
          '';
        };
      }) // {
        nixosConfigurations."arbbot-test-runner.us-central1-a.c.arb-bot-429100.internal" =
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [ ./test_runner_conf.nix ];
          };
      };
}

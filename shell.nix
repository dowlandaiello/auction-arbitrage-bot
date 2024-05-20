{ pkgs ? import <nixpkgs> {} }:

let
  packageOverrides = pkgs.callPackage ./python-packages.nix {};
  python = pkgs.python3.override { inherit packageOverrides; };
  pythonWithPackages = python.withPackages (ps: with ps; [
    cosmpy
    schedule
    python-dotenv
  ]);
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [
    gnumake
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc
    mypy-protobuf
    mypy
    black
  ];

  packages = [
    pythonWithPackages
  ];

  shellHook = ''
    export PYTHONPATH=src:build/gen
    make proto
  '';
}
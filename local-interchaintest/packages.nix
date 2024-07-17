{
  local-ic = let
    repo = pkgs.fetchFromGitHub {
      owner = "strangelove-ventures";
      repo = "interchaintest";
      rev = "v8.5.0";
      hash = "sha256-NKp0CFPA593UNG/GzMQh7W/poz1/dESrqlRG8VQVxUk=";
    };
  in pkgs.buildGoModule rec {
    pname = "local-ic";
    version = "8.5.0";
    src = repo;
    proxyVendor = true;
    subPackages = [ "local-interchain/cmd/local-ic" ];
    vendorHash = "sha256-NWq2/gLMYZ7T5Q8niqFRJRrfnkb0CjipwPQa4g3nCac=";
  };
  local-interchaintest = pkgs.rustPlatform.buildRustPackage {
    name = "local-interchaintest";
    src = ./.;
    nativeBuildInputs = [ pkgs.libiconv pkgs.pkg-config ];
    buildInputs = [ pkgs.openssl packages.local-ic ];
    cargoSha256 = "sha256-XAjcq0XKl4UcrfAGLmBdQbmWqNjTIbF3q70vOZSO5gQ=";
    cargoLock = {
      lockFile = ./Cargo.lock;
      outputHashes = {
        "localic-std-0.0.1" =
          "sha256-v2+BGy7aH63B5jR8/oR0CSHOUBgNdfk+8JgNKfOFaq0=";
        "localic-utils-0.1.0" =
          "sha256-1Xg2XSJXqWfCJ4MB6ElrsVYpztXSzAl7HFAZ12QRhfo=";
      };
    };
  };
}

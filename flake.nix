{
  description = "The extended registry for Cloud Haskell";
  inputs.haskellNix.url = "github:input-output-hk/haskell.nix";
  inputs.nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.static-ls.url = "github:josephsumabat/static-ls";
  outputs = { self, nixpkgs, flake-utils, static-ls, haskellNix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        overlays = [
          haskellNix.overlay
          (final: prev: {
            # This overlay adds our project to pkgs
            distributed-process-registryProject =
              final.haskell-nix.project' {
                src = ./.;
                compiler-nix-name = "ghc967";
                # This is used by `nix develop .` to open a shell for use with
                # `cabal`, `hlint` and `haskell-language-server`
                shell.tools = {
                  cabal = { };
                  hlint = { };
                  #haskellPackages.hiedb-plugin = { };
                  #static-ls.outputs.packages.${system}.static-ls = { };
                  haskell-language-server = { };
                };
                # Non-Haskell shell tools go here
                shell.buildInputs = [
                  pkgs.nixpkgs-fmt
                  pkgs.ghciwatch
                  #pkgs.haskellPackages.hiedb
                  #static-ls.outputs.packages.${system}.static-ls
                ];
                # This adds `js-unknown-ghcjs-cabal` to the shell.
                # shell.crossPlatforms = p: [p.ghcjs];
              };
          })
        ];
        pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
        flake = pkgs.distributed-process-registryProject.flake {
          # This adds support for `nix build .#js-unknown-ghcjs:hello:exe:hello`
          crossPlatforms = p: if (system == "x86_64-linux") then [ p.musl64 ] else [ ];
        };
      in
      pkgs.lib.recursiveUpdate flake { packages.default = flake.packages."distributed-process-registry:lib:distributed-process-registry"; });
}

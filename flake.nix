{
  description = "Pi coding agent";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nixpkgs unstable no longer supports Intel macOS. Keep using the final
    # Darwin branch that does so for pi's x86_64-darwin package.
    nixpkgs-darwin-x64.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.flake-parts.flakeModules.easyOverlay ];

      inherit systems;

      perSystem =
        {
          config,
          inputs',
          lib,
          self',
          system,
          ...
        }:
        let
          pkgs =
            (if system == "x86_64-darwin" then inputs'.nixpkgs-darwin-x64 else inputs'.nixpkgs).legacyPackages;

          pi = pkgs.callPackage ./nix/package.nix {
            source = inputs.self;
            platforms = systems;
          };
        in
        {
          _module.args.pkgs = pkgs;

          overlayAttrs.pi = pi;

          packages = {
            default = pi;
            pi = pi;
          };

          apps = {
            default = {
              type = "app";
              program = "${lib.getExe self'.packages.default}";
              meta.description = pi.meta.description;
            };
            pi = config.apps.default;
          };
        };
    };
}

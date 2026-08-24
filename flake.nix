{
  description = "Agent Skills for Crush, Claude Code, and Kiro, with an installer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        installer = pkgs.runCommand "cli-skill-installer" { } ''
          mkdir -p "$out"
          cp "${./install.sh}" "$out/install.sh"
          chmod +x "$out/install.sh"
          cp -r "${./skills}" "$out/skills"
          patchShebangs "$out/install.sh"
        '';
      in
      {
        packages = {
          default = installer;
          installer = installer;
        };

        apps.default = {
          type = "app";
          program = "${installer}/install.sh";
        };
      });
}

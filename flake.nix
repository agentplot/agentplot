{
  description = "Agent-optimized clanServices — co-located infrastructure, CLI packages, skills, and HM module delegation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    agentplot-kit = {
      url = "github:agentplot/agentplot-kit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agent-skills-nix = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-plugins-nix = {
      url = "github:mreimbold/claude-plugins-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-agent-deck = {
      url = "github:codecorral/nix-agent-deck";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      clan.modules.linkding = ./services/linkding;
      clan.modules.microvm = ./services/microvm;

      nixosModules.agentplot = import ./modules/agentplot.nix;
      darwinModules.agentplot = import ./modules/agentplot.nix;

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          linkding-cli = pkgs.callPackage ./services/linkding/packages/linkding-cli { };
        }
      );
    };
}

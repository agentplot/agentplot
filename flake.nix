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
    { self, nixpkgs, agent-skills-nix, agentplot-kit, nix-openclaw, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      inherit (agentplot-kit.lib) mkClientTooling;
    in
    {
      clan.modules.linkding = import ./services/linkding { inherit mkClientTooling; };
      clan.modules.microvm = ./services/microvm;
      clan.modules.gno = import ./services/gno { inherit mkClientTooling; };
      clan.modules.qmd = import ./services/qmd { inherit mkClientTooling; };
      clan.modules.subcog = import ./services/subcog { inherit mkClientTooling; };
      clan.modules.ogham-mcp = import ./services/ogham-mcp { inherit mkClientTooling; };
      clan.modules.miniflux = import ./services/miniflux { inherit mkClientTooling; };
      clan.modules.obsidian = import ./services/obsidian { inherit mkClientTooling; };
      clan.modules.himalaya = import ./services/himalaya { inherit mkClientTooling; };
      clan.modules.tana = import ./services/tana { inherit mkClientTooling; };
      clan.modules.openclaw = import ./services/openclaw {
        inherit mkClientTooling;
        openclaw-packages = nix-openclaw.packages or { };
        lobster = nix-openclaw.packages.lobster or null;
      };
      clan.modules.paperless = import ./services/paperless {
        inherit mkClientTooling;
        enex2paperless = nix-openclaw.packages.enex2paperless or null;
      };

      nixosModules.agentplot = {
        imports = [ ./modules/agentplot.nix ];
        config.agentplot.hmBaseModules = [ agent-skills-nix.homeManagerModules.default ];
      };
      nixosModules.oidc = import ./modules/oidc.nix;
      darwinModules.agentplot = {
        imports = [ ./modules/agentplot.nix ];
        config.agentplot.hmBaseModules = [ agent-skills-nix.homeManagerModules.default ];
      };
      darwinModules.oidc = import ./modules/oidc.nix;

      lib = {
        mkFleetDashboard = { pkgs, inventorySerialization }:
          import ./packages/fleet-dashboard { inherit pkgs inventorySerialization; };
        mkFleetInventory = { pkgs, inventorySerialization }:
          import ./packages/fleet-dashboard/inventory.nix { inherit pkgs inventorySerialization; };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          linkding-cli = pkgs.callPackage ./services/linkding/packages/linkding-cli { };
          miniflux-cli = pkgs.callPackage ./services/miniflux/packages/miniflux-cli { };
          paperless-cli = pkgs.callPackage ./services/paperless/packages/paperless-cli { };
        }
      );
    };
}

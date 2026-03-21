# Smoke test: verify two mock clanServices both writing to agentplot.hmModules compose without conflict.
# Run: nix-instantiate --eval tests/hmModules-composition.nix
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  # Evaluate the adapter module with two mock HM modules
  eval = lib.evalModules {
    modules = [
      ../modules/agentplot.nix
      {
        # Simulate two clanServices writing to hmModules
        config.agentplot.hmModules.linkding-personal = {
          programs.git.enable = true;
        };
        config.agentplot.hmModules.paperless-default = {
          programs.bash.enable = true;
        };
        config.agentplot.user = "testuser";
      }
      # Stub home-manager.users to avoid needing actual HM
      {
        options.home-manager.users = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options.imports = lib.mkOption {
              type = lib.types.listOf lib.types.deferredModule;
              default = [ ];
            };
          });
          default = { };
        };
      }
    ];
  };

  cfg = eval.config;
in
assert cfg.agentplot.user == "testuser";
assert builtins.length (builtins.attrNames cfg.agentplot.hmModules) == 2;
assert builtins.hasAttr "linkding-personal" cfg.agentplot.hmModules;
assert builtins.hasAttr "paperless-default" cfg.agentplot.hmModules;
assert builtins.hasAttr "testuser" cfg.home-manager.users;
"PASS: hmModules composition smoke test — two services compose without conflict"

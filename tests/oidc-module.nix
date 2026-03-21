# Smoke test: verify OIDC module with Kanidm provider auto-derives endpoints correctly.
# Run: nix-instantiate --eval tests/oidc-module.nix
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  eval = lib.evalModules {
    modules = [
      ../modules/oidc.nix
      {
        config.agentplot.oidc.clients.linkding = {
          enable = true;
          provider = "kanidm";
          issuerUrl = "auth.example.com";
          clientId = "myhost";
        };
      }
      # Stub clan.core.vars to avoid needing actual Clan framework
      {
        options.clan.core.vars.generators = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              share = lib.mkOption { type = lib.types.bool; default = false; };
              files = lib.mkOption {
                type = lib.types.attrsOf (lib.types.submodule {
                  options = {
                    secret = lib.mkOption { type = lib.types.bool; default = false; };
                    mode = lib.mkOption { type = lib.types.str; default = "0400"; };
                    path = lib.mkOption { type = lib.types.str; default = "/run/vars/stub"; };
                  };
                });
                default = { };
              };
              prompts = lib.mkOption {
                type = lib.types.attrsOf (lib.types.submodule {
                  options = {
                    type = lib.mkOption { type = lib.types.str; default = "text"; };
                    description = lib.mkOption { type = lib.types.str; default = ""; };
                  };
                });
                default = { };
              };
              runtimeInputs = lib.mkOption { type = lib.types.listOf lib.types.package; default = [ ]; };
              script = lib.mkOption { type = lib.types.str; default = ""; };
            };
          });
          default = { };
        };
      }
    ];
  };

  oidc = eval.config.agentplot.oidc.clients.linkding;
  generators = eval.config.clan.core.vars.generators;

  # Generic provider evaluation
  evalGeneric = lib.evalModules {
    modules = [
      ../modules/oidc.nix
      {
        config.agentplot.oidc.clients.paperless = {
          enable = true;
          provider = "generic";
          issuerUrl = "id.example.com";
          clientId = "paperless";
          endpoints = {
            authorization = "https://id.example.com/authorize";
            token = "https://id.example.com/token";
            userinfo = "https://id.example.com/userinfo";
            jwks = "https://id.example.com/jwks";
          };
        };
      }
      # Stub clan.core.vars
      {
        options.clan.core.vars.generators = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              share = lib.mkOption { type = lib.types.bool; default = false; };
              files = lib.mkOption {
                type = lib.types.attrsOf (lib.types.submodule {
                  options = {
                    secret = lib.mkOption { type = lib.types.bool; default = false; };
                    mode = lib.mkOption { type = lib.types.str; default = "0400"; };
                    path = lib.mkOption { type = lib.types.str; default = "/run/vars/stub"; };
                  };
                });
                default = { };
              };
              prompts = lib.mkOption {
                type = lib.types.attrsOf (lib.types.submodule {
                  options = {
                    type = lib.mkOption { type = lib.types.str; default = "text"; };
                    description = lib.mkOption { type = lib.types.str; default = ""; };
                  };
                });
                default = { };
              };
              runtimeInputs = lib.mkOption { type = lib.types.listOf lib.types.package; default = [ ]; };
              script = lib.mkOption { type = lib.types.str; default = ""; };
            };
          });
          default = { };
        };
      }
    ];
  };

  generic = evalGeneric.config.agentplot.oidc.clients.paperless;
  genericGens = evalGeneric.config.clan.core.vars.generators;
in
# Verify Kanidm endpoint auto-derivation
assert oidc.endpoints.authorization == "https://auth.example.com/ui/oauth2";
assert oidc.endpoints.token == "https://auth.example.com/oauth2/token";
assert oidc.endpoints.userinfo == "https://auth.example.com/oauth2/openid/myhost/userinfo";
assert oidc.endpoints.jwks == "https://auth.example.com/oauth2/openid/myhost/public_key.jwk";
# Verify defaults
assert oidc.signAlgorithm == "ES256";
assert oidc.provider == "kanidm";
# Verify vars generator was created
assert builtins.hasAttr "oidc-linkding" generators;
assert generators."oidc-linkding".files."client-secret".secret == true;
# Verify generic provider uses explicit endpoints
assert generic.provider == "generic";
assert generic.endpoints.authorization == "https://id.example.com/authorize";
assert generic.endpoints.token == "https://id.example.com/token";
assert generic.endpoints.userinfo == "https://id.example.com/userinfo";
assert generic.endpoints.jwks == "https://id.example.com/jwks";
# Verify generic provider also gets a vars generator
assert builtins.hasAttr "oidc-paperless" genericGens;
"PASS: OIDC module smoke test — Kanidm auto-derivation and generic explicit endpoints"

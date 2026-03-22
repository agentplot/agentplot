{ config, lib, pkgs, ... }:
let
  cfg = config.agentplot.oidc;

  oidcClientModule = { name, config, ... }: {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable this OIDC client registration";
      };

      provider = lib.mkOption {
        type = lib.types.enum [ "kanidm" "generic" ];
        default = "kanidm";
        description = "OIDC provider type. 'kanidm' auto-derives endpoint URLs; 'generic' requires explicit endpoints.";
      };

      issuerUrl = lib.mkOption {
        type = lib.types.str;
        description = "OIDC issuer domain (e.g., 'auth.example.com'). Used for Kanidm endpoint derivation.";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        description = "OIDC client identifier";
      };

      signAlgorithm = lib.mkOption {
        type = lib.types.str;
        default = "ES256";
        description = "OIDC signing algorithm";
      };

      endpoints = {
        authorization = lib.mkOption {
          type = lib.types.str;
          default =
            if config.provider == "kanidm"
            then "https://${config.issuerUrl}/ui/oauth2"
            else "";
          description = "Authorization endpoint URL";
        };

        token = lib.mkOption {
          type = lib.types.str;
          default =
            if config.provider == "kanidm"
            then "https://${config.issuerUrl}/oauth2/token"
            else "";
          description = "Token endpoint URL";
        };

        userinfo = lib.mkOption {
          type = lib.types.str;
          default =
            if config.provider == "kanidm"
            then "https://${config.issuerUrl}/oauth2/openid/${config.clientId}/userinfo"
            else "";
          description = "Userinfo endpoint URL";
        };

        jwks = lib.mkOption {
          type = lib.types.str;
          default =
            if config.provider == "kanidm"
            then "https://${config.issuerUrl}/oauth2/openid/${config.clientId}/public_key.jwk"
            else "";
          description = "JWKS endpoint URL";
        };
      };
    };
  };

  enabledClients = lib.filterAttrs (_: c: c.enable) cfg.clients;
in
{
  options.agentplot.oidc = {
    clients = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule oidcClientModule);
      default = { };
      description = "OIDC client registrations for agentplot services";
    };
  };

  config = lib.mkIf (enabledClients != { }) {
    clan.core.vars.generators = lib.mapAttrs' (
      clientName: clientCfg:
      lib.nameValuePair "oidc-${clientName}" ({
        share = true;
        files."client-secret" = {
          secret = true;
          mode = "0440";
        };
        runtimeInputs = [ pkgs.openssl ];
      } // (if clientCfg.provider == "kanidm" then {
        # kanidm: auto-generate secret (fleet controls the IdP)
        script = ''
          openssl rand -hex 32 > $out/client-secret
        '';
      } else {
        # generic: prompt for secret (created in external IdP dashboard)
        prompts."client-secret" = {
          type = "hidden";
          description = "OIDC client secret for '${clientName}' (issuer: ${clientCfg.issuerUrl})";
        };
        script = ''
          cp "$prompts/client-secret" "$out/client-secret"
        '';
      }))
    ) enabledClients;
  };
}

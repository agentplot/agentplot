# Dashboard serving module — serves static dashboard HTML via Caddy file_server.
#
# Usage (in consuming NixOS/Darwin config):
#
#   agentplot.dashboards = {
#     enable = true;
#     domain = "dashboards.swancloud.net";
#     sites = {
#       fleet = fleet-dashboard;              # derivation with index.html
#       capabilities = capabilities-dashboard; # derivation with index.html
#     };
#   };
#
# Each site is served at /<site-name>/ under the configured domain.
{ config, lib, ... }:
let
  cfg = config.agentplot.dashboards;
in
{
  options.agentplot.dashboards = {
    enable = lib.mkEnableOption "Caddy-based static dashboard serving";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "FQDN for the Caddy virtual host (e.g., dashboards.swancloud.net)";
    };

    sites = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = ''
        Attrset of site name to derivation. Each derivation must contain an
        index.html. Sites are served at /<name>/ under the configured domain.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy.virtualHosts.${cfg.domain} = {
      extraConfig = lib.concatStringsSep "\n" (
        [ config.caddy-cloudflare.tls ]
        ++ lib.mapAttrsToList (name: drv: ''
          handle_path /${name}/* {
            root * ${drv}
            file_server
          }
        '') cfg.sites
        ++ [
          ''
            handle / {
              respond "Dashboard index: ${lib.concatStringsSep ", " (builtins.attrNames cfg.sites)}" 200
            }
          ''
        ]
      );
    };
  };
}

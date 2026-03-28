# Capabilities dashboard — self-contained HTML with baked-in capabilities JSON.
#
# Usage (in consuming flake):
#
#   # 1. Collect serialization from each machine's evaluated config:
#   capabilitiesSerialization = {
#     machines = {
#       mac-studio = nixosConfigurations.mac-studio.config.agentplot.serialization;
#       macbook    = darwinConfigurations.macbook.config.agentplot.serialization;
#       openclaw   = nixosConfigurations.openclaw.config.agentplot.serialization;
#     };
#   };
#
#   # 2. Build the dashboard:
#   capabilities-dashboard = inputs.agentplot.lib.mkCapabilitiesDashboard {
#     inherit pkgs capabilitiesSerialization;
#   };
#
#   # Result: $out/index.html — self-contained SPA, no external dependencies.
{ pkgs, capabilitiesSerialization }:

let
  capabilitiesJsonFile = pkgs.writeText "capabilities.json" (builtins.toJSON {
    inherit (capabilitiesSerialization) machines;
  });
in
pkgs.runCommand "capabilities-dashboard" {
  nativeBuildInputs = [ pkgs.python3 ];
} ''
  mkdir -p $out
  python3 -c "
import sys
html = open('${./dashboard.html}').read()
json_data = open('${capabilitiesJsonFile}').read()
html = html.replace('__CAPABILITIES_JSON__', json_data, 1)
open(sys.argv[1], 'w').write(html)
  " "$out/index.html"
''

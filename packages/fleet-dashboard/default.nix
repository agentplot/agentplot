# Fleet dashboard — self-contained HTML with baked-in inventory JSON.
# Usage: nix build .#fleet-dashboard
{ pkgs, inventorySerialization }:

let
  inventoryJsonFile = pkgs.writeText "fleet-inventory.json" (builtins.toJSON {
    inherit (inventorySerialization) meta machines instances tags;
  });
in
pkgs.runCommand "fleet-dashboard" {
  nativeBuildInputs = [ pkgs.python3 ];
} ''
  mkdir -p $out
  python3 -c "
import sys
html = open('${./dashboard.html}').read()
json_data = open('${inventoryJsonFile}').read()
html = html.replace('__INVENTORY_JSON__', json_data, 1)
open(sys.argv[1], 'w').write(html)
  " "$out/index.html"
''

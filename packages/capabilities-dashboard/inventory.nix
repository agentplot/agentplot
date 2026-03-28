# Capabilities inventory JSON — plain JSON export for programmatic consumption.
#
# Usage (in consuming flake):
#
#   # Collect serialization from each machine, then:
#   capabilities-inventory = inputs.agentplot.lib.mkCapabilitiesInventory {
#     inherit pkgs capabilitiesSerialization;
#   };
#
#   # Result: plain JSON file parseable by jq, Python, etc.
{ pkgs, capabilitiesSerialization }:

pkgs.writeText "capabilities-inventory.json" (builtins.toJSON {
  inherit (capabilitiesSerialization) machines;
})

# Fleet inventory JSON — extracts serializable data from Clan's inventorySerialization.
# Usage: nix build .#fleet-inventory
{ pkgs, inventorySerialization }:

pkgs.writeText "fleet-inventory.json" (builtins.toJSON {
  inherit (inventorySerialization) meta machines instances tags;
})

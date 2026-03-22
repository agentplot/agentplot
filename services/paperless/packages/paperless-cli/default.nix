{
  writeShellApplication,
  restish,
}:
writeShellApplication {
  name = "paperless-cli";
  runtimeInputs = [
    restish
  ];
  text = ''
    : "''${PAPERLESS_BASE_URL:?PAPERLESS_BASE_URL not set}"
    : "''${PAPERLESS_API_TOKEN:?PAPERLESS_API_TOKEN not set}"

    TMPHOME=$(mktemp -d)
    trap 'rm -rf "$TMPHOME"' EXIT

    # restish uses configdir: ~/Library/Application Support on macOS, ~/.config on Linux
    if [[ "$(uname)" == "Darwin" ]]; then
      CFGDIR="$TMPHOME/Library/Application Support/restish"
    else
      CFGDIR="$TMPHOME/.config/restish"
    fi
    mkdir -p "$CFGDIR"

    cat > "$CFGDIR/apis.json" << APIEOF
    {
      "paperless": {
        "base": "$PAPERLESS_BASE_URL",
        "spec_files": ["${./openapi.json}"],
        "profiles": {
          "default": {
            "headers": {
              "Authorization": "Token $PAPERLESS_API_TOKEN"
            }
          }
        }
      }
    }
    APIEOF

    HOME="$TMPHOME" exec restish paperless "$@"
  '';
}

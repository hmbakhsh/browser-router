#!/bin/zsh
set -euo pipefail

REPOSITORY="${BROWSER_ROUTER_REPOSITORY:-hmbakhsh/browser-router}"
DESTINATION="$HOME/Applications/Browser Router.app"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/$REPOSITORY/releases/latest")
DOWNLOAD_URL=$(python3 -c 'import json,sys; data=json.load(sys.stdin); print(next(asset["browser_download_url"] for asset in data["assets"] if asset["name"] == "Browser-Router.zip"))' <<< "$RELEASE_JSON")

echo "Downloading Browser Router…"
curl -fL "$DOWNLOAD_URL" -o "$TEMP_DIR/Browser-Router.zip"
ditto -x -k "$TEMP_DIR/Browser-Router.zip" "$TEMP_DIR"

pkill -x BrowserRouter 2>/dev/null || true
mkdir -p "$HOME/Applications"
rm -rf "$DESTINATION"
ditto "$TEMP_DIR/Browser Router.app" "$DESTINATION"
open -Ra "$DESTINATION"
open "$DESTINATION"

echo "Installed $DESTINATION"

#!/bin/zsh
set -euo pipefail

REPOSITORY="${ROOTIE_REPOSITORY:-hmbakhsh/rootie}"
DESTINATION="$HOME/Applications/Rootie.app"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/$REPOSITORY/releases/latest")
DOWNLOAD_URL=$(python3 -c 'import json,sys; data=json.load(sys.stdin); print(next(asset["browser_download_url"] for asset in data["assets"] if asset["name"] == "Rootie.zip"))' <<< "$RELEASE_JSON")

echo "Downloading Rootie…"
curl -fL "$DOWNLOAD_URL" -o "$TEMP_DIR/Rootie.zip"
ditto -x -k "$TEMP_DIR/Rootie.zip" "$TEMP_DIR"

pkill -x Rootie 2>/dev/null || true
mkdir -p "$HOME/Applications"
rm -rf "$DESTINATION"
ditto "$TEMP_DIR/Rootie.app" "$DESTINATION"
open -Ra "$DESTINATION"
open "$DESTINATION"

echo "Installed $DESTINATION"

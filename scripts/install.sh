#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
SOURCE_APP="$ROOT/dist/Browser Router.app"
DESTINATION="$HOME/Applications/Browser Router.app"

"$ROOT/scripts/build-app.sh"
pkill -x BrowserRouter 2>/dev/null || true
mkdir -p "$HOME/Applications"
rm -rf "$DESTINATION"
ditto "$SOURCE_APP" "$DESTINATION"
open -Ra "$DESTINATION"
open "$DESTINATION"

echo "Installed $DESTINATION"
echo "Edit ~/.browser-router/config.json, then make Browser Router the default from its menu."

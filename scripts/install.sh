#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
SOURCE_APP="$ROOT/dist/Rootie.app"
DESTINATION="$HOME/Applications/Rootie.app"

"$ROOT/scripts/build-app.sh"
pkill -x Rootie 2>/dev/null || true
mkdir -p "$HOME/Applications"
rm -rf "$DESTINATION"
ditto "$SOURCE_APP" "$DESTINATION"
open -Ra "$DESTINATION"
open "$DESTINATION"

echo "Installed $DESTINATION"
echo "Edit ~/.rootie/config.json, then make Rootie the default from its menu."

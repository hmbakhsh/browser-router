#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
OUTPUT_DIR="${ROOTIE_RELEASE_OUTPUT_DIR:-$ROOT/dist/release}"
VERSION="${ROOTIE_VERSION:?ROOTIE_VERSION is required}"
BUILD_NUMBER="${ROOTIE_BUILD_NUMBER:?ROOTIE_BUILD_NUMBER is required}"
NOTES_FILE="${ROOTIE_RELEASE_NOTES:?ROOTIE_RELEASE_NOTES is required}"
DOWNLOAD_PREFIX="https://github.com/hmbakhsh/rootie/releases/download/v${VERSION}/"
SPARKLE_BIN="$ROOT/.build/artifacts/sparkle/Sparkle/bin"

[[ "$VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || {
  echo "ROOTIE_VERSION must use MAJOR.MINOR.PATCH." >&2
  exit 1
}
[[ "$BUILD_NUMBER" =~ '^[1-9][0-9]*$' ]] || {
  echo "ROOTIE_BUILD_NUMBER must be a positive integer." >&2
  exit 1
}
[[ -f "$NOTES_FILE" ]] || {
  echo "Release notes not found: $NOTES_FILE" >&2
  exit 1
}

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

ROOTIE_RELEASE_BUILD=1 "$ROOT/scripts/build-app.sh" >/dev/null

APP="$ROOT/dist/Rootie.app"
ARCHIVE="$OUTPUT_DIR/Rootie.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
cp "$NOTES_FILE" "$OUTPUT_DIR/Rootie.md"

GENERATE_ARGS=(
  --account io.github.hmbakhsh.rootie
  --download-url-prefix "$DOWNLOAD_PREFIX"
  --embed-release-notes
  --maximum-deltas 0
  --link "https://github.com/hmbakhsh/rootie/releases/tag/v${VERSION}"
  "$OUTPUT_DIR"
)

if [[ -n "${SPARKLE_PRIVATE_KEY:-}" ]]; then
  print -rn -- "$SPARKLE_PRIVATE_KEY" | "$SPARKLE_BIN/generate_appcast" \
    --ed-key-file - "${GENERATE_ARGS[@]}"
else
  "$SPARKLE_BIN/generate_appcast" "${GENERATE_ARGS[@]}"
fi

rm "$OUTPUT_DIR/Rootie.md"
"$ROOT/scripts/verify-release.sh" "$APP" "$ARCHIVE" "$OUTPUT_DIR/appcast.xml"

echo "$OUTPUT_DIR"

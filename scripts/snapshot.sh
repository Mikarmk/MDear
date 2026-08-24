#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_FILE="${1:-$ROOT_DIR/Tests/Fixtures/tables.md}"
OUTPUT_FILE="${2:-$ROOT_DIR/build/table-snapshot.png}"
SNAPSHOT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mdore-snapshot.XXXXXX")"
trap 'rm -rf "$SNAPSHOT_DIR"' EXIT

mkdir -p "$(dirname "$OUTPUT_FILE")"
swiftc -parse-as-library \
  -framework AppKit \
  -framework WebKit \
  -framework UniformTypeIdentifiers \
  "$ROOT_DIR/Sources/MDore/Localization.swift" \
  "$ROOT_DIR/Sources/MDore/MarkdownDocument.swift" \
  "$ROOT_DIR/Sources/MDore/MarkdownRenderer.swift" \
  "$ROOT_DIR/Tests/VisualSnapshot.swift" \
  -o "$SNAPSHOT_DIR/VisualSnapshot"

"$SNAPSHOT_DIR/VisualSnapshot" "$INPUT_FILE" "$OUTPUT_FILE"
echo "$OUTPUT_FILE"

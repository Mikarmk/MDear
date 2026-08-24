#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mdore-tests.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

ARCH="$(uname -m)"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"

swiftc -parse-as-library \
  -target "${ARCH}-apple-macos14.0" \
  -sdk "$SDK_PATH" \
  -framework AppKit \
  -framework UniformTypeIdentifiers \
  "$ROOT_DIR/Sources/MDore/MarkdownDocument.swift" \
  "$ROOT_DIR/Sources/MDore/MarkdownRenderer.swift" \
  "$ROOT_DIR/Tests/RendererTests.swift" \
  -o "$TEST_DIR/RendererTests"

"$TEST_DIR/RendererTests"


#!/bin/sh
# Compiles the Foundation-only watch logic (StaseisWatch/Shared) for macOS and runs the assertions.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
xcrun --sdk macosx swiftc -swift-version 5 -O -o "$out/watch_tests" \
  "$here"/../StaseisWatch/Shared/*.swift "$here/main.swift"
"$out/watch_tests"

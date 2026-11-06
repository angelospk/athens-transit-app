#!/usr/bin/env bash
# Renders the store screenshots from slides.html and the app captures next to it.
# Captures: release build on an Android emulator, 1080x2400, status bar cropped (top 110 px).
# Usage: docs/store/screenshots/src/render.sh   (needs google-chrome; fonts load from Google Fonts)
set -euo pipefail
cd "$(dirname "$0")"
for s in 1 2 3 4 5; do
  for sz in ios:1320,2868 play:1080,2160; do
    google-chrome --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
      --virtual-time-budget=4000 --window-size="${sz#*:}" \
      --screenshot="../${sz%%:*}/0$s.png" "file://$PWD/slides.html?s=$s" 2>/dev/null &
  done
done
wait

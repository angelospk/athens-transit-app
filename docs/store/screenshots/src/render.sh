#!/usr/bin/env bash
# Renders the store screenshots from slides.html and the app captures next to it.
# Captures: release build on an Android emulator, 1080x2400, status bar cropped (top 110 px).
# Usage: docs/store/screenshots/src/render.sh   (needs google-chrome; fonts load from Google Fonts)
set -euo pipefail
cd "$(dirname "$0")"
# Play: all five frames, phone cropped at the bottom.
# App Store: a full iPhone frame, and no frame 04 (Android notification; the app cannot run that
# live card on iOS), so the iOS set is frames 1, 2, 3, 5 saved as 01-04.
shoot() { google-chrome --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
  --virtual-time-budget=4000 --window-size="$1" --user-data-dir="$(mktemp -d)" \
  --screenshot="$2" "file://$PWD/slides.html?$3" 2>/dev/null; }
for lang in el en; do
  mkdir -p "../ios/$lang" "../play/$lang"
  rm -f "../ios/$lang"/*.png "../play/$lang"/*.png
  for s in 1 2 3 4 5; do shoot 1080,2160 "../play/$lang/0$s.png" "s=$s&lang=$lang" & done
  i=1
  for s in 1 2 3 5; do shoot 1320,2868 "../ios/$lang/0$i.png" "s=$s&lang=$lang&device=iphone" & i=$((i + 1)); done
  wait
done

#!/usr/bin/env bash
# Generates examples/demo-source.png, the synthetic colour image used for the
# README screenshot. Synthetic on purpose: the repo can license its own demo
# art, and the scene is built to exercise the parts of mkwall that matter —
# a smooth sky that bands at 16 levels, dark foreground that needs --gamma,
# and hard-edged shapes that must stay crisp.
set -euo pipefail
cd "$(dirname "$0")"

W=1200 H=1620

# -seed pins the plasma cloud: without it every rebuild gives a different sky
# and the committed screenshot stops matching what this script produces.
magick -size ${W}x${H} gradient:'#1b2a4a-#e8a05c' \
  \( -seed 1972 -size ${W}x${H} plasma:fractal -blur 0x18 -colorspace Gray \) \
  -compose Overlay -composite \
  -fill '#fff3d0' -draw "circle 840,430 840,330" \
  -fill '#2b3550' -draw "polygon 0,1130 250,780 430,1010 620,700 900,1090 1200,850 1200,1620 0,1620" \
  -fill '#141a28' -draw "polygon 0,1320 320,1080 560,1290 860,1040 1200,1300 1200,1620 0,1620" \
  -fill '#05070c' -draw "polygon 0,1500 200,1400 480,1520 760,1410 1200,1530 1200,1620 0,1620" \
  -strip demo-source.png

magick identify -format 'wrote %f  %wx%h  %[colorspace]\n' demo-source.png

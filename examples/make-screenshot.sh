#!/usr/bin/env bash
# Builds docs/example.png, the README screenshot.
#
# Panels 2 and 3 are put through a 16-level remap before display, so what you
# see is what the Paperwhite's panel actually renders — not the 8-bit file.
# That is the whole point of the comparison: the default output bands in the
# sky, and --levels 16 --dither is what fixes it.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=examples/demo-source.png
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
FONT=Adwaita-Sans
BOLD=Adwaita-Sans-Bold
PANEL_W=330

[[ -f $SRC ]] || ./examples/make-demo.sh

./mkwall -f -o "$TMP/a" "$SRC" >/dev/null
./mkwall --gamma 1.5 --levels 16 --dither -f -o "$TMP/b" "$SRC" >/dev/null

# The panel can only show 16 evenly spaced grays; simulate that for display.
magick -size 16x1 gradient:black-white -colorspace Gray -depth 8 "$TMP/ramp.png"
magick "$TMP/a/demo-source.png" +dither -remap "$TMP/ramp.png" "$TMP/a-panel.png"

panel() { # image caption -> $TMP/p<n>.png
  # -border for the gap, not -splice: -splice with gravity center would insert
  # the padding through the middle of the picture.
  magick "$1" -resize ${PANEL_W}x \
    -bordercolor '#d0d4da' -border 1 \
    -bordercolor white -border 0x7 \
    \( -background white -fill '#3a4049' -font "$FONT" -pointsize 15 label:"$2" \) \
    -background white -gravity center -append "$3"
}

panel "$SRC"              "source · 1200×1620 colour"          "$TMP/p1.png"
panel "$TMP/a-panel.png"  "mkwall (defaults)"                  "$TMP/p2.png"
panel "$TMP/b/demo-source.png" "--gamma 1.5 --levels 16 --dither" "$TMP/p3.png"

magick montage -mode concatenate -tile 3x -background white -geometry +14+14 \
  "$TMP/p1.png" "$TMP/p2.png" "$TMP/p3.png" "$TMP/row.png"

magick -background white -fill '#1b1f24' -font "$BOLD" -pointsize 19 \
  label:'mkwall → 1072×1448, 8-bit grayscale, no alpha' \
  -bordercolor white -border 14x10 "$TMP/title.png"
magick -background white -fill '#6a7078' -font "$FONT" -pointsize 14 \
  label:'shown as the Paperwhite'\''s 16-level e-ink panel renders it' \
  -bordercolor white -border 14x0 "$TMP/sub.png"

mkdir -p docs
magick -background white "$TMP/title.png" "$TMP/sub.png" "$TMP/row.png" \
  -gravity center -append -bordercolor white -border 10 \
  -colors 256 -define png:compression-level=9 -strip docs/example.png

magick identify -format 'wrote %f  %wx%h  %b\n' docs/example.png

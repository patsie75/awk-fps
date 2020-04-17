#!/bin/bash

[ -w "$1" ] || { echo "Usage: $0 <xpm3file.xpm>" >&2; exit 1; }

# awk converts human readable colors back to #RRGGBB values
# sed converts xpm3 format to xpm2
awk 'BEGIN {
  # get list of color names and their srgb() values
  cmd = "convert -list color"
  while ((cmd | getline) > 0)
   color[$1] = $2
  close(cmd)
}
(($2 == "c") && (c=substr($3, 1, length($3)-2)) && (c in color)) {
  # color line and color is in the color[] array, extract srgb values
  match(color[c], /srgb\(([0-9]*),([0-9]*),([0-9]*)\)/, arr)

  printf("\"%-*s c #%02X%02X%02X\", # %s\n", 2, substr($1,2), arr[1], arr[2], arr[3], color[c] )
  next
} 1' "$1" | \
sed 's/^static char.*/! XPM2/;/^\/\*/d;s/^"//;s/",\?//;/^};/d' >"$(basename "$1" .xpm).xpm2"


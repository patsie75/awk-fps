#!/bin/bash

[ -w "$1" ] || { echo "Usage: $0 <xpm3file.xpm>" >&2; exit 1; }
sed 's/^static char.*/! XPM2/;/^\/\*/d;s/^"//;s/",\?//;/^};/d' "$1" >"$(basename $1 .xpm).xpm2"


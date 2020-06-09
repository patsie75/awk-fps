#!/usr/bin/env bash

stty=$(which stty)
function _exit() { "$stty" "$saved"; }

saved="$("$stty" -g)"
"$stty" -echo raw

trap _exit EXIT

#/usr/bin/gawk -f ./fps.gawk
/usr/local/bin/gawk5 -f ./fps/main.gawk

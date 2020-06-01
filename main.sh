#!/usr/bin/env bash

function _exit() { /usr/bin/stty "$saved"; }

saved="$(/usr/bin/stty -g)"
/usr/bin/stty -echo raw

trap _exit EXIT

/usr/bin/gawk -f ./fps.gawk

#!/usr/bin/awk -f

(NR == FNR) && (NF) { printf("map \"%s\"\n", $0) }
(NR != FNR) && (NF == 3) && ($1 !~ /^#/) { printf("obj %3d %3d %3d\n", $1, $2, $3) }


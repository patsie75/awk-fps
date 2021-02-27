@namespace "math"

function abs(i) { return( (i<0) ? -i : i ) }
function max(a,b) { return( (a>b) ? a : b ) }
function min(a,b) { return( (a<b) ? a : b ) }
function floor(n,    x) { x=int(n); return(x==n || n>0) ? x : x-1 }


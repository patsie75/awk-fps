#!/usr/bin/gawk -f

@include "lib/draw.gawk"

function abs(i) { return( (i<0) ? -i : i ) }
function max(a,b) { return( (a>b) ? a : b ) }
function min(a,b) { return( (a<b) ? a : b ) }

## Draw a pixel of color "col" on position (x,y) on "canvas"
function pixel(scr, x, y, col,   x0,y0) {
  #printf("pixel(%d,%d) [%.5f,%.5f]\n", shortint(x),shortint(y), x,y )
  #scr[int(y)*scr["width"] + int(x)] = col
  #scr[shortint(y)*scr["width"] + shortint(x)] = col
  #scr[int(y+0.0001)*scr["width"] + int(x+0.0001)] = col

  x0 = int(x+0.0001)
  y0 = int(y+0.0001)
  if ((0 <= x0 && x0 < scr["width"]) && (0 <= y0 && y0 < scr["height"])) {
    scr[y0*scr["width"] + x0] = col
  }
}

## Draw a horizontal line from (x1,y1) and length len
function hline(scr, x1,y1, len, col,   i, l) {
  l = int(x1+len)
  for (i=x1; i<l; i++)
    pixel(scr, i,y1, col)
}

## Draw a vertical line from (x1,y1) and length len
function vline(scr, x1,y1, len, col,   i, l) {
  l = int(y1+len)
  for (i=y1; i<l; i++)
    pixel(scr, x1,i, col)
}


## Draw a line from (x1,y1) to (x2,y2)
function line(scr, x1,y1,x2,y2, col,   direction, a1,a2,b1,b2, tmp, i,j, m) {
  #printf("line2(): (%d,%d),(%d,%d)\n", x1,y1, x2,y2)

  if (abs(x1-x2) >= abs(y1-y2)) {
    # horizontal line
    direction = 1
    a1=x1; a2=x2; b1=y1; b2=y2
  } else {
    # vertical line
    direction = 0
    a1=y1; a2=y2; b1=x1; b2=x2
  }

  # swap points if a1 > a2
  if (a1 > a2) {
    tmp=a1; a1=a2; a2=tmp
    tmp=b1; b1=b2; b2=tmp
  }

  # calculate slope/delta
  m = (a2-a1) ? (b2-b1) / (a2-a1) : 0

  j = b1
  # draw either a "horizontal" or "vertical" line
  for (i=a1; i<=a2; i++) {
    pixel(scr, direction ? i : j, direction ? j : i, col)
    j += m
  }
}

## Draw a triangle (x1,y1), (x2,y2), (x3,y3)
function triangle(src, x1,y1, x2,y2, x3,y3, col) {
  line(scr, x1,y1, x2,y2, col)
  line(scr, x2,y2, x3,y3, col)
  line(scr, x3,y3, x1,y1, col)
}

function fillTriangle(scr, x1,y1, x2,y2, x3,y3, col, type,    i, d1,d2,d3, sx,ex) {
  if ((x1 < 0) && (x2 < 0) && (x3 < 0)) return
  if ((y1 < 0) && (y2 < 0) && (y3 < 0)) return
  if ((x1 > scr["width"]) && (x2 > scr["width"]) && (x3 > scr["width"])) return
  if ((y1 > scr["height"]) && (y2 > scr["height"]) && (y3 > scr["height"])) return

  # y1 < y2 < y3
  if (y2 < y1) { i=y1; y1=y2; y2=i; i=x1; x1=x2; x2=i }
  if (y3 < y2) { i=y2; y2=y3; y3=i; i=x2; x2=x3; x3=i }
  if (y2 < y1) { i=y1; y1=y2; y2=i; i=x1; x1=x2; x2=i }

  # get delta/slopes
  i = y2-y1; d1 = i ? (x2-x1) / i : 0
  i = y3-y2; d2 = i ? (x3-x2) / i : 0
  i = y1-y3; d3 = i ? (x1-x3) / i : 0

  # upper triangle
  for (i=y1; i<y2; i++) {
    sx = x1 + (i-y1) * d3
    ex = x1 + (i-y1) * d1

    if (sx < ex) {
      hline(scr, sx,i, (ex-sx)+1, col)
    } else {
      hline(scr, ex,i, (sx-ex)+1, col)
    }
  }

  # lower triangle
  for(i=y2; i<=y3; i++) {
    sx = x1 + (i-y1) * d3
    ex = x2 + (i-y2) * d2

    if (sx < ex) {
      hline(scr, sx,i, (ex-sx)+1, col)
    } else {
      hline(scr, ex,i, (sx-ex)+1, col)
    }
  }

}

## Draw a box (x1,y1), (x2,y2)
function box(scr, x1,y1,x2,y2, col,   i, tmp) {
  if (x1 > x2) {
    tmp=x1; x1=x2; x2=tmp
  }
  if (y1 > y2) {
    tmp=y1; y1=y2; y2=tmp
  }

  for (i=x1; i<=x2; i++) {
    pixel(scr, i,y1, col)
    pixel(scr, i,y2, col)
  }
  for (i=y1+1; i<y2; i++) {
    pixel(scr, x1,i, col)
    pixel(scr, x2,i, col)
  }
}


#!/usr/bin/gawk -f

BEGIN {
  hex = "0123456789ABCDEF"
}

function hex2dec(h,    result, l) {
  result = 0
  l = length(h)

  for (i=1; i<=l; i++) {
    result *= 16
    result += index(hex, toupper(substr(h,i,1)) ) - 1
  }

  return(result)
}


function loadxpm2(dst, fname,   w,h, nrcolors,charsppx, col,color,data, i,pix) {
  # read header "! XPM2"
  if ( ((getline < fname) < 1) || ($0 != "! XPM2") ) { close(fname); return(0); }

  # read picture meta info "<width> <height> <nrcolors> <chars-per-pixel>"
  if ( ((getline < fname) < 1) || (NF != 4) ) { close(fname); return(0); }
  w = int($1)
  h = int($2)
  nrcolors = int($3)
  charsppx = int($4)

  # read colormap "<chars> c #<RR><GG><BB>"
  for (i=0; i<nrcolors; i++) {
    if ((getline < fname) < 1) { close(fname); return(0); }
    chr = substr($0, 1, charsppx)
    col = substr($0, charsppx+4)
    color[chr] = sprintf("%s;%s;%s", hex2dec(substr(col,2,2)), hex2dec(substr(col,4,2)), hex2dec(substr(col,6,2)) )
    #printf("loadxpm2(): %2d: %s c %s\n", i, chr, color[chr])
  }

  # read pixel data
  data = ""
  while ( (length(data) / charsppx) < (w*h)) {
    if ((getline < fname) < 1) {
      printf("loadxpm2(): EOF -- data: %s\n", data)
      printf("loadxpm2(): %d out of %d pixels read\n", (length(data) / charsppx), (w*h))
      close(fname)
      return(0)
    }
    data = data $0
  }

  # done reading
  close(fname)

  # convert data to graphic
  for (i=0; i<(h*w); i++) {
    pix = substr(data, (i*charsppx)+1, charsppx)
    if (!(pix in color)) {
      printf("Could not find color %s in color[]\n", pix)
      printf("data = \"%s\"\n", data)
      return(0)
    } else dst[i] = color[pix]
  }
  dst["width"] = w
  dst["height"] = h

  delete color
  return(1)
}


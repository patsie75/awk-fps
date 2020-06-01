#!/usr/bin/gawk -f

function loadxpm2(dst, fname,   w,h, nrcolors,charsppx, col,color,data, i,pix, line) {
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
    color[chr] = sprintf("%s;%s;%s", awk::strtonum("0x"substr(col,2,2)), awk::strtonum("0x"substr(col,4,2)), awk::strtonum("0x"substr(col,6,2)) )
  }

  # read pixel data
  i = 0
  while (i < h) {
    if ((getline < fname) < 1) {
      printf("loadxpm2(): EOF -- data: %s\n", data)
      printf("loadxpm2(): %d out of %d lines read\n", i, h)
      close(fname)
      return(0)
    }
    data[i++] = $0
  }

  # done reading
  close(fname)

  # convert data to graphic
  for (j=0; j<h; j++) {
    line = data[j]

    for (i=0; i<w; i++) {
      pix = substr(line, (i*charsppx)+1, charsppx)
      if (!(pix in color)) {
        printf("Could not find color %s in color[]\n", pix)
        printf("data[%d] = \"%s\"\n", j, line)
        return(0)
      } else dst[j*w+i] = color[pix]
    }
  }

  dst["width"] = w
  dst["height"] = h

  delete color
  return(1)
}


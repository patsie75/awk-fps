#!/usr/bin/gawk -f

BEGIN {
  "tput cols"  | getline terminal["width"]
  "tput lines" | getline terminal["height"]
  close("tput cols")
  close("tput lines")
}

## initialize and clear canvas
function init(scr, width, height) {

  ## autodetect width/height if not supplied
  if (!width) {
    if ("COLUMNS" in ENVIRON) width = ENVIRON["COLUMNS"]
    else { "tput cols" | getline width; close("tput cols") }
  }

  if (!height) {
    if (ENVIRON["LINES"]) height = (ENVIRON["LINES"] - 1) * 2
    else { "tput lines" | getline height; height = (height-1) * 2; close("tput lines") }
  }

  # fallback width/height if autodetect fails
  if (!width) width = 80
  if (!height) height = 48

  # two pixels per lines
#  height = (height-1) * 2

  scr["width"] = width
  scr["height"] = height

  clear(scr)
}

# turn cursor on or off
function cursor(state) {
  if (state == "off") printf("\033[?25l")
  else if (state == "on") printf("\033[?25h")
}

## clean the canvas (black)
function clear(scr) {
  #fill(scr, color["black"])
  fill(scr, colors["0"]["1"])
}

## fill the canvas with a color
function fill(scr, col,   i, size) {
  size = scr["height"] * scr["width"]
  for (i=0; i<size; i++)
    scr[i] = col
}

## Draw "canvas" onto the terminal
function draw(scr, xpos,ypos,    x,y,ywidth,y2width,buf,pix) {
  ## set pixel
  #pix = sprintf("%c", 0x2592) ## utf8 Medium Shade
  pix = sprintf("%c", 0x2580) ## utf8 Upper Half Block

  # clear buffer
  buf = ""

  w = scr["width"]
  h = scr["height"]

  prevfg = -1
  prevbg = -1

  # position of zero means center
  if (xpos == 0) xpos = int((terminal["width"] - w) / 2)+1
  if (ypos == 0) ypos = int((terminal["height"] - h/2) / 2)+1

  # negative position means right aligned
  if (xpos < 0) xpos = (terminal["width"] - w + (xpos+2))
  if (ypos < 0) ypos = (terminal["height"] - h/2 + (ypos+1))

  # for each line
  for (y=0; y<h; y+=2) {
    ywidth = y*w
    y2width = (y+1)*w
    buf = buf sprintf("\033[%s;%sH", (y/2)+ypos, xpos)

    # for each pixel in line
    for (x=0; x<w; x++) {
      #pix = sprintf("%c", (x < (w/2)) ? " " : 0x2580)
      fg = scr[ywidth+x]
      bg = scr[y2width+x]
      if ((fg != prevfg) || (bg != prevbg))
        buf = buf sprintf("\033[38;2;%s;48;2;%sm%c", fg, bg, pix)
      else
        buf = buf pix
      prevfg = fg
      prevbg = bg
    }
  }

  # draw buffer to screen and reset colors
  printf("%s\033[0m\n", buf)
#  fflush("/dev/stdout")
}

function myTime() {
  # /proc/uptime has more precision than systime()
  if ((getline < "/proc/uptime") > 0) {
    close("/proc/uptime")
    return($1)
  } else return(systime())
}

# return number of frames in time interval
function fps(f) {
  f["frame"]++
  f["now"] = myTime()

  if (f["interval"] == 0)
    f["interval"] = 1

  if ( (f["now"] - f["prev"]) >= f["interval"] ) {
    f["fps"] = f["frame"] / (f["now"] - f["prev"])
    f["prev"] = f["now"]
    f["frame"] = 0
  }

  return( f["fps"] )
}


# copy graphic buffer to another graphic buffer (with transparency, and edge clipping)
# usage: dst, src, [dstx, dsty, [srcx, srcy, [srcw, srch, [transparent] ] ] ]
function copy(dst, src, dstx, dsty, srcx, srcy, srcw, srch, transp,   dx,dy, dw,dh, sx,sy, sw,sh, x,y, w,h, t, pix, sw_mul_y, ydy_mul_dw, xdx) {
  # src/dst default values
  dw = dst["width"]
  dh = dst["height"]
  sw = src["width"]
  sh = src["height"]

  dx = int(src["x"])
  dy = int(src["y"])
  sx = 0
  sy = 0
  w = src["width"]
  h = src["height"]

  # arguments override
  if (length(dstx)) dx = dstx
  if (length(dsty)) dy = dsty
  if (length(srcx)) sx = srcx
  if (length(srcy)) sy = srcy
  if (length(srcw)) w = ((srcw > 0) && (srcw < src["width"])) ? srcw : w
  if (length(srch)) h = ((srch > 0) && (srch < src["height"])) ? srch : h

  # transparancy
  if (sprintf("%s", transp)) t = transp
  else if ("transparent" in src) t = src["transparent"]
  else if ("transparent" in glib) t = glib["transparent"]

  for (y=sy; y<(sy+h); y++) {
    # clip image off top/bottom
    if ((y - sy + dy) >= dh) break
    if ((y - sy + dh) < 0) continue
    sw_mul_y = sw * y
    ydy_mul_dw = (y - sy + dy) * dw

    for (x=sx; x<(sx+w); x++) {
      xdx = x - sx + dx

      # clip image on left/right
      if (xdx >= dw) break
      if (xdx < 0) continue

      # draw non-transparent pixel or else background
      pix = src[sw_mul_y + x]
      dst[ydy_mul_dw + xdx] = ((pix == t) || (pix == "None")) ? dst[ydy_mul_dw + xdx] : pix
      #if ((pix == t) || (pix == "None"))
      #  dst[ydy_mul_dw + xdx] = dst[ydy_mul_dw + xdx]
      #else
      #  dst[ydy_mul_dw + xdx] = pix
    }
  }
}


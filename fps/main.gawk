#!/usr/bin/gawk -f

@include "lib/2d.gawk"
@include "lib/xpm2.gawk"
@include "lib/math.gawk"
@include "fps/input.gawk"
@include "fps/sprite.gawk"
@include "fps/raycast.gawk"

function sortDist(i1, v1, i2, v2) { return (v2["dist"] - v1["dist"]) }

function darken(col, val,    arr) {
  if (cfg["shade"]) {
    val = (val > 1) ? val : 1
    if (split(col, arr, ";") == 3)
      return sprintf("%d;%d;%d", math::min(255,arr[1]/val), math::min(255,arr[2]/val), math::min(255,arr[3]/val))
  }
  return col
}


function miniMap(scr, map, posX,posY, offsetX, offsetY,    x,y, w, c) {
  if (offsetX < 0) offsetX = scr["width"] + offsetX - 1
  if (offsetY < 0) offsetY = scr["height"] + offsetY - 1

  # draw minimap
  for (y=-5; y<=5; y++) {
    for (x=-5; x<=5; x++) {
      # check map borders
      if ( (int(posX+x) >= 0) && (int(posX+x) < map["width"]) && (int(posY+x) >= 0) && (int(posY+y) < map["height"]) ) {
        # get wall type and colour
        w = map[int(posY+y) * map["width"] + int(posX+x)]
        if (w in wall) c = wall[w]
        else c = (w == " ") ? COL_BLACK : COL_GRAY

        glib::pixel(scr, offsetX+x, offsetY+y, c)
      } else glib::pixel(scr, offsetX+x, offsetY+y, COL_BLACK)
    }
  }

  # draw player pixel
  glib::pixel(scr, offsetX,offsetY, COL_LMAGENTA)
}


function loadMap(map, object, fname,     linenr, x,y, c, obj, str) {
  map["width"] = 0
  map["height"] = 0
  y = 0
  obj = 0

  while ((getline < fname) > 0) {
    linenr++
#printf("loadMap(): linenr: %d, line: \"%s\" (len: %d) NR == %d\n", linenr, $0, length($0), NF)

    # skip empty and comment lines
    if ((NF == 0) || ($1 ~ /^#/)) continue

    switch ($1) {
      case "map":
        match($0, /^ *map "([^"]+)" *$/, str)

#printf("map[%s] = { %s }\n", y, str[1])
        # check line length (map width)
        if (!map["width"]) map["width"] = length(str[1])
        else if (map["width"] != length(str[1])) {
          printf("loadMap(): Error on line #%d, file \"%s\": invalid line length (%d != %d)\n", linenr, fname, length(str[1]), map["width"])
          exit 1
        }

        for (x=0; x<map["width"]; x++) {
          c = substr(str[1], x+1, 1)
          switch(c) {
            case "s": c = " "; posX = newPosX = x + 0.5; posY = newPosY = y + 0.5; break
          }
          map[y*map["width"]+x] = c
        }
        y++
        break

      case "obj":
        object[obj]["x"] = $2 + 0.5
        object[obj]["y"] = $3 + 0.5
        object[obj]["sprite"] = $4
#printf("object[%d] = { %s, %s, %s }\n", obj, object[obj]["x"], object[obj]["y"], object[obj]["sprite"])
        obj++
        break

      default:
        printf("loadMap(): Error on line #%d, file \"%s\": unknown type \"%s\". Only \"map\" and \"obj\" allowed\n", linenr, file, $1)
        exit 1
    }

  }

  #object["objects"] = obj
  map["height"] = y
  close(fname)
}


function loadCfg(cfg, fname,    linenr, keyval) {
  while ((getline <fname) > 0) {
    linenr++
    if ((NF > 0) && ($1 !~ /^#/)) {
      if ( match($0, /[[:space:]]*([^=[:space:]]+)[[:space:]]*=[[:space:]]*(.+)/, keyval) ) {
        gsub(/^"|"$/, "", keyval[2])
        cfg[keyval[1]] = keyval[2]
        #printf("loadCfg(): key = \"%s\" val = \"%s\"\n", keyval[1], keyval[2])
      } else {
        printf("loadCfg(): Error on line #%d of \"%s\" Could not match \"key = value\"\n", linenr, fname)
        exit 1
      }
    }
  }
}


BEGIN {
  COL_BLACK    = "0;0;0"
  COL_LRED     = "255;64;64"
  COL_RED      = "255;0;0"
  COL_DRED     = "128;0;0"
  COL_LGREEN   = "64;255;64"
  COL_GREEN    = "0;255;0"
  COL_DGREEN   = "0;128;0"
  COL_FLOOR    = "100;100;100"
  COL_LYELLOW  = "255;255;128"
  COL_YELLOW   = "255;255;0"
  COL_DYELLOW  = "128;128;0"
  COL_LBLUE    = "64;64;255"
  COL_BLUE     = "0;0;255"
  COL_DBLUE    = "0;0;128"
  COL_LCYAN    = "255;128;255"
  COL_CYAN     = "255;0;255"
  COL_DCYAN    = "128;0;128"
  COL_LMAGENTA = "128;255;255"
  COL_MAGENTA  = "0;255;255"
  COL_DMAGENTA = "0;128;128"
  COL_WHITE    = "255;255;255"
  COL_GRAY     = "128;128;128"
  COL_DGRAY    = "64;64;64"

#  wall[" "] = COL_BLACK
#  wall["1"] = COL_RED
#  wall["2"] = COL_GREEN
#  wall["3"] = COL_YELLOW
#  wall["4"] = COL_BLUE
#  wall["5"] = COL_CYAN
#  wall["6"] = COL_MAGENTA
#  wall["7"] = COL_WHITE

  wall["a"] = COL_GRAY
  wall["b"] = COL_GRAY
  wall["c"] = COL_GRAY
  wall["d"] = COL_GRAY
  wall["f"] = COL_GRAY
  wall["w"] = COL_GRAY
  wall["x"] = COL_GRAY
  wall["z"] = COL_GRAY
  wall["A"] = COL_GRAY
  wall["B"] = COL_GRAY

  wall["e"] = COL_BLUE
  wall["g"] = COL_BLUE
  wall["h"] = COL_BLUE
  wall["i"] = COL_BLUE

  wall["j"] = "165;42;42"
  wall["k"] = "165;42;42"
  wall["l"] = "165;42;42"
  wall["t"] = "165;42;42"
  wall["w"] = "165;42;42"

  wall["q"] = COL_RED
  wall["r"] = COL_RED

  cfg["KEY_QUIT"]  = "\033"
  cfg["KEY_MOVF"]  = "w"
  cfg["KEY_MOVFF"] = "W"
  cfg["KEY_MOVB"]  = "s"
  cfg["KEY_MOVBF"] = "S"
  cfg["KEY_MOVL"]  = "a"
  cfg["KEY_MOVLF"] = "A"
  cfg["KEY_MOVR"]  = "d"
  cfg["KEY_MOVRF"] = "D"
  cfg["KEY_ROTL"]  = "j"
  cfg["KEY_ROTLF"] = "J"
  cfg["KEY_ROTR"]  = "l"
  cfg["KEY_ROTRF"] = "L"
  cfg["KEY_MMAP"]  = "\t"
  cfg["KEY_SHADE"] = "~"
  cfg["KEY_INCFOV"] = "+"
  cfg["KEY_DECFOV"] = "-"

  # shading on/off
  cfg["shade"] = 1

  # rotation and movement speed
  cfg["rotSpeed"] = 3.14159265 / 8
  cfg["moveSpeed"] = 0.4

  ## load config
  loadCfg(cfg, "fps.cfg")

  glib::init(scr, cfg["width"],cfg["height"])

  texWidth = 64
  texHeight = 64

  ## minimap position
  mmPosX = mmPosY = 7

  # player position
  posX = newPosX = 22
  posY = newPosX = 12

  # player direction
  dirX = 1
  dirY = 0

  # camera plane
  planeX = 0
  planeY = -0.75

  nTextures = split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", mTextures, "")

  ## load texture map
  xpm2::load(tex, "gfx/textures.xpm2")

  ## split up texture map into single textures
  for (i=0; i<114; i+=2) {
    c = mTextures[int(i/2)+1]
    wallTex[c][0] = 0
    glib::init(wallTex[c], texWidth,texHeight)
    glib::copy(wallTex[c], tex, 0,0, (i%6)*texWidth,int(i/6)*texHeight)
  }
  delete(tex)

  ## load spritemap
  xpm2::load(spr, "gfx/sprites.xpm2")

  for (i=0; i<50; i++) {
    sprite[i][0] = 0
    glib::init(sprite[i], texWidth, texHeight)
    glib::copy(sprite[i], spr, 0,0, (i%5)*(texWidth+1),int(i/5)*(texHeight+1))
    sprite[i]["transparent"] = "152;0;136"; # #980088 / cyan
  }
  delete(spr)

  ## load map
  #loadMap(worldMap, object, "maps/wolf.w3d")
  #loadMap(worldMap, object, "maps/objects.w3d")
  loadMap(worldMap, object, "maps/jail.w3d")

  ##
  ## main loop
  ##
  glib::cursor("off")

  while ("awk" != "difficult") {
    # ceiling and floor
    for (y=0; y<scr["height"]/2; y++) {
      c = darken(COL_DGRAY, y/25+1)
      glib::hline(scr, 0,y, scr["width"], c)
    }
    for (y=scr["height"]/2; y<scr["height"]; y++) {
      c = darken(COL_FLOOR, (scr["height"]-y)/25+1)
      glib::hline(scr, 0,y, scr["width"], c)
    }

    ##
    ## Raycasting
    ##

    raycast(scr)

    ##
    ## Sprites
    ##

    # calculate distance from player
    for (i in object)
      object[i]["dist"] = ( (posX - object[i]["x"]) * (posX - object[i]["x"]) + (posY - object[i]["y"]) * (posY - object[i]["y"]) )

    # sort objects by distance from player (far -> near)
    asort(object, object, "sortDist")

    # loop through objects (far -> near)
    for (i in object)
      drawSprite(scr, i)

    # layer minimap on top of screenbuffer
    miniMap(scr, worldMap, posX, posY, mmPosX, mmPosY)

    # draw screenbuffer to terminal
    glib::draw(scr, -1,1)

    ## handle user input
    key = input()
    event(key)


    # TODO colision detection
    #if (worldMap[int(posY * worldMap["width"] + newPosX)] == " ") posX = newPosX
    #if (worldMap[int(newPosY * worldMap["width"] + PosX)] == " ") posY = newPosY
    if ( (int(newPosX) > 0) && (int(newPosX) < worldMap["width"]-1) )
      posX = newPosX
    if ( (int(newPosY) > 0) && (int(newPosY) < worldMap["height"]-1) )
      posY = newPosY
  }
}

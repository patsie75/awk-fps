#!/usr/bin/gawk -f

@include "lib/2d.gawk"
@include "lib/xpm2.gawk"

function sortDist(i1, v1, i2, v2) {
  return (v2["dist"] - v1["dist"])
}

function darken(col, val,    arr) {
  if (cfg["shade"]) {
    val = (val > 1) ? val : 1
    if (split(col, arr, ";") == 3)
      return sprintf("%d;%d;%d", min(255,arr[1]/val), min(255,arr[2]/val), min(255,arr[3]/val))
  }
  return col
}

function floor(n,    x) { x=int(n); return(x==n || n>0) ? x : x-1 }

function miniMap(scr, map, posX,posY, offsetX, offsetY,    x,y) {
  if (offsetX < 0) offsetX = scr["width"] + offsetX - 1
  if (offsetY < 0) offsetY = scr["height"] + offsetY - 1

  for (y=-5; y<=5; y++) {
    for (x=-5; x<=5; x++) {
      if ( (int(posX+x) > map["width"]) || (int(posX+x) < 0) || (int(posY+y) > map["height"]) || (int(posY+y) < 0) )
        pixel(scr, offsetX+x, offsetY+y, COL_BLACK)
      else {
        c = map[int(posY+y)*map["width"]+int(posX+x)]
        pixel(scr, offsetX+x, offsetY+y, (c == " ") ? COL_BLACK : COL_GRAY)
      }
    }
  }
  pixel(scr, offsetX,offsetY, COL_LMAGENTA)
}

function input() {
  system("stty -echo")
  cmd = "saved=$(stty -g); stty raw; var=$(dd bs=1 count=1 2>/dev/null); stty \"$saved\"; echo \"$var\""
  cmd | getline key
  close(cmd)
  system("stty echo")

  return(key)
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

  wall[" "] = COL_BLACK
  wall["1"] = COL_RED
  wall["2"] = COL_GREEN
  wall["3"] = COL_YELLOW
  wall["4"] = COL_BLUE
  wall["5"] = COL_CYAN
  wall["6"] = COL_MAGENTA
  wall["7"] = COL_WHITE

  KEY_QUIT  = "\033"
  KEY_MOVF  = "w"
  KEY_MOVB  = "s"
  KEY_MOVL  = "a"
  KEY_MOVR  = "d"
  KEY_ROTL  = "j"
  KEY_ROTLF = "J"
  KEY_ROTR  = "l"
  KEY_ROTRF = "L"
  KEY_MMAP  = "\t"
  KEY_SHADE = "~"

  cfg["shade"] = 1

  init(scr)
  #init(scr, 160,100)

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

  # rotation and movement speed
  rotSpeed = 3.14159265 / 8
  moveSpeed = 0.4


  nTextures = split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", mTextures, "")

  ## load texture map
  loadxpm2(tex, "gfx/textures.xpm2")

  ## split up texture map into single textures
  for (i=0; i<114; i+=2) {
    c = mTextures[int(i/2)+1]
    wallTex[c][0] = 0
    init(wallTex[c], texWidth,texHeight)
    copy(wallTex[c], tex, 0,0, (i%6)*texWidth,int(i/6)*texHeight)
  }

  ## load spritemap
  loadxpm2(spr, "gfx/sprites.xpm2")

  for (i=0; i<50; i++) {
    sprite[i][0] = 0
    init(sprite[i], texWidth, texHeight)
    copy(sprite[i], spr, 0,0, (i%5)*(texWidth+1),int(i/5)*(texHeight+1))
    sprite[i]["transparent"] = "152;0;136"; # #980088 / cyan
  }

  ## load map
  #loadMap(worldMap, object, "maps/wolf.w3d")
  loadMap(worldMap, object, "maps/objects.w3d")

  ##
  ## main loop
  ##

  cursor("off")

  frameNr = 0
#  while (frameNr++ < 1) {
  while ("awk" != "difficult") {

    # ceiling and floor
    for (y=0; y<scr["height"]/2; y++) {
      c = darken(COL_DGRAY, y/25+1)
      hline(scr, 0,y, scr["width"], c)
    }
    for (y=scr["height"]/2; y<scr["height"]; y++) {
      c = darken(COL_FLOOR, (scr["height"]-y)/25+1)
      hline(scr, 0,y, scr["width"], c)
    }

    # start raycast
    for (x=0; x<scr["width"]; x++) {
      cameraX = 2 * x / scr["width"] - 1

      rayDirX = dirX + planeX * cameraX
      rayDirY = dirY + planeY * cameraX

      # which box of the map we're in
      mapX = int(posX)
      mapY = int(posY)

#printf("x: %d, cam: %.2f, rayDir {%.2f,%.2f}, map {%d,%d}\n", x, cameraX, rayDirX, rayDirY, mapX, mapY)

      # length of ray from one x or y-side to next x or y-side
      deltaDistX = (rayDirY == 0) ? 0 : ((rayDirX == 0) ? 1 : abs(1 / rayDirX))
      deltaDistY = (rayDirX == 0) ? 0 : ((rayDirY == 0) ? 1 : abs(1 / rayDirY))

      hit = 0

      # calculate step and initial sideDist
      if (rayDirX < 0) {
        stepX = -1
        sideDistX = (posX - mapX) * deltaDistX
      } else {
        stepX = 1
        sideDistX = (mapX + 1.0 - posX) * deltaDistX
      }

      if (rayDirY < 0) {
        stepY = -1
        sideDistY = (posY - mapY) * deltaDistY
      } else {
        stepY = 1
        sideDistY = (mapY + 1.0 - posY) * deltaDistY
      }

      # perform DDA
#printf("hit0: %d, map: {%.2f,%.2f}, worldMap["width"]: %d, mapHeight: %d\n", hit, mapX,mapY, worldMap["width"], worldMap["height"])
      while (!hit && (mapX>=0 && mapX<worldMap["width"]) && (mapY>=0 && mapY<worldMap["height"])) {
#printf("hit-loop() map {%d, %d}, sideDist {%.2f, %.2f}, deltaDist {%.2f, %.2f}, step: {%.2f, %.2f}\n", mapX,mapY, sideDistX,sideDistY, deltaDistX,deltaDistY, stepX,stepY)
        # jump to next map square, OR in x-direction, OR in y-direction
        if (sideDistX < sideDistY) {
          sideDistX += deltaDistX
          mapX += stepX
          side = 0
        } else {
          sideDistY += deltaDistY
          mapY += stepY
          side = 1
        }

        # Check if ray has hit a wall
        if (worldMap[mapY*worldMap["width"]+mapX] != " ") {
          hit = 1
#printf("worldMap[%d*%d+%d] == \"%s\"\n", mapY, mapWidth, mapX, worldMap[mapY*worldMap["width"]+mapX])
        }
      } 

#printf("hit: %d, side: %d, map: {%d,%d}, pos: {%.2f,%.2f}, step: {%.2f,%.2f}, raydir: {%.2f,%.2f}\n", hit, side, mapX,mapY, posX,posY, stepX,stepY, rayDirX,rayDirY)
      # Calculate distance projected on camera direction (Euclidean distance will give fisheye effect!)
      if (side == 0) perpWallDist = (mapX - posX + (1 - stepX) / 2) / rayDirX
      else           perpWallDist = (mapY - posY + (1 - stepY) / 2) / rayDirY
      perpWallDist = perpWallDist ? perpWallDist : 1

#printf("perpWallDist: %.2f\n", perpWallDist)
      # Calculate height of line to draw on screen
      lineHeight = int(scr["height"] / perpWallDist)
      lineHeight = lineHeight ? lineHeight : 1

      # calculate lowest and highest pixel to fill in current stripe
      drawStart = -lineHeight / 2 + scr["height"] / 2
      if (drawStart < 0) drawStart = 0

      drawEnd = lineHeight / 2 + scr["height"] / 2
      if (drawEnd >= scr["height"]) drawEnd = scr["height"] - 1


      ##
      ## start texture mapping
      ##

      # texture to draw
      texNum = worldMap[mapY*worldMap["width"]+mapX]

      # calculate value of wallX
      if (side == 0) wallX = posY + perpWallDist * rayDirY
      else           wallX = posX + perpWallDist * rayDirX
      wallX -= floor(wallX)

      # x coordinate on the texture
      texX = int(wallX * texWidth)
      if (side == 0 && rayDirX > 0) texX = texWidth - texX - 1;
      if (side == 1 && rayDirY < 0) texX = texWidth - texX - 1;

      # How much to increase the texture coordinate per screen pixel
      step = 1.0 * texHeight / lineHeight
      # Starting texture coordinate
      texPos = (drawStart - scr["height"] / 2 + lineHeight / 2) * step

      for (y=drawStart; y<=drawEnd; y++) {
        # Cast the texture coordinate to integer, and mask with (texHeight - 1) in case of overflow
        texY = int(and(texPos, texHeight - 1))
        texPos += step
        color = wallTex[texNum][texHeight * texY + texX]


        # make color darker for y-sides: R, G and B byte each divided through two with a "shift" and an "and"
        tmp = (perpWallDist > 1) ? perpWallDist : 1

        if (side == 1) color = darken(color, (tmp+2)/2)
        else color = darken(color, tmp/2)

        ## draw final pixel to buffer
        pixel(scr, x,y, color)
      }

      ZBuffer[x] = perpWallDist;
    }

    ##
    ## Sprites
    ##

    # calculate distance from player
    for (i in object)
      object[i]["dist"] = ( (posX - object[i]["x"]) * (posX - object[i]["x"]) + (posY - object[i]["y"]) * (posY - object[i]["y"]) )

    # sort objects by distance from player (far -> near)
    asort(object, object, "sortDist")

    # loop through objects (far -> near)
    for (i in object) {
#printf("object[%s][sprite] = [%s]\n", i, object[i]["sprite"])
      spriteX = object[i]["x"] - posX
      spriteY = object[i]["y"] - posY

      invDet = 1.0 / (planeX * dirY - dirX * planeY); # required for correct matrix multiplication

      transformX = invDet * (dirY * spriteX - dirX * spriteY);
      transformY = invDet * (-planeY * spriteX + planeX * spriteY); # this is actually the depth inside the screen, that what Z is in 3D

      spriteScreenX = int((scr["width"] / 2) * (1 + transformX / transformY));

      # calculate height of the sprite on screen
      spriteHeight = abs(int(scr["height"] / transformY)); # using 'transformY' instead of the real distance prevents fisheye
      # calculate lowest and highest pixel to fill in current stripe
      drawStartY = (-spriteHeight / 2) + (scr["height"] / 2)
      if (drawStartY < 0) drawStartY = 0
      drawEndY = (spriteHeight / 2) + (scr["height"] / 2) - 1
      if (drawEndY > scr["height"]) drawEndY = scr["height"]

      # calculate width of the sprite
      spriteWidth = abs( int(scr["height"] / transformY))
      drawStartX = int( (-spriteWidth / 2) + spriteScreenX)
      if (drawStartX < 0) drawStartX = 0
      drawEndX = (spriteWidth / 2) + spriteScreenX
      if (drawEndX > scr["width"]) drawEndX = scr["width"] 


      # loop through every vertical stripe of the sprite on screen
      for (stripe = drawStartX; stripe < drawEndX; stripe++) {
        #texX = int(256 * (stripe - (-spriteWidth / 2 + spriteScreenX)) * texWidth / spriteWidth) / 256;
        texX = int((stripe - (-spriteWidth / 2 + spriteScreenX)) * texWidth / spriteWidth)
        # the conditions in the if are:
        # 1) it's in front of camera plane so you don't see things behind you
        # 2) it's on the screen (left)
        # 3) it's on the screen (right)
        # 4) ZBuffer, with perpendicular distance
#if (object[i]["sprite"] == 3) printf("transformY == %s, stripe == %s, ZBuffer == %s, width == %s\n", transformY, stripe, ZBuffer[stripe], scr["width"])
        if (transformY > 0 && stripe > 0 && stripe < scr["width"] && transformY < ZBuffer[stripe]) {
          for (y = drawStartY; y < drawEndY; y++) # for every pixel of the current stripe
          {
            d = y * 256 - scr["height"] * 128 + spriteHeight * 128; # 256 and 128 factors to avoid floats
            texY = ((d * texHeight) / spriteHeight) / 256 + 1;

            c = sprite[object[i]["sprite"]][int(texY) * texWidth + int(texX)]; # get current color from the texture
            if (c != sprite[object[i]["sprite"]]["transparent"]) {
              tmp = (object[i]["dist"] > 1) ? object[i]["dist"] : 1
              c = darken(c, tmp/5)

              pixel(scr, stripe, y, c)
            }
          }
        }
      }

    }

    # layer minimap on top of screenbuffer
    miniMap(scr, worldMap, posX, posY, mmPosX, mmPosY)

    # draw screenbuffer to terminal
    draw(scr, -1,1)

    ## handle user input
    key = input()

    # quit key exits game
    if (key == KEY_QUIT) {
      cursor("on")
      exit 0
    }

    # rotate left
    if (key == KEY_ROTL) {
      oldDirX = dirX;
      dirX = dirX * cos(rotSpeed) - dirY * sin(rotSpeed);
      dirY = oldDirX * sin(rotSpeed) + dirY * cos(rotSpeed);

      oldPlaneX = planeX;
      planeX = planeX * cos(rotSpeed) - planeY * sin(rotSpeed);
      planeY = oldPlaneX * sin(rotSpeed) + planeY * cos(rotSpeed);
    }

    # rotate left fast
    if (key == KEY_ROTLF) {
      oldDirX = dirX
      dirX = dirX * cos(rotSpeed*2) - dirY * sin(rotSpeed*2)
      dirY = oldDirX * sin(rotSpeed*2) + dirY * cos(rotSpeed*2)

      oldPlaneX = planeX
      planeX = planeX * cos(rotSpeed*2) - planeY * sin(rotSpeed*2)
      planeY = oldPlaneX * sin(rotSpeed*2) + planeY * cos(rotSpeed*2)
    }

    # rotate right
    if (key == KEY_ROTR) {
      oldDirX = dirX
      dirX = dirX * cos(-rotSpeed) - dirY * sin(-rotSpeed)
      dirY = oldDirX * sin(-rotSpeed) + dirY * cos(-rotSpeed)
  
      oldPlaneX = planeX
      planeX = planeX * cos(-rotSpeed) - planeY * sin(-rotSpeed)
      planeY = oldPlaneX * sin(-rotSpeed) + planeY * cos(-rotSpeed)
    }

    # rotate right fast
    if (key == KEY_ROTRF) {
      oldDirX = dirX
      dirX = dirX * cos(-rotSpeed*2) - dirY * sin(-rotSpeed*2)
      dirY = oldDirX * sin(-rotSpeed*2) + dirY * cos(-rotSpeed*2)
  
      oldPlaneX = planeX
      planeX = planeX * cos(-rotSpeed*2) - planeY * sin(-rotSpeed*2)
      planeY = oldPlaneX * sin(-rotSpeed*2) + planeY * cos(-rotSpeed*2)
    }

    # move forward
    if (key == KEY_MOVF) {
      newPosX = posX + dirX * moveSpeed
      newPosY = posY + dirY * moveSpeed
    }

    # move back
    if (key == KEY_MOVB) {
      newPosX = posX - dirX * moveSpeed
      newPosY = posY - dirY * moveSpeed
    }

    # move left (strafe)
    if (key == KEY_MOVL) {
      newPosX = posX - dirY * moveSpeed
      newPosY = posY + dirX * moveSpeed
    }

    # move right (strafe)
    if (key == KEY_MOVR) {
      newPosX = posX + dirY * moveSpeed
      newPosY = posY - dirX * moveSpeed
    }

    # minimap location
    if (key == KEY_MMAP) {
      switch (mmPosX "," mmPosY) {
        case   "7,7": mmPosX = -7; mmPosY =  7; break
        case  "-7,7": mmPosX = -7; mmPosY = -7; break
        case "-7,-7": mmPosX =  7; mmPosY = -7; break
        default:      mmPosX =  7; mmPosY =  7
      }
    }
    if (key == KEY_SHADE) {
      cfg["shade"] = cfg["shade"] ? 0 : 1
    }

    # TODO colision detection
    #if (worldMap[int(posY * worldMap["width"] + newPosX)] == " ") posX = newPosX
    #if (worldMap[int(newPosY * worldMap["width"] + PosX)] == " ") posY = newPosY
    if ( (int(newPosX) > 0) && (int(newPosX) < worldMap["width"]-1) )
      posX = newPosX
    if ( (int(newPosY) > 0) && (int(newPosY) < worldMap["height"]-1) )
      posY = newPosY
  }
}

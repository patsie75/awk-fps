#!/usr/bin/gawk -f

@include "lib/2d.gawk"
@include "lib/xpm2.gawk"

function darken(col,    arr) {
  if (split(col, arr, ";") == 3)
    return sprintf("%d;%d;%d", arr[1]/2, arr[2]/2, arr[3]/2)
  else return col
}

function floor(n,    x) { x=int(n); return(x==n || n>0) ? x : x-1 }

function miniMap(scr, map, posX,posY,    x,y) {
  offsetX = offsetY = 7

  for (y=-5; y<=5; y++) {
    for (x=-5; x<=5; x++) {
      if ( (int(posX+x) > map["width"]) || (int(posX+x) < 0) || (int(posY+y) > map["height"]) || (int(posY+y) < 0) )
        pixel(scr, offsetX+x, offsetY+y, COL_BLACK)
      else {
        c = map[int(posY+y)*map["width"]+int(posX+x)]
        pixel(scr, offsetX+x, offsetY+y, wall[c])
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

function loadMap(map, fname,     line, x, y) {
  map["width"] = 0
  map["height"] = 0
  y = 0

  while ((getline line < fname) > 0) {
    linenr++
#printf("loadMap(): linenr: %d, line: \"%s\" (len: %d)\n", linenr, line, length(line))

    # skip empty lines
    if (length(line) == 0) continue

    # check line length (map width)
    if (!map["width"]) map["width"] = length(line)
    else if (map["width"] != length(line)) {
      printf("Error: line %d, file \"%s\", invalid line length (%d != %d)\n", linenr, fname, length(line), map["width"])
      exit 1
    }

    for (x=0; x<map["width"]; x++) {
      c = substr(line, x+1, 1)
      switch(c) {
        case "s": c = " "; posX = x; posY = y; break
        case "S": c = " "; posX = x; posY = y; break
      }
      map[y*map["width"]+x] = c
    }
    y++

  }
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
  COL_FLOOR    = "16;64;16"
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

  KEY_QUIT = "Q"
  KEY_MOVF = "w"
  KEY_MOVB = "s"
  KEY_MOVL = "a"
  KEY_MOVR = "d"
  KEY_ROTL = "j"
  KEY_ROTR = "l"

  init(scr)

  texWidth = 64
  texHeight = 64

  # player position
  posX = 22
  posY = 12

  # player direction
  dirX = -1
  dirY = 0

  # camera plane
  planeX = 0
  planeY = 0.66

  rotSpeed = 0.1
  moveSpeed = 0.5

  #loadMap(worldMap, "maps/level1.map")
  #loadMap(worldMap, "maps/level2.map")
  loadMap(worldMap, "maps/wolf.map")

  loadxpm2(tex, "gfx/wolftextures.xpm2")
  for (i=0; i<8; i++) {
    wallTex[i][0] = 0
    init(wallTex[i], 64,64)
    copy(wallTex[i], tex, 0,0, i*64,0)
  }

  frameNr = 0
  while ("awk" != "difficult") {
#  while (frameNr++ < 1) {

    #clear(scr)
    fill(scr, COL_DGRAY)
    fillBox(scr, 0,scr["height"] / 2, scr["width"]-1, scr["height"]-1, COL_FLOOR)

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

      # calculate lowest and highest pixel to fill in current stripe
      drawStart = -lineHeight / 2 + scr["height"] / 2
      if (drawStart < 0) drawStart = 0

      drawEnd = lineHeight / 2 + scr["height"] / 2
      if (drawEnd >= scr["height"]) drawEnd = scr["height"] - 1


      # texture to draw
      texNum = worldMap[mapY*worldMap["width"]+mapX] - 1

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

      for (y=drawStart; y<drawEnd; y++) {
        # Cast the texture coordinate to integer, and mask with (texHeight - 1) in case of overflow
        texY = int(and(texPos, texHeight - 1))
        texPos += step
        color = wallTex[texNum][texHeight * texY + texX]
        # make color darker for y-sides: R, G and B byte each divided through two with a "shift" and an "and"
        if (side == 1) color = darken(color)

        pixel(scr, x,y, color)
      }
    }

    miniMap(scr, worldMap, posX, posY)

    # draw screenbuffer to terminal
    draw(scr, 1,1)
    system("sleep 0.1")

    ## handle user input
    key = input()

    if (key == KEY_QUIT) {
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

    # rotate right
    if (key == KEY_ROTR) {
      oldDirX = dirX;
      dirX = dirX * cos(-rotSpeed) - dirY * sin(-rotSpeed);
      dirY = oldDirX * sin(-rotSpeed) + dirY * cos(-rotSpeed);
  
      oldPlaneX = planeX;
      planeX = planeX * cos(-rotSpeed) - planeY * sin(-rotSpeed);
      planeY = oldPlaneX * sin(-rotSpeed) + planeY * cos(-rotSpeed);
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

    # TODO colision detection
    #if (worldMap[int(posY * worldMap["width"] + newPosX)] == " ") posX = newPosX
    #if (worldMap[int(newPosY * worldMap["width"] + PosX)] == " ") posY = newPosY
    posX = newPosX
    posY = newPosY
  }
}

#!/usr/bin/gawk -f

@include "lib/2d.gawk"

function input() {
  system("stty -echo")
  cmd = "saved=$(stty -g); stty raw; var=$(dd bs=1 count=1 2>/dev/null); stty \"$saved\"; echo \"$var\""
  cmd | getline key
  close(cmd)
  system("stty echo")

  return(key)
}


BEGIN {
  KEY_QUIT = "Q"
  KEY_MOVF = "w"
  KEY_MOVB = "s"
  KEY_MOVL = "a"
  KEY_MOVR = "d"
  KEY_ROTL = "j"
  KEY_ROTR = "l"

  init(scr)

  scr["width"] = scr["width"]
  scr["height"] = scr["height"]

  mapWidth = 32
  mapHeight = 32

  mapStr = \
    "43434111111111111111111111111113" \
    "1   3                          1" \
    "4   4                   1 2 3  3" \
    "1   3                          1" \
    "4   4   23232     1     3 4 1  3" \
    "1   3   4         1            1" \
    "4       4         1     2 3 4  3" \
    "1       4         1            1" \
    "4       4         1            3" \
    "131313134         1212121211   1" \
    "1                          1   3" \
    "2           12             3   1" \
    "1           34             1   3" \
    "2                          3   1" \
    "1       3         2121212121   3" \
    "1       1                      2" \
    "1       2                      4" \
    "1       1                      2" \
    "121212121       21212  41314   4" \
    "1       2       1   1  1   1   2" \
    "4       1       1   1  411 4   4" \
    "1       2       21212    1 1   2" \
    "4       1                4 4   4" \
    "1       2                141   2" \
    "4       1                      4" \
    "1       2                      2" \
    "4       12341234123412341234   4" \
    "1                              2" \
    "4                              4" \
    "1                              2" \
    "41414141414141414141414141414141"

  # convert map string to array
  for (y=0; y<mapHeight; y++)
    for (x=0; x<mapWidth; x++)
      worldMap[y*mapWidth+x] = substr(mapStr, y*mapWidth+x+1, 1)

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

  frameNr = 0
  while ("awk" != "difficult") {
#  while (frameNr++ < 100) {

    key = input()

    if (key == KEY_QUIT) { exit 0 }

    if (key == KEY_ROTL) {
      oldDirX = dirX;
      dirX = dirX * cos(rotSpeed) - dirY * sin(rotSpeed);
      dirY = oldDirX * sin(rotSpeed) + dirY * cos(rotSpeed);

      oldPlaneX = planeX;
      planeX = planeX * cos(rotSpeed) - planeY * sin(rotSpeed);
      planeY = oldPlaneX * sin(rotSpeed) + planeY * cos(rotSpeed);
    }

    if (key == KEY_ROTR) {
      oldDirX = dirX;
      dirX = dirX * cos(-rotSpeed) - dirY * sin(-rotSpeed);
      dirY = oldDirX * sin(-rotSpeed) + dirY * cos(-rotSpeed);
  
      oldPlaneX = planeX;
      planeX = planeX * cos(-rotSpeed) - planeY * sin(-rotSpeed);
      planeY = oldPlaneX * sin(-rotSpeed) + planeY * cos(-rotSpeed);
    }

    if (key == KEY_MOVF) {
      posX = posX + dirX * moveSpeed
      posY = posY + dirY * moveSpeed
    }

    if (key == KEY_MOVB) {
      posX = posX - dirX * moveSpeed
      posY = posY - dirY * moveSpeed
    }

    #clear(scr)
    fill(scr, "0;0;0")

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
#printf("hit0: %d, map: {%.2f,%.2f}, mapWidth: %d, mapHeight: %d\n", hit, mapX,mapY, mapWidth, mapHeight)
      while (!hit && (mapX>=0 && mapX<mapWidth) && (mapY>=0 && mapY<mapHeight)) {
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
        if (worldMap[mapY*mapWidth+mapX] != " ") {
          hit = 1
#printf("worldMap[%d*%d+%d] == \"%s\"\n", mapY, mapWidth, mapX, worldMap[mapY*mapWidth+mapX])
        }
      } 

#printf("hit: %d, side: %d, map: {%d,%d}, pos: {%.2f,%.2f}, step: {%.2f,%.2f}, raydir: {%.2f,%.2f}\n", hit, side, mapX,mapY, posX,posY, stepX,stepY, rayDirX,rayDirY)
      # Calculate distance projected on camera direction (Euclidean distance will give fisheye effect!)
      if (side == 0) perpWallDist = (mapX - posX + (1 - stepX) / 2) / rayDirX
      else           perpWallDist = (mapY - posY + (1 - stepY) / 2) / rayDirY

#printf("perpWallDist: %.2f\n", perpWallDist)
      # Calculate height of line to draw on screen
      lineHeight = int(scr["height"] / perpWallDist)

      # calculate lowest and highest pixel to fill in current stripe
      drawStart = -lineHeight / 2 + scr["height"] / 2
      if (drawStart < 0) drawStart = 0

      drawEnd = lineHeight / 2 + scr["height"] / 2
      if (drawEnd >= scr["height"]) drawEnd = scr["height"] - 1

      # color to draw
      switch(worldMap[mapY*mapHeight+mapX]) {
        case "1":
          color = side ? "255;0;0" : "128;0;0"
          break

        case "2":
          color = side ? "0;255;0" : "0;128;0"
          break

        case "3":
          color = side ? "0;0;255" : "0;0;128"
          break

        default:
          color = side ? "255;255;255" : "128;128;128"
      }

#printf("vline(scr, %d, %d, \"%s\")\n", drawStart, (drawEnd-drawStart), color)
      vline(scr, x, drawStart, (drawEnd-drawStart), color)
    }

    draw(scr, 1,1)
    system("sleep 0.1")
  }
}

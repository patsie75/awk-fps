function raycast(src) {
    # start raycast
    for (x=0; x<scr["width"]; x++) {
      cameraX = 2 * x / scr["width"] - 1

      rayDirX = dirX + planeX * cameraX
      rayDirY = dirY + planeY * cameraX
#      rayDirY = dirX + planeX * cameraX
#      rayDirX = dirY + planeY * cameraX

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
      step = texHeight / lineHeight
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

}

function drawSprite(scr, i) {
#printf("object[%s][sprite] = [%s]\n", i, object[i]["sprite"])
      spriteX = object[i]["x"] - posX
      spriteY = object[i]["y"] - posY

      invDet = 1.0 / (planeX * dirY - dirX * planeY); # required for correct matrix multiplication

      transformX = invDet * (dirY * spriteX - dirX * spriteY)
      transformY = invDet * (-planeY * spriteX + planeX * spriteY); # this is actually the depth inside the screen, that what Z is in 3D

      transformY = transformY ? transformY : 0.001

#printf("object[%s] { %s, %s, %s }, transform: { %s, %s }, sprite: { %s, %s } pos: { %s, %s }\n", i, object[i]["x"], object[i]["y"], object[i]["sprite"], transformX, transformY, spriteX, spriteY, posX, posY)
      spriteScreenX = int((scr["width"] / 2) * (1 + transformX / transformY));

      # calculate height of the sprite on screen
      spriteHeight = abs(int(scr["height"] / transformY)); # using 'transformY' instead of the real distance prevents fisheye
      # calculate lowest and highest pixel to fill in current stripe
      drawStartY = (-spriteHeight / 2) + (scr["height"] / 2)
      if (drawStartY < 0) drawStartY = 0
      #drawEndY = (spriteHeight / 2) + (scr["height"] / 2) - 1
      #drawEndY = max(sprite[obj[i]["sprite"]]["height"], (spriteHeight / 2) + (scr["height"] / 2) - 1)
      drawEndY = max(sprite[obj[i]["sprite"]]["height"], (spriteHeight + scr["height"]) / 2 - 1)
      if (drawEndY > scr["height"]) drawEndY = scr["height"]

      # calculate width of the sprite
      spriteWidth = abs( int(scr["height"] / transformY))
      drawStartX = int( (-spriteWidth / 2) + spriteScreenX)
      if (drawStartX < 0) drawStartX = 0
      drawEndX = (spriteWidth / 2) + spriteScreenX
      if (drawEndX > scr["width"]) drawEndX = scr["width"]


      # loop through every vertical stripe of the sprite on screen
      for (stripe = drawStartX; stripe < drawEndX; stripe++) {
        texX = int(256 * (stripe - (-spriteWidth / 2 + spriteScreenX)) * texWidth / spriteWidth) / 256;
        #texX = int((stripe - (-spriteWidth / 2 + spriteScreenX)) * texWidth / spriteWidth)
        # the conditions in the if are:
        # 1) it's in front of camera plane so you don't see things behind you
        # 2) it's on the screen (left)
        # 3) it's on the screen (right)
        # 4) ZBuffer, with perpendicular distance
        if (transformY > 0 && stripe >= 0 && stripe < scr["width"] && transformY < ZBuffer[stripe]) {
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

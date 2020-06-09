
function input() {
  cmd = "dd bs=1 count=1 2>/dev/null"
  cmd | getline key
  close(cmd)

  return(key)
}


function event(key) {
  # exit
  if (key == cfg["KEY_QUIT"]) {
    cursor("on")
    exit 0
  }

  # rotate left
  if (key == cfg["KEY_ROTL"]) {
    oldDirX = dirX;
    dirX = dirX * cos(cfg["rotSpeed"]) - dirY * sin(cfg["rotSpeed"]);
    dirY = oldDirX * sin(cfg["rotSpeed"]) + dirY * cos(cfg["rotSpeed"]);

    oldPlaneX = planeX;
    planeX = planeX * cos(cfg["rotSpeed"]) - planeY * sin(cfg["rotSpeed"]);
    planeY = oldPlaneX * sin(cfg["rotSpeed"]) + planeY * cos(cfg["rotSpeed"]);
  }

  # rotate left fast
  if (key == cfg["KEY_ROTLF"]) {
    oldDirX = dirX
    dirX = dirX * cos(cfg["rotSpeed"]*2) - dirY * sin(cfg["rotSpeed"]*2)
    dirY = oldDirX * sin(cfg["rotSpeed"]*2) + dirY * cos(cfg["rotSpeed"]*2)

    oldPlaneX = planeX
    planeX = planeX * cos(cfg["rotSpeed"]*2) - planeY * sin(cfg["rotSpeed"]*2)
    planeY = oldPlaneX * sin(cfg["rotSpeed"]*2) + planeY * cos(cfg["rotSpeed"]*2)
  }

  # rotate right
  if (key == cfg["KEY_ROTR"]) {
    oldDirX = dirX
    dirX = dirX * cos(cfg["rotSpeed"]*-1) - dirY * sin(cfg["rotSpeed"]*-1)
    dirY = oldDirX * sin(cfg["rotSpeed"]*-1) + dirY * cos(cfg["rotSpeed"]*-1)

    oldPlaneX = planeX
    planeX = planeX * cos(cfg["rotSpeed"]*-1) - planeY * sin(cfg["rotSpeed"]*-1)
    planeY = oldPlaneX * sin(cfg["rotSpeed"]*-1) + planeY * cos(cfg["rotSpeed"]*-1)
  }

  # rotate right fast
  if (key == cfg["KEY_ROTRF"]) {
    oldDirX = dirX
    dirX = dirX * cos(cfg["rotSpeed"]*-2) - dirY * sin(cfg["rotSpeed"]*-2)
    dirY = oldDirX * sin(cfg["rotSpeed"]*-2) + dirY * cos(cfg["rotSpeed"]*-2)

    oldPlaneX = planeX
    planeX = planeX * cos(cfg["rotSpeed"]*-2) - planeY * sin(cfg["rotSpeed"]*-2)
    planeY = oldPlaneX * sin(cfg["rotSpeed"]*-2) + planeY * cos(cfg["rotSpeed"]*-2)
  }

  # move forward
  if (key == cfg["KEY_MOVF"]) {
    newPosX = posX + dirX * cfg["moveSpeed"]
    newPosY = posY + dirY * cfg["moveSpeed"]
  }

  # move back
  if (key == cfg["KEY_MOVB"]) {
    newPosX = posX - dirX * cfg["moveSpeed"]
    newPosY = posY - dirY * cfg["moveSpeed"]
  }

  # move left (strafe)
  if (key == cfg["KEY_MOVL"]) {
    newPosX = posX - dirY * cfg["moveSpeed"]
    newPosY = posY + dirX * cfg["moveSpeed"]
  }

  # move right (strafe)
  if (key == cfg["KEY_MOVR"]) {
    newPosX = posX + dirY * cfg["moveSpeed"]
    newPosY = posY - dirX * cfg["moveSpeed"]
  }

  # minimap location
  if (key == cfg["KEY_MMAP"]) {
    switch (mmPosX "," mmPosY) {
      case   "7,7": mmPosX = -7; mmPosY =  7; break
      case  "-7,7": mmPosX = -7; mmPosY = -7; break
      case "-7,-7": mmPosX =  7; mmPosY = -7; break
      default:      mmPosX =  7; mmPosY =  7
    }
  }

  if (key == cfg["KEY_SHADE"]) {
    cfg["shade"] = cfg["shade"] ? 0 : 1
  }

}

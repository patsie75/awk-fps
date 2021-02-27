@include "lib/2d.gawk"

function input() {
  cmd = "dd bs=1 count=1 2>/dev/null"
  cmd | getline key
  close(cmd)

  return(key)
}


function event(key) {
  # exit
  if (key == cfg["KEY_QUIT"]) {
    glib::cursor("on")
    exit 0
  }

  # rotate left
  if ( (key == cfg["KEY_ROTL"]) || (key == cfg["KEY_ROTLF"]) ) {
    spd = (key == cfg["KEY_ROTLF"]) ? 2 : 1

    oldDirX = dirX;
    dirX = dirX * cos(cfg["rotSpeed"] * spd) - dirY * sin(cfg["rotSpeed"] * spd)
    dirY = oldDirX * sin(cfg["rotSpeed"] * spd) + dirY * cos(cfg["rotSpeed"] * spd)

    oldPlaneX = planeX;
    planeX = planeX * cos(cfg["rotSpeed"] * spd) - planeY * sin(cfg["rotSpeed"] * spd)
    planeY = oldPlaneX * sin(cfg["rotSpeed"] * spd) + planeY * cos(cfg["rotSpeed"] * spd)
  }

  # rotate right
  if ( (key == cfg["KEY_ROTR"]) || (key == cfg["KEY_ROTRF"]) ) {
    spd = (key == cfg["KEY_ROTRF"]) ? -2 : -1

    oldDirX = dirX
    dirX = dirX * cos(cfg["rotSpeed"] * spd) - dirY * sin(cfg["rotSpeed"] * spd)
    dirY = oldDirX * sin(cfg["rotSpeed"] * spd) + dirY * cos(cfg["rotSpeed"] * spd)

    oldPlaneX = planeX
    planeX = planeX * cos(cfg["rotSpeed"] * spd) - planeY * sin(cfg["rotSpeed"] * spd)
    planeY = oldPlaneX * sin(cfg["rotSpeed"] * spd) + planeY * cos(cfg["rotSpeed"] * spd)
  }

  # move forward
  if ( (key == cfg["KEY_MOVF"]) || (key == cfg["KEY_MOVFF"]) ) {
    spd = (key == cfg["KEY_MOVFF"]) ? 2 : 1
    newPosX = posX + dirX * cfg["moveSpeed"] * spd
    newPosY = posY + dirY * cfg["moveSpeed"] * spd
  }

  # move back
  if ( (key == cfg["KEY_MOVB"]) || (key == cfg["KEY_MOVBF"]) ) {
    spd = (key == cfg["KEY_MOVBF"]) ? 2 : 1
    newPosX = posX - dirX * cfg["moveSpeed"] * spd
    newPosY = posY - dirY * cfg["moveSpeed"] * spd
  }

  # move left (strafe)
  if ( (key == cfg["KEY_MOVL"]) || (key == cfg["KEY_MOVLF"]) ) {
    spd = (key == cfg["KEY_MOVLF"]) ? 2 : 1
    newPosX = posX - dirY * cfg["moveSpeed"] * spd
    newPosY = posY + dirX * cfg["moveSpeed"] * spd
  }

  # move right (strafe)
  if ( (key == cfg["KEY_MOVR"]) || (key == cfg["KEY_MOVRF"]) ) {
    spd = (key == cfg["KEY_MOVRF"]) ? 2 : 1
    newPosX = posX + dirY * cfg["moveSpeed"] * spd
    newPosY = posY - dirX * cfg["moveSpeed"] * spd
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

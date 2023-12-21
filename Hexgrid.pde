class Hexgrid { //<>//
  HashMap<PVector, Hexagon> allHexes;
  PVector[] neighbors;
  
  //variables to constrain the cube grid parameters 
  int qMin = -230;   //the q axis corresponds to the x axis on the screen. Higher values are further right
  int qMax = 230;
  int rMin = -230;   //the r axis is 30 degrees counterclockwise to the q/x axis. Higher values are down and to the left
  int rMax = 230;
  int hexSize;
  Hexagon r1Hex;


  Hexgrid(int hexSize_, PGraphics mask) {
    neighbors = new PVector[6]; //pre-compute the 3D transformations to return adjacent hexes in 2D grid
    neighbors[0] = new PVector(0, 1, -1); // N
    neighbors[1] = new PVector(1, 0, -1); // NE
    neighbors[2] = new PVector(1, -1, 0); // SE
    neighbors[3] = new PVector(0, -1, 1); // S
    neighbors[4] = new PVector(-1, 0, 1); // SW
    neighbors[5] = new PVector(-1, 1, 0); // NW

    hexSize = hexSize_;

    mask.loadPixels();
    allHexes = new HashMap<PVector, Hexagon>();
    for (int q = qMin; q <= qMax; q++) {
      for (int r = rMin; r <= rMax; r++) {
        int y = -q - r;
        PVector loc = (hexToPixel(q, r));
        if (loc.x > hexSize/2 && loc.x < mask.width-hexSize/2 && loc.y > hexSize/2 && loc.y < mask.height-hexSize/2) {
          if (mask.get((int)loc.x, (int)loc.y)== -1) {
            PVector hexID = new PVector(q, y, r);
            Hexagon h = new Hexagon(this, q, r);
            //println(hexID);
            allHexes.put(hexID, h);
          }
        }
      }
    }
  }

  void drawOutlines(PGraphics buffer) {
    buffer.beginDraw();
    buffer.clear();
    buffer.noFill();
    buffer.strokeWeight(10);
    buffer.stroke(0, 0, 255);
    //println(allHexes.entrySet());
    for (Map.Entry<PVector, Hexagon> me : allHexes.entrySet()) {
      Hexagon h = me.getValue();
      h.drawHexOutline(buffer);  
      //println("drawing hexagon: " + h + " at " + h.pixelX + ", " + h.pixelY);
    }
    buffer.endDraw();
  }

  void drawHexes(PGraphics buffer) {
    buffer.beginDraw();
    buffer.clear();
    buffer.noFill();
    buffer.noStroke();
    //println(allHexes.entrySet());
    color c;
    for (Map.Entry<PVector, Hexagon> me : allHexes.entrySet()) {
      Hexagon h = me.getValue();
      switch(h.state) {
        case 0:
          c = color(0, 0, 0);
          break;
        case 1:
          c = color(255, 255, 255);
          break;
        case 2:
          c = color(0, 255, 0);
          break;
        default:
          c = color(0, 0, 0);
      }
      h.drawHexFill(buffer, c);
    }
    if (startHex != null) {
      startHex.drawHexFill(buffer, color(122, 114, 122));
    }
    if (targetHex != null) {
      targetHex.drawHexFill(buffer, color(122, 114, 122));
    }
    buffer.endDraw();
  }

  /*
   * Generate map 
   */
  void seedMap(int i, int f) { //low i == more passable hexes
    int val = 25;
    float j;
    for (Map.Entry<PVector, Hexagon> me : allHexes.entrySet()) {
      j = random(val);
      Hexagon h = me.getValue();
      if ((val - i) <= j) {
        h.impassable();
      }
      if ( ((val - i) >= j) && (f <= j)) {
        h.passable();
      }
      if (f >= j) {
        h.fuel();
      }
    }
  }


  Hexagon getHex(PVector hexKey) {   //hashmap lookup to return hexagon from PVector key
    Hexagon h = allHexes.get(hexKey);
    return(h);
  }

  Hexagon pixelToHex(int xPixel, int yPixel) {   //find which hex a specified pixel lies in
    PVector hexID = new PVector();
    hexID.x = (2./3*xPixel)/hexSize;
    hexID.z = (-1./3 * xPixel + sqrt(3)/3 * yPixel)/hexSize;
    hexID.y = (-hexID.x - hexID.z);
    hexID = cubeRound(hexID);
    Hexagon h = allHexes.get(hexID);
    return h;
  }

  Hexagon[] getNeighbors(Hexagon h) {   //return an array of the 6 neighbor cells. If the neighbor is out of bounds, its array location will be null
    Hexagon[] neighborList = new Hexagon[6];
    PVector hexID = h.getKey();
    for (int i = 0; i < 6; i++) {
      PVector neighborID = hexID.copy();
      neighborID = neighborID.add(neighbors[i]);
      Hexagon neighbor = getHex(neighborID);
      if (neighbor == null) {
        neighborList[i] = null;
      } else {
        neighborList[i] = neighbor;
      }
    }
    return(neighborList);
  }

  boolean checkHex(PVector hexKey_) {
    return (allHexes.containsKey(hexKey_));
  }
  
  int passable(PVector hexKey_){
   Hexagon h = getHex(hexKey_);
   return h.state;
  }

  PVector hexToPixel(int q, int r) {
    PVector temp = new PVector(0, 0);
    temp.x = hexSize * (3./2. * q);
    temp.y = hexSize * (sqrt(3)/2. * q + sqrt(3) * r);
    return(temp);
  }

  PVector cubeRound(PVector hexID) {
    int rx = round(hexID.x);
    int ry = round(hexID.y);
    int rz = round(hexID.z);

    float xdiff = abs(rx - hexID.x);
    float ydiff = abs(ry - hexID.y);
    float zdiff = abs(rz - hexID.z);

    if (xdiff > ydiff && xdiff > zdiff) {
      rx = -ry-rz;
    } else if (ydiff > zdiff) {
      ry = -rx-rz;
    } else {
      rz = -rx-ry;
    }
    PVector rHexID = new PVector(rx, ry, rz);
    return(rHexID);
  }
  
  float normalizeRadians(float theta) {
    while (theta < 0 || theta > TWO_PI) {
      if (theta < 0) {
        theta += TWO_PI;
      }
      if (theta > TWO_PI) {
        theta -= TWO_PI;
      }
    }
    return theta;
  }
  
  Float cubeDistance(Hexagon a, Hexagon b) {
    PVector vec = cubeSubtract(a,b);
    return (abs(vec.x) + abs(vec.y) + abs(vec.z))/2;
  }

  PVector cubeSubtract(Hexagon a, Hexagon b) {
    PVector sub = new PVector(a.hexQ - b.hexQ, a.hexR - b.hexR, a.hexS - b.hexS);
    return sub;
  }
}

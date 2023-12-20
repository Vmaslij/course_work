class Hexagon {
  float size;
  int pixelX, pixelY;
  Hexgrid hexgrid;
  int hexQ, hexR, hexS;     //q for "column" = x axis, r for "row" = z axis
  PVector id;
  PVector pixelxy;
  boolean fillin = false;
  int blinkAlpha = 0;
  boolean blink = false;


  //pathfinding variables
  float f = 0; // Стоимость пути + эвристика
  float g = 0; // Стоимость пути (просто стоимость перехода от соседа к соседу тоже по эвристике)
  float heuristic = 0;
  List<Hexagon> neighbors = new ArrayList<Hexagon>();
  Hexagon previous = null;
  int fuel_val = 0;
  int state; // 0 - barrier, 1 - hex cell, 2 - fuel cell 

  //

  Hexagon(Hexgrid hexgrid_, int hexQ_, int hexR_) {
    hexgrid = hexgrid_;
    hexQ = hexQ_;
    hexR = hexR_;
    hexS = -hexQ - hexR;
    int hexX = hexQ;
    int hexZ = hexR;
    int hexY = hexS;
    size = hexSize;
    pixelxy = hexToPixel(hexQ, hexR);
    pixelX = int(pixelxy.x);
    pixelY = int(pixelxy.y);
    id = new PVector(hexX, hexY, hexZ);

  }

  PVector getKey() {
    return(id);
  }
  
  void resetPathfindingVars(){
   f = 0;
   g = 0;
   heuristic = 0;
   fuel_val = 0;
   neighbors.clear();
   addNeighbors();
   previous = null;
  }

  void addNeighbors() {
    neighbors.clear();
    Hexagon[] neighbors_ = hexGrid.getNeighbors(this);
    for (int i = 0; i < neighbors_.length; i++) {
      Hexagon h = neighbors_[i];
      if (h!= null && hexGrid.checkHex(h.id)) {
        neighbors.add(h);
      }
    }
  }

  void drawHexOutline(PGraphics buffer) {
    buffer.pushMatrix();
    buffer.translate(pixelX, pixelY);
    buffer.noFill();
    buffer.strokeWeight(hexSize / 5);
    buffer.stroke(0, 0, 255);
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape(CLOSE);
    buffer.popMatrix();
  }

  void drawHexOutline(PGraphics buffer, color c, int strokeWeight_) {
    buffer.pushMatrix();
    buffer.translate(pixelX, pixelY);
    buffer.noFill();
    buffer.strokeWeight(strokeWeight_);
    buffer.stroke(c);
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape(CLOSE);
    buffer.popMatrix();
  }

  void drawHexFill(PGraphics buffer, color c) {
    buffer.pushMatrix();
    buffer.translate(pixelX, pixelY);
    buffer.fill(c);
    buffer.noStroke();
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape();
    buffer.popMatrix();
  }

  void drawHexFill(PGraphics buffer, color c, int alpha) {
    buffer.pushMatrix();
    buffer.translate(pixelX, pixelY);
    buffer.fill(c, alpha);
    buffer.noStroke();
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape();
    buffer.popMatrix();
  }
  // Regular cell
  void passable() {
    state = 1;
    fuel_val = 0;
  }
  // Fuel cell
  void fuel() {
    state = 2;
    fuel_val = int(random(minHexFuel, maxHexFuel));
  }
  // Barrier cell
  void impassable() {
    state = 0;
    fuel_val = 0;
  }

  void blinkHex(PGraphics buffer) {
    buffer.beginDraw();
    buffer.pushMatrix();
    buffer.translate(pixelX, pixelY);
    buffer.fill(255, blinkAlpha);
    buffer.noStroke();
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape();
    buffer.popMatrix();  
    if (blinkAlpha<=0) {
      blink = true;
    }
    if (blinkAlpha >=255) {
      blink = false;
    }
    if (blink) {
      blinkAlpha+= 25;
    } else {
      blinkAlpha-=25;
    }
    constrain(blinkAlpha, 0, 255);
    buffer.endDraw();
    //println("blink: " + blinkAlpha);
  }

  PVector hexToPixel(int q, int r) {
    PVector temp = new PVector(0, 0);
    temp.x = hexSize * (3./2 * q);
    temp.y = hexSize * (sqrt(3)/2 * q + sqrt(3) * r);
    //println(temp);
    return(temp);
  }
  PVector getXY() {
    return (pixelxy);
  }
}

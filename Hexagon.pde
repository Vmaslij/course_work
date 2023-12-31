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
  int init_fuel_val = 0;
  int state; // 0 - barrier, 1 - hex cell, 2 - fuel cell 


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
  
  void move(int hexQ_, int hexR_) {
    hexQ = hexQ_;
    hexR = hexR_;
    hexS = -hexQ - hexR;
    int hexX = hexQ;
    int hexZ = hexR;
    int hexY = hexS;
    size = hexSize * multiplex;
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
  
  boolean checkMultiplexBarrier(int circle) {
    boolean result = true;
    
    if (this.state >= 1) {
      if (circle >= ceil(multiplex)) {
        return result;
      }
      Hexagon[] neighbors_ = hexGrid.getNeighbors(this);
        for (int i = 0; i < neighbors_.length; i++) {
          Hexagon h = neighbors_[i];
          if (h!= null && hexGrid.checkHex(h.id)) {
            if (!h.checkMultiplexBarrier(circle + 1)) {
              result = false; 
              return result;
            }
          } else {
            result = false; 
            return result;
          }
        }
    } else {
     result = false; 
    }
    return result;
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

  void drawHexOutline(color c, int strokeWeight_) {
    pushMatrix();
    translate(pixelX, pixelY);
    //noFill();
    fill(c);
    strokeWeight(strokeWeight_);
    stroke(c);
    beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
      vertex(cornerX, cornerY);
    }
    endShape(CLOSE);
    popMatrix();
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
    init_fuel_val = 0;
  }
  
  // Fuel cell
  void fuel() {
    state = 2;
    fuel_val = ceil(random(minHexFuel, maxHexFuel));
    init_fuel_val = fuel_val;
  }
  
  // Barrier cell
  void impassable() {
    state = 0;
    fuel_val = 0;
    init_fuel_val = 0;
  }

  PVector hexToPixel(int q, int r) {
    PVector temp = new PVector(0, 0);
    temp.x = hexSize * (3./2 * q);
    temp.y = hexSize * (sqrt(3)/2 * q + sqrt(3) * r);
    return(temp);
  }
  
  PVector getXY() {
    return (pixelxy);
  }
}

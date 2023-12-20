import processing.video.*;
import java.util.*;
import org.ejml.*;
import java.io.*;
import boofcv.struct.calib.*;
import boofcv.io.calibration.CalibrationIO;
import boofcv.alg.geo.PerspectiveOps;
import georegression.*;

Hexgrid hexGrid;
Arena arena;
Hexagon startHex;
Hexagon targetHex;
int startDirection;
Algorithm pathFinder;


PGraphics gridOutlines;
PGraphics gridFill;
PGraphics arenaMask;

//Settings variables
int impassableRate = 5; //set between 0 and 10. Higher numbers increase the rate of impassable hexes 
int fuelRate = 3; //set between 0 and 10.
int maxHexFuel = 15; // Max possible fuel on grid cell
int minHexFuel = 5; // Min possible fuel on grid cell
int initFuel = 15; // Initial fuel robot has
int hexSize = 25; //
int stepDelay = 1; //time delay for step, seems that it should be bigger

int click_count; // Count number of times mouse clicked (set to 0 when target hex was chosen)
boolean draw_path; // Draw and calc path from start to target if true
PrintWriter logfile;


/*
 * Initial setup for app
 */
void setup() {
  frameRate(30);
  surface.setSize(1920, 1080);
  fullScreen(1);

  initArena();
  gridOutlines = createGraphics(width, height);
  gridFill = createGraphics(width, height);
  hexGrid.drawOutlines(gridOutlines);
  pathFinder = new Algorithm(hexGrid);
  logfile = createWriter("logfile.txt");
  logfile.println("Barrier rate [0, 10]: ");
  logfile.println(impassableRate);
  logfile.println("Fuel rate [0, 10]: ");
  logfile.println(fuelRate);
  logfile.println("Max fuel value in cell: ");
  logfile.println(maxHexFuel);
  logfile.println("Min fuel value in cell: ");
  logfile.println(minHexFuel);
  logfile.println("Initial robot fuel value: ");
  logfile.println(initFuel);
  click_count = 0;
  draw_path = false;
  hexGrid.seedMap(impassableRate, fuelRate);
}

void initArena() { // Create a mask to determine where hexes will be drawn
  arena = new Arena();
  PVector[] pxCorners = new PVector[6];
  int j = 0;
  for (int i = 0; i < 360; i+= 60) {
    float theta = radians(i);
    float x = .5*height * cos(theta);
    float y = .5*height * sin(theta);
    pxCorners[j] = new PVector(x, y);
    //println(pxCorners[j]);
    j++;
  }
  arenaMask = arena.init(pxCorners);
  hexGrid = new Hexgrid(hexSize, arenaMask); // Make initial random map
}

/*
 * Called in infinite loop during app work
 */
void draw() {
  background(255);
  hexGrid.drawHexes(gridFill);
  image(gridFill, 0, 0, width, height);
  image(gridOutlines, 0, 0, width, height);
  if ((draw_path == true) && (click_count == 0)) {
    pathFinder.calculate();
    pathFinder.generatePath();
    pathFinder.displayPath();
  }
  delay(stepDelay);
}

/*
 * Mouse click handler
 * Start of coordinates is left higher corner
 */
void mouseClicked() {
  int x, y;
  x = mouseX;
  y = mouseY;
  click_count++;
  if (click_count == 1) { // Set start hex on first click
    startHex = hexGrid.pixelToHex(x, y);
    if (startHex == null || (startHex.state == 0)) { // Case click was outside the map
      startHex = pickHex();
    }
  }
  
  if (click_count == 2) { // Set target hex on second click
    targetHex = hexGrid.pixelToHex(x, y);
    if (targetHex == null || (targetHex.state == 0)) {
      targetHex = pickHex();
    }
    
    draw_path = true; 
    click_count = 0; 
    logfile.println("New path calculation start:\r\n");
    
    pathFinder.reset();
    pathFinder.setTargets(startHex, targetHex); // set start and end targets
    pathFinder.calculate();
    pathFinder.displayPath();
  }
}

/*
 * Key pressing event handler
 * On press 'R' regenerates map
 */
void keyPressed() {
   if (key == 'R' || key == 'r') {
     hexGrid.seedMap(impassableRate, fuelRate); //assign impassable/passable to each hex (generating map)
     pathFinder.reset();
     startHex = null;
     targetHex = null;
     draw_path = false;
   }
   if (key == 'W' || key == 'w') {
     logfile.flush();
     logfile.close();
     exit();
   }
}

/*
 * Random cell choice
 */
Hexagon pickHex() {
  Hexagon h;
  Object[] keys = hexGrid.allHexes.keySet().toArray();
  do {
    Object randHexKey = keys[new Random().nextInt(keys.length)];
    h = hexGrid.getHex((PVector)randHexKey);
  } while ( h == targetHex || h == startHex || (h.state == 0) || (h.state == 2));
  return h;
}
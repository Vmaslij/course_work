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
PGraphics robot_body;

//Settings variables
int impassableRate = 5; //set between 0 and 10. Higher numbers increase the rate of impassable hexes 
int fuelRate = 2; //set between 0 and 10.
int maxHexFuel = 4; // Max possible fuel on grid cell && robot could have
int minHexFuel = 2; // Min possible fuel on grid cell
int initFuel = 4; // Initial fuel robot has
int hexSize = 25; //
int stepDelay = 10; //time delay for step, seems that it should be bigger
float multiplex = 1; // Size multiplexor

int click_count; // Count number of times mouse clicked (set to 0 when target hex was chosen)
int robot_state = 0;
int reverse_index;
boolean draw_path; // Draw and calc path from start to target if true
PrintWriter logfile;
JSONArray values;

void parseFile() {
  values = loadJSONArray("settings.json");

  //for (int i = 0; i < values.size(); i++) {
    
    JSONObject setting_vars = values.getJSONObject(0); 

    impassableRate = setting_vars.getInt("barrier_rate");
    fuelRate = setting_vars.getInt("fuel_rate");
    maxHexFuel = setting_vars.getInt("maxCellFuel");
    minHexFuel = setting_vars.getInt("minCellFuel");
    initFuel = setting_vars.getInt("start_fuel");
    hexSize = setting_vars.getInt("cell_size");
    stepDelay = setting_vars.getInt("step_delay");
    multiplex = setting_vars.getFloat("robot_size");
  //}
}

/*
 * Initial setup for app
 */
void setup() {
  frameRate(30);
  surface.setSize(1920, 1080);
  fullScreen(1);
  parseFile();
  initArena();
  gridOutlines = createGraphics(width, height);
  gridFill = createGraphics(width, height);
  hexGrid.drawOutlines(gridOutlines);
  pathFinder = new Algorithm(hexGrid);
  logfile = createWriter("logfile.txt");
  logfile.println("Частота генерации препятствий [0, 10]: ");
  logfile.println(impassableRate);
  logfile.println("Частота генерации топливных точек [0, 10]: ");
  logfile.println(fuelRate);
  logfile.println("Максимальное количества топлива на точке и максимальное количество топлива у робота: ");
  logfile.println(maxHexFuel);
  logfile.println("Минимальное количества топлива на точке: ");
  logfile.println(minHexFuel);
  logfile.println("Начальное значение топлива у робота: ");
  logfile.println(initFuel);
  logfile.println("Размер робота: ");
  logfile.println(ceil(multiplex));
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
    if (!pathFinder.log) {
      pathFinder.calculate();
      pathFinder.generatePath();
    }
    pathFinder.displayPath();
    if (pathFinder.log) {
      if (robot_state == 0) {
        loop();
        reverse_index = pathFinder.path.size() - 1;
        stepDelay = stepDelay * 20;
      }
      //println(robot_state);
      if (robot_state < pathFinder.path.size()) {
        Hexagon h = pathFinder.path.get(reverse_index);
        pathFinder.robo.move(h.hexQ, h.hexR);
        pathFinder.robo.drawHexOutline(color(255, 0, 200), hexSize / 4);
        robot_state++;
        reverse_index--;
      } else {
        noLoop();
        stepDelay = stepDelay / 20;
      }
    }
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
  //println(hexGrid.pixelToHex(x, y).checkMultiplexBarrier(1));
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
    logfile.println("\r\nНовый маршрут:");
    robot_state = 0;
    
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
  } while ( h == targetHex || h == startHex || (h.state == 0) || (h.state == 2) || (!h.checkMultiplexBarrier(1)));
  return h;
}

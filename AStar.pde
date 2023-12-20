 //<>//
class Algorithm {
  long calc_ms = 0;
  long gen_ms = 0;
  long tmp;
  int rfuel;
  Hexagon start;
  Hexagon target;
  Hexagon current;
  Hexgrid hexGrid;
  ArrayList <Hexagon> openSet;
  ArrayList <Hexagon> closedSet;
  ArrayList <Hexagon> path;


  Algorithm(Hexgrid hexGrid_) {
    hexGrid = hexGrid_;
    for (Map.Entry<PVector, Hexagon> me : hexGrid.allHexes.entrySet()) {
      Hexagon h = me.getValue();
      h.addNeighbors();
    }

    openSet = new ArrayList<Hexagon>();
    closedSet = new ArrayList<Hexagon>();
    path = new ArrayList<Hexagon>();
  }

  void setTargets( Hexagon start_, Hexagon target_) {
    start = start_;
    start.fuel_val = initFuel;
    target = target_;
    openSet.clear();
    closedSet.clear();
    path.clear();
    openSet.add(start);
  }

  float heuristic(Hexagon a, Hexagon b) {
    float d = hexGrid.cubeDistance(a, b);
    return d;
  }

  void generatePath() {
    tmp = millis();
    path.clear();
    Hexagon temp = current;
    path.add(temp);
    while (temp.previous != null) {
      path.add(temp.previous);
      temp = temp.previous;
    }
    gen_ms += millis() - tmp;
    //println("path length: " + (path.size()-1));
  }
  void reset(){
    for (Map.Entry<PVector, Hexagon> me : hexGrid.allHexes.entrySet()) {
      Hexagon h = me.getValue();
      h.resetPathfindingVars();
    } 
    rfuel = initFuel;
    calc_ms = 0;
    gen_ms = 0;
    loop();
  }
  
  void calculate() {
    //while (true) { //remove delay in draw function and uncomment to skip animation and show the solution in one step
    tmp = millis();
    if (openSet.size() > 0) {
      int winner = 0; // Выбираем первый узел, как узел с минимальным путем или стоимостью
      for (int i = 0; i < openSet.size(); i++) { // Проверяем весь список не проверенных узлов
        if (openSet.get(i).f < openSet.get(winner).f) { // Если суммарная (стоимость пути до узла + эвристика) стоимость узла меньше минимума, то выбирается этот узел
          winner = i;
        }
      }
      current = openSet.get(winner); // Переходим в лучший узел и теперь будем искать куда можно отсюда пойти

      // Did I finish?
      if (current == target) { // В случае если дошли до цели
        logfile.println("target found");
        logfile.println("path length: " + (path.size()-1));
        noLoop();
        logfile.println("Calculating path time:");
        logfile.println(calc_ms);
        logfile.println("Generating path time:");
        logfile.println(gen_ms);
        logfile.println("Sum time:");
        logfile.println(gen_ms + calc_ms);
        //generatePath();
        return;
      }

      // Best option moves from openSet to closedSet
      //openSet = removeFromArray(openSet, current);

      openSet.remove(current); // Убираем текущий узел из списка непросмотренных
      closedSet.add(current); // Добавляем текущий узел в список просмотренных узлов

      //check all the neighbors
      List<Hexagon> neighbors = current.neighbors; // Собираем список всех узлов соседей
      for (int i = 0; i < neighbors.size(); i++) {
        Hexagon neighbor = neighbors.get(i);

        //Valid next spot?
        if (!closedSet.contains(neighbor) && (neighbor.state >= 1)) { // Убираем по сути из списка узлов соседей просмотренные и узлы препятствия
          float tempG = current.g + heuristic(neighbor, current); // Получаем путь до текущей вершины + эвристика от соседа до нашей вершины
          
          
          //Is this a better path than before?
          boolean newPath = false;
          if (openSet.contains(neighbor)) {
            if (tempG < neighbor.g) { // Путь до соседа короче, чем тот что у него был (стало быть нашли путь лучше до этой точки)
              neighbor.fuel_val += current.fuel_val - tempG;
              println(neighbor.fuel_val);
              if (neighbor.fuel_val < 0) {
              	neighbor.g = 3E36;
              	//neighbor.g = (~neighbor.g) - heuristic(neighbor, target) - 10; //!
              } else {
              	neighbor.g = tempG; // Запомнили в переменную соседа этот путь
              }
              newPath = true;
            }
          } else { // Добавляем соседа в список доступных вершин
          	neighbor.fuel_val += current.fuel_val - tempG;
            println(neighbor.fuel_val);
            if (neighbor.fuel_val < 0) {
		      	neighbor.g = 3E36;
		      	//neighbor.g = (~neighbor.g) - heuristic(neighbor, target) - 10; //!
		      } else {
		      	neighbor.g = tempG; // Запомнили в переменную соседа этот путь
		      }
            newPath = true;
            openSet.add(neighbor); // Добавляем соседа в список доступных вершин
          }
          //Yes, it's a better path
          if (newPath) {
            neighbor.heuristic = heuristic(neighbor, target); // Запоминаем на будущее значение эвристики от этого соседа до цели
            neighbor.f = neighbor.g + neighbor.heuristic; // Запоминаем общую стоимость пути 
            neighbor.previous = current; // Запоминаем, откуда попали в этот узел
          }
        }
      }
      calc_ms += millis() - tmp;
    } else { //no solution
      println("no solution");
      noLoop();
      calc_ms += millis() - tmp;
      logfile.println("Calculating path time:");
      logfile.println(calc_ms);
      logfile.println("Generating path time:");
      logfile.println(gen_ms);
      logfile.println("Sum time:");
      logfile.println(gen_ms + calc_ms);
      return;
    }
    //}
  }
  void displayPath() {
    //println(path);
    noFill();
    stroke(255, 0, 200);
    strokeWeight(hexSize / 5);
    beginShape();
    for (int i = 0; i < path.size(); i++) {
      Hexagon h = path.get(i);
      ellipse(h.pixelX, h.pixelY, hexSize / 2, hexSize / 2);
      vertex(h.pixelX, h.pixelY);
      //println(h.pixelxy);
    }
    endShape();
  }
}

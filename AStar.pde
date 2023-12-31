
class Algorithm {
  long calc_ms = 0;
  long gen_ms = 0;
  long tmp;
  int rfuel;
  int robosize = ceil(multiplex);
  boolean log = false;
  Hexagon robo;
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
    start.init_fuel_val = initFuel;
    robo = new Hexagon(hexGrid, start.hexQ, start.hexR);
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
    tmp = System.nanoTime();
    path.clear();
    Hexagon temp = current;
    path.add(temp);
    while (temp.previous != null) {
      path.add(temp.previous);
      if (log) {
        logfile.println("Остаток топлива " + (temp.fuel_val) + " Длина пути пройденная от старта " + (temp.g));
      }
      temp = temp.previous;
    }
    if (log) {
        logfile.println("Остаток топлива " + (temp.fuel_val) + " Длина пути пройденная от старта " + (temp.g));
      }
    gen_ms += System.nanoTime() - tmp;
  }
  
  void reset(){
    for (Map.Entry<PVector, Hexagon> me : hexGrid.allHexes.entrySet()) {
      Hexagon h = me.getValue();
      h.resetPathfindingVars();
    } 
    rfuel = initFuel;
    calc_ms = 0;
    gen_ms = 0;
    log = false;
    loop();
  }
  
  void calculate() {
    tmp = System.nanoTime();
    if (openSet.size() > 0) {
      int winner = 0; // Выбираем первый узел, как узел с минимальным путем или стоимостью
      for (int i = 0; i < openSet.size(); i++) { // Проверяем весь список не проверенных узлов
        if (openSet.get(i).f < openSet.get(winner).f) { // Если суммарная (стоимость пути до узла + эвристика) стоимость узла меньше минимума, то выбирается этот узел
          winner = i;
        }
      }
      current = openSet.get(winner); // Переходим в лучший узел и теперь будем искать куда можно отсюда пойти
      if (current.f >= 3E36) { // Случай, когда все вершины в которые можно перейти недостижимы из-за недостатка топлива
        logfile.println("Результат: Точка недостижима из-за недостатка топлива");
        log = true;
        noLoop();
        calc_ms += System.nanoTime() - tmp;
        logfile.println("Время поиска пути (наносекунды):");
        logfile.println(calc_ms);
        logfile.println("Время восстановления пути (наносекунды):");
        logfile.println(gen_ms);
        logfile.println("Суммарное время (наносекунды):");
        logfile.println(gen_ms + calc_ms);
        return;
      }

      if (current == target) { // В случае если дошли до цели
        log = true;
        logfile.println("Результат: Найден кратчайший маршрут до точки");
        logfile.println("Длина пути: " + (path.size()));
        calc_ms += System.nanoTime() - tmp;
        noLoop();
        logfile.println("Время поиска пути (наносекунды):");
        logfile.println(calc_ms);
        logfile.println("Время восстановления пути (наносекунды):");
        logfile.println(gen_ms);
        logfile.println("Суммарное время (наносекунды):");
        logfile.println(gen_ms + calc_ms);
        return;
      }

      openSet.remove(current); 
      closedSet.add(current); 

      List<Hexagon> neighbors = current.neighbors; // Собираем список всех узлов соседей
      for (int i = 0; i < neighbors.size(); i++) {
        Hexagon neighbor = neighbors.get(i);

        // Проверка возможности перейти в соседнюю клетку
        if (!closedSet.contains(neighbor) && (neighbor.state >= 1) && (neighbor.checkMultiplexBarrier(1))) { 
          float tempG = current.g + heuristic(neighbor, current); // Получаем путь до текущей вершины + эвристика от соседа до нашей вершины
          
          boolean newPath = false;
          if (openSet.contains(neighbor)) {
            if (tempG < neighbor.g) { // Путь до соседа короче, чем тот что у него был (стало быть нашли путь лучше до этой точки)
              newPath = true;
            }
          } else { // Добавляем соседа в список доступных вершин
            newPath = true;
            openSet.add(neighbor); // Добавляем соседа в список доступных вершин
          }
          // Нашли лучший путь до соседней клетки или увидели в первый раз эту клетку 
          if (newPath) {
            neighbor.fuel_val = current.fuel_val - ceil(heuristic(neighbor, current)) + neighbor.init_fuel_val;
            if (neighbor.fuel_val > maxHexFuel) { // Ограничение сверху на максимальное топливу у робота (типо бак больше не может вместить)
              neighbor.fuel_val = maxHexFuel;
            }
            
            if (current.fuel_val <= 0) {
              neighbor.fuel_val = neighbor.init_fuel_val;
              neighbor.g = 3E36;           
            } else {
              neighbor.g = tempG; // Запомнили стоимость пути до этого соседа
            }
            neighbor.heuristic = heuristic(neighbor, target); // Запоминаем на будущее значение эвристики от этого соседа до цели
            neighbor.f = neighbor.g + neighbor.heuristic; // Запоминаем общую стоимость пути
            neighbor.previous = current; // Запоминаем, откуда попали в этот узел
          }
        }
      }
      calc_ms += System.nanoTime() - tmp;
    } else { // Случай, когда цель недостижима
      logfile.println("Результат: Цель недостижима из-за препятствий");
      log = true;
      noLoop();
      calc_ms += System.nanoTime() - tmp;
      logfile.println("Время поиска пути (наносекунды):");
        logfile.println(calc_ms);
        logfile.println("Время восстановления пути (наносекунды):");
        logfile.println(gen_ms);
        logfile.println("Суммарное время (наносекунды):");
        logfile.println(gen_ms + calc_ms);
      return;
    }
  }

  void displayPath() {
    noFill();
    stroke(255, 0, 200);
    strokeWeight(hexSize / 5);
    beginShape();
    for (int i = 0; i < path.size(); i++) {
      Hexagon h = path.get(i);
      ellipse(h.pixelX, h.pixelY, hexSize / 2, hexSize / 2);
      vertex(h.pixelX, h.pixelY);
    }
    endShape();
  }
}

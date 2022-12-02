final int SCREEN_WIDTH = 1350;
final int SCREEN_HEIGHT = 700;

final float VERTEX_MOVE_SPEED_FACTOR = 5;
final int VERTEX_RADIUS = 15;

final int BUTTON_SAVE_LEVEL = 0;
final int BUTTON_LEVEL_SELECT = 1;
final int BUTTON_LEVEL = 100;

Construction constr;
Button saveButton;
Button levelSelectButton;
ArrayList<Button> levelButtons;
boolean editMode;
int chosenLevel;
int levelsCount;
int progress;
int progressBackup;
boolean victory;

class Vertex {
    float x;
    float y;
    float newX;
    float newY;
    boolean moving;
    boolean selected;

    Vertex(float x, float y) {
        this.x = x;
        this.y = y;
    }

    void moveTowardsNew() {
        if (!moving) return;
        float distanceX = x - newX;
        float distanceY = y - newY;
        float distance = (float) Math.sqrt(distanceX * distanceX + distanceY * distanceY);
        if (distance > 3) {
            x += -distanceX / distance * VERTEX_MOVE_SPEED_FACTOR;
            y += -distanceY / distance * VERTEX_MOVE_SPEED_FACTOR;
        } else {
            moving = false;
            x = newX;
            y = newY;
        }
    }
}

class Line {
    int vertex1Id;
    int vertex2Id;
    boolean intersects;

    Line(int vertex1Id, int vertex2Id) {
        this.vertex1Id = vertex1Id;
        this.vertex2Id = vertex2Id;
    }
}

class Construction {
    ArrayList<Vertex> vertices;
    ArrayList<Line> lines;

    Construction() {
        vertices = new ArrayList<Vertex>();
        lines = new ArrayList<Line>();
    }

    void addVertex(Vertex vertex) {
        vertices.add(vertex);
    }

    void addLine(Line line) {
        lines.add(line);
    }

    void removeVertex(int vertexId) {
        ArrayList<Integer> adjacent = adjacentLineIds(vertexId);
        for (int i = adjacent.size() - 1; i >= 0; i--) {
            lines.remove(adjacent.get(i).intValue());
        }
        vertices.remove(vertexId);
        for (int i = 0; i < lines.size(); i++) {
            Line line = lines.get(i);
            if (line.vertex1Id > vertexId) {
                line.vertex1Id--;
            }
            if (line.vertex2Id > vertexId) {
                line.vertex2Id--;
            }
        }
    }

    private ArrayList<Integer> adjacentLineIds(int vertexId) {
        ArrayList<Integer> adjacentLineIds = new ArrayList<Integer>();
        for (int lineId = 0; lineId < lines.size(); lineId++) {
            Line line = lines.get(lineId);
            if (line.vertex1Id == vertexId || line.vertex2Id == vertexId) {
                adjacentLineIds.add(lineId);
            }
        }
        return adjacentLineIds;
    }

    boolean verticesMoving() {
        for (int i = 0; i < vertices.size(); i++) {
            if (vertices.get(i).moving) {
                return true;
            }
        }
        return false;
    }

    int selectedVertexId() {
        for (int i = 0; i < vertices.size(); i++) {
            if (vertices.get(i).selected) {
                return i;
            }
        }
        return -1;
    }

    void selectVertex(int vertexId) {
        if (verticesMoving()) return;
        if (selectedVertexId() >= 0) return;
        vertices.get(vertexId).selected = true;
    }

    void swapVertices(int vertex2Id) {
        if (verticesMoving()) return;
        int vertex1Id = selectedVertexId();
        if (vertex1Id < 0) return;
        Vertex vertex1 = vertices.get(vertex1Id);
        Vertex vertex2 = vertices.get(vertex2Id);
        vertex1.moving = true;
        vertex1.newX = vertex2.x;
        vertex1.newY = vertex2.y;
        vertex2.moving = true;
        vertex2.newX = vertex1.x;
        vertex2.newY = vertex1.y;
        vertex1.selected = false;
    }

    void moveVertices() {
        for (int i = 0; i < vertices.size(); i++) {
            vertices.get(i).moveTowardsNew();
        }
    }

    int mouseoverVertexId(int mouseX, int mouseY) {
        for (int i = 0; i < vertices.size(); i++) {
            Vertex vertex = vertices.get(i);
            float distance = (float) Math.sqrt(Math.pow(mouseX - vertex.x, 2) +
                                               Math.pow(mouseY - vertex.y, 2));
            if (distance < VERTEX_RADIUS) {
                return i;
            }
        }
        return -1;
    }

    void setIntersectionStatuses() {
        if (verticesMoving()) return;
        for (int lineId = 0; lineId < lines.size(); lineId++) {
            if (hasIntersections(lineId)) {
                lines.get(lineId).intersects = true;
            } else {
                lines.get(lineId).intersects = false;
            }
        }
    }

    private boolean twoLinesIntersect(Line line1, Line line2) {
        Vertex a1 = vertices.get(line1.vertex1Id);
        Vertex a2 = vertices.get(line1.vertex2Id);
        Vertex b1 = vertices.get(line2.vertex1Id);
        Vertex b2 = vertices.get(line2.vertex2Id);
        float v1 = (b2.x - b1.x) * (a1.y - b1.y) - (b2.y - b1.y) * (a1.x - b1.x);
        float v2 = (b2.x - b1.x) * (a2.y - b1.y) - (b2.y - b1.y) * (a2.x - b1.x);
        float v3 = (a2.x - a1.x) * (b1.y - a1.y) - (a2.y - a1.y) * (b1.x - a1.x);
        float v4 = (a2.x - a1.x) * (b2.y - a1.y) - (a2.y - a1.y) * (b2.x - a1.x);
        return v1 * v2 < 0 && v3 * v4 < 0;
    }

    private boolean hasIntersections(int lineId) {
        Line thisLine = lines.get(lineId);
        for (int i = 0; i < lines.size(); i++) {
            if (i != lineId) {
                Line anotherLine = lines.get(i);
                if (twoLinesIntersect(thisLine, anotherLine)) return true;
            }
        }
        return false;
    }

    boolean hasIntersections() {
        for (int i = 0; i < lines.size(); i++) {
            if (lines.get(i).intersects) return true;
        }
        return false;
    }

    JSONObject export() {
        JSONObject vertices = new JSONObject();
        JSONObject lines = new JSONObject();
        for (int i = 0; i < this.vertices.size(); i++) {
            Vertex vertex = this.vertices.get(i);
            JSONObject jsonVertex = new JSONObject();
            jsonVertex.put("x", String.valueOf((int)vertex.x));
            jsonVertex.put("y", String.valueOf((int)vertex.y));
            vertices.put(String.valueOf(i), jsonVertex);
        }
        for (int i = 0; i < this.lines.size(); i++) {
            Line line = this.lines.get(i);
            JSONObject jsonLine = new JSONObject();
            jsonLine.put("vertex1Id", String.valueOf(line.vertex1Id));
            jsonLine.put("vertex2Id", String.valueOf(line.vertex2Id));
            lines.put(String.valueOf(i), jsonLine);
        }
        JSONObject level = new JSONObject();
        level.put("vertices", vertices);
        level.put("lines", lines);
        return level;
    }

    void display() {
        for (int i = 0; i < lines.size(); i++) {
            Line line = lines.get(i);
            Vertex vertex1 = vertices.get(line.vertex1Id);
            Vertex vertex2 = vertices.get(line.vertex2Id);
            stroke(0, 0, 255);
            if (line.intersects) {
                stroke(255, 0, 0);
            }
            strokeWeight(5);
            line(vertex1.x, vertex1.y, vertex2.x, vertex2.y);
        }
        for (int i = 0; i < vertices.size(); i++) {
            Vertex vertex = vertices.get(i);
            stroke(0, 0, 255);
            if (vertex.selected) {
                fill(255, 255, 255);
            } else {
                fill(0, 0, 255);
            }
            circle(vertex.x, vertex.y, VERTEX_RADIUS);
        }
    }
}

class Button {
    int x;
    int y;
    String text;
    int type;
    int width;

    Button(int x, int y, int type, String text) {
        this.x = x;
        this.y = y;
        this.type = type;
        this.text = text;
    }

    boolean mouseOver() {
        if (mouseX > x && mouseX < x + width && mouseY > y - 30 && mouseY < y + 15) {
            return true;
        }
        return false;
    }

    void display() {
        textSize(36);
        fill(255);
        stroke(255);
        width = text.length() * 23;
        if (mouseOver()) {
            fill(200);
            stroke(200);
        }
        rect(x, y - 30, width, 30);
        fill(228, 135, 135);
        text(text, x, y);
    }
}

int getLevelsCount() {
    return listFiles(sketchPath() + "/level/").length;
}

void loadProgress() {
    JSONObject json = loadJSONObject("progress.json");
    progress = Integer.parseInt(json.getString("progress"));
    levelButtons = new ArrayList<Button>();
    for (int i = 0; i < levelsCount; i++) {
        String name = String.valueOf(i + 1);
        if (i > progress) name = "?";
        Button levelButton = new Button(i * 60 + 50,
                                        SCREEN_HEIGHT / 2,
                                        BUTTON_LEVEL + i,
                                        name);
        levelButtons.add(levelButton);
    }
}

void loadProgress(int lvlcnt) {
    JSONObject json = loadJSONObject("progress.json");
    levelButtons = new ArrayList<Button>();
    for (int i = 0; i < levelsCount; i++) {
        String name = String.valueOf(i + 1);
        if (i > lvlcnt) name = "?";
        Button levelButton = new Button(i * 60 + 50,
                                        SCREEN_HEIGHT / 2,
                                        BUTTON_LEVEL + i,
                                        name);
        levelButtons.add(levelButton);
    }
}

void saveProgress() {
    PrintWriter writer = createWriter("progress.json");
    writer.println("{\"progress\":\""+progress+"\"}");
    writer.flush();
    writer.close();
}

void saveLevel() {
    PrintWriter writer = createWriter("/level/"+chosenLevel+".json");
    writer.println(constr.export().toString());
    writer.flush();
    writer.close();
}

void loadLevel(int levelNum) {
    Construction level = new Construction();
    JSONObject json = loadJSONObject("/level/"+levelNum+".json");
    JSONObject vertices = json.getJSONObject("vertices");
    for (int i = 0; i < vertices.size(); i++) {
        JSONObject vertex = vertices.getJSONObject(String.valueOf(i));
        level.addVertex(new Vertex(Integer.parseInt(vertex.getString("x")),
                                    Integer.parseInt(vertex.getString("y"))));
    }
    JSONObject lines = json.getJSONObject("lines");
    for (int i = 0; i < lines.size(); i++) {
        JSONObject line = lines.getJSONObject(String.valueOf(i));
        level.addLine(new Line(Integer.parseInt(line.getString("vertex1Id")),
                               Integer.parseInt(line.getString("vertex2Id"))));
    }
    constr = level;
}

void setup() {
    size(1350, 700);

    surface.setTitle("КЛУБОК");
    surface.setResizable(false);
    surface.setLocation(5, 5);

    editMode = false;
    chosenLevel = -1;
    levelsCount = getLevelsCount();

    saveButton = new Button(SCREEN_WIDTH - 400,
                            SCREEN_HEIGHT - 30,
                            BUTTON_SAVE_LEVEL,
                            "СОХРАНИТЬ УРОВЕНЬ");
    levelSelectButton = new Button(50,
                                   SCREEN_HEIGHT - 30,
                                   BUTTON_LEVEL_SELECT,
                                   "ВЫБОР УРОВНЯ");

    loadProgress();
}

void draw() {
    background(122, 216, 164);

    if (victory) {
        delay(10000);
        victory = false;
    }

    if (chosenLevel >= 0) {
        if (chosenLevel == 0) {
            textSize(36);
            text("Нажми на один и затем на другой кружок, чтобы поменять их местами",
                 30,
                 SCREEN_HEIGHT/4);
            text("Цель: на игровом поле не должна переплетаться ни одна линиия",
                 30,
                 SCREEN_HEIGHT/4 + 40);
        }

        constr.moveVertices();
        constr.setIntersectionStatuses();
        constr.display();
    } else {
        textSize(96);
        text("КЛУБОК", SCREEN_WIDTH / 2 - 200, SCREEN_HEIGHT / 5);
        textSize(36);
        text("ВЫБОР УРОВНЯ", SCREEN_WIDTH / 2 - 150, SCREEN_HEIGHT / 3);
        for (int i = 0; i < levelButtons.size(); i++) {
            levelButtons.get(i).display();
        }
        if (progress == levelsCount - 1) {
            text("ВСЕ УРОВНИ ПРОЙДЕНЫ! ПОЗДРАВЛЯЮ!", SCREEN_WIDTH / 2 - 350, SCREEN_HEIGHT*0.9);
        }
    }

    fill(228, 135, 135);
    if (chosenLevel >= 0) {
        textSize(20);
        text("УРОВЕНЬ " + (chosenLevel + 1), 50, 50);
        levelSelectButton.display();
    }
    if (editMode) {
        textSize(20);
        text("EDIT", SCREEN_WIDTH - 50, 20);

        if (chosenLevel >= 0) {
            saveButton.display();
        }
    }
    if (!editMode && chosenLevel >= 0 && !constr.hasIntersections()) {
        textSize(48);
        text("УРОВЕНЬ ПРОЙДЕН!", SCREEN_WIDTH / 3, SCREEN_HEIGHT / 2);
        if (progress == chosenLevel && progress < levelsCount - 1) {
            progress++;
            saveProgress();
            loadProgress();
        }
        chosenLevel = -1;
        victory = true;
    }
}

void keyPressed() {
    if (key == 'e') {
        editMode = editMode ? false : true;
        if (editMode) {
            loadProgress(levelsCount);
            progressBackup = progress;
            progress = levelsCount - 1;
        } else {
            loadProgress();
            progress = progressBackup;
        }
    }
}

void mousePressed() {
    if (mouseButton == LEFT) {
        if (chosenLevel >= 0) {
            int vertexId = constr.mouseoverVertexId(mouseX, mouseY);
            if (vertexId >= 0) {
                int selectedVertexId = constr.selectedVertexId();
                if (selectedVertexId >= 0) {
                    constr.swapVertices(vertexId);
                } else {
                    constr.selectVertex(vertexId);
                }
            }

            if (levelSelectButton.mouseOver()) {
                chosenLevel = -1;
            }
        } else {
            for (int i = 0; i < levelButtons.size(); i++) {
                Button btn = levelButtons.get(i);
                if (btn.mouseOver()) {
                    if (btn.type - BUTTON_LEVEL <= progress) {
                        chosenLevel = btn.type - BUTTON_LEVEL;
                        loadLevel(chosenLevel);
                    }
                }
            }
        }
    }
    if (editMode) {
        if (mouseButton == LEFT) {
            if (saveButton.mouseOver()) {
                saveLevel();
                javax.swing.JOptionPane.showMessageDialog(null, "Уровень "+(chosenLevel+1)+" успешно сохранен");
            }
        }
        if (mouseButton == RIGHT) {
            int mouseoverVertexId = constr.mouseoverVertexId(mouseX, mouseY);
            if (mouseoverVertexId == -1) {
                constr.addVertex(new Vertex(mouseX, mouseY));
            } else {
                int selectedVertexId = constr.selectedVertexId();
                if (selectedVertexId == -1) {
                    constr.selectVertex(mouseoverVertexId);
                } else {
                    constr.addLine(new Line(mouseoverVertexId, selectedVertexId));
                    constr.vertices.get(selectedVertexId).selected = false;
                }
            }
        }
        if (mouseButton == CENTER) {
            int mouseoverVertexId = constr.mouseoverVertexId(mouseX, mouseY);
            if (mouseoverVertexId != -1) {
                constr.removeVertex(mouseoverVertexId);
            }
        }
    }
}
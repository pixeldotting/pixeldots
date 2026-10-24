// pixeldots installer: screens, input handling, and the child process that does the real work (apply.sh).
// Platform-independent on purpose: main_sdl.cpp feeds it keys/mouse and shows the Canvas, main_headless.cpp
// feeds scripted input and dumps the Canvas to PPM, so the whole flow can be tested without a display.
// Look: Material You like the Pixel setup wizard. All layout is in "design units" (1080 x 1500) scaled to the window.
#pragma once
#include <string>
#include <sys/types.h>
#include <vector>
#include "gfx.hpp"

enum class K { Up, Down, Left, Right, Enter, Esc, Backspace, Tab, PgUp, PgDn, Home, End };

struct Item {
    std::string id, label, attr;
    bool on = false, unfree = false;
};

struct ListView {
    int rows = 6;  // visible rows, set by the screen that shows the list
    std::vector<Item> items;
    std::vector<int> vis;  // indices into items that match the filter
    std::string filter;
    int cur = 0, top = 0;  // positions inside vis

    void refilter();
    void move(int d);
    bool select(const std::string& id);
    const Item* sel() const { return vis.empty() ? nullptr : &items[vis[cur]]; }
    Item* selMut() { return vis.empty() ? nullptr : &items[vis[cur]]; }
};

enum class Scr { Welcome, Locale, Layout, Timezone, Hostname, Account, Apps, Look, Summary, Install, Done, Failed };

class App {
public:
    explicit App(const std::string& dataDir);
    ~App();
    void key(K k);
    void text(const std::string& s);  // typed characters (already UTF-8 from the platform layer)
    void tick(double dt);
    void draw(Canvas& c);

    void click(float x, float y);  // window pixels
    void wheel(int dy);            // >0 = up
    bool fontOk() const { return font.ok(); }

    bool quit = false;
    int exitCode = 0;  // 0 = installed, desktop can start; 1 = aborted or failed

    Scr screen() const { return scr; }
    float lastU = 1, lastOx = 0, lastOy = 0;  // layout of the last drawn frame (tests convert design units to pixels)

private:
    // data
    ListView locales, layouts, zones, apps;
    std::string host = "pixeldots", user, pw1, pw2, err;
    int field = 0;      // active text field on Account
    int lookRow = 0, modeIdx = 0, variantIdx = 0;
    bool autostart = true;
    bool showInfo = false;
    Font font;
    Background bg;
    enum Act { HNext, HBack, HQuit, HInfo, HInfoClose, HRow, HApp, HMode, HVariant, HAuto, HField };
    struct Hit { float x, y, w, h; Act act; int arg; };
    std::vector<Hit> hits;
    Canvas* cv = nullptr;  // frame context while drawing
    float u = 1, ox = 0, oy = 0, bs = 0;
    Scr scr = Scr::Welcome;
    double t = 0;

    // install child
    std::string applyPath, logPath;
    pid_t child = -1;
    int outFd = -1;
    std::string buf;
    std::vector<std::string> log;
    int pct = 0;
    std::string msg;

    void go(Scr s);
    void next();
    void back();
    bool validate();
    bool startInstall();
    void consume();
    void finishChild();
    std::string appIds() const;
    std::string selId(const ListView& l) const;
    std::string selLabel(const ListView& l) const;

    ListView* activeList();
    void listKey(ListView& l, K k);

    void advance();
    int step() const;
    // drawing helpers, all in design units
    float PX(float v) const { return ox + v * u; }
    float PY(float v) const { return oy + v * u; }
    void rr(float x, float y, float w, float h, float r, uint32_t col, float a = 1);
    void ring(float x, float y, float w, float h, float r, float t, uint32_t col, float a = 1);
    void cap(float x0, float y0, float x1, float y1, float t, uint32_t col, float a = 1);
    float tw(const std::string& s, float size) const;
    std::string fit(const std::string& s, float size, float maxw) const;
    void txt(float x, float cy, const std::string& s, float size, uint32_t col, float weight = 0, int align = 0, float a = 1);
    void hit(float x, float y, float w, float h, Act act, int arg = 0);
    void arrow(float cx, float cy, float s, uint32_t col, float t, bool right);
    void iconX(float cx, float cy, float s, uint32_t col, float t);
    void iconInfo(float cx, float cy, float s, uint32_t col);
    void iconSearch(float cx, float cy, float s, uint32_t col);
    void topBar(const std::string& left);
    void titleBlock(const std::string& title, const std::string& sub);
    void bottomBar(int left /*0 none, 1 back, 2 quit*/, const std::string& label);
    void sw(float x, float y, bool on);
    void drawField(float y, const std::string& label, const std::string& val, bool secret, bool active, int idx);
    void fitRows(ListView& l, int base);
    void drawList(bool search, float y0);
    void drawApps();
    void drawWelcome();
    void drawHost();
    void drawAccount();
    void drawLook();
    void drawSummary();
    void drawInstall();
    void drawDone();
    void drawFailed();
    void drawInfo();
};

// pixeldots installer: screens, input handling, and the child process that does the real work (apply.sh).
// Platform-independent on purpose: main_sdl.cpp feeds it keys and shows the Canvas, main_headless.cpp
// feeds scripted keys and dumps the Canvas to PPM, so the whole flow can be tested without a display.
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
    static constexpr int ROWS = 9;
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

    bool quit = false;
    int exitCode = 0;  // 0 = installed, desktop can start; 1 = aborted or failed

    Scr screen() const { return scr; }

private:
    // data
    ListView locales, layouts, zones, apps;
    std::string host = "pixeldots", user, pw1, pw2, err;
    int field = 0;      // active text field on Account
    int lookRow = 0, modeIdx = 0, variantIdx = 0;
    bool autostart = true;
    int menu = 0;       // Welcome
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

    void header(Canvas& c, const char* title, const char* sub);
    void footer(Canvas& c, const std::string& hint);
    void drawList(Canvas& c, ListView& l, bool checks);
    void drawField(Canvas& c, int x, int y, int w, const std::string& label, const std::string& val, bool active, bool secret);
    void drawWelcome(Canvas& c);
    void drawHost(Canvas& c);
    void drawAccount(Canvas& c);
    void drawLook(Canvas& c);
    void drawSummary(Canvas& c);
    void drawInstall(Canvas& c);
    void drawDone(Canvas& c);
    void drawFailed(Canvas& c);
};

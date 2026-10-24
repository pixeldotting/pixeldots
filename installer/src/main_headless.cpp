// Display-less driver for tests: runs a script of tokens against the App and dumps frames as PPM.
//   pixeldots-installer-headless <data-dir> <script-file>
// tokens (whitespace separated): up down left right enter esc bksp tab pgup pgdn home end
//   type:<text>   wait:<seconds>   shot:<file.ppm>   expect:<screen>   (expect aborts with exit 3 on mismatch)
//   click:<x>,<y> window pixels   clicku:<x>,<y> design units (1080x1500)   wheel:<+-n>
// window size from env PD_SIZE (default 1600x900)
#include <chrono>
#include <csignal>
#include <cstdlib>
#include <cstdio>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <unistd.h>
#include "app.hpp"

static const char* name(Scr s) {
    switch (s) {
        case Scr::Welcome: return "welcome"; case Scr::Locale: return "locale"; case Scr::Layout: return "layout";
        case Scr::Timezone: return "timezone"; case Scr::Hostname: return "hostname"; case Scr::Account: return "account";
        case Scr::Apps: return "apps"; case Scr::Look: return "look"; case Scr::Summary: return "summary";
        case Scr::Install: return "install"; case Scr::Done: return "done"; case Scr::Failed: return "failed";
    }
    return "?";
}

int main(int argc, char** argv) {
    if (argc < 3) { std::fprintf(stderr, "usage: %s <data-dir> <script>\n", argv[0]); return 2; }
    signal(SIGPIPE, SIG_IGN);
    App app(argv[1]);
    if (!app.fontOk()) { std::fprintf(stderr, "font.sdf not found in %s\n", argv[1]); return 2; }
    int cw = 1600, ch = 900;
    if (const char* sz = std::getenv("PD_SIZE")) std::sscanf(sz, "%dx%d", &cw, &ch);
    Canvas cv(cw, ch);
    app.draw(cv);
    std::ifstream f(argv[2]);
    std::map<std::string, K> keys = {{"up", K::Up}, {"down", K::Down}, {"left", K::Left}, {"right", K::Right},
                                     {"enter", K::Enter}, {"esc", K::Esc}, {"bksp", K::Backspace}, {"tab", K::Tab},
                                     {"pgup", K::PgUp}, {"pgdn", K::PgDn}, {"home", K::Home}, {"end", K::End}};
    std::string tok;
    while (f >> tok) {
        if (tok[0] == '#') { std::getline(f, tok); continue; }
        auto colon = tok.find(':');
        std::string cmd = tok.substr(0, colon), arg = colon == std::string::npos ? "" : tok.substr(colon + 1);
        if (keys.count(cmd)) app.key(keys[cmd]);
        else if (cmd == "type") { for (auto& ch : arg) if (ch == '_') ch = ' '; app.text(arg); }
        else if (cmd == "wait") {
            double left = std::stod(arg);
            while (left > 0) { app.tick(0.05); left -= 0.05; usleep(50000); }
        } else if (cmd == "click" || cmd == "clicku") {
            float x = 0, y = 0;
            std::sscanf(arg.c_str(), "%f,%f", &x, &y);
            app.draw(cv);  // hit regions of the current screen
            if (cmd == "clicku") { x = app.lastOx + x * app.lastU; y = app.lastOy + y * app.lastU; }
            app.click(x, y);
        } else if (cmd == "bench") {
            int n = std::stoi(arg);
            auto t0 = std::chrono::steady_clock::now();
            for (int i = 0; i < n; i++) { app.tick(0.05); app.draw(cv); }  // worst case: background recomputed every frame
            double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count() / n;
            std::printf("draw %dx%d: %.1f ms/frame\n", cv.w, cv.h, ms);
        } else if (cmd == "benchui") {
            int n = std::stoi(arg);
            app.draw(cv);
            auto t0 = std::chrono::steady_clock::now();
            for (int i = 0; i < n; i++) app.draw(cv);  // background cached: UI cost only
            double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count() / n;
            std::printf("ui-only %dx%d: %.1f ms/frame\n", cv.w, cv.h, ms);
        } else if (cmd == "wheel") {
            app.wheel(std::stoi(arg));
        } else if (cmd == "shot") {
            app.tick(2.0);  // let the blobs settle
            app.draw(cv);
            FILE* o = std::fopen(arg.c_str(), "wb");
            std::fprintf(o, "P6\n%d %d\n255\n", cv.w, cv.h);
            for (uint32_t p : cv.px) { unsigned char rgb[3] = {(unsigned char)(p >> 16), (unsigned char)(p >> 8), (unsigned char)p}; std::fwrite(rgb, 1, 3, o); }
            std::fclose(o);
        } else if (cmd == "expect") {
            if (arg != name(app.screen())) { std::fprintf(stderr, "expected screen %s, got %s\n", arg.c_str(), name(app.screen())); return 3; }
        } else { std::fprintf(stderr, "unknown token %s\n", tok.c_str()); return 2; }
        app.tick(0.0);
        if (app.quit) break;
    }
    std::printf("quit=%d exit=%d screen=%s\n", app.quit, app.exitCode, name(app.screen()));
    return 0;
}

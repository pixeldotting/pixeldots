#include "app.hpp"

#include <cctype>
#include <cerrno>
#include <cstdlib>
#include <fcntl.h>
#include <fstream>
#include <sstream>
#include <sys/wait.h>
#include <unistd.h>

namespace {

const char* const MODES[] = {"dark", "light"};
const char* const VARIANTS[] = {"tonal-spot", "expressive", "content", "fidelity",
                                "fruit-salad", "monochrome", "neutral", "rainbow"};
constexpr int NMODES = 2, NVARIANTS = 8;

std::string lower(std::string s) {
    for (auto& ch : s) ch = (char)std::tolower((unsigned char)ch);
    return s;
}

std::string clip(const std::string& s, size_t n) {
    if (s.size() <= n) return s;
    return n < 2 ? s.substr(0, n) : s.substr(0, n - 1) + ".";
}

std::vector<std::string> readLines(const std::string& path) {
    std::vector<std::string> out;
    std::ifstream f(path);
    std::string l;
    while (std::getline(f, l)) {
        if (!l.empty() && l.back() == '\r') l.pop_back();
        if (!l.empty() && l[0] != '#') out.push_back(l);
    }
    return out;
}

std::vector<std::string> split(const std::string& s, char d) {
    std::vector<std::string> out;
    std::string cur;
    std::istringstream is(s);
    while (std::getline(is, cur, d)) out.push_back(cur);
    return out;
}

std::string getenvOr(const char* k, const std::string& dflt) {
    const char* v = std::getenv(k);
    return (v && *v) ? v : dflt;
}

// Current system time zone, so the list can start on it (best effort).
std::string currentZone() {
    char buf[256];
    ssize_t n = readlink("/etc/localtime", buf, sizeof buf - 1);
    if (n > 0) {
        std::string p(buf, n);
        auto i = p.find("zoneinfo/");
        if (i != std::string::npos) return p.substr(i + 9);
    }
    return "UTC";
}

bool hostOk(const std::string& h) {
    if (h.empty() || h.size() > 63 || h.front() == '-' || h.back() == '-') return false;
    for (char ch : h)
        if (!std::isalnum((unsigned char)ch) && ch != '-') return false;
    return true;
}

}  // namespace

// ───────────────────────── ListView ─────────────────────────

void ListView::refilter() {
    vis.clear();
    std::string f = lower(filter);
    for (size_t i = 0; i < items.size(); i++)
        if (f.empty() || lower(items[i].id + " " + items[i].label).find(f) != std::string::npos) vis.push_back((int)i);
    cur = top = 0;
}

void ListView::move(int d) {
    if (vis.empty()) return;
    cur = std::max(0, std::min((int)vis.size() - 1, cur + d));
    if (cur < top) top = cur;
    if (cur >= top + ROWS) top = cur - ROWS + 1;
}

bool ListView::select(const std::string& id) {
    for (size_t i = 0; i < vis.size(); i++)
        if (items[vis[i]].id == id) {
            cur = (int)i;
            top = std::max(0, cur - ROWS / 2);
            if (top + ROWS > (int)vis.size()) top = std::max(0, (int)vis.size() - ROWS);
            return true;
        }
    return false;
}

// ───────────────────────── App ─────────────────────────

App::App(const std::string& dataDir) {
    auto pairs = [&](const std::string& file, ListView& lv) {
        for (auto& l : readLines(dataDir + "/" + file)) {
            auto p = split(l, '|');
            Item it;
            it.id = p[0];
            it.label = p.size() > 1 ? p[1] : p[0];
            lv.items.push_back(it);
        }
        lv.refilter();
    };
    pairs("locales.txt", locales);
    pairs("layouts.txt", layouts);
    for (auto& l : readLines(dataDir + "/timezones.txt")) zones.items.push_back({l, "", "", false, false});
    zones.refilter();
    for (auto& l : readLines(dataDir + "/apps.tsv")) {
        auto p = split(l, '|');
        if (p.size() < 5) continue;
        Item it;
        it.id = p[0];
        it.label = p[1];
        it.attr = p[2];
        it.unfree = p[3] == "1";
        it.on = p[4] == "1";
        apps.items.push_back(it);
    }
    apps.refilter();

    locales.select(getenvOr("PD_DEFAULT_LOCALE", "en_US.UTF-8"));
    layouts.select(getenvOr("PD_DEFAULT_LAYOUT", "us"));
    if (!zones.select(getenvOr("PD_DEFAULT_TZ", currentZone()))) zones.select("UTC");
    user = getenvOr("PD_DEFAULT_USER", getenvOr("USER", "user"));
    applyPath = getenvOr("PD_APPLY", dataDir + "/../apply.sh");
    logPath = getenvOr("PD_LOG", "");
}

App::~App() {
    if (child > 0) {
        kill(child, SIGTERM);
        waitpid(child, nullptr, 0);
    }
    if (outFd >= 0) close(outFd);
}

std::string App::selId(const ListView& l) const { return l.sel() ? l.sel()->id : ""; }
std::string App::selLabel(const ListView& l) const {
    return l.sel() ? (l.sel()->label.empty() ? l.sel()->id : l.sel()->label) : "";
}

std::string App::appIds() const {
    std::string s;
    for (auto& it : apps.items)
        if (it.on) s += (s.empty() ? "" : ",") + it.id;
    return s;
}

ListView* App::activeList() {
    switch (scr) {
        case Scr::Locale: return &locales;
        case Scr::Layout: return &layouts;
        case Scr::Timezone: return &zones;
        case Scr::Apps: return &apps;
        default: return nullptr;
    }
}

void App::go(Scr s) {
    scr = s;
    err.clear();
}

void App::next() {
    switch (scr) {
        case Scr::Welcome: go(Scr::Locale); break;
        case Scr::Locale: go(Scr::Layout); break;
        case Scr::Layout: go(Scr::Timezone); break;
        case Scr::Timezone: go(Scr::Hostname); break;
        case Scr::Hostname: go(Scr::Account); break;
        case Scr::Account: go(Scr::Apps); break;
        case Scr::Apps: go(Scr::Look); break;
        case Scr::Look: go(Scr::Summary); break;
        default: break;
    }
}

void App::back() {
    switch (scr) {
        case Scr::Locale: go(Scr::Welcome); break;
        case Scr::Layout: go(Scr::Locale); break;
        case Scr::Timezone: go(Scr::Layout); break;
        case Scr::Hostname: go(Scr::Timezone); break;
        case Scr::Account: go(Scr::Hostname); break;
        case Scr::Apps: go(Scr::Account); break;
        case Scr::Look: go(Scr::Apps); break;
        case Scr::Summary: go(Scr::Look); break;
        default: break;
    }
}

bool App::validate() {
    if (scr == Scr::Hostname) {
        if (!hostOk(host)) {
            err = "Use letters, digits and '-' (max 63, no leading/trailing '-').";
            return false;
        }
    } else if (scr == Scr::Account) {
        if (pw1.empty() && pw2.empty()) return true;  // keep the current password
        if (pw1.size() < 4) {
            err = "Password is too short (4+ characters).";
            return false;
        }
        if (pw1 != pw2) {
            err = "Passwords do not match.";
            return false;
        }
    }
    return true;
}

void App::listKey(ListView& l, K k) {
    switch (k) {
        case K::Up: l.move(-1); break;
        case K::Down: l.move(1); break;
        case K::PgUp: l.move(-ListView::ROWS); break;
        case K::PgDn: l.move(ListView::ROWS); break;
        case K::Home: l.move(-1000000); break;
        case K::End: l.move(1000000); break;
        case K::Backspace:
            if (!l.filter.empty()) {
                l.filter.pop_back();
                l.refilter();
            }
            break;
        case K::Enter:
            if (!l.vis.empty()) next();
            break;
        case K::Esc:
            if (!l.filter.empty()) {
                l.filter.clear();
                l.refilter();
            } else
                back();
            break;
        default: break;
    }
}

void App::key(K k) {
    switch (scr) {
        case Scr::Welcome:
            if (k == K::Up || k == K::Down) menu = 1 - menu;
            if (k == K::Enter) {
                if (menu == 0) next();
                else { quit = true; exitCode = 1; }
            }
            break;
        case Scr::Locale:
        case Scr::Layout:
        case Scr::Timezone:
        case Scr::Apps:
            listKey(*activeList(), k);
            break;
        case Scr::Hostname:
            if (k == K::Backspace && !host.empty()) host.pop_back();
            if (k == K::Enter && validate()) next();
            if (k == K::Esc) back();
            break;
        case Scr::Account:
            if (k == K::Backspace) {
                std::string& f = field == 0 ? pw1 : pw2;
                if (!f.empty()) f.pop_back();
            }
            if (k == K::Up || (k == K::Tab && field == 1)) field = 0;
            if (k == K::Down || (k == K::Tab && field == 0)) field = 1;
            if (k == K::Enter) {
                if (field == 0) field = 1;
                else if (validate()) next();
            }
            if (k == K::Esc) back();
            break;
        case Scr::Look:
            if (k == K::Up) lookRow = std::max(0, lookRow - 1);
            if (k == K::Down) lookRow = std::min(2, lookRow + 1);
            if (k == K::Left || k == K::Right) {
                int d = k == K::Right ? 1 : -1;
                if (lookRow == 0) modeIdx = (modeIdx + d + NMODES) % NMODES;
                if (lookRow == 1) variantIdx = (variantIdx + d + NVARIANTS) % NVARIANTS;
                if (lookRow == 2) autostart = !autostart;
            }
            if (k == K::Enter) next();
            if (k == K::Esc) back();
            break;
        case Scr::Summary:
            if (k == K::Enter) {
                go(Scr::Install);
                if (!startInstall()) go(Scr::Failed);
            }
            if (k == K::Esc) back();
            break;
        case Scr::Install: break;  // no way out while the system is being rebuilt
        case Scr::Done:
            if (k == K::Enter) { quit = true; exitCode = 0; }
            break;
        case Scr::Failed:
            if (k == K::Enter) {
                go(Scr::Install);
                if (!startInstall()) go(Scr::Failed);
            }
            if (k == K::Esc) { quit = true; exitCode = 1; }
            break;
    }
}

void App::text(const std::string& s) {
    for (char ch : s) {
        if (ch < 32 || ch > 126) continue;
        if (ListView* l = activeList(); l && scr != Scr::Apps) {
            if (ch == ' ' && l->filter.empty()) continue;
            l->filter += ch;
            l->refilter();
        } else if (scr == Scr::Apps) {
            if (ch == ' ')
                if (Item* it = apps.selMut()) it->on = !it->on;
        } else if (scr == Scr::Hostname) {
            if ((std::isalnum((unsigned char)ch) || ch == '-') && host.size() < 63) host += ch;
        } else if (scr == Scr::Account) {
            std::string& f = field == 0 ? pw1 : pw2;
            if (f.size() < 64) f += ch;
        } else if (scr == Scr::Look && ch == ' ') {
            key(K::Right);
        }
    }
}

// ───────────────────────── install child ─────────────────────────

bool App::startInstall() {
    log.clear();
    buf.clear();
    pct = 0;
    msg = "Starting";
    int in[2], out[2];
    if (pipe(in) != 0) { msg = "pipe() failed"; return false; }
    if (pipe(out) != 0) { close(in[0]); close(in[1]); msg = "pipe() failed"; return false; }
    pid_t p = fork();
    if (p < 0) {
        close(in[0]); close(in[1]); close(out[0]); close(out[1]);
        msg = "fork() failed";
        return false;
    }
    if (p == 0) {
        dup2(in[0], 0);
        dup2(out[1], 1);
        dup2(out[1], 2);
        close(in[0]); close(in[1]); close(out[0]); close(out[1]);
        setenv("PD_LOCALE", selId(locales).c_str(), 1);
        setenv("PD_LAYOUT", selId(layouts).c_str(), 1);
        setenv("PD_TZ", selId(zones).c_str(), 1);
        setenv("PD_HOSTNAME", host.c_str(), 1);
        setenv("PD_USER", user.c_str(), 1);
        setenv("PD_APPS", appIds().c_str(), 1);
        setenv("PD_MODE", MODES[modeIdx], 1);
        setenv("PD_VARIANT", (std::string("scheme-") + VARIANTS[variantIdx]).c_str(), 1);
        setenv("PD_AUTOSTART", autostart ? "1" : "0", 1);
        execlp("bash", "bash", applyPath.c_str(), (char*)nullptr);
        _exit(127);
    }
    close(in[0]);
    close(out[1]);
    // The password goes through a pipe, never through argv, env or a file.
    std::string line = pw1 + "\n";
    ssize_t w = write(in[1], line.data(), line.size());
    (void)w;
    close(in[1]);
    fcntl(out[0], F_SETFL, O_NONBLOCK);
    outFd = out[0];
    child = p;
    return true;
}

void App::consume() {
    for (;;) {
        size_t e = buf.find_first_of("\r\n");
        if (e == std::string::npos) break;
        std::string raw = buf.substr(0, e);
        buf.erase(0, e + 1);
        std::string l;
        for (size_t i = 0; i < raw.size(); i++) {  // strip ANSI escapes, keep printable ASCII
            unsigned char ch = (unsigned char)raw[i];
            if (ch == 0x1b) {
                if (i + 1 < raw.size() && raw[i + 1] == '[') {
                    i += 2;
                    while (i < raw.size() && !(raw[i] >= '@' && raw[i] <= '~')) i++;
                }
                continue;
            }
            if (ch == '\t') l += ' ';
            else if (ch >= 32 && ch <= 126) l += (char)ch;
            else if (ch >= 128) l += '?';
        }
        if (l.empty()) continue;
        if (l.compare(0, 3, "@@ ") == 0) {
            std::istringstream is(l.substr(3));
            int v = 0;
            if (is >> v) {
                pct = std::max(0, std::min(100, v));
                std::getline(is, msg);
                if (!msg.empty() && msg[0] == ' ') msg.erase(0, 1);
                l = "> " + msg;
            }
        }
        log.push_back(l);
        if (log.size() > 200) log.erase(log.begin(), log.begin() + 100);
    }
}

void App::finishChild() {
    int st = 0;
    waitpid(child, &st, 0);
    child = -1;
    close(outFd);
    outFd = -1;
    bool ok = WIFEXITED(st) && WEXITSTATUS(st) == 0;
    if (ok) pct = 100;
    else msg = WIFEXITED(st) ? "Install script exited with code " + std::to_string(WEXITSTATUS(st)) : "Install script was killed";
    go(ok ? Scr::Done : Scr::Failed);
}

void App::tick(double dt) {
    t += dt;
    if (scr != Scr::Install || outFd < 0) return;
    char tmp[4096];
    bool eof = false;
    for (;;) {
        ssize_t n = read(outFd, tmp, sizeof tmp);
        if (n > 0) buf.append(tmp, (size_t)n);
        else if (n == 0) { eof = true; break; }
        else { if (errno != EAGAIN && errno != EINTR) eof = true; break; }
    }
    consume();
    if (eof) {
        if (!buf.empty()) { buf += '\n'; consume(); }
        finishChild();
    }
}

// ───────────────────────── drawing ─────────────────────────

void App::header(Canvas& c, const char* title, const char* sub) {
    c.text(8, 5, "pixeldots", pal::primary);
    c.text(8 + 6 * 9 + 4, 5, "setup", pal::dim);
    int step = 0;
    switch (scr) {
        case Scr::Locale: step = 1; break;
        case Scr::Layout: step = 2; break;
        case Scr::Timezone: step = 3; break;
        case Scr::Hostname: step = 4; break;
        case Scr::Account: step = 5; break;
        case Scr::Apps: step = 6; break;
        case Scr::Look: step = 7; break;
        case Scr::Summary: step = 8; break;
        default: break;
    }
    for (int i = 1; i <= 8; i++) {  // step squares
        int x = 312 - (9 - i) * 9;
        if (i < step) c.rect(x, 6, 6, 6, pal::primary);
        else if (i == step) c.rect(x, 6, 6, 6, pal::pink);
        else c.rect(x, 6, 6, 6, pal::line);
    }
    c.rect(8, 16, 304, 1, pal::line);
    c.text(8, 22, title, pal::text, 2);
    if (sub && *sub) c.text(8, 40, sub, pal::dim);
}

void App::footer(Canvas& c, const std::string& hint) {
    c.rect(8, 164, 304, 1, pal::line);
    c.text(8, 169, hint, pal::dim);
}

void App::drawList(Canvas& c, ListView& l, bool checks) {
    const int x = 8, y = 52, w = 304, h = ListView::ROWS * 10 + 6;
    c.pbox(x, y, w, h, pal::panel, pal::line);
    if (l.vis.empty()) {
        c.text(x + 8, y + 8, "No matches", pal::dim);
        return;
    }
    for (int r = 0; r < ListView::ROWS; r++) {
        int i = l.top + r;
        if (i >= (int)l.vis.size()) break;
        const Item& it = l.items[l.vis[i]];
        int ry = y + 3 + r * 10;
        bool sel = i == l.cur;
        if (sel) {
            c.rect(x + 2, ry, w - 8, 10, pal::panel2);
            c.rect(x + 2, ry, 2, 10, pal::pink);
        }
        int tx = x + 10;
        if (checks) {
            c.rect(tx, ry + 1, 7, 7, pal::line);
            c.rect(tx + 1, ry + 2, 5, 5, pal::panel);
            if (it.on) c.rect(tx + 2, ry + 3, 3, 3, pal::teal);
            tx += 12;
        }
        uint32_t col = sel ? pal::text : pal::dim;
        std::string main = it.label.empty() ? it.id : it.label;
        c.text(tx, ry + 1, clip(main, checks ? 30 : 46), col);
        if (!it.label.empty() && !checks) c.textRight(x + w - 14, ry + 1, clip(it.id, 18), sel ? pal::primary : pal::line);
        if (checks && it.unfree) c.textRight(x + w - 14, ry + 1, "unfree", pal::warn);
    }
    if ((int)l.vis.size() > ListView::ROWS) {  // scrollbar
        int th = std::max(6, (h - 8) * ListView::ROWS / (int)l.vis.size());
        int ty = y + 4 + (h - 8 - th) * l.top / std::max(1, (int)l.vis.size() - ListView::ROWS);
        c.rect(x + w - 5, ty, 2, th, pal::primary);
    }
}

void App::drawField(Canvas& c, int x, int y, int w, const std::string& label, const std::string& val, bool active, bool secret) {
    c.text(x, y - 11, label, active ? pal::primary : pal::dim);
    c.pbox(x, y, w, 15, pal::panel, active ? pal::pink : pal::line);
    std::string shown = secret ? std::string(val.size(), '*') : val;
    size_t maxc = (size_t)(w - 14) / 6;
    if (shown.size() > maxc) shown = shown.substr(shown.size() - maxc);
    c.text(x + 5, y + 4, shown, pal::text);
    if (active && ((int)(t * 2) % 2 == 0)) c.rect(x + 5 + Canvas::textWidth(shown) + (shown.empty() ? 0 : 1), y + 3, 5, 9, pal::pink);
}

void App::drawWelcome(Canvas& c) {
    c.textCenter(34, "pixeldots", pal::primary, 4);
    static const uint32_t cols[] = {pal::primary, pal::pink, pal::teal, pal::warn, pal::ok};
    for (int i = 0; i < 9; i++) {
        int phase = ((int)(t * 4) + i) % 5;
        c.rect(W / 2 - 44 + i * 10, 70, 6, 6, cols[phase]);
    }
    c.textCenter(86, "Material You desktop for NixOS", pal::dim);
    static const char* const items[] = {"Start setup", "Quit"};
    for (int i = 0; i < 2; i++) {
        int y = 112 + i * 14;
        bool sel = menu == i;
        if (sel) c.rect(W / 2 - 50, y - 2, 100, 12, pal::panel2);
        c.textCenter(y, items[i], sel ? pal::text : pal::dim);
        if (sel) c.text(W / 2 - 46, y, ">", pal::pink);
    }
    footer(c, "Up/Down choose   Enter confirm");
}

void App::drawHost(Canvas& c) {
    c.text(8, 54, "How should this computer be called on the network?", pal::dim);
    drawField(c, 8, 82, 200, "Computer name", host, true, false);
    if (!err.empty()) c.text(8, 106, err, pal::bad);
}

void App::drawAccount(Canvas& c) {
    c.text(8, 54, "Account", pal::dim);
    c.pbox(8, 64, 200, 15, pal::panel2, pal::line);
    c.text(13, 68, user, pal::primary);
    c.textRight(203, 68, "current user", pal::dim);
    drawField(c, 8, 100, 200, "New password (optional)", pw1, field == 0, true);
    drawField(c, 8, 128, 200, "Repeat password", pw2, field == 1, true);
    if (err.empty()) c.text(8, 150, "Leave both empty to keep your current password.", pal::dim);
    else c.text(8, 150, err, pal::bad);
}

void App::drawLook(Canvas& c) {
    struct Row { const char* label; std::string val; };
    Row rows[3] = {{"Scheme mode", MODES[modeIdx]},
                   {"Palette style", VARIANTS[variantIdx]},
                   {"Start Hyprland on tty1 login", autostart ? "yes" : "no"}};
    for (int i = 0; i < 3; i++) {
        int y = 56 + i * 28;
        bool sel = lookRow == i;
        c.pbox(8, y, 304, 22, sel ? pal::panel2 : pal::panel, sel ? pal::pink : pal::line);
        c.text(16, y + 7, rows[i].label, sel ? pal::text : pal::dim);
        std::string v = "< " + rows[i].val + " >";
        c.textRight(304, y + 7, v, sel ? pal::primary : pal::dim);
    }
    c.text(8, 146, "Colours come from your wallpaper (matugen).", pal::dim);
}

void App::drawSummary(Canvas& c) {
    int napps = 0;
    for (auto& a : apps.items) napps += a.on;
    struct Row { const char* k; std::string v; };
    Row rows[] = {
        {"Language", selLabel(locales)},
        {"Keyboard", selLabel(layouts)},
        {"Time zone", selId(zones)},
        {"Computer", host},
        {"User", user + (pw1.empty() ? " (password kept)" : " (new password)")},
        {"Apps", std::to_string(napps) + " selected"},
        {"Look", std::string(MODES[modeIdx]) + ", " + VARIANTS[variantIdx]},
        {"Desktop", autostart ? "starts on tty1 login" : "start Hyprland by hand"},
    };
    int y = 50;
    for (auto& r : rows) {
        c.text(8, y, r.k, pal::dim);
        c.text(80, y, clip(r.v, 38), pal::text);
        y += 11;
    }
    c.text(8, 142, "Runs nixos-rebuild switch (network, takes a while)", pal::warn);
    c.text(8, 152, "Existing /etc/nixos files are left untouched.", pal::dim);
}

void App::drawInstall(Canvas& c) {
    c.pbox(8, 52, 304, 12, pal::panel, pal::line);
    c.rect(11, 55, (298 * pct) / 100, 6, pal::primary);
    c.textRight(308, 68, std::to_string(pct) + "%", pal::dim);
    c.text(8, 68, clip(msg, 44), pal::text);
    c.pbox(8, 80, 304, 80, pal::panel, pal::line);
    int n = (int)log.size(), rows = 7, first = std::max(0, n - rows);
    for (int i = first; i < n; i++) c.text(14, 85 + (i - first) * 10, clip(log[i], 49), pal::dim);
}

void App::drawDone(Canvas& c) {
    c.textCenter(46, "All set!", pal::pink, 4);
    c.textCenter(86, "The desktop is installed.", pal::text);
    c.textCenter(98, "Enter leaves the installer and starts Hyprland.", pal::dim);
    if ((int)(t * 2) % 2 == 0) c.textCenter(126, "Press Enter", pal::primary);
}

void App::drawFailed(Canvas& c) {
    c.pbox(8, 52, 304, 100, pal::panel, pal::bad);
    c.text(14, 57, msg.empty() ? "The install script failed." : clip(msg, 49), pal::bad);
    int n = (int)log.size(), rows = 8, first = std::max(0, n - rows);
    for (int i = first; i < n; i++) c.text(14, 70 + (i - first) * 10, clip(log[i], 49), pal::dim);
}

void App::draw(Canvas& c) {
    c.clear(pal::bg);
    switch (scr) {
        case Scr::Welcome: drawWelcome(c); return;
        case Scr::Locale:
            header(c, "Language", "System language and formats");
            break;
        case Scr::Layout: header(c, "Keyboard", "Layout used in the console and in Hyprland"); break;
        case Scr::Timezone: header(c, "Time zone", "Type to search, e.g. berlin"); break;
        case Scr::Hostname: header(c, "Computer", nullptr); break;
        case Scr::Account: header(c, "You", nullptr); break;
        case Scr::Apps: header(c, "Apps", "Space to toggle. Base apps are always installed"); break;
        case Scr::Look: header(c, "Look", "Change later with material-theme"); break;
        case Scr::Summary: header(c, "Ready?", nullptr); break;
        case Scr::Install: header(c, "Installing", "Do not power off"); break;
        case Scr::Done: header(c, "Done", nullptr); break;
        case Scr::Failed: header(c, "Failed", "Nothing was undone: fix the problem and retry"); break;
    }
    ListView* l = activeList();
    if (l && scr != Scr::Apps) {
        c.pbox(188, 22, 124, 14, pal::panel, l->filter.empty() ? pal::line : pal::pink);
        std::string f = l->filter.empty() ? "type to search" : l->filter;
        c.text(193, 26, clip(f, 18), l->filter.empty() ? pal::line : pal::text);
    }
    switch (scr) {
        case Scr::Locale: case Scr::Layout: case Scr::Timezone: drawList(c, *l, false); footer(c, "Up/Down move   Enter next   Esc back"); break;
        case Scr::Apps: drawList(c, apps, true); footer(c, "Up/Down move   Space toggle   Enter next   Esc back"); break;
        case Scr::Hostname: drawHost(c); footer(c, "Enter next   Esc back"); break;
        case Scr::Account: drawAccount(c); footer(c, "Tab switch field   Enter next   Esc back"); break;
        case Scr::Look: drawLook(c); footer(c, "Up/Down row   Left/Right change   Enter next"); break;
        case Scr::Summary: drawSummary(c); footer(c, "Enter install   Esc back"); break;
        case Scr::Install: drawInstall(c); footer(c, logPath.empty() ? "Full log: see apply.sh output" : "Full log: " + logPath); break;
        case Scr::Done: drawDone(c); footer(c, "Enter continue"); break;
        case Scr::Failed: drawFailed(c); footer(c, "Enter retry   Esc quit" + (logPath.empty() ? std::string() : "   log: " + clip(logPath, 30))); break;
        default: break;
    }
}

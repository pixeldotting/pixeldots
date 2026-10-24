#include "app.hpp"

#include <cctype>
#include <cerrno>
#include <cstdio>
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

// Same rules as the backend (installer/install-iso.sh checks them again before anything is written).
bool userOk(const std::string& u) {
    if (u.empty() || u.size() > 32 || u == "root") return false;
    if (!(std::islower((unsigned char)u[0]) || u[0] == '_')) return false;
    for (char ch : u)
        if (!(std::islower((unsigned char)ch) || std::isdigit((unsigned char)ch) || ch == '_' || ch == '-')) return false;
    return true;
}

std::string humanSize(unsigned long long b) {
    const char* unit[] = {"B", "KiB", "MiB", "GiB", "TiB"};
    double v = (double)b;
    int i = 0;
    while (v >= 1024 && i < 4) { v /= 1024; i++; }
    char buf[32];
    std::snprintf(buf, sizeof buf, i >= 3 ? "%.1f %s" : "%.0f %s", v, unit[i]);
    return buf;
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
    if (cur >= top + rows) top = cur - rows + 1;
}

bool ListView::select(const std::string& id) {
    for (size_t i = 0; i < vis.size(); i++)
        if (items[vis[i]].id == id) {
            cur = (int)i;
            top = std::max(0, cur - rows / 2);
            if (top + rows > (int)vis.size()) top = std::max(0, (int)vis.size() - rows);
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
    apps.rows = 7;
    font.load(dataDir + "/font.sdf");

    locales.select(getenvOr("PD_DEFAULT_LOCALE", "en_US.UTF-8"));
    layouts.select(getenvOr("PD_DEFAULT_LAYOUT", "us"));
    if (!zones.select(getenvOr("PD_DEFAULT_TZ", currentZone()))) zones.select("UTC");
    iso = getenvOr("PD_ISO", "") == "1";
    user = iso ? "" : getenvOr("PD_DEFAULT_USER", getenvOr("USER", "user"));  // ISO: the new user's name is typed, never defaulted
    disksCmd = getenvOr("PD_DISKS_CMD", "pixeldots-disks");
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
    showInfo = false;
    bg.setScreen((int)s);
}

int App::step() const {
    switch (scr) {
        case Scr::Locale: return 1;
        case Scr::Layout: return 2;
        case Scr::Timezone: return 3;
        case Scr::Hostname: return 4;
        case Scr::Account: return 5;
        case Scr::Apps: return 6;
        case Scr::Look: return 7;
        case Scr::Summary: return 8;
        default: return 0;
    }
}

std::string App::stepText() const {
    int n = 0;
    switch (scr) {
        case Scr::Locale: n = 1; break;
        case Scr::Layout: n = 2; break;
        case Scr::Timezone: n = 3; break;
        case Scr::Hostname: n = 4; break;
        case Scr::Account: n = 5; break;
        case Scr::Apps: n = 6; break;
        case Scr::Look: n = 7; break;
        case Scr::Disk: n = 8; break;
        case Scr::Summary: n = iso ? 9 : 8; break;
        case Scr::Erase: n = 10; break;
        default: return "pixeldots";
    }
    return "Step " + std::to_string(n) + " of " + (iso ? "10" : "8");
}

std::string& App::fieldRef() {
    if (iso) return field == 0 ? user : field == 1 ? pw1 : pw2;
    return field == 0 ? pw1 : pw2;
}

const Item* App::pickedDisk() const {
    for (auto& it : disks.items)
        if (it.id == diskPick) return &it;
    return nullptr;
}

// Disks come from `pixeldots-disks` (installer/disks.sh): one "name|model|size_bytes|transport|removable" per line,
// or a single "ERR|message". The UI only ever offers what that script prints, the backend asks it again.
void App::loadDisks() {
    disks.items.clear();
    diskErr.clear();
    if (FILE* p = popen(disksCmd.c_str(), "r")) {
        char line[512];
        while (std::fgets(line, sizeof line, p)) {
            std::string l = line;
            while (!l.empty() && (l.back() == '\n' || l.back() == '\r')) l.pop_back();
            auto f = split(l, '|');
            if (f.size() >= 2 && f[0] == "ERR") { diskErr = f[1]; continue; }
            if (f.size() < 5) continue;
            bool nameOk = !f[0].empty();
            for (char ch : f[0]) nameOk = nameOk && (std::islower((unsigned char)ch) || std::isdigit((unsigned char)ch));
            if (!nameOk) continue;  // never show or pass on a name that is not a plain kernel device name
            Item it;
            it.id = f[0];
            for (char ch : f[1]) it.label += (ch >= 32 && ch <= 126 && ch != '|') ? ch : '?';
            it.attr = f[2] + "|" + f[3] + "|" + f[4];
            disks.items.push_back(it);
        }
        pclose(p);
    } else {
        diskErr = "Could not list disks.";
    }
    disks.refilter();
    if (!pickedDisk()) diskPick.clear();  // the chosen disk vanished: choose again
    if (disks.items.empty() && diskErr.empty()) diskErr = "No suitable disk found (it must be 20 GiB or more and not the installation medium).";
}

// What the primary button / Enter does on the current screen.
void App::advance() {
    switch (scr) {
        case Scr::Welcome: next(); break;
        case Scr::Locale: case Scr::Layout: case Scr::Timezone:
            if (activeList() && !activeList()->vis.empty()) next();
            break;
        case Scr::Hostname: case Scr::Account:
            if (validate()) next();
            break;
        case Scr::Apps: case Scr::Look: next(); break;
        case Scr::Disk:
            if (validate()) next();
            break;
        case Scr::Summary:
            if (iso) { go(Scr::Erase); break; }  // ISO: erasing needs its own confirmation screen
            go(Scr::Install);
            if (!startInstall()) go(Scr::Failed);
            break;
        case Scr::Erase:
            if (!eraseOn) { err = "Turn the switch on to confirm."; break; }
            go(Scr::Install);
            if (!startInstall()) go(Scr::Failed);
            break;
        case Scr::Failed:
            go(Scr::Install);
            if (!startInstall()) go(Scr::Failed);
            break;
        case Scr::Done: quit = true; exitCode = 0; break;
        case Scr::Install: break;
    }
}

void App::next() {
    switch (scr) {
        case Scr::Welcome: go(Scr::Locale); break;
        case Scr::Locale: go(Scr::Layout); break;
        case Scr::Layout: go(Scr::Timezone); break;
        case Scr::Timezone: go(Scr::Hostname); break;
        case Scr::Hostname: field = 0; go(Scr::Account); break;
        case Scr::Account: go(Scr::Apps); break;
        case Scr::Apps: go(Scr::Look); break;
        case Scr::Look:
            if (iso) { loadDisks(); go(Scr::Disk); }
            else go(Scr::Summary);
            break;
        case Scr::Disk: go(Scr::Summary); break;
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
        case Scr::Disk: go(Scr::Look); break;
        case Scr::Summary: go(iso ? Scr::Disk : Scr::Look); break;
        case Scr::Erase: eraseOn = false; go(Scr::Summary); break;
        default: break;
    }
}

bool App::validate() {
    if (scr == Scr::Hostname) {
        if (!hostOk(host)) {
            err = "Use letters, digits and '-' (max 63, no leading/trailing '-').";
            return false;
        }
    } else if (scr == Scr::Disk) {
        if (!diskErr.empty() && disks.items.empty()) { err = diskErr; return false; }
        if (!pickedDisk()) { err = "Choose a disk first: Space or click on it."; return false; }
    } else if (scr == Scr::Account && iso) {
        if (!userOk(user)) {
            err = "User name: a-z, 0-9, '_' or '-', start with a letter (max 32).";
            return false;
        }
        if (pw1.size() < 6) { err = "Password is too short (6+ characters)."; return false; }
        if (pw1 != pw2) { err = "Passwords do not match."; return false; }
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
        case K::PgUp: l.move(-l.rows); break;
        case K::PgDn: l.move(l.rows); break;
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
    if (showInfo) {  // the help card swallows one key
        if (k == K::Esc || k == K::Enter) showInfo = false;
        return;
    }
    switch (scr) {
        case Scr::Welcome:
            if (k == K::Enter || k == K::Right) advance();
            if (k == K::Esc) { quit = true; exitCode = 1; }
            break;
        case Scr::Locale:
        case Scr::Layout:
        case Scr::Timezone:
        case Scr::Apps:
            if (k == K::Enter) advance();
            else listKey(*activeList(), k);
            break;
        case Scr::Hostname:
            if (k == K::Backspace && !host.empty()) host.pop_back();
            if (k == K::Enter) advance();
            if (k == K::Esc) back();
            break;
        case Scr::Account: {
            const int nf = iso ? 3 : 2;
            if (k == K::Backspace) {
                std::string& f = fieldRef();
                if (!f.empty()) f.pop_back();
            }
            if (k == K::Up) field = std::max(0, field - 1);
            if (k == K::Down) field = std::min(nf - 1, field + 1);
            if (k == K::Tab) field = (field + 1) % nf;
            if (k == K::Enter) {
                if (field < nf - 1) field++;
                else advance();
            }
            if (k == K::Esc) back();
            break;
        }
        case Scr::Disk:
            if (k == K::Enter) advance();
            else if (k == K::Esc) back();
            else listKey(disks, k);
            break;
        case Scr::Erase:
            if (k == K::Enter) advance();
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
            if (k == K::Enter) advance();
            if (k == K::Esc) back();
            break;
        case Scr::Summary:
            if (k == K::Enter) advance();
            if (k == K::Esc) back();
            break;
        case Scr::Install: break;  // no way out while the system is being rebuilt
        case Scr::Done:
            if (k == K::Enter) advance();
            break;
        case Scr::Failed:
            if (k == K::Enter) advance();
            if (k == K::Esc) { quit = true; exitCode = 1; }
            break;
    }
}

void App::click(float x, float y) {
    for (auto it = hits.rbegin(); it != hits.rend(); ++it) {
        if (x < it->x || y < it->y || x >= it->x + it->w || y >= it->y + it->h) continue;
        switch (it->act) {
            case HInfoClose: showInfo = false; break;
            case HInfo: showInfo = true; break;
            case HNext: advance(); break;
            case HBack: back(); break;
            case HQuit: quit = true; exitCode = 1; break;
            case HRow:
                if (ListView* l = activeList()) l->cur = it->arg;
                break;
            case HApp:
                apps.cur = it->arg;
                if (Item* a = apps.selMut()) a->on = !a->on;
                break;
            case HMode: lookRow = 0; modeIdx = it->arg; break;
            case HVariant: lookRow = 1; variantIdx = it->arg; break;
            case HAuto: lookRow = 2; autostart = !autostart; break;
            case HField: field = it->arg; break;
            case HDisk:
                disks.cur = it->arg;
                if (it->arg >= 0 && it->arg < (int)disks.items.size()) diskPick = disks.items[it->arg].id;
                err.clear();
                break;
            case HErase: eraseOn = !eraseOn; err.clear(); break;
        }
        return;
    }
}

void App::wheel(int dy) {
    if (scr == Scr::Disk) { disks.move(dy > 0 ? -1 : 1); return; }
    if (ListView* l = activeList()) l->move(dy > 0 ? -1 : 1);
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
        } else if (scr == Scr::Disk) {
            if (ch == ' ' && !disks.vis.empty()) { diskPick = disks.items[disks.vis[disks.cur]].id; err.clear(); }  // explicit choice only
        } else if (scr == Scr::Erase) {
            if (ch == ' ') { eraseOn = !eraseOn; err.clear(); }
        } else if (scr == Scr::Account) {
            std::string& f = fieldRef();
            if (iso && field == 0) {  // user name: lower-case letters, digits, _ and -
                char c = (char)std::tolower((unsigned char)ch);
                if ((std::islower((unsigned char)c) || std::isdigit((unsigned char)c) || c == '_' || c == '-') && f.size() < 32) f += c;
            } else if (f.size() < 64) {
                f += ch;
            }
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
        std::vector<std::pair<std::string, std::string>> envs = {
            {"PD_LOCALE", selId(locales)}, {"PD_LAYOUT", selId(layouts)}, {"PD_TZ", selId(zones)},
            {"PD_HOSTNAME", host}, {"PD_USER", user}, {"PD_APPS", appIds()}, {"PD_MODE", MODES[modeIdx]},
            {"PD_VARIANT", std::string("scheme-") + VARIANTS[variantIdx]}, {"PD_AUTOSTART", autostart ? "1" : "0"}};
        if (iso) {
            const Item* d = pickedDisk();
            std::string sz = d ? split(d->attr, '|')[0] : "";
            envs.push_back({"PD_DISK", d ? d->id : ""});
            envs.push_back({"PD_DISK_MODEL", d ? d->label : ""});
            envs.push_back({"PD_DISK_SIZE", sz});
            envs.push_back({"PD_ERASE_CONFIRM", eraseOn && d ? d->id : ""});  // set only after the Erase screen was confirmed
        }
        if (iso) {
            // The UI runs as the live user; the installer needs root. Values go through `env` (none of them is secret),
            // the password stays on stdin. PD_TEST_NO_SUDO exists for the headless tests only.
            std::vector<std::string> a;
            if (getenvOr("PD_TEST_NO_SUDO", "") != "1") { a.push_back("sudo"); a.push_back("-n"); }
            a.push_back("env");
            for (auto& kv : envs) a.push_back(kv.first + "=" + kv.second);
            a.push_back(applyPath);
            std::vector<char*> av;
            for (auto& x : a) av.push_back(const_cast<char*>(x.c_str()));
            av.push_back(nullptr);
            execvp(av[0], av.data());
        } else {
            for (auto& kv : envs) setenv(kv.first.c_str(), kv.second.c_str(), 1);
            execlp("bash", "bash", applyPath.c_str(), (char*)nullptr);
        }
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
        for (size_t pos; (pos = l.find("$6$")) != std::string::npos;) {  // defence in depth: a hash must never reach the screen
            size_t e = l.find_first_of(" \"'", pos);
            l = l.substr(0, pos) + "[hash hidden]" + (e == std::string::npos ? "" : l.substr(e));
        }
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
    bg.tick((float)dt);
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
// Design space is 1080 x 1500 units, scaled to the window and centred; blobs fill the whole window.

void App::rr(float x, float y, float w, float h, float r, uint32_t col, float a) { cv->rrect(PX(x), PY(y), w * u, h * u, r * u, col, a); }
void App::ring(float x, float y, float w, float h, float r, float t, uint32_t col, float a) { cv->ring(PX(x), PY(y), w * u, h * u, r * u, t * u, col, a); }
void App::cap(float x0, float y0, float x1, float y1, float t, uint32_t col, float a) { cv->capsule(PX(x0), PY(y0), PX(x1), PY(y1), t * u, col, a); }
float App::tw(const std::string& s, float size) const { return font.width(s, size * u) / u; }

std::string App::fit(const std::string& s, float size, float maxw) const {
    if (tw(s, size) <= maxw) return s;
    std::string r = s;
    while (!r.empty() && tw(r + "...", size) > maxw) {
        do r.pop_back(); while (!r.empty() && ((unsigned char)r.back() & 0xC0) == 0x80);  // whole UTF-8 characters
        if (!r.empty() && (unsigned char)r.back() >= 0xC0) r.pop_back();
    }
    return r + "...";
}

void App::txt(float x, float cy, const std::string& s, float size, uint32_t col, float weight, int align, float a) {
    float wpx = font.width(s, size * u);
    float xp = PX(x) - (align == 1 ? wpx / 2 : align == 2 ? wpx : 0);
    font.drawMid(*cv, xp, PY(cy), s, size * u, col, weight, a);
}

void App::hit(float x, float y, float w, float h, Act act, int arg) { hits.push_back({PX(x), PY(y), w * u, h * u, act, arg}); }

void App::arrow(float cx, float cy, float s, uint32_t col, float t, bool right) {
    float d = right ? 1.f : -1.f;
    cap(cx - d * s, cy, cx + d * s, cy, t, col);
    cap(cx + d * s, cy, cx + d * s * 0.2f, cy - s * 0.8f, t, col);
    cap(cx + d * s, cy, cx + d * s * 0.2f, cy + s * 0.8f, t, col);
}
void App::iconX(float cx, float cy, float s, uint32_t col, float t) {
    cap(cx - s, cy - s, cx + s, cy + s, t, col);
    cap(cx - s, cy + s, cx + s, cy - s, t, col);
}
void App::iconInfo(float cx, float cy, float s, uint32_t col) {
    cv->circle(PX(cx), PY(cy - s * 0.62f), s * 0.17f * u, col);
    cap(cx, cy - s * 0.12f, cx, cy + s * 0.62f, s * 0.3f, col);
}
void App::iconSearch(float cx, float cy, float s, uint32_t col) {
    float r = s * 0.62f;
    ring(cx - s * 0.15f - r, cy - s * 0.15f - r, 2 * r, 2 * r, r, s * 0.2f, col);
    cap(cx + s * 0.3f, cy + s * 0.3f, cx + s * 0.8f, cy + s * 0.8f, s * 0.22f, col);
}

void App::topBar(const std::string& left) {
    float w = tw(left, 36) + 72;
    rr(72, 72, w, 96, 48, pal::circle, 0.95f);
    txt(72 + 36, 120, left, 36, pal::text, 0.2f);
    rr(912, 72, 96, 96, 48, pal::circle, 0.95f);
    iconInfo(960, 120, 34, pal::text);
    hit(912, 72, 96, 96, HInfo);
}

void App::titleBlock(const std::string& title, const std::string& sub) {
    txt(72, 285, title, 104, pal::text, 0.5f);
    if (!sub.empty()) txt(72, 372, fit(sub, 38, 936), 38, pal::dim);
}

void App::bottomBar(int left, const std::string& label, uint32_t fill, uint32_t fg) {
    const float y = 1238 + bs, h = 190;
    float rx = 72, rw = 936;
    if (left) {
        rr(72, y, 300, h, 95, pal::pillDark);
        if (left == 1) arrow(222, y + h / 2, 34, pal::text, 12, false);
        else iconX(222, y + h / 2, 28, pal::text, 12);
        hit(72, y, 300, h, left == 1 ? HBack : HQuit);
        rx = 412;
        rw = 596;
    }
    rr(rx, y, rw, h, 95, fill);
    float lw = tw(label, 48), total = lw + 30 + 68, sx = rx + rw / 2 - total / 2;
    txt(sx, y + h / 2, label, 48, fg, 0.4f);
    arrow(sx + lw + 30 + 30, y + h / 2, 30, fg, 12, true);
    hit(rx, y, rw, h, HNext);
}

void App::sw(float x, float y, bool on) {  // M3 switch, 116 x 64
    if (on) {
        rr(x, y, 116, 64, 32, pal::primary);
        cv->circle(PX(x + 116 - 32), PY(y + 32), 22 * u, pal::onPrimary);
    } else {
        ring(x, y, 116, 64, 32, 4, pal::dim);
        cv->circle(PX(x + 32), PY(y + 32), 14 * u, pal::dim);
    }
}

void App::drawField(float y, const std::string& label, const std::string& val, bool secret, bool active, int idx) {
    rr(72, y, 936, 130, 40, pal::card, 0.95f);
    if (active) ring(72, y, 936, 130, 40, 5, pal::primary);
    txt(112, y + 34, label, 28, active ? pal::primary : pal::dim);
    float cx = 112;
    if (secret) {
        for (size_t i = 0; i < val.size() && i < 24; i++) {
            cv->circle(PX(cx + 11), PY(y + 88), 10 * u, pal::text);
            cx += 34;
        }
        if (val.size() > 24) { txt(cx, y + 88, "+" + std::to_string(val.size() - 24), 34, pal::dim); cx += 90; }
    } else {
        std::string shown = fit(val, 48, 800);
        txt(112, y + 88, shown, 48, pal::text);
        cx = 112 + tw(shown, 48);
    }
    if (active && ((int)(t * 2) % 2 == 0)) cap(cx + 4, y + 66, cx + 4, y + 110, 5, pal::primary);
    hit(72, y, 936, 130, HField, idx);
}

// Lists show more rows when the window is taller than the design.
void App::fitRows(ListView& l, int base) {
    l.rows = base + (int)(bs / 108);
    int n = (int)l.vis.size();
    l.top = std::max(0, std::min(l.top, n - l.rows));
    if (l.cur < l.top) l.top = l.cur;
    if (l.cur >= l.top + l.rows) l.top = l.cur - l.rows + 1;
}

void App::drawList(bool search, float y0) {
    ListView* l = activeList();
    if (!l) return;
    fitRows(*l, 6);
    if (search) {
        rr(72, 424, 936, 100, 50, pal::card, 0.95f);
        iconSearch(136, 474, 30, pal::dim);
        if (l->filter.empty()) txt(190, 474, "Type to search", 40, pal::dim, 0, 0, 0.7f);
        else {
            std::string f = fit(l->filter, 40, 760);
            txt(190, 474, f, 40, pal::text);
            if ((int)(t * 2) % 2 == 0) cap(190 + tw(f, 40) + 6, 450, 190 + tw(f, 40) + 6, 498, 4, pal::primary);
        }
    }
    const float rh = 96, pitch = 108;
    if (l->vis.empty()) {
        txt(540, y0 + 60, "No matches", 44, pal::dim, 0, 1);
        return;
    }
    for (int r = 0; r < l->rows; r++) {
        int i = l->top + r;
        if (i >= (int)l->vis.size()) break;
        const Item& it = l->items[l->vis[i]];
        float y = y0 + r * pitch;
        bool sel = i == l->cur;
        rr(72, y, 936, rh, 40, sel ? pal::primary : pal::card, sel ? 1.f : 0.95f);
        std::string main = it.label.empty() ? it.id : it.label;
        txt(112, y + rh / 2, fit(main, 44, it.label.empty() ? 780 : 560), 44, sel ? pal::onPrimary : pal::text, sel ? 0.3f : 0);
        if (!it.label.empty()) txt(972, y + rh / 2, fit(it.id, 30, 280), 30, sel ? pal::onPrimary : pal::dim, 0, 2, sel ? 0.75f : 1);
        hit(72, y, 936, rh, HRow, i);
    }
    if ((int)l->vis.size() > l->rows) {  // scroll thumb
        float trackH = l->rows * pitch - 12, th = std::max(60.f, trackH * l->rows / l->vis.size());
        float ty = y0 + (trackH - th) * l->top / std::max(1, (int)l->vis.size() - l->rows);
        rr(1024, ty, 8, th, 4, pal::primary, 0.7f);
    }
}

void App::drawApps() {
    const float rh = 96, pitch = 108, y0 = 430;
    fitRows(apps, 7);
    for (int r = 0; r < apps.rows; r++) {
        int i = apps.top + r;
        if (i >= (int)apps.vis.size()) break;
        const Item& it = apps.items[apps.vis[i]];
        float y = y0 + r * pitch;
        rr(72, y, 936, rh, 40, it.on ? pal::cardHi : pal::card, 0.95f);
        if (i == apps.cur) ring(72, y, 936, rh, 40, 5, pal::primary);
        txt(112, y + rh / 2, it.label, 44, pal::text);
        float rightEdge = 1008 - 36 - 116;
        if (it.unfree) {
            float w = tw("unfree", 26) + 36;
            rr(rightEdge - 20 - w, y + 26, w, 44, 22, pal::warn, 0.18f);
            txt(rightEdge - 20 - w / 2, y + 48, "unfree", 26, pal::warn, 0, 1);
        }
        sw(rightEdge, y + 16, it.on);
        hit(72, y, 936, rh, HApp, i);
    }
    if ((int)apps.vis.size() > apps.rows) {
        float trackH = apps.rows * pitch - 12, th = std::max(60.f, trackH * apps.rows / apps.vis.size());
        float ty = y0 + (trackH - th) * apps.top / std::max(1, (int)apps.vis.size() - apps.rows);
        rr(1024, ty, 8, th, 4, pal::primary, 0.7f);
    }
}

void App::drawWelcome() {
    topBar("pixeldots");
    txt(540, 1000 + bs, "Hi there", 210, pal::text, 0.4f, 1);
    txt(540, 1150 + bs, iso ? "Install pixeldots on this computer" : "Let's set up your desktop", 44, pal::dim, 0, 1);
    bottomBar(2, "Start");
}

void App::drawHost() {
    topBar(stepText());
    titleBlock("Computer name", "The name this computer shows on the network");
    drawField(500, "Name", host, false, true, 0);
    if (!err.empty()) txt(112, 690, fit(err, 34, 860), 34, pal::error);
    else txt(112, 690, "Letters, digits and '-'", 34, pal::dim);
    bottomBar(1, "Next");
}

void App::drawAccount() {
    topBar(stepText());
    if (iso) {
        titleBlock("Your account", "Name and password for the new user");
        drawField(450, "User name", user, false, field == 0, 0);
        drawField(600, "Password", pw1, true, field == 1, 1);
        drawField(750, "Repeat password", pw2, true, field == 2, 2);
        if (!err.empty()) txt(112, 940, fit(err, 34, 860), 34, pal::error);
        else txt(112, 940, "6+ characters. Typed with the US layout here", 34, pal::dim);
        bottomBar(1, "Next");
        return;
    }
    titleBlock("Password", "Leave both empty to keep your current one");
    rr(72, 424, 936, 110, 40, pal::card, 0.95f);
    cv->circle(PX(72 + 70), PY(479), 34 * u, pal::primary);
    txt(72 + 70, 479, user.empty() ? "?" : std::string(1, (char)std::toupper((unsigned char)user[0])), 40, pal::onPrimary, 0.5f, 1);
    txt(190, 479, fit(user, 46, 540), 46, pal::text);
    txt(972, 479, "current user", 30, pal::dim, 0, 2);
    drawField(570, "New password", pw1, true, field == 0, 0);
    drawField(724, "Repeat password", pw2, true, field == 1, 1);
    if (!err.empty()) txt(112, 920, fit(err, 34, 860), 34, pal::error);
    else txt(112, 920, "Typed with the US layout in this installer", 34, pal::dim);
    bottomBar(1, "Next");
}

void App::drawLook() {
    topBar(stepText());
    titleBlock("Look", "Colours come from your wallpaper, change them later");
    auto label = [&](float y, const char* s, int row) { txt(80, y, s, 32, lookRow == row ? pal::primary : pal::dim, lookRow == row ? 0.4f : 0); };
    label(440, "Mode", 0);
    for (int i = 0; i < NMODES; i++) {
        float x = 72 + i * 472, y = 478;
        bool on = modeIdx == i;
        rr(x, y, 464, 104, 52, on ? pal::primary : pal::card, on ? 1.f : 0.95f);
        std::string m = MODES[i];
        m[0] = (char)std::toupper((unsigned char)m[0]);
        txt(x + 232, y + 52, m, 42, on ? pal::onPrimary : pal::text, on ? 0.4f : 0, 1);
        hit(x, y, 464, 104, HMode, i);
    }
    label(660, "Palette style", 1);
    for (int i = 0; i < NVARIANTS; i++) {
        float x = 72 + (i % 3) * 316, y = 698 + (i / 3) * 106;
        bool on = variantIdx == i;
        rr(x, y, 304, 92, 46, on ? pal::primary : pal::card, on ? 1.f : 0.95f);
        txt(x + 152, y + 46, fit(VARIANTS[i], 34, 270), 34, on ? pal::onPrimary : pal::text, on ? 0.4f : 0, 1);
        hit(x, y, 304, 92, HVariant, i);
    }
    float y = 1030;
    rr(72, y, 936, 120, 44, pal::card, 0.95f);
    if (lookRow == 2) ring(72, y, 936, 120, 44, 5, pal::primary);
    txt(112, y + 60, "Start Hyprland on tty1 login", 40, pal::text);
    sw(1008 - 36 - 116, y + 28, autostart);
    hit(72, y, 936, 120, HAuto);
    bottomBar(1, "Next");
}

void App::drawSummary() {
    topBar(stepText());
    titleBlock("Ready?", iso ? "Check everything, then continue" : "Check everything, then install");
    int napps = 0;
    for (auto& a : apps.items) napps += a.on;
    struct Row { const char* k; std::string v; };
    const Item* pd = pickedDisk();
    std::vector<Row> rows = {
        {"Language", selLabel(locales)},
        {"Keyboard", selLabel(layouts)},
        {"Time zone", selId(zones)},
        {"Computer", host},
        {"User", user + (pw1.empty() ? "" : " (new password)")},
        {"Apps", std::to_string(napps) + " selected"},
        {"Look", std::string(MODES[modeIdx]) + ", " + VARIANTS[variantIdx]},
        {"Desktop", autostart ? "starts on tty1 login" : "start Hyprland by hand"},
    };
    if (iso) rows.push_back({"Disk", pd ? pd->label + ", " + humanSize(std::strtoull(split(pd->attr, '|')[0].c_str(), nullptr, 10)) : "?"});
    rr(72, 424, 936, 700, 48, pal::card, 0.95f);
    float pitch = iso ? 72.f : 78.f;
    for (size_t i = 0; i < rows.size(); i++) {
        float y = 424 + 44 + i * pitch;
        txt(112, y, rows[i].k, 32, pal::dim);
        txt(340, y, fit(rows[i].v, 40, 630), 40, pal::text);
    }
    if (iso) txt(80, 1175, "Nothing is erased until you confirm on the next screen", 30, pal::warn);
    else txt(80, 1175, "Runs nixos-rebuild switch: needs network, takes a while", 30, pal::warn);
    bottomBar(1, iso ? "Continue" : "Install");
}

void App::drawInstall() {
    topBar("pixeldots");
    txt(72, 285, "Installing", 104, pal::text, 0.5f);
    txt(72, 372, iso && pickedDisk() ? "Installing to " + pickedDisk()->label + ". Do not turn the computer off" : "Do not turn the computer off", 38, pal::dim);
    txt(540, 600, std::to_string(pct) + "%", 260, pal::primary, 0.4f, 1);
    rr(72, 790, 936, 48, 24, pal::card, 0.95f);
    float fw = std::max(48.f, 936.f * pct / 100.f);
    rr(72, 790, fw, 48, 24, pal::primary);
    txt(72, 900, fit(msg, 46, 936), 46, pal::text);
    rr(72, 960, 936, 250, 40, pal::card, 0.95f);
    int n = (int)log.size(), rows = 5, first = std::max(0, n - rows);
    for (int i = first; i < n; i++) txt(112, 1000 + (i - first) * 44, fit(log[i], 28, 860), 28, pal::dim);
}

void App::drawDone() {
    topBar("pixeldots");
    txt(540, 960 + bs, "All set", 210, pal::text, 0.4f, 1);
    txt(540, 1110 + bs, iso ? "Remove the installation medium, then restart" : "Your desktop is installed", 44, pal::dim, 0, 1);
    bottomBar(0, iso ? "Restart" : "Start desktop");
}

void App::drawFailed() {
    topBar("pixeldots");
    txt(72, 285, "Install failed", 104, pal::text, 0.5f);
    txt(72, 372, iso ? "The disk may be partly written. Fix the problem and retry" : "Nothing is undone. Fix the problem and retry", 38, pal::dim);
    rr(72, 424, 936, 740, 48, pal::errorCard, 0.97f);
    txt(112, 480, fit(msg.empty() ? "The install script failed" : msg, 40, 860), 40, pal::error, 0.3f);
    int n = (int)log.size(), rows = 12, first = std::max(0, n - rows);
    for (int i = first; i < n; i++) txt(112, 548 + (i - first) * 48, fit(log[i], 28, 860), 28, pal::text, 0, 0, 0.85f);
    if (!logPath.empty()) txt(112, 1124, fit("Log: " + logPath, 26, 860), 26, pal::dim);
    bottomBar(2, "Retry");
}

void App::drawDisk() {
    topBar(stepText());
    titleBlock("Disk", "Pick where to install. Nothing is chosen yet");
    if (disks.items.empty()) {
        rr(72, 424, 936, 300, 48, pal::errorCard, 0.97f);
        txt(112, 490, "Can't install here", 44, pal::error, 0.3f);
        std::string e = diskErr, l2;
        std::string l1 = fit(e, 32, 860);
        if (l1.size() < e.size() || tw(e, 32) > 860) {  // wrap on a space near the middle
            size_t cut = e.rfind(' ', e.size() / 2 + 8);
            if (cut != std::string::npos) { l1 = e.substr(0, cut); l2 = e.substr(cut + 1); }
        }
        txt(112, 560, fit(l1, 32, 860), 32, pal::text);
        if (!l2.empty()) txt(112, 604, fit(l2, 32, 860), 32, pal::text);
        bottomBar(1, "Next");
        return;
    }
    const float rh = 128, pitch = 140, y0 = 430;
    disks.rows = 4 + (int)(bs / pitch);
    int n = (int)disks.vis.size();
    disks.top = std::max(0, std::min(disks.top, n - disks.rows));
    if (disks.cur < disks.top) disks.top = disks.cur;
    if (disks.cur >= disks.top + disks.rows) disks.top = disks.cur - disks.rows + 1;
    for (int r = 0; r < disks.rows; r++) {
        int i = disks.top + r;
        if (i >= n) break;
        const Item& it = disks.items[disks.vis[i]];
        auto f = split(it.attr, '|');
        std::string size = humanSize(std::strtoull(f[0].c_str(), nullptr, 10));
        bool chosen = it.id == diskPick, cursor = i == disks.cur;
        float y = y0 + r * pitch;
        rr(72, y, 936, rh, 40, chosen ? pal::primary : pal::card, chosen ? 1.f : 0.95f);
        if (cursor && !chosen) ring(72, y, 936, rh, 40, 5, pal::primary);
        uint32_t fg = chosen ? pal::onPrimary : pal::text, fg2 = chosen ? pal::onPrimary : pal::dim;
        cv->circle(PX(134), PY(y + rh / 2), 24 * u, chosen ? pal::onPrimary : pal::dim);  // radio button
        cv->circle(PX(134), PY(y + rh / 2), 18 * u, chosen ? pal::primary : pal::card);
        if (chosen) cv->circle(PX(134), PY(y + rh / 2), 10 * u, pal::onPrimary);
        txt(190, y + 46, fit(it.label, 42, 560), 42, fg, chosen ? 0.3f : 0);
        txt(972, y + 46, size, 42, fg, 0, 2);
        std::string sub = "/dev/" + it.id + (f.size() > 1 && !f[1].empty() ? "  " + f[1] : "") + (f.size() > 2 && f[2] == "1" ? "  removable" : "");
        txt(190, y + 94, fit(sub, 30, 780), 30, fg2, 0, 0, 0.9f);
        hit(72, y, 936, rh, HDisk, i);
    }
    if (n > disks.rows) {
        float trackH = disks.rows * pitch - 12, th = std::max(60.f, trackH * disks.rows / n);
        rr(1024, y0 + (trackH - th) * disks.top / std::max(1, n - disks.rows), 8, th, 4, pal::primary, 0.7f);
    }
    if (!err.empty()) txt(80, 1200 + bs * 0, fit(err, 32, 900), 32, pal::error);
    bottomBar(1, "Next");
}

void App::drawErase() {
    topBar(stepText());
    txt(72, 285, "Erase disk?", 104, pal::text, 0.5f);
    txt(72, 372, "This cannot be undone", 38, pal::error);
    const Item* d = pickedDisk();
    rr(72, 424, 936, 540, 48, pal::errorCard, 0.97f);
    txt(112, 486, "Everything on this disk will be erased", 38, pal::error, 0.3f);
    if (d) {
        auto f = split(d->attr, '|');
        txt(112, 580, fit(d->label, 56, 860), 56, pal::text, 0.4f);
        txt(112, 650, humanSize(std::strtoull(f[0].c_str(), nullptr, 10)) + "   /dev/" + d->id, 40, pal::text, 0, 0, 0.9f);
    }
    txt(112, 740, "It will get a new GPT table:", 30, pal::dim);
    txt(112, 786, "1 GiB EFI system partition (FAT32)", 30, pal::text, 0, 0, 0.85f);
    txt(112, 830, "the rest as one ext4 partition for the system", 30, pal::text, 0, 0, 0.85f);
    txt(112, 900, "Other disks are not touched", 30, pal::dim);
    const float y = 1000;
    rr(72, y, 936, 130, 44, pal::card, 0.95f);
    if (eraseOn) ring(72, y, 936, 130, 44, 5, pal::error);
    txt(112, y + 65, "I understand, erase this disk", 40, pal::text);
    sw(1008 - 36 - 116, y + 33, eraseOn);
    hit(72, y, 936, 130, HErase);
    if (!err.empty()) txt(80, 1170, fit(err, 32, 900), 32, pal::error);
    bottomBar(1, "Erase and install", eraseOn ? pal::error : 0x3A3D4A, eraseOn ? 0x3B0A06 : pal::dim);
}

void App::drawInfo() {
    cv->rrect(0, 0, (float)cv->w, (float)cv->h, 0, 0x000000, 0.6f);
    hit(-100000, -100000, 200000, 200000, HInfoClose);
    rr(110, 330, 860, 700, 56, 0x2B2F3D);
    txt(160, 410, "Keys", 56, pal::text, 0.5f);
    const char* lines[] = {"Enter  next / confirm", "Esc  back", "Up Down  move in lists", "Type  search or fill the field",
                           "Space  toggle (apps)", "Tab  next field", "Left Right  change (look)"};
    for (int i = 0; i < 7; i++) txt(160, 500 + i * 66, lines[i], 38, pal::text, 0, 0, 0.9f);
    txt(160, 975, fit(logPath.empty() ? "Mouse works too" : "Log: " + logPath, 26, 760), 26, pal::dim);
}

void App::draw(Canvas& c) {
    cv = &c;
    u = std::min(c.h / 1500.f, c.w / 1080.f);
    ox = (c.w - 1080 * u) / 2;
    oy = 0;
    bs = std::max(0.f, c.h / u - 1500.f);  // extra design height in tall windows: bottom items move down by this
    lastU = u; lastOx = ox; lastOy = oy;
    hits.clear();
    bg.draw(c);
    switch (scr) {
        case Scr::Welcome: drawWelcome(); break;
        case Scr::Locale:
            topBar(stepText()); titleBlock("Language", "System language and formats");
            drawList(true, 548); bottomBar(1, "Next"); break;
        case Scr::Layout:
            topBar(stepText()); titleBlock("Keyboard", "Layout for the console and Hyprland");
            drawList(true, 548); bottomBar(1, "Next"); break;
        case Scr::Timezone:
            topBar(stepText()); titleBlock("Time zone", "Try typing a city, like berlin");
            drawList(true, 548); bottomBar(1, "Next"); break;
        case Scr::Hostname: drawHost(); break;
        case Scr::Account: drawAccount(); break;
        case Scr::Apps:
            topBar(stepText()); titleBlock("Apps", "Space toggles, the basics are always included");
            drawApps(); bottomBar(1, "Next"); break;
        case Scr::Look: drawLook(); break;
        case Scr::Summary: drawSummary(); break;
        case Scr::Install: drawInstall(); break;
        case Scr::Done: drawDone(); break;
        case Scr::Failed: drawFailed(); break;
        case Scr::Disk: drawDisk(); break;
        case Scr::Erase: drawErase(); break;
    }
    if (showInfo) drawInfo();
}

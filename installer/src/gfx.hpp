// Software renderer for the installer: anti-aliased rounded shapes, SDF text, and the animated blob background.
// Everything works on one ARGB Canvas of any size, so the same code feeds SDL (window) and the headless tests (PPM).
#pragma once
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

namespace pal {  // Material You dark palette sampled from the Pixel setup wizard
constexpr uint32_t bg = 0x17191F, blobA = 0x445274, blobB = 0x353B4D, circle = 0x23262E, pillDark = 0x121318,
                   primary = 0xB8C6EE, onPrimary = 0x243055, text = 0xE4E5F0, dim = 0xA9ABBA, card = 0x262A36,
                   cardHi = 0x30344A, error = 0xFFB4AB, errorCard = 0x4A2326, warn = 0xFFD27A, ok = 0x9FD8A4;
}

inline float clamp01(float v) { return v < 0 ? 0 : (v > 1 ? 1 : v); }

struct Canvas {
    int w = 0, h = 0;
    std::vector<uint32_t> px;
    Canvas(int w_ = 1, int h_ = 1) { resize(w_, h_); }
    void resize(int w_, int h_) {
        w = std::max(1, w_);
        h = std::max(1, h_);
        px.assign((size_t)w * h, 0xFF000000);
    }

    // a in 0..1 is coverage*opacity
    void blend(int x, int y, uint32_t hex, float a) {
        if (a <= 0 || x < 0 || y < 0 || x >= w || y >= h) return;
        uint32_t& d = px[(size_t)y * w + x];
        float r = (hex >> 16) & 255, g = (hex >> 8) & 255, b = hex & 255;
        float dr = (d >> 16) & 255, dg = (d >> 8) & 255, db = d & 255;
        d = 0xFF000000 | ((uint32_t)(dr + (r - dr) * a + 0.5f) << 16) | ((uint32_t)(dg + (g - dg) * a + 0.5f) << 8) |
            (uint32_t)(db + (b - db) * a + 0.5f);
    }

    // Signed distance (px) to a rounded rect, negative inside.
    static float sdRound(float px_, float py_, float cx, float cy, float hw, float hh, float r) {
        float qx = std::fabs(px_ - cx) - (hw - r), qy = std::fabs(py_ - cy) - (hh - r);
        return std::hypot(std::max(qx, 0.f), std::max(qy, 0.f)) + std::min(std::max(qx, qy), 0.f) - r;
    }

    void rrect(float x, float y, float rw, float rh, float r, uint32_t hex, float alpha = 1) {
        r = std::min(r, std::min(rw, rh) / 2);
        float cx = x + rw / 2, cy = y + rh / 2;
        for (int j = (int)std::floor(y) - 1; j <= (int)std::ceil(y + rh) + 1; j++)
            for (int i = (int)std::floor(x) - 1; i <= (int)std::ceil(x + rw) + 1; i++)
                blend(i, j, hex, clamp01(0.5f - sdRound(i + 0.5f, j + 0.5f, cx, cy, rw / 2, rh / 2, r)) * alpha);
    }
    void circle(float cx, float cy, float r, uint32_t hex, float alpha = 1) { rrect(cx - r, cy - r, 2 * r, 2 * r, r, hex, alpha); }

    // Outline of a rounded rect, drawn inside the rect.
    void ring(float x, float y, float rw, float rh, float r, float t, uint32_t hex, float alpha = 1) {
        r = std::min(r, std::min(rw, rh) / 2);
        float cx = x + rw / 2, cy = y + rh / 2;
        for (int j = (int)std::floor(y) - 1; j <= (int)std::ceil(y + rh) + 1; j++)
            for (int i = (int)std::floor(x) - 1; i <= (int)std::ceil(x + rw) + 1; i++) {
                float d = sdRound(i + 0.5f, j + 0.5f, cx, cy, rw / 2, rh / 2, r);
                blend(i, j, hex, clamp01(0.5f - (std::fabs(d + t / 2) - t / 2)) * alpha);
            }
    }

    // Line with round caps (icons are built from these).
    void capsule(float x0, float y0, float x1, float y1, float t, uint32_t hex, float alpha = 1) {
        float lx = std::min(x0, x1) - t, hx = std::max(x0, x1) + t, ly = std::min(y0, y1) - t, hy = std::max(y0, y1) + t;
        float dx = x1 - x0, dy = y1 - y0, len2 = dx * dx + dy * dy;
        for (int j = (int)std::floor(ly); j <= (int)std::ceil(hy); j++)
            for (int i = (int)std::floor(lx); i <= (int)std::ceil(hx); i++) {
                float qx = i + 0.5f - x0, qy = j + 0.5f - y0;
                float k = len2 > 0 ? clamp01((qx * dx + qy * dy) / len2) : 0;
                float d = std::hypot(qx - dx * k, qy - dy * k) - t / 2;
                blend(i, j, hex, clamp01(0.5f - d) * alpha);
            }
    }
};

// ───────────── font: SDF atlas baked by tools/gen-font-sdf.py ─────────────
class Font {
public:
    bool load(const std::string& path) {
        FILE* f = std::fopen(path.c_str(), "rb");
        if (!f) return false;
        std::vector<uint8_t> all;
        uint8_t tmp[65536];
        size_t n;
        while ((n = std::fread(tmp, 1, sizeof tmp, f)) > 0) all.insert(all.end(), tmp, tmp + n);
        std::fclose(f);
        if (all.size() < 26 || std::memcmp(all.data(), "PDSDF2\0\0", 8) != 0) return false;
        const uint8_t* p = all.data() + 8;
        uint16_t count, bake, spread;
        std::memcpy(&count, p, 2); std::memcpy(&bake, p + 2, 2); std::memcpy(&spread, p + 4, 2);
        std::memcpy(&ascent_, p + 6, 4); std::memcpy(&descent_, p + 10, 4);
        bake_ = bake; spread_ = spread;
        p += 6 + 12;
        const size_t rec = 2 + 4 + 2 + 2 + 2 + 2 + 4;
        size_t dataStart = 8 + 18 + (size_t)count * rec;
        if (all.size() < dataStart) return false;
        for (int i = 0; i < count; i++, p += rec) {
            G g;
            uint16_t code;
            std::memcpy(&code, p, 2);
            std::memcpy(&g.adv, p + 2, 4); std::memcpy(&g.l, p + 6, 2); std::memcpy(&g.t, p + 8, 2);
            std::memcpy(&g.w, p + 10, 2); std::memcpy(&g.h, p + 12, 2); std::memcpy(&g.off, p + 14, 4);
            if (code < 256) glyph_[code] = g;
        }
        data_.assign(all.begin() + dataStart, all.end());
        ok_ = true;
        return true;
    }
    bool ok() const { return ok_; }

    float width(const std::string& s, float size) const {
        float w = 0;
        for (size_t i = 0; i < s.size();) w += glyph_[cp(s, i)].adv;
        return w * size / bake_;
    }
    // Draws with the baseline at `base`. weight > 0 makes strokes thicker by shifting the SDF threshold.
    void draw(Canvas& cv, float x, float base, const std::string& s, float size, uint32_t hex, float weight = 0, float alpha = 1) const {
        float sc = size / bake_, bold = weight * size * 0.012f;
        for (size_t i = 0; i < s.size();) {
            const G& g = glyph_[cp(s, i)];
            if (g.w > 0) blit(cv, g, x, base, sc, bold, hex, alpha);
            x += g.adv * sc;
        }
    }
    // Vertical centre of capital letters sits at cy.
    void drawMid(Canvas& cv, float x, float cy, const std::string& s, float size, uint32_t hex, float weight = 0, float alpha = 1) const {
        draw(cv, x, cy + 0.35f * size, s, size, hex, weight, alpha);
    }

private:
    struct G { float adv = 0; int16_t l = 0, t = 0; uint16_t w = 0, h = 0; uint32_t off = 0; };
    G glyph_[256];
    std::vector<uint8_t> data_;
    float ascent_ = 0, descent_ = 0;
    int bake_ = 72, spread_ = 9;
    bool ok_ = false;
    // Next UTF-8 code point at s[i] (advances i) mapped to a glyph slot; anything the atlas lacks becomes '?'.
    static int cp(const std::string& s, size_t& i) {
        unsigned char c = (unsigned char)s[i++];
        uint32_t v = c;
        int extra = c >= 0xF0 ? 3 : c >= 0xE0 ? 2 : c >= 0xC0 ? 1 : 0;
        if (extra) v = c & (0x3F >> extra);
        while (extra-- > 0 && i < s.size() && ((unsigned char)s[i] & 0xC0) == 0x80) v = (v << 6) | ((unsigned char)s[i++] & 0x3F);
        return (v >= 32 && v < 127) || (v >= 160 && v < 256) ? (int)v : '?';
    }

    float sample(const G& g, float fx, float fy) const {  // bilinear, outside = 0
        int x0 = (int)std::floor(fx), y0 = (int)std::floor(fy);
        float tx = fx - x0, ty = fy - y0;
        auto at = [&](int x, int y) -> float {
            if (x < 0 || y < 0 || x >= g.w || y >= g.h) return 0.f;
            return (float)data_[g.off + (size_t)y * g.w + x];
        };
        float a = at(x0, y0) * (1 - tx) + at(x0 + 1, y0) * tx, b = at(x0, y0 + 1) * (1 - tx) + at(x0 + 1, y0 + 1) * tx;
        return a * (1 - ty) + b * ty;
    }
    void blit(Canvas& cv, const G& g, float ox, float base, float sc, float bold, uint32_t hex, float alpha) const {
        float x0 = ox + g.l * sc, y0 = base - g.t * sc;
        float k = (float)spread_ * sc / 127.f;  // byte delta -> dest px
        for (int j = (int)std::floor(y0); j <= (int)std::ceil(y0 + g.h * sc); j++)
            for (int i = (int)std::floor(x0); i <= (int)std::ceil(x0 + g.w * sc); i++) {
                float v = sample(g, (i + 0.5f - x0) / sc - 0.5f, (j + 0.5f - y0) / sc - 0.5f);
                cv.blend(i, j, hex, clamp01((v - 128.f) * k + 0.5f + bold) * alpha);
            }
    }
};

// ───────────── animated background: two layers of organic blobs ─────────────
struct Blob { float x, y, r; };  // x,y as fraction of width/height, r as fraction of height
struct Pose { Blob a[5], b[5]; };

class Background {
public:
    Background() { cur_ = tgt_ = poseFor(0); }
    void setScreen(int s) { tgt_ = poseFor(s); }
    void tick(float dt) {
        t_ += dt;
        float k = 1 - std::exp(-dt * 3.0f);
        for (int i = 0; i < 5; i++) {
            lerp(cur_.a[i], tgt_.a[i], k);
            lerp(cur_.b[i], tgt_.b[i], k);
        }
    }
    // Fields are computed on a 1/4 grid and sampled bilinearly: the distance field is smooth, so edges stay sharp.
    // The result is cached and recomputed at most every 40 ms (blobs move slowly), other frames just copy it.
    void draw(Canvas& cv) {
        if (cw_ != cv.w || ch_ != cv.h || t_ - lastT_ >= 0.04f || lastT_ < 0) {
            render(cv.w, cv.h);
            lastT_ = t_;
        }
        std::memcpy(cv.px.data(), cache_.data(), cache_.size() * sizeof(uint32_t));
    }

private:
    Pose cur_, tgt_;
    float t_ = 0, lastT_ = -1;
    int cw_ = 0, ch_ = 0;
    std::vector<float> fa_, fb_;
    std::vector<uint32_t> cache_;

    void render(int w, int h) {
        const int S = 8;
        cw_ = w; ch_ = h;
        cache_.assign((size_t)w * h, 0);
        int lw = w / S + 2, lh = h / S + 2;
        fa_.assign((size_t)lw * lh, 0); fb_.assign((size_t)lw * lh, 0);
        float ref = 0.85f * std::sqrt((float)w * h);  // blob sizes follow the window area, not just its height
        float kpx = 0.22f * ref;  // blend radius: bigger = more liquid
        Canvas probe(1, 1);
        probe.w = w; probe.h = h;
        for (int j = 0; j < lh; j++)
            for (int i = 0; i < lw; i++) {
                fa_[(size_t)j * lw + i] = field(cur_.a, i * S, j * S, probe, kpx, ref);
                fb_[(size_t)j * lw + i] = field(cur_.b, i * S, j * S, probe, kpx, ref);
            }
        const float cbg[3] = {(float)((pal::bg >> 16) & 255), (float)((pal::bg >> 8) & 255), (float)(pal::bg & 255)};
        const float cb[3] = {(float)((pal::blobB >> 16) & 255), (float)((pal::blobB >> 8) & 255), (float)(pal::blobB & 255)};
        const float ca[3] = {(float)((pal::blobA >> 16) & 255), (float)((pal::blobA >> 8) & 255), (float)(pal::blobA & 255)};
        const float inv = 1.f / S;
        for (int y = 0; y < h; y++) {
            int iy = y / S;
            float ty = (y - iy * S) * inv;
            const float *a0 = &fa_[(size_t)iy * lw], *a1 = a0 + lw, *b0 = &fb_[(size_t)iy * lw], *b1 = b0 + lw;
            uint32_t* out = &cache_[(size_t)y * w];
            for (int x = 0; x < w; x++) {
                int ix = x / S;
                float tx = (x - ix * S) * inv;
                float da = (a0[ix] * (1 - tx) + a0[ix + 1] * tx) * (1 - ty) + (a1[ix] * (1 - tx) + a1[ix + 1] * tx) * ty;
                float db = (b0[ix] * (1 - tx) + b0[ix + 1] * tx) * (1 - ty) + (b1[ix] * (1 - tx) + b1[ix + 1] * tx) * ty;
                float r = cbg[0], g = cbg[1], b = cbg[2];
                float kb = 0.5f - db, ka = 0.5f - da;
                if (kb > 0) { kb = kb > 1 ? 1 : kb; r += (cb[0] - r) * kb; g += (cb[1] - g) * kb; b += (cb[2] - b) * kb; }
                if (ka > 0) { ka = ka > 1 ? 1 : ka; r += (ca[0] - r) * ka; g += (ca[1] - g) * ka; b += (ca[2] - b) * ka; }
                out[x] = 0xFF000000 | ((uint32_t)(r + 0.5f) << 16) | ((uint32_t)(g + 0.5f) << 8) | (uint32_t)(b + 0.5f);
            }
        }
    }

    static void lerp(Blob& a, const Blob& b, float k) { a.x += (b.x - a.x) * k; a.y += (b.y - a.y) * k; a.r += (b.r - a.r) * k; }
    static float smin(float a, float b, float k) {
        float h = std::max(k - std::fabs(a - b), 0.f) / k;
        return std::min(a, b) - h * h * k * 0.25f;
    }
    float field(const Blob* bl, int x, int y, const Canvas& cv, float k, float ref) const {
        float d = 1e9f;
        for (int i = 0; i < 5; i++) {
            float dx = bl[i].x * cv.w - x + 12 * ref / 1000.f * std::sin(t_ * 0.35f + i * 1.7f);
            float dy = bl[i].y * cv.h - y + 12 * ref / 1000.f * std::cos(t_ * 0.3f + i * 2.3f);
            d = smin(d, std::hypot(dx, dy) - bl[i].r * ref, k);
        }
        return d;
    }
    // Welcome mimics the Pixel setup wizard; other screens move the blobs around so every step feels different.
    static Pose poseFor(int s) {
        Pose p = {{{0.80f, 0.02f, 0.20f}, {0.58f, -0.04f, 0.13f}, {1.02f, 0.12f, 0.18f}, {0.74f, 0.17f, 0.075f}, {0.96f, -0.06f, 0.2f}},
                  {{0.10f, 0.84f, 0.30f}, {0.50f, 1.06f, 0.40f}, {0.93f, 0.80f, 0.24f}, {0.30f, 1.0f, 0.24f}, {0.72f, 1.1f, 0.28f}}};
        if (s == 0) return p;
        float ox = 0.16f * std::sin(s * 1.9f), oy = 0.10f * std::cos(s * 2.3f), bx = 0.10f * std::sin(s * 2.7f + 1), sc = 1 + 0.18f * std::sin(s * 1.3f);
        for (int i = 0; i < 5; i++) {
            p.a[i].x = (s % 2 ? 1.0f - p.a[i].x : p.a[i].x) + ox;
            p.a[i].y += oy;
            p.a[i].r *= sc;
            p.b[i].x += bx;
            p.b[i].y -= 0.12f * (0.5f + 0.5f * std::sin(s * 1.1f));
            p.b[i].r *= 1 + 0.12f * std::cos(s * 1.7f);
        }
        return p;
    }
};

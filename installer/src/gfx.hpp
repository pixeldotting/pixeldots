// Tiny software canvas: 320x180 logical pixels, ARGB. The platform layer scales it up with nearest-neighbour.
#pragma once
#include <algorithm>
#include <cstdint>
#include <string>
#include <vector>
#include "font.hpp"

constexpr int W = 320, H = 180;

namespace pal {
constexpr uint32_t bg = 0xFF17151C, panel = 0xFF24212B, panel2 = 0xFF2E2A38, line = 0xFF4A4458,
                   text = 0xFFE8E1EC, dim = 0xFF948DA0, primary = 0xFFC4B5FF, onPrimary = 0xFF2A1B5C,
                   pink = 0xFFFF8FC0, teal = 0xFF62E0D0, ok = 0xFF86E39A, bad = 0xFFFF7B7B, warn = 0xFFFFD56B;
}

struct Canvas {
    std::vector<uint32_t> px = std::vector<uint32_t>(W * H, pal::bg);

    void clear(uint32_t c) { std::fill(px.begin(), px.end(), c); }
    void put(int x, int y, uint32_t c) {
        if (x >= 0 && y >= 0 && x < W && y < H) px[y * W + x] = c;
    }
    void rect(int x, int y, int w, int h, uint32_t c) {
        for (int j = y; j < y + h; j++)
            for (int i = x; i < x + w; i++) put(i, j, c);
    }
    // Pixel-art box: 1px border, the four corner pixels are cut off.
    void pbox(int x, int y, int w, int h, uint32_t fill, uint32_t border) {
        rect(x + 1, y + 1, w - 2, h - 2, fill);
        rect(x + 1, y, w - 2, 1, border);
        rect(x + 1, y + h - 1, w - 2, 1, border);
        rect(x, y + 1, 1, h - 2, border);
        rect(x + w - 1, y + 1, 1, h - 2, border);
    }
    static int textWidth(const std::string& s, int scale = 1) {
        return s.empty() ? 0 : (int)s.size() * font::ADV * scale - scale;
    }
    void text(int x, int y, const std::string& s, uint32_t c, int scale = 1) {
        for (char ch : s) {
            int idx = (ch >= 32 && ch <= 126) ? ch - 32 : '?' - 32;
            for (int r = 0; r < font::GH; r++)
                for (int col = 0; col < font::GW; col++)
                    if (font::glyphs[idx][r] & (0x10 >> col)) rect(x + col * scale, y + r * scale, scale, scale, c);
            if (font::hasDescender(ch))
                for (int r = 0; r < 2; r++)
                    for (int col = 0; col < font::GW; col++)
                        if (font::desc[font::descIndex(ch)][r] & (0x10 >> col))
                            rect(x + col * scale, y + (font::GH + r) * scale, scale, scale, c);
            x += font::ADV * scale;
        }
    }
    void textRight(int xr, int y, const std::string& s, uint32_t c, int scale = 1) {
        text(xr - textWidth(s, scale), y, s, c, scale);
    }
    void textCenter(int y, const std::string& s, uint32_t c, int scale = 1) {
        text((W - textWidth(s, scale)) / 2, y, s, c, scale);
    }
};

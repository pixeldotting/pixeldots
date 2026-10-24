#!/usr/bin/env python3
"""Bake an 8-bit signed-distance-field atlas of U+0020..U+007E and U+00A0..U+00FF for the installer (installer/data/font.sdf).

    python3 tools/gen-font-sdf.py <font.ttf> installer/data/font.sdf [axis=value ...]

Variable fonts (Google Sans Flex): pass axes by tag or name, e.g. `wght=400 ROND=0 opsz=24`; unlisted axes keep their
default. Run it without axes once to list what the font offers.

Needs Pillow + numpy + scipy. The installer then scales text freely with sharp edges and can fake weights
by shifting the SDF threshold. Format (little endian):
    "PDSDF2\\0\\0" | u16 count | u16 bake_px | u16 spread | f32 ascent | f32 descent | f32 line_gap
    count x { u16 codepoint | f32 advance | i16 left | i16 top | u16 w | u16 h | u32 offset }   (left/top in bake px, top = above baseline)
    data: w*h bytes per glyph, 128 = outline, >128 inside, <128 outside, 127/spread bytes per bake px.
"""
import struct, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import distance_transform_edt

BAKE, SPREAD, SS = 72, 9, 4  # bake em size, distance range in bake px, supersampling

TAGS = {"wght": "weight", "wdth": "width", "opsz": "optical", "slnt": "slant", "ital": "italic", "grad": "grade", "rond": "round"}

def set_axes(font, wanted):
    try:
        axes = font.get_variation_axes()
    except Exception:
        axes = []
    if not axes:
        if wanted: sys.exit("this font has no variable axes, remove the axis=value arguments")
        return
    names = [(a["name"].decode() if isinstance(a["name"], bytes) else str(a["name"])) for a in axes]
    print("axes:", ", ".join(f"{n} [{a['minimum']}..{a['maximum']}, default {a['default']}]" for n, a in zip(names, axes)))
    values = [a["default"] for a in axes]
    for key, val in wanted.items():
        word = TAGS.get(key.lower(), key.lower())
        hits = [i for i, n in enumerate(names) if word in n.lower()]
        if not hits: sys.exit(f"no axis matches '{key}' (have: {', '.join(names)})")
        values[hits[0]] = float(val)
    font.set_variation_by_axes(values)
    print("using:", ", ".join(f"{n}={v}" for n, v in zip(names, values)))

def main(ttf, out, wanted):
    big = ImageFont.truetype(ttf, BAKE * SS)
    set_axes(big, wanted)
    asc, desc = [v / SS for v in big.getmetrics()]
    glyphs, blobs, off = [], [], 0
    for code in list(range(32, 127)) + list(range(160, 256)):
        ch = chr(code)
        adv = big.getlength(ch) / SS
        bbox = big.getbbox(ch, anchor="ls")  # relative to origin on the baseline
        if ch == " " or bbox[2] <= bbox[0]:
            glyphs.append((code, adv, 0, 0, 0, 0, off)); continue
        pad = SPREAD * SS
        x0, y0, x1, y1 = bbox[0] - pad, bbox[1] - pad, bbox[2] + pad, bbox[3] + pad
        x0 -= x0 % SS; y0 -= y0 % SS  # cell grid aligned to whole bake pixels
        w, h = x1 - x0, y1 - y0
        w += (-w) % SS; h += (-h) % SS  # multiple of SS
        img = Image.new("L", (w, h), 0)
        ImageDraw.Draw(img).text((-x0, -y0), ch, font=big, fill=255, anchor="ls")
        m = np.asarray(img) > 127
        sd = distance_transform_edt(m) - distance_transform_edt(~m)  # + inside, in supersampled px
        sd = sd[: h // SS * SS, : w // SS * SS].reshape(h // SS, SS, w // SS, SS).mean(axis=(1, 3)) / SS
        data = np.clip(128 + sd * (127.0 / SPREAD), 0, 255).astype(np.uint8)
        glyphs.append((code, adv, x0 // SS, -(y0 // SS), data.shape[1], data.shape[0], off))
        blobs.append(data.tobytes()); off += data.size
    with open(out, "wb") as f:
        f.write(b"PDSDF2\0\0" + struct.pack("<HHHfff", len(glyphs), BAKE, SPREAD, asc, desc, 0.0))
        for code, adv, l, t, w, h, o in glyphs:
            f.write(struct.pack("<HfhhHHI", code, adv, l, t, w, h, o))
        for b in blobs: f.write(b)
    print(f"{len(glyphs)} glyphs, {off} bytes of data -> {out}")

if __name__ == "__main__":
    if len(sys.argv) < 3: sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2], dict(a.split("=", 1) for a in sys.argv[3:]))

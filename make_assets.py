#!/usr/bin/env python3
"""Regenerates the wallpapers and logo. Needs: pip install pillow numpy"""
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                    "stage-aurora", "02-overlay", "files", "usr")
W, H = 1920, 1080


def gradient(top, bottom):
    t = np.linspace(0, 1, H)[:, None, None]
    a, b = np.array(top, float), np.array(bottom, float)
    return np.broadcast_to(a + (b - a) * t, (H, W, 3)).copy()


def ribbon(canvas, color, y0, amp, freq, phase, thick, alpha):
    layer = np.zeros((H, W), float)
    xs = np.arange(W)
    for x in xs[::1]:
        c = y0 + amp * math.sin(x * freq + phase) + 0.4 * amp * math.sin(x * freq * 2.3 + phase * 1.7)
        ys = np.arange(H)
        layer[:, x] = np.exp(-((ys - c) / thick) ** 2)
    img = Image.fromarray((layer * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(28))
    m = np.asarray(img, float)[:, :, None] / 255.0 * alpha
    canvas += m * (np.array(color, float) - canvas) * 1.0
    return canvas


def stars(canvas, n, seed):
    rng = np.random.default_rng(seed)
    for _ in range(n):
        x, y = int(rng.integers(0, W)), int(rng.integers(0, H * 0.7))
        canvas[y:y + 2, x:x + 2] = np.clip(canvas[y:y + 2, x:x + 2] + rng.uniform(60, 160), 0, 255)
    return canvas


def save(name, canvas):
    d = os.path.join(ROOT, "share", "wallpapers", name, "contents", "images")
    os.makedirs(d, exist_ok=True)
    Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8)).save(
        os.path.join(d, "1920x1080.jpg"), quality=88, optimize=True)


# Dawn: teal -> violet -> warm horizon
c = gradient((8, 14, 40), (70, 30, 90))
c = ribbon(c, (60, 230, 190), 420, 90, 0.0031, 0.4, 70, 0.80)
c = ribbon(c, (120, 140, 255), 520, 70, 0.0042, 2.1, 55, 0.65)
c = ribbon(c, (255, 130, 190), 640, 60, 0.0027, 4.0, 45, 0.50)
save("AuroraDawn", stars(c, 260, 1))

# Night: deep blue with green curtains
c = gradient((3, 6, 20), (10, 24, 48))
c = ribbon(c, (70, 255, 160), 360, 110, 0.0028, 1.0, 85, 0.85)
c = ribbon(c, (40, 200, 220), 470, 80, 0.0039, 3.3, 60, 0.55)
save("AuroraNight", stars(c, 420, 2))

# Bloom: warm magenta/orange
c = gradient((25, 8, 40), (120, 40, 80))
c = ribbon(c, (255, 170, 90), 560, 80, 0.0030, 0.2, 75, 0.70)
c = ribbon(c, (255, 90, 170), 470, 100, 0.0036, 2.6, 60, 0.65)
c = ribbon(c, (150, 120, 255), 380, 60, 0.0045, 4.4, 45, 0.50)
save("AuroraBloom", stars(c, 180, 3))

# Logo: rounded gradient tile with three aurora arcs
S = 512
tile = np.zeros((S, S, 4), np.uint8)
yy, xx = np.mgrid[0:S, 0:S]
t = (xx + yy) / (2 * S)
tile[..., 0] = (30 + 60 * t)
tile[..., 1] = (60 + 150 * (1 - t))
tile[..., 2] = (160 + 90 * t)
tile[..., 3] = 255
img = Image.fromarray(tile)
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle((16, 16, S - 16, S - 16), radius=110, fill=255)
img.putalpha(mask)
# three flowing aurora ribbons
ov = Image.new("RGBA", (S, S), (0, 0, 0, 0))
od = ImageDraw.Draw(ov)
for k, (yc, amp, a, wd) in enumerate(((190, 46, 255, 30), (265, 52, 205, 26), (335, 44, 150, 22))):
    pts = [(x, yc + amp * math.sin((x / S) * 2 * math.pi * 1.15 + k * 0.9)) for x in range(70, S - 69, 1)]
    od.line(pts, fill=(255, 255, 255, a), width=wd, joint="curve")
    for (x, y) in (pts[0], pts[-1]):
        od.ellipse((x - wd / 2, y - wd / 2, x + wd / 2, y + wd / 2), fill=(255, 255, 255, a))
img = Image.alpha_composite(img, ov)
d = ImageDraw.Draw(img)
for (x, y, r) in ((140, 110, 6), (370, 95, 4), (430, 150, 3)):
    d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, 230))
logo = os.path.join(ROOT, "share", "aurora")
os.makedirs(logo, exist_ok=True)
img.save(os.path.join(logo, "logo.png"))
pl = os.path.join(ROOT, "share", "plymouth", "themes", "aurora")
os.makedirs(pl, exist_ok=True)
img.resize((256, 256), Image.LANCZOS).save(os.path.join(pl, "logo.png"))
for size in (256, 64):
    p = os.path.join(ROOT, "share", "icons", "hicolor", f"{size}x{size}", "apps")
    os.makedirs(p, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(os.path.join(p, "aurora-logo.png"))
print("assets written")

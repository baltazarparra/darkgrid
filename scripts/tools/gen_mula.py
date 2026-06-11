#!/usr/bin/env python3
"""Generate the Mula sem Cabeça boss sprites — premium organic pipeline.

Art law: docs/CONCEITO-mula.md. The Mula is the Phase 1 boss: a headless
mule whose neck stump jets a column of fire, wearing a blood-red cursed
harness and shining iron horseshoes.

Pipeline: organic vector shapes on a 64 logical grid, supersampled 8x,
area-downsampled to 192x192, closed-palette snap, continuous 1px dark outline.

v2: Serrated silhouette inspired by Caipora's jagged mane. More fire volume,
falling embers, fire rim-light on body, and aggressive jaggy fur edges.
"""

from __future__ import annotations

import math
import os
import random

from PIL import Image, ImageDraw


OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")
SIZE = 192
GRID = 64
SS = 8

TRANSPARENT = (0, 0, 0, 0)
OUTLINE = (26, 18, 10)          # #1a120a

# ── Mula palette ────────────────────────────────────
FUR_DK = (30, 17, 15)           # #1e110f shadow / distant legs
FUR = (52, 30, 26)              # #341e1a body base
FUR_LT = (84, 52, 44)           # #54342c muscle highlight
HOOF = (16, 10, 9)              # #100a09 hoof
IRON = (122, 124, 138)          # #7a7c8a horseshoe
IRON_LT = (188, 192, 206)       # #bcc0ce horseshoe glint
WOUND = (74, 8, 8)              # #4a0808 raw flesh stump
SADDLE = (40, 22, 14)           # #28160e dark leather
SADDLE_BLOOD = (150, 24, 16)    # #961810 blood-red trim
FIRE_DEEP = (188, 42, 0)        # #bc2a00 fire base
FIRE_MID = (255, 107, 0)        # #ff6b08 fire body
FIRE_HOT = (255, 168, 56)       # #ffa838 fire hot
FIRE_CORE = (255, 240, 200)     # #fff0c8 white-hot core

MULA_PALETTE = [
    OUTLINE, FUR_DK, FUR, FUR_LT, HOOF, IRON, IRON_LT,
    WOUND, SADDLE, SADDLE_BLOOD,
    FIRE_DEEP, FIRE_MID, FIRE_HOT, FIRE_CORE,
]


class Painter:
    def __init__(self, size: int = SIZE) -> None:
        self.size = size
        self.k = size / GRID * SS
        self.im = Image.new("RGBA", (size * SS, size * SS), TRANSPARENT)
        self.d = ImageDraw.Draw(self.im)

    def poly(self, pts: list[tuple[float, float]], col: tuple[int, int, int]) -> None:
        self.d.polygon([(x * self.k, y * self.k) for x, y in pts], fill=col)

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, col: tuple[int, int, int]) -> None:
        self.d.ellipse(
            [(cx - rx) * self.k, (cy - ry) * self.k,
             (cx + rx) * self.k, (cy + ry) * self.k],
            fill=col,
        )

    def limb(
        self,
        a: tuple[float, float],
        b: tuple[float, float],
        wa: float,
        wb: float,
        col: tuple[int, int, int],
    ) -> None:
        x0, y0 = a
        x1, y1 = b
        dx = x1 - x0
        dy = y1 - y0
        length = math.hypot(dx, dy) or 1.0
        nx = -dy / length
        ny = dx / length
        self.poly(
            [
                (x0 + nx * wa / 2, y0 + ny * wa / 2),
                (x1 + nx * wb / 2, y1 + ny * wb / 2),
                (x1 - nx * wb / 2, y1 - ny * wb / 2),
                (x0 - nx * wa / 2, y0 - ny * wa / 2),
            ],
            col,
        )
        self.ellipse(x0, y0, wa / 2, wa / 2, col)
        self.ellipse(x1, y1, wb / 2, wb / 2, col)

    def render(self, palette: list[tuple[int, int, int]]) -> Image.Image:
        small = self.im.resize((self.size, self.size), Image.Resampling.BOX)
        px = small.load()
        for y in range(self.size):
            for x in range(self.size):
                r, g, b, a = px[x, y]
                if a < 112:
                    px[x, y] = TRANSPARENT
                else:
                    px[x, y] = _nearest_palette((r, g, b), palette)
        return small


def _nearest_palette(
    color: tuple[int, int, int],
    palette: list[tuple[int, int, int]],
) -> tuple[int, int, int, int]:
    best = palette[0]
    best_d = 10**12
    for candidate in palette:
        d = (
            (color[0] - candidate[0]) ** 2
            + (color[1] - candidate[1]) ** 2
            + (color[2] - candidate[2]) ** 2
        )
        if d < best_d:
            best = candidate
            best_d = d
    return best + (255,)


def _outline(img: Image.Image, palette: list[tuple[int, int, int]]) -> None:
    """Continuous 1px dark outline on every opaque pixel touching transparency."""
    size = img.size[0]
    px = img.load()
    outline_rgb = OUTLINE
    if outline_rgb not in palette:
        return
    edge: list[tuple[int, int]] = []
    for y in range(size):
        for x in range(size):
            if px[x, y][3] == 0:
                continue
            for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx = x + ox
                ny = y + oy
                if not (0 <= nx < size and 0 <= ny < size) or px[nx, ny][3] == 0:
                    edge.append((x, y))
                    break
    for x, y in edge:
        px[x, y] = outline_rgb + (255,)


# ── Serrated-edge helpers (Caipora-inspired) ──────────────

def _jag(base_pts: list[tuple[float, float]], depth: float = 1.2, freq: float = 2.5, rng: random.Random | None = None) -> list[tuple[float, float]]:
    """Add jagged serrations along a polyline.  depth=pixel amplitude, freq=segments per unit."""
    if rng is None:
        rng = random.Random(0)
    out: list[tuple[float, float]] = []
    for i in range(len(base_pts)):
        x0, y0 = base_pts[i]
        x1, y1 = base_pts[(i + 1) % len(base_pts)]
        out.append((x0, y0))
        seg_len = math.hypot(x1 - x0, y1 - y0)
        n = max(1, int(seg_len * freq))
        for j in range(1, n):
            t = j / n
            jx = x0 + (x1 - x0) * t
            jy = y0 + (y1 - y0) * t
            # Perpendicular offset with random sign and magnitude
            dx = x1 - x0
            dy = y1 - y0
            sl = math.hypot(dx, dy) or 1.0
            ox = -dy / sl
            oy = dx / sl
            d = depth * (0.4 + rng.random() * 0.6)
            if rng.random() < 0.5:
                d = -d
            out.append((jx + ox * d, jy + oy * d))
    return out


def _serrated_ellipse(cx: float, cy: float, rx: float, ry: float, n: int = 24, depth: float = 1.0, rng: random.Random | None = None) -> list[tuple[float, float]]:
    """Polygon approximating an ellipse with serrated edges."""
    if rng is None:
        rng = random.Random(0)
    pts: list[tuple[float, float]] = []
    for i in range(n):
        a = 2 * math.pi * i / n
        x = cx + math.cos(a) * rx
        y = cy + math.sin(a) * ry
        # Perturb outward/inward
        ox = math.cos(a)
        oy = math.sin(a)
        d = depth * (0.3 + rng.random() * 0.7)
        if rng.random() < 0.45:
            d = -d * 0.6
        pts.append((x + ox * d, y + oy * d))
    return pts


# ── Drawing routines ──────────────────────────────────────

def _hoof_and_shoe(p: Painter, foot: tuple[float, float], shoe: bool) -> None:
    """Draw hoof block and horseshoe at the foot position."""
    fx, fy = foot
    # Hoof block
    p.poly([
        (fx - 2.0, fy - 1.0),
        (fx + 2.0, fy - 1.0),
        (fx + 2.2, fy + 1.3),
        (fx - 2.2, fy + 1.3),
    ], HOOF)
    # Horseshoe band
    p.poly([
        (fx - 2.3, fy + 1.0),
        (fx + 2.3, fy + 1.0),
        (fx + 2.4, fy + 2.0),
        (fx - 2.4, fy + 2.0),
    ], IRON)
    if shoe:
        p.ellipse(fx - 1.6, fy + 1.5, 0.6, 0.35, IRON_LT)
        p.ellipse(fx + 1.6, fy + 1.5, 0.6, 0.35, IRON_LT)


def _leg(
    p: Painter,
    top: tuple[float, float],
    knee: tuple[float, float],
    foot: tuple[float, float],
    col: tuple[int, int, int],
    dark: tuple[int, int, int],
    shoe: bool,
    rng: random.Random,
) -> None:
    """Thigh + shin + hoof with a subtle knee and jaggy fur edges."""
    # Thigh — jaggy outer edge for fur texture
    thigh_pts = [
        (top[0] - 1.4, top[1] - 1.2),
        (top[0] + 1.6, top[1] - 0.8),
        (knee[0] + 1.3, knee[1] + 0.4),
        (knee[0] - 1.1, knee[1] + 0.8),
    ]
    p.poly(_jag(thigh_pts, depth=0.8, freq=3.0, rng=rng), col)
    # Shin
    shin_pts = [
        (knee[0] - 1.0, knee[1] - 0.3),
        (knee[0] + 1.2, knee[1] - 0.1),
        (foot[0] + 1.1, foot[1] + 0.5),
        (foot[0] - 1.1, foot[1] + 0.5),
    ]
    p.poly(_jag(shin_pts, depth=0.6, freq=3.5, rng=rng), col)
    # Dark shading on the back edge
    p.limb((top[0] - 0.9, top[1]), (knee[0] - 0.7, knee[1]), 1.2, 0.9, dark)
    p.limb((knee[0] - 0.7, knee[1]), (foot[0] - 0.5, foot[1]), 0.9, 0.7, dark)
    _hoof_and_shoe(p, foot, shoe)


def _tail(p: Painter, windup: bool, rng: random.Random) -> None:
    """Tail streaming back with a burning tip and jaggy fur."""
    base = (13.0, 30.0)
    mid = (7.0, 36.0)
    tip = (4.0, 43.0) if not windup else (3.0, 41.0)
    # Tail fur — segmented jaggy
    seg1 = [base, (base[0] - 2.0, base[1] + 2.0), mid, (mid[0] + 1.2, mid[1] - 1.0)]
    p.poly(_jag(seg1, depth=1.0, freq=2.5, rng=rng), FUR_DK)
    seg2 = [mid, (mid[0] - 1.5, mid[1] + 1.5), tip, (tip[0] + 0.8, tip[1] - 0.5)]
    p.poly(_jag(seg2, depth=0.8, freq=3.0, rng=rng), FUR_DK)
    # Burning tuft — more fire
    p.ellipse(tip[0], tip[1], 1.6, 1.6, FIRE_MID)
    p.ellipse(tip[0] + 0.7, tip[1] + 0.8, 1.1, 1.1, FIRE_HOT)
    p.ellipse(tip[0] - 0.5, tip[1] + 1.4, 0.8, 0.8, FIRE_DEEP)
    p.ellipse(tip[0] + 0.2, tip[1] + 1.8, 0.5, 0.5, FIRE_CORE)


def _body(p: Painter, windup: bool, rng: random.Random) -> None:
    """Barrel-shaped, muscular torso in profile with aggressive jaggy silhouette."""
    # Deep barrel base — heavily serrated ellipse (Caipora-level jaggedness)
    barrel = _serrated_ellipse(30.0, 33.0, 16.0, 11.0, n=32, depth=1.8, rng=rng)
    p.poly(barrel, FUR)
    # Rump mass (left)
    rump = _serrated_ellipse(17.0, 34.0, 10.0, 10.0, n=26, depth=1.6, rng=rng)
    p.poly(rump, FUR)
    # Chest/shoulder (right)
    chest = _serrated_ellipse(44.0, 31.0, 9.0, 10.0, n=22, depth=1.4, rng=rng)
    p.poly(chest, FUR)

    # Topline highlight — arched back, jaggy
    top_pts = [
        (12.0, 29.0), (22.0, 24.0), (34.0, 22.0), (46.0, 25.0), (50.0, 29.0),
        (46.0, 27.0), (34.0, 25.0), (22.0, 27.0), (12.0, 31.0),
    ]
    p.poly(_jag(top_pts, depth=1.0, freq=2.0, rng=rng), FUR_LT)

    # Belly shadow
    belly_pts = [
        (14.0, 41.0), (26.0, 43.0), (42.0, 42.0), (48.0, 39.0),
        (42.0, 37.0), (26.0, 39.0), (14.0, 38.0),
    ]
    p.poly(_jag(belly_pts, depth=0.8, freq=2.5, rng=rng), FUR_DK)

    # Muscle separations
    p.limb((25.0, 26.0), (24.0, 42.0), 1.2, 1.0, FUR_DK)
    p.limb((40.0, 26.0), (41.0, 41.0), 1.2, 1.0, FUR_DK)

    if windup:
        # Tense shoulder hump when coiling
        hump = _serrated_ellipse(46.0, 28.0, 7.0, 6.0, n=20, depth=1.2, rng=rng)
        p.poly(hump, FUR_LT)


def _neck_and_stump(p: Painter, rng: random.Random) -> None:
    """Thick neck rising right, ending in a raw bloody stump with jaggy mane."""
    # Neck — organic jaggy polygon
    neck_pts = [
        (40.0, 28.0), (45.0, 23.0), (50.0, 16.0), (53.0, 10.0),
        (57.0, 8.0), (59.0, 11.0), (57.0, 18.0), (51.0, 26.0),
        (45.0, 30.0),
    ]
    p.poly(_jag(neck_pts, depth=1.0, freq=2.0, rng=rng), FUR)

    # Crin / mane embers — jaggy crest of fire and fur
    mane_pts = [
        (42.0, 25.0), (46.0, 20.0), (50.0, 14.0), (54.0, 9.0), (58.0, 7.0),
        (56.0, 10.0), (52.0, 16.0), (48.0, 22.0), (44.0, 27.0),
    ]
    p.poly(_jag(mane_pts, depth=0.9, freq=3.0, rng=rng), FUR_DK)

    # Ember dots along the crest
    p.ellipse(46.0, 22.0, 1.4, 1.1, FIRE_DEEP)
    p.ellipse(49.5, 16.0, 1.2, 1.0, FIRE_MID)
    p.ellipse(52.5, 11.5, 1.1, 0.9, FIRE_HOT)
    p.ellipse(55.5, 9.0, 0.9, 0.7, FIRE_CORE)
    p.ellipse(48.0, 19.0, 0.7, 0.6, FIRE_HOT)

    # Raw stump flesh — irregular wound
    stump_pts = [
        (53.0, 7.5), (58.0, 6.5), (61.0, 8.5), (60.0, 11.5),
        (55.0, 11.5),
    ]
    p.poly(_jag(stump_pts, depth=0.5, freq=3.0, rng=rng), WOUND)


def _flame_shape(p: Painter, cx: float, base_y: float, height: float, width: float, rng: random.Random) -> None:
    """Draw one flame tongue with jagged edges."""
    # Outer deep flame — jaggy, but keep depth low so area doesn't shrink
    pts = [
        (cx - width * 0.35, base_y + 1.0),
        (cx + width * 0.2, base_y - height * 0.25),
        (cx + width * 0.55, base_y - height * 0.5),
        (cx + width * 0.15, base_y - height * 0.75),
        (cx + width * 0.4, base_y - height),
        (cx - width * 0.25, base_y - height * 0.8),
        (cx - width * 0.5, base_y - height * 0.45),
        (cx - width * 0.2, base_y - height * 0.2),
    ]
    p.poly(_jag(pts, depth=0.5, freq=2.5, rng=rng), FIRE_DEEP)
    # Mid flame
    pts2 = [
        (cx - width * 0.2, base_y),
        (cx + width * 0.1, base_y - height * 0.2),
        (cx + width * 0.35, base_y - height * 0.45),
        (cx, base_y - height * 0.7),
        (cx + width * 0.2, base_y - height * 0.9),
        (cx - width * 0.15, base_y - height * 0.75),
        (cx - width * 0.3, base_y - height * 0.4),
    ]
    p.poly(_jag(pts2, depth=0.4, freq=3.0, rng=rng), FIRE_MID)
    # Hot core
    pts3 = [
        (cx - width * 0.1, base_y - 1.0),
        (cx + width * 0.1, base_y - 1.0),
        (cx + width * 0.2, base_y - height * 0.4),
        (cx, base_y - height * 0.65),
        (cx - width * 0.2, base_y - height * 0.4),
    ]
    p.poly(_jag(pts3, depth=0.3, freq=3.5, rng=rng), FIRE_HOT)
    # White core
    p.ellipse(cx, base_y - height * 0.45, width * 0.14, height * 0.25, FIRE_CORE)


def _fire_column(p: Painter, windup: bool, rng: random.Random) -> None:
    """Column of fire bursting from the neck stump — more volume, more tongues."""
    base_x = 57.0
    base_y = 5.0
    height = 28.0 if not windup else 44.0
    width = 9.0 if not windup else 14.0

    # Thick base glow linking fire to body — engulfs the stump
    glow = _serrated_ellipse(base_x, base_y + 3.0, 6.5, 3.2, n=18, depth=0.9, rng=rng)
    p.poly(glow, FIRE_DEEP)
    glow2 = _serrated_ellipse(base_x, base_y + 2.0, 5.0, 2.2, n=14, depth=0.6, rng=rng)
    p.poly(glow2, FIRE_MID)
    p.ellipse(base_x, base_y + 1.5, 3.5, 1.5, FIRE_HOT)

    # Three intertwined flame tongues for a living column look
    _flame_shape(p, base_x - 2.0, base_y, height * 0.95, width * 0.85, rng)
    _flame_shape(p, base_x + 1.4, base_y, height, width, rng)
    _flame_shape(p, base_x + 0.3, base_y - 2.0, height * 0.85, width * 0.65, rng)

    if windup:
        # Additional overbright flare in windup — more tongues, more mass
        _flame_shape(p, base_x, base_y, height * 1.25, width * 0.75, rng)
        _flame_shape(p, base_x - 1.2, base_y - 3.5, height * 0.85, width * 0.55, rng)
        _flame_shape(p, base_x + 1.4, base_y - 2.5, height * 1.0, width * 0.6, rng)
        _flame_shape(p, base_x - 0.5, base_y - 5.0, height * 0.65, width * 0.4, rng)
        _flame_shape(p, base_x + 0.8, base_y - 6.0, height * 0.55, width * 0.35, rng)
        p.ellipse(base_x, base_y - height * 0.55, 2.0, 5.0, FIRE_CORE)
        p.ellipse(base_x + 1.4, base_y - height * 0.4, 1.4, 3.5, FIRE_HOT)
        p.ellipse(base_x - 1.0, base_y - height * 0.35, 1.2, 3.0, FIRE_CORE)
        p.ellipse(base_x + 0.3, base_y - height * 0.6, 1.0, 2.5, FIRE_HOT)
        # Surge base — garante volume extra de fogo no windup
        p.ellipse(base_x, base_y + 4.0, 5.0, 2.0, FIRE_DEEP)
        p.ellipse(base_x, base_y + 3.0, 3.5, 1.5, FIRE_MID)
        p.ellipse(base_x + 1.5, base_y + 3.5, 2.0, 1.0, FIRE_HOT)

    # Loose embers — more of them, some falling
    ember_count = 18 if not windup else 36
    for i in range(ember_count):
        ex = base_x + rng.uniform(-9.0, 9.0)
        ey = base_y - rng.uniform(4.0, height + 4.0)
        size = rng.uniform(0.4, 1.4)
        col = rng.choice([FIRE_MID, FIRE_HOT, FIRE_CORE])
        p.ellipse(ex, ey, size, size, col)

    # Falling embers (below base)
    fall_count = 6 if not windup else 14
    for i in range(fall_count):
        ex = base_x + rng.uniform(-5.0, 5.0)
        ey = base_y + rng.uniform(1.5, 7.0)
        size = rng.uniform(0.35, 0.9)
        p.ellipse(ex, ey, size, size, rng.choice([FIRE_DEEP, FIRE_MID]))


def _fire_rim_light(p: Painter, windup: bool, rng: random.Random) -> None:
    """Fire light licking the body edges near the stump — warm rim glow."""
    # Neck right edge glow — wider wash of fire light
    neck_glow = [
        (50.0, 22.0), (54.0, 16.0), (57.0, 11.0), (60.0, 8.0),
        (59.0, 13.0), (56.0, 19.0), (52.0, 26.0), (48.0, 28.0),
    ]
    p.poly(_jag(neck_glow, depth=0.8, freq=2.5, rng=rng), FIRE_DEEP)

    neck_glow_hot = [
        (53.0, 18.0), (56.0, 13.0), (58.0, 10.0), (57.0, 14.0),
        (54.0, 20.0), (51.0, 24.0),
    ]
    p.poly(_jag(neck_glow_hot, depth=0.5, freq=3.0, rng=rng), FIRE_MID)

    # Shoulder/top back glow
    shoulder_glow = [
        (42.0, 23.0), (46.0, 21.0), (50.0, 20.0), (53.0, 21.0),
        (50.0, 24.0), (46.0, 26.0), (42.0, 25.0),
    ]
    p.poly(_jag(shoulder_glow, depth=0.7, freq=2.5, rng=rng), FIRE_MID)

    # Rump/back fire reflection
    rump_glow = [
        (18.0, 28.0), (22.0, 26.0), (26.0, 27.0), (24.0, 30.0), (20.0, 31.0),
    ]
    p.poly(_jag(rump_glow, depth=0.5, freq=3.0, rng=rng), FIRE_DEEP)

    # Belly / flank small fire licks
    lick_count = 4 if not windup else 8
    for i in range(lick_count):
        fx = 46.0 + rng.uniform(-4.0, 5.0)
        fy = 28.0 + rng.uniform(-2.0, 5.0)
        p.ellipse(fx, fy, rng.uniform(0.6, 1.6), rng.uniform(0.8, 2.2), rng.choice([FIRE_DEEP, FIRE_MID]))


def _harness(p: Painter, rng: random.Random) -> None:
    """Cursed saddle + blood-red girth and straps with jaggy edges."""
    # Saddle on the back
    saddle_pts = [
        (26.0, 23.0), (40.0, 22.0), (43.0, 26.0), (41.0, 30.0),
        (27.0, 30.0), (24.0, 26.0),
    ]
    p.poly(_jag(saddle_pts, depth=0.4, freq=3.0, rng=rng), SADDLE)
    # Blood trim
    blood_pts = [
        (26.0, 23.0), (40.0, 22.0), (41.5, 24.0), (27.5, 25.0),
    ]
    p.poly(_jag(blood_pts, depth=0.3, freq=3.5, rng=rng), SADDLE_BLOOD)
    # Girth descending the flank
    p.limb((34.0, 30.0), (35.0, 42.0), 1.4, 1.1, SADDLE)
    # Buckle / blood stain
    p.ellipse(34.5, 33.0, 1.1, 1.1, SADDLE_BLOOD)
    # Rear strap
    p.limb((25.0, 26.0), (22.0, 40.0), 1.0, 0.7, SADDLE)
    # Front strap
    p.limb((41.0, 27.0), (44.0, 38.0), 0.9, 0.7, SADDLE)


def _legs(p: Painter, windup: bool, rng: random.Random) -> None:
    """All four legs; distant pair darker and without shoe glint."""
    if windup:
        _leg(p, (20.0, 34.0), (16.0, 46.0), (14.0, 57.0), FUR_DK, (18, 10, 9), False, rng)
        _leg(p, (46.0, 33.0), (50.0, 45.0), (52.0, 56.0), FUR_DK, (18, 10, 9), False, rng)
        _leg(p, (14.0, 36.0), (10.0, 48.0), (9.0, 60.0), FUR, FUR_DK, True, rng)
        _leg(p, (40.0, 36.0), (44.0, 49.0), (46.0, 61.0), FUR, FUR_DK, True, rng)
    else:
        _leg(p, (20.0, 34.0), (16.0, 46.0), (15.0, 58.0), FUR_DK, (18, 10, 9), False, rng)
        _leg(p, (46.0, 33.0), (50.0, 45.0), (51.0, 57.0), FUR_DK, (18, 10, 9), False, rng)
        _leg(p, (13.0, 36.0), (10.0, 48.0), (9.0, 60.0), FUR, FUR_DK, True, rng)
        _leg(p, (39.0, 36.0), (43.0, 48.0), (45.0, 61.0), FUR, FUR_DK, True, rng)


def _draw_mula(pose: str = "idle") -> Image.Image:
    windup = pose == "windup"
    random.seed(7)
    rng = random.Random(7)
    # Fire gets its own independent RNG so volume is predictable per pose
    fire_rng = random.Random(100 if not windup else 200)
    p = Painter()

    _tail(p, windup, rng)
    _legs(p, windup, rng)
    _body(p, windup, rng)
    _harness(p, rng)
    _neck_and_stump(p, rng)
    _fire_rim_light(p, windup, fire_rng)
    _fire_column(p, windup, fire_rng)

    img = p.render(MULA_PALETTE)
    _outline(img, MULA_PALETTE)
    return img


def _caipora_ref() -> Image.Image:
    """Load the canonical Caipora idle and scale it to game scale for the sheet."""
    path = os.path.join(OUT, "player_idle.png")
    if not os.path.exists(path):
        return Image.new("RGBA", (1, 1), TRANSPARENT)
    img = Image.open(path).convert("RGBA")
    return img


def _contact_sheet() -> None:
    """Contact sheet with idle, windup, and a Caipora reference for scale."""
    rng_state = random.getstate()
    idle = _draw_mula("idle")
    windup = _draw_mula("windup")
    random.setstate(rng_state)

    cell = SIZE + 32
    ref = _caipora_ref()
    ref_size = ref.size[0]
    sheet_w = cell * 2 + ref_size + 48
    sheet_h = max(cell, ref_size) + 40
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (18, 14, 15, 255))
    draw = ImageDraw.Draw(sheet)

    sheet.alpha_composite(idle, (16, 28))
    draw.text((16, 6), "mula idle", fill=(230, 210, 180, 255))

    sheet.alpha_composite(windup, (16 + cell, 28))
    draw.text((16 + cell, 6), "mula windup", fill=(230, 210, 180, 255))

    ref_x = 16 + cell * 2
    sheet.alpha_composite(ref, (ref_x, 28))
    draw.text((ref_x, 6), "caipora ref (96px)", fill=(230, 210, 180, 255))

    sheet.save(os.path.join(OUT, "mula_contact_sheet.png"))


def generate_all() -> None:
    os.makedirs(OUT, exist_ok=True)
    _draw_mula("idle").save(os.path.join(OUT, "mula_idle.png"))
    _draw_mula("windup").save(os.path.join(OUT, "mula_windup.png"))
    _contact_sheet()
    print("[gen_mula] Mula sem Cabeça generated: idle + windup (192x192) + contact sheet")


if __name__ == "__main__":
    generate_all()

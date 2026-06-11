#!/usr/bin/env python3
"""Generate the Mula sem Cabeça boss sprites — premium organic pipeline.

Art law: docs/PLANO-redesign-mula.md (to be consolidated into
CONCEITO-mula.md after approval). The Mula is the Phase 1 boss: a headless
mule whose neck stump jets a column of fire, wearing a blood-red cursed
harness and shining iron horseshoes.

Pipeline: organic vector shapes on a 64 logical grid, supersampled 8x,
area-downsampled to 192x192, closed-palette snap, continuous 1px dark outline.
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
) -> None:
    """Thigh + shin + hoof with a subtle knee."""
    # Thigh
    p.limb(top, knee, 3.2, 2.4, col)
    # Shin
    p.limb(knee, foot, 2.2, 1.9, col)
    # Dark shading on the back edge
    p.limb((top[0] - 0.9, top[1]), (knee[0] - 0.7, knee[1]), 1.2, 0.9, dark)
    p.limb((knee[0] - 0.7, knee[1]), (foot[0] - 0.5, foot[1]), 0.9, 0.7, dark)
    _hoof_and_shoe(p, foot, shoe)


def _tail(p: Painter, windup: bool) -> None:
    """Tail streaming back with a burning tip."""
    base = (13.0, 30.0)
    mid = (7.0, 36.0)
    tip = (4.0, 43.0) if not windup else (3.0, 41.0)
    p.limb(base, mid, 2.6, 1.8, FUR_DK)
    p.limb(mid, tip, 1.8, 1.0, FUR_DK)
    # Burning tuft
    p.ellipse(tip[0], tip[1], 1.4, 1.4, FIRE_MID)
    p.ellipse(tip[0] + 0.6, tip[1] + 0.8, 0.9, 0.9, FIRE_HOT)
    p.ellipse(tip[0] - 0.4, tip[1] + 1.2, 0.6, 0.6, FIRE_DEEP)


def _body(p: Painter, windup: bool) -> None:
    """Barrel-shaped, muscular torso in profile."""
    # Deep barrel base
    p.ellipse(30.0, 33.0, 16.0, 11.0, FUR)
    # Rump mass (left)
    p.ellipse(17.0, 34.0, 10.0, 10.0, FUR)
    # Chest/shoulder (right)
    p.ellipse(44.0, 31.0, 9.0, 10.0, FUR)

    # Topline highlight — arched back
    p.poly([
        (12.0, 29.0), (22.0, 24.0), (34.0, 22.0), (46.0, 25.0), (50.0, 29.0),
        (46.0, 27.0), (34.0, 25.0), (22.0, 27.0), (12.0, 31.0),
    ], FUR_LT)

    # Belly shadow
    p.poly([
        (14.0, 41.0), (26.0, 43.0), (42.0, 42.0), (48.0, 39.0),
        (42.0, 37.0), (26.0, 39.0), (14.0, 38.0),
    ], FUR_DK)

    # Muscle separations
    p.limb((25.0, 26.0), (24.0, 42.0), 1.2, 1.0, FUR_DK)
    p.limb((40.0, 26.0), (41.0, 41.0), 1.2, 1.0, FUR_DK)

    if windup:
        # Tense shoulder hump when coiling
        p.ellipse(46.0, 28.0, 7.0, 6.0, FUR_LT)


def _neck_and_stump(p: Painter) -> None:
    """Thick neck rising right, ending in a raw bloody stump."""
    neck_pts = [
        (40.0, 28.0), (45.0, 23.0), (50.0, 16.0), (53.0, 10.0),
        (57.0, 8.0), (59.0, 11.0), (57.0, 18.0), (51.0, 26.0),
        (45.0, 30.0),
    ]
    p.poly(neck_pts, FUR)
    # Mane embers along the crest
    p.ellipse(46.0, 22.0, 1.3, 1.0, FIRE_DEEP)
    p.ellipse(49.5, 16.0, 1.1, 0.9, FIRE_MID)
    p.ellipse(52.5, 11.5, 1.0, 0.8, FIRE_HOT)
    p.ellipse(55.5, 9.0, 0.8, 0.6, FIRE_CORE)

    # Raw stump flesh
    stump_pts = [
        (53.0, 7.5), (58.0, 6.5), (61.0, 8.5), (60.0, 11.5),
        (55.0, 11.5),
    ]
    p.poly(stump_pts, WOUND)


def _flame_shape(p: Painter, cx: float, base_y: float, height: float, width: float) -> None:
    """Draw one flame tongue with jagged edges."""
    # Outer deep flame
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
    p.poly(pts, FIRE_DEEP)
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
    p.poly(pts2, FIRE_MID)
    # Hot core
    pts3 = [
        (cx - width * 0.1, base_y - 1.0),
        (cx + width * 0.1, base_y - 1.0),
        (cx + width * 0.2, base_y - height * 0.4),
        (cx, base_y - height * 0.65),
        (cx - width * 0.2, base_y - height * 0.4),
    ]
    p.poly(pts3, FIRE_HOT)
    # White core
    p.ellipse(cx, base_y - height * 0.45, width * 0.12, height * 0.22, FIRE_CORE)


def _fire_column(p: Painter, windup: bool) -> None:
    """Column of fire bursting from the neck stump."""
    rng = random.Random(7)
    base_x = 57.0
    base_y = 6.0
    height = 24.0 if not windup else 32.0
    width = 7.0 if not windup else 10.0

    # Base glow linking fire to body
    p.ellipse(base_x, base_y + 2.0, 4.0, 2.0, FIRE_DEEP)

    # Two intertwined flame tongues for a living column look
    _flame_shape(p, base_x - 1.2, base_y, height * 0.95, width * 0.85)
    _flame_shape(p, base_x + 1.0, base_y, height, width)

    if windup:
        # Additional overbright flare in windup
        _flame_shape(p, base_x, base_y, height * 1.1, width * 0.6)
        p.ellipse(base_x, base_y - height * 0.55, 1.2, 3.5, FIRE_CORE)

    # Loose embers
    ember_count = 10 if not windup else 18
    for i in range(ember_count):
        ex = base_x + rng.uniform(-6.0, 6.0)
        ey = base_y - rng.uniform(4.0, height)
        size = rng.uniform(0.35, 0.9)
        col = rng.choice([FIRE_MID, FIRE_HOT, FIRE_CORE])
        p.ellipse(ex, ey, size, size, col)


def _harness(p: Painter) -> None:
    """Cursed saddle + blood-red girth and straps."""
    # Saddle on the back
    p.poly([
        (26.0, 23.0), (40.0, 22.0), (43.0, 26.0), (41.0, 30.0),
        (27.0, 30.0), (24.0, 26.0),
    ], SADDLE)
    # Blood trim
    p.poly([
        (26.0, 23.0), (40.0, 22.0), (41.5, 24.0), (27.5, 25.0),
    ], SADDLE_BLOOD)
    # Girth descending the flank
    p.limb((34.0, 30.0), (35.0, 42.0), 1.4, 1.1, SADDLE)
    # Buckle / blood stain
    p.ellipse(34.5, 33.0, 1.1, 1.1, SADDLE_BLOOD)
    # Rear strap
    p.limb((25.0, 26.0), (22.0, 40.0), 1.0, 0.7, SADDLE)
    # Front strap
    p.limb((41.0, 27.0), (44.0, 38.0), 0.9, 0.7, SADDLE)


def _legs(p: Painter, windup: bool) -> None:
    """All four legs; distant pair darker and without shoe glint."""
    if windup:
        # Distant hind leg
        _leg(p, (20.0, 34.0), (16.0, 46.0), (14.0, 57.0), FUR_DK, (18, 10, 9), False)
        # Distant foreleg
        _leg(p, (46.0, 33.0), (50.0, 45.0), (52.0, 56.0), FUR_DK, (18, 10, 9), False)
        # Near hind leg — planted and flexed
        _leg(p, (14.0, 36.0), (10.0, 48.0), (9.0, 60.0), FUR, FUR_DK, True)
        # Near foreleg — coiled
        _leg(p, (40.0, 36.0), (44.0, 49.0), (46.0, 61.0), FUR, FUR_DK, True)
    else:
        # Distant hind leg
        _leg(p, (20.0, 34.0), (16.0, 46.0), (15.0, 58.0), FUR_DK, (18, 10, 9), False)
        # Distant foreleg
        _leg(p, (46.0, 33.0), (50.0, 45.0), (51.0, 57.0), FUR_DK, (18, 10, 9), False)
        # Near hind leg
        _leg(p, (13.0, 36.0), (10.0, 48.0), (9.0, 60.0), FUR, FUR_DK, True)
        # Near foreleg
        _leg(p, (39.0, 36.0), (43.0, 48.0), (45.0, 61.0), FUR, FUR_DK, True)


def _draw_mula(pose: str = "idle") -> Image.Image:
    windup = pose == "windup"
    random.seed(7)
    p = Painter()

    _tail(p, windup)
    _legs(p, windup)
    _body(p, windup)
    _harness(p)
    _neck_and_stump(p)
    _fire_column(p, windup)

    img = p.render(MULA_PALETTE)
    _outline(img, MULA_PALETTE)
    return img


def _caipora_ref() -> Image.Image:
    """Load the canonical Caipora idle and scale it to game scale for the sheet."""
    path = os.path.join(OUT, "player_idle.png")
    if not os.path.exists(path):
        return Image.new("RGBA", (1, 1), TRANSPARENT)
    img = Image.open(path).convert("RGBA")
    # Game scale: Caipora arena scale is 1.2; Mula arena scale will be ~0.966.
    # For hierarchy comparison we show both at 1.0 source texel size side-by-side.
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

    # Mula idle
    sheet.alpha_composite(idle, (16, 28))
    draw.text((16, 6), "mula idle", fill=(230, 210, 180, 255))

    # Mula windup
    sheet.alpha_composite(windup, (16 + cell, 28))
    draw.text((16 + cell, 6), "mula windup", fill=(230, 210, 180, 255))

    # Caipora reference
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

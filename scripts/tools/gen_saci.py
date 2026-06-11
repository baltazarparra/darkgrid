#!/usr/bin/env python3
"""Generate the Saci arena sprites.

The Saci is a child-sized folk-horror boss: smaller than the Caipora in height,
but sharper in silhouette. He reads as one blackened hopping leg, a red blade of
a cap, ember eyes, pipe smoke, and a dirty whirlwind. He must not use the
Caipora's pure white eyes, exact orange mane colors, or crystal green.
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw


OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")
SIZE = 128
SS = 8

TRANSPARENT = (0, 0, 0, 0)
OUTLINE = (18, 8, 7)
CHAR = (34, 19, 17)
CHAR_LT = (57, 31, 25)
CAP_DK = (99, 9, 8)
CAP = (190, 24, 18)
CAP_HOT = (232, 70, 36)
EMBER = (238, 92, 28)
EMBER_HOT = (255, 178, 82)
PIPE = (88, 52, 28)
PIPE_DK = (42, 26, 18)
SMOKE = (142, 130, 112)
ASH = (72, 63, 52)
BLOOD = (139, 0, 0)

PALETTE = [
    OUTLINE,
    CHAR,
    CHAR_LT,
    CAP_DK,
    CAP,
    CAP_HOT,
    EMBER,
    EMBER_HOT,
    PIPE,
    PIPE_DK,
    SMOKE,
    ASH,
    BLOOD,
]


class Painter:
    def __init__(self) -> None:
        self.im = Image.new("RGBA", (SIZE * SS, SIZE * SS), TRANSPARENT)
        self.d = ImageDraw.Draw(self.im)

    def poly(self, pts: list[tuple[float, float]], col: tuple[int, int, int]) -> None:
        self.d.polygon([(x * SS, y * SS) for x, y in pts], fill=col)

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, col: tuple[int, int, int]) -> None:
        self.d.ellipse(
            [(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS],
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

    def render(self) -> Image.Image:
        small = self.im.resize((SIZE, SIZE), Image.Resampling.BOX)
        px = small.load()
        for y in range(SIZE):
            for x in range(SIZE):
                r, g, b, a = px[x, y]
                if a < 112:
                    px[x, y] = TRANSPARENT
                else:
                    px[x, y] = _nearest_palette((r, g, b))
        return small


def _nearest_palette(color: tuple[int, int, int]) -> tuple[int, int, int, int]:
    best = PALETTE[0]
    best_d = 10**12
    for candidate in PALETTE:
        d = (
            (color[0] - candidate[0]) ** 2
            + (color[1] - candidate[1]) ** 2
            + (color[2] - candidate[2]) ** 2
        )
        if d < best_d:
            best = candidate
            best_d = d
    return best + (255,)


def _outline(img: Image.Image) -> None:
    px = img.load()
    edge: list[tuple[int, int]] = []
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y][3] == 0:
                continue
            for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx = x + ox
                ny = y + oy
                if not (0 <= nx < img.width and 0 <= ny < img.height) or px[nx, ny][3] == 0:
                    edge.append((x, y))
                    break
    for x, y in edge:
        px[x, y] = OUTLINE + (255,)


def _shrink_child(img: Image.Image, factor: float = 0.78) -> Image.Image:
    px = img.load()
    xs: list[int] = []
    ys: list[int] = []
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y][3] > 0:
                xs.append(x)
                ys.append(y)
    if not xs:
        return img
    left = min(xs)
    top = min(ys)
    right = max(xs) + 1
    bottom = max(ys) + 1
    crop = img.crop((left, top, right, bottom))
    new_size = (max(1, int(round(crop.width * factor))), max(1, int(round(crop.height * factor))))
    small = crop.resize(new_size, Image.Resampling.NEAREST)
    out = Image.new("RGBA", img.size, TRANSPARENT)
    # Keep the foot line anchored while the cap and body shrink into child scale.
    paste_x = int(round((left + right) * 0.5 - small.width * 0.5))
    paste_y = bottom - small.height
    out.alpha_composite(small, (paste_x, paste_y))
    return out


def _draw_whirlwind(p: Painter, windup: bool) -> None:
    rings = [
        [(31, 95), (47, 87), (70, 87), (88, 94), (82, 101), (55, 101), (33, 99)],
        [(43, 78), (58, 71), (77, 73), (91, 80), (85, 86), (61, 85), (42, 83)],
        [(52, 61), (67, 55), (84, 59), (96, 66), (88, 70), (67, 69), (51, 66)],
    ]
    for i, pts in enumerate(rings):
        if windup and i > 0:
            pts = [(x + 5, y - 4) for x, y in pts]
        p.poly(pts, ASH if i % 2 == 0 else SMOKE)
    # Broken ash teeth in the spiral: the house is burning around him.
    for x, y in ((37, 88), (49, 72), (83, 64), (91, 83), (72, 101)):
        p.ellipse(x + (4 if windup else 0), y - (3 if windup else 0), 1.3, 1.0, EMBER)


def _draw_body(p: Painter, windup: bool) -> None:
    lean = 8 if windup else 0
    crouch = -6 if windup else 0
    hx = 58 + lean
    hy = 36 + crouch
    bx = 56 + lean * 0.55
    by = 61 + crouch * 0.4
    foot_y = 96

    # Cap first: a red knife-shape, not a soft hat.
    if windup:
        p.poly([(hx - 17, hy - 15), (hx - 3, hy - 34), (hx + 22, hy - 26), (hx + 16, hy - 6)], CAP_DK)
        p.poly([(hx - 16, hy - 16), (hx - 4, hy - 31), (hx + 18, hy - 23), (hx + 11, hy - 7)], CAP)
        p.poly([(hx - 12, hy - 15), (hx - 4, hy - 28), (hx + 3, hy - 20)], CAP_HOT)
    else:
        p.poly([(hx - 18, hy - 14), (hx - 8, hy - 31), (hx + 17, hy - 25), (hx + 14, hy - 7)], CAP_DK)
        p.poly([(hx - 17, hy - 14), (hx - 7, hy - 28), (hx + 14, hy - 23), (hx + 9, hy - 7)], CAP)
        p.poly([(hx - 13, hy - 13), (hx - 8, hy - 25), (hx, hy - 19)], CAP_HOT)

    # Head, burnt face, ember slits.
    p.poly(
        [
            (hx - 13, hy - 7),
            (hx + 8, hy - 10),
            (hx + 14, hy + 4),
            (hx + 8, hy + 17),
            (hx - 8, hy + 18),
            (hx - 15, hy + 7),
        ],
        CHAR,
    )
    p.poly([(hx - 13, hy - 7), (hx - 3, hy - 9), (hx - 6, hy + 18), (hx - 15, hy + 7)], OUTLINE)
    p.ellipse(hx - 4.8, hy + 2.5, 2.5, 0.9, EMBER_HOT)
    p.ellipse(hx + 5.4, hy + 2.0, 2.5, 0.9, EMBER_HOT)
    p.limb((hx + 9, hy + 10), (hx + 23, hy + 13), 2.0, 1.2, PIPE)
    p.ellipse(hx + 27, hy + 12, 3.0, 2.5, PIPE_DK)
    p.ellipse(hx + 28, hy + 9, 1.1, 1.0, EMBER)

    # Smoke beads from the pipe and cap.
    for i, (sx, sy) in enumerate(((91, 39), (97, 31), (93, 23), (102, 18))):
        p.ellipse(sx + (5 if windup else 0), sy - (6 if windup and i > 0 else 0), 2.0 - i * 0.25, 1.7, SMOKE)

    # Compact torso and long arms: child-sized, predatory, not cute.
    p.poly(
        [
            (bx - 10, by - 8),
            (bx + 9, by - 7),
            (bx + 14, by + 12),
            (bx + 4, by + 28),
            (bx - 9, by + 25),
            (bx - 14, by + 8),
        ],
        CHAR,
    )
    p.poly([(bx + 5, by - 6), (bx + 14, by + 12), (bx + 4, by + 28), (bx + 1, by + 4)], CHAR_LT)
    p.ellipse(bx - 2, by + 9, 1.4, 1.4, EMBER)
    p.ellipse(bx + 5, by + 18, 1.1, 1.1, EMBER_HOT)
    p.limb((bx - 10, by + 1), (bx - 29, by + 14), 4.2, 2.6, CHAR)
    p.limb((bx + 9, by + 1), (bx + 27, by - 2), 4.0, 2.4, CHAR_LT)
    p.ellipse(bx - 31, by + 15, 2.5, 2.0, CHAR)
    p.ellipse(bx + 30, by - 2, 2.4, 2.0, CHAR_LT)

    # One leg only. Windup coils it under the body; idle plants it on ash.
    if windup:
        knee = (bx - 1, by + 34)
        ankle = (bx + 18, foot_y - 4)
    else:
        knee = (bx - 2, by + 36)
        ankle = (bx - 4, foot_y)
    p.limb((bx + 1, by + 24), knee, 6.2, 4.6, CHAR)
    p.limb(knee, ankle, 4.8, 3.2, CHAR_LT)
    p.limb(ankle, (ankle[0] + 13, foot_y + 1), 3.6, 2.0, CHAR)
    p.ellipse(ankle[0] + 14, foot_y + 1, 2.3, 1.4, OUTLINE)
    p.limb((ankle[0] - 1, ankle[1] - 7), (ankle[0] + 2, ankle[1] - 2), 1.0, 0.8, EMBER)

    # Blood and soot catch the horror physically.
    p.limb((bx - 7, by + 25), (bx - 12, by + 33), 1.4, 0.9, BLOOD)
    p.ellipse(bx - 12, by + 35, 1.4, 1.0, BLOOD)


def saci(pose: str = "idle") -> Image.Image:
    windup = pose == "windup"
    p = Painter()
    _draw_whirlwind(p, windup)
    _draw_body(p, windup)
    img = p.render()
    img = _shrink_child(img)
    _outline(img)
    return img


def _contact_sheet() -> None:
    frames = [("idle", saci("idle")), ("windup", saci("windup"))]
    caipora_path = os.path.join(OUT, "player_idle.png")
    caipora = Image.open(caipora_path).convert("RGBA") if os.path.exists(caipora_path) else None
    zoom = 2
    cell = SIZE * zoom + 18
    caipora_w = caipora.width * zoom + 18 if caipora else 0
    width = cell * len(frames) + caipora_w
    height = SIZE * zoom + 54
    sheet = Image.new("RGBA", (width, height), (18, 14, 15, 255))
    draw = ImageDraw.Draw(sheet)
    base_y = height - 32
    for i, (label, img) in enumerate(frames):
        x = i * cell
        big = img.resize((SIZE * zoom, SIZE * zoom), Image.Resampling.NEAREST)
        sheet.alpha_composite(big, (x + 8, base_y - big.height))
        tiny = img.resize((32, 32), Image.Resampling.BOX)
        sheet.alpha_composite(tiny, (x + 8, base_y + 4))
        draw.text((x + 8, 4), f"saci {label}", fill=(230, 210, 180, 255))
    if caipora:
        x = cell * len(frames)
        big = caipora.resize((caipora.width * zoom, caipora.height * zoom), Image.Resampling.NEAREST)
        sheet.alpha_composite(big, (x + 8, base_y - big.height))
        draw.text((x + 8, 4), "caipora ref", fill=(230, 210, 180, 255))
    sheet.save(os.path.join(OUT, "saci_contact_sheet.png"))


def generate_all() -> None:
    os.makedirs(OUT, exist_ok=True)
    saci("idle").save(os.path.join(OUT, "saci_idle.png"))
    saci("windup").save(os.path.join(OUT, "saci_windup.png"))
    _contact_sheet()
    print("[gen_saci] Saci idle/windup (128x128) + contact sheet generated")


if __name__ == "__main__":
    generate_all()

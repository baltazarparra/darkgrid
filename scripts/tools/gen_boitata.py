#!/usr/bin/env python3
"""Generate the Boitata arena sprites.

The Boitata is a giant serpent of corpse-fire: broader than an adult invader,
taller than the child-sized Caipora, but not borrowing the protagonist's exact
orange, white eyes, or crystal green. The arena uses the same node scale as the
premium humanoid sprites (1.2); mass comes from the canvas and silhouette.
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw


OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")
SIZE = (160, 128)
SS = 8

TRANSPARENT = (0, 0, 0, 0)
OUTLINE = (17, 8, 6)
CHAR = (28, 13, 9)
CHAR_LT = (49, 20, 12)
SCALE_DK = (72, 22, 13)
SCALE = (132, 38, 19)
FIRE = (226, 87, 24)
FIRE_HOT = (255, 178, 72)
FIRE_WHITE = (255, 232, 174)
ASH = (126, 119, 98)
BLOOD = (139, 0, 0)
EYE = (250, 203, 83)

PALETTE = [
    OUTLINE,
    CHAR,
    CHAR_LT,
    SCALE_DK,
    SCALE,
    FIRE,
    FIRE_HOT,
    FIRE_WHITE,
    ASH,
    BLOOD,
    EYE,
]


class Painter:
    def __init__(self) -> None:
        self.im = Image.new("RGBA", (SIZE[0] * SS, SIZE[1] * SS), TRANSPARENT)
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
        small = self.im.resize(SIZE, Image.Resampling.BOX)
        px = small.load()
        for y in range(SIZE[1]):
            for x in range(SIZE[0]):
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


def _draw_coils(p: Painter, windup: bool) -> None:
    lift = -10.0 if windup else 0.0
    # Burnt outer coils: a wide, readable horizontal mass.
    p.ellipse(80, 89, 58, 24, CHAR)
    p.ellipse(49, 88, 31, 18, SCALE_DK)
    p.ellipse(103, 88, 37, 20, SCALE_DK)
    p.ellipse(77, 89, 34, 13, OUTLINE)
    p.ellipse(80, 90, 25, 8, CHAR_LT)

    # Body crossing over the front coil, pointed left toward the Caipora.
    p.limb((121, 86), (93, 72 + lift * 0.25), 23, 19, SCALE_DK)
    p.limb((95, 72 + lift * 0.25), (62, 70 + lift * 0.35), 20, 16, SCALE)
    p.limb((64, 70 + lift * 0.35), (38, 81), 16, 10, SCALE_DK)
    p.poly([(35, 78), (20, 72), (30, 84), (18, 91), (39, 87)], CHAR)

    # Charred belly slits and blood scars keep the horror material.
    for x, y, ang in ((45, 76, -4), (58, 71, -2), (72, 69, 0), (91, 72, 3), (111, 82, 5)):
        p.limb((x - 4, y + ang * 0.2), (x + 4, y - ang * 0.2), 1.2, 1.0, CHAR)
    p.limb((115, 96), (126, 105), 2.0, 1.2, BLOOD)
    p.ellipse(129, 106, 1.8, 1.5, BLOOD)

    # Scale teeth along the spine. Large notches read at 32px.
    spine = [
        (37, 65 + lift * 0.2),
        (49, 61 + lift * 0.3),
        (63, 58 + lift * 0.4),
        (78, 58 + lift * 0.5),
        (94, 62 + lift * 0.6),
        (109, 70 + lift * 0.7),
        (123, 81),
    ]
    for i, (x, y) in enumerate(spine):
        h = 8 + (i % 2) * 3
        p.poly([(x - 4, y), (x + 3, y - h), (x + 5, y + 1)], FIRE if i % 3 else FIRE_HOT)


def _draw_head(p: Painter, windup: bool) -> None:
    if windup:
        neck_a = (98, 67)
        neck_b = (88, 38)
        head = (74, 25)
        jaw_y = 39
    else:
        neck_a = (91, 70)
        neck_b = (72, 53)
        head = (55, 47)
        jaw_y = 60

    p.limb(neck_a, neck_b, 18, 14, SCALE_DK)
    p.limb((neck_b[0] + 2, neck_b[1] + 2), (head[0] + 10, head[1] + 9), 15, 11, SCALE)

    hx, hy = head
    p.poly(
        [
            (hx + 17, hy - 10),
            (hx - 2, hy - 13),
            (hx - 18, hy - 5),
            (hx - 25, hy + 8),
            (hx - 18, hy + 18),
            (hx + 2, hy + 21),
            (hx + 19, hy + 13),
        ],
        SCALE_DK,
    )
    p.poly([(hx - 23, hy + 8), (hx - 36, hy + 2), (hx - 25, hy + 13)], CHAR)
    p.poly([(hx - 20, hy + 12), (hx - 35, jaw_y), (hx - 13, hy + 20)], CHAR_LT)
    p.poly([(hx - 11, hy + 15), (hx - 20, hy + 31), (hx + 5, hy + 22)], CHAR)

    # Horns/ash roots, not cute eyes. Eyes are hot slits, never protagonist white dots.
    p.limb((hx - 3, hy - 10), (hx - 13, hy - 25), 3.0, 1.2, ASH)
    p.limb((hx + 8, hy - 8), (hx + 15, hy - 22), 3.0, 1.2, ASH)
    p.ellipse(hx - 6.5, hy + 2.0, 3.4, 1.0, EYE)
    p.ellipse(hx + 6.0, hy + 1.5, 3.0, 0.9, EYE)
    p.limb((hx - 16, hy + 11), (hx - 30, hy + 5), 1.6, 0.8, FIRE_HOT)
    p.limb((hx - 16, hy + 14), (hx - 29, hy + 18), 1.4, 0.7, FIRE)

    if windup:
        p.ellipse(hx - 2, hy + 10, 7.5, 5.5, FIRE_WHITE)
        p.ellipse(hx - 2, hy + 10, 4.5, 3.2, FIRE_HOT)


def _draw_fire(p: Painter, windup: bool) -> None:
    flames = [
        (26, 64, 8, 19),
        (45, 57, 6, 14),
        (67, 55, 6, 18),
        (88, 57, 7, 16),
        (112, 66, 7, 18),
        (132, 83, 6, 14),
    ]
    for i, (x, y, w, h) in enumerate(flames):
        top = y - h * (1.35 if windup and i in (1, 2, 3) else 1.0)
        col = FIRE_HOT if i % 2 else FIRE
        p.poly([(x - w, y), (x, top), (x + w, y)], col)
        if i in (2, 3) or windup:
            p.poly([(x - w * 0.42, y - 2), (x, top + h * 0.38), (x + w * 0.42, y - 2)], FIRE_WHITE)

    # Floating corpse-lights around the body, sparse enough for browser sprites.
    sparks = [(20, 55), (38, 38), (79, 41), (124, 52), (140, 73)]
    for i, (x, y) in enumerate(sparks):
        r = 1.2 if i % 2 else 1.7
        p.ellipse(x, y - (6 if windup and i in (1, 2) else 0), r, r, FIRE_HOT)


def boitata(pose: str = "idle") -> Image.Image:
    windup = pose == "windup"
    p = Painter()
    _draw_fire(p, windup)
    _draw_coils(p, windup)
    _draw_head(p, windup)
    img = p.render()
    _outline(img)
    return img


def _contact_sheet() -> None:
    frames = [("idle", boitata("idle")), ("windup", boitata("windup"))]
    caipora_path = os.path.join(OUT, "player_idle.png")
    caipora = Image.open(caipora_path).convert("RGBA") if os.path.exists(caipora_path) else None
    zoom = 2
    cell_w = SIZE[0] * zoom + 18
    height = SIZE[1] * zoom + 54
    width = cell_w * len(frames) + ((caipora.width * zoom + 18) if caipora else 0)
    sheet = Image.new("RGBA", (width, height), (18, 14, 15, 255))
    draw = ImageDraw.Draw(sheet)
    base_y = height - 32
    for i, (label, img) in enumerate(frames):
        x = i * cell_w
        big = img.resize((SIZE[0] * zoom, SIZE[1] * zoom), Image.Resampling.NEAREST)
        sheet.alpha_composite(big, (x + 8, base_y - big.height))
        tiny = img.resize((40, 32), Image.Resampling.BOX)
        sheet.alpha_composite(tiny, (x + 8, base_y + 4))
        draw.text((x + 8, 4), f"boitata {label}", fill=(230, 210, 180, 255))
    if caipora:
        x = cell_w * len(frames)
        big = caipora.resize((caipora.width * zoom, caipora.height * zoom), Image.Resampling.NEAREST)
        sheet.alpha_composite(big, (x + 8, base_y - big.height))
        draw.text((x + 8, 4), "caipora ref", fill=(230, 210, 180, 255))
    sheet.save(os.path.join(OUT, "boitata_contact_sheet.png"))


def generate_all() -> None:
    os.makedirs(OUT, exist_ok=True)
    boitata("idle").save(os.path.join(OUT, "boitata_idle.png"))
    boitata("windup").save(os.path.join(OUT, "boitata_windup.png"))
    _contact_sheet()
    print("[gen_boitata] Boitata idle/windup (160x128) + contact sheet generated")


if __name__ == "__main__":
    generate_all()

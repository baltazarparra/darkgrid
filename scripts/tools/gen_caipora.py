#!/usr/bin/env python3
"""Generate the Caipora protagonist sprites.

Concept: "A Guardia da Mata" (see docs/CONCEITO-protagonista.md).
Blood-red mane worn like a cape, void face with two glowing white eyes,
dark horns rising from a leaf hood, layered leaf poncho, leather pouch,
bare feet, and a gnarled staff crowned by a glowing green crystal.

Output contract is intentionally stable:
  player_idle/walk_1/walk_2/windup/strike/recover.png
  player_idle/walk_1/walk_2/windup/strike/recover_chama.png

CHAMA variant = "juba em brasa": the mane ignites (fire ramp + embers).
The PNGs are generated assets. Do not hand-edit them as source of truth.
"""

from __future__ import annotations

import math
import os
from dataclasses import dataclass

from PIL import Image, ImageDraw


OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")
SIZE = 96
SS = 8

# Closed palette. One warm accent (mane/fire) + one cold accent (crystal/eyes).
HAIR_DK = (68, 11, 16)
HAIR = (142, 28, 18)
F_LOW = (206, 50, 8)
F_MID = (255, 104, 8)
F_HOT = (255, 176, 50)
F_CORE = (255, 239, 178)

SK_DK = (70, 40, 28)
SK = (116, 70, 44)
SK_HL = (168, 108, 64)

LF_DK2 = (10, 19, 14)
LF_DK = (22, 39, 23)
LF = (48, 78, 38)
LF_HL = (92, 122, 56)

WOOD_DK = (31, 18, 16)
WOOD = (65, 38, 29)
VOID = (10, 7, 18)
EYE_GLOW = (200, 232, 212)
EYE_WHITE = (255, 255, 255)
CR = (29, 167, 92)
CR_HL = (138, 240, 176)
OUTLINE = (8, 7, 10)

HAIR_RAMP_BASE = [HAIR_DK, HAIR, F_LOW]
HAIR_RAMP_CHAMA = [HAIR_DK, F_LOW, F_MID, F_HOT]
GLOW_COLORS = {F_MID, F_HOT, F_CORE, EYE_GLOW, EYE_WHITE, CR, CR_HL}
PALETTE = [
    HAIR_DK,
    HAIR,
    F_LOW,
    F_MID,
    F_HOT,
    F_CORE,
    SK_DK,
    SK,
    SK_HL,
    LF_DK2,
    LF_DK,
    LF,
    LF_HL,
    WOOD_DK,
    WOOD,
    VOID,
    EYE_GLOW,
    EYE_WHITE,
    CR,
    CR_HL,
]
# Warm rim: lit by the mane (and embers when chama).
RIM_MAP = {
    HAIR_DK: HAIR,
    HAIR: F_LOW,
    SK_DK: SK,
    SK: SK_HL,
    LF_DK2: LF_DK,
    LF_DK: LF,
    LF: LF_HL,
    WOOD_DK: WOOD,
    WOOD: SK_DK,
}
# Cold rim: lit by the crystal (subtler map, leaves and skin only).
CRYSTAL_RIM = {
    LF_DK2: LF_DK,
    LF_DK: LF,
    LF: LF_HL,
    SK_DK: SK,
    SK: SK_HL,
    WOOD_DK: WOOD,
    HAIR_DK: HAIR,
}


@dataclass(frozen=True)
class Rig:
    pose: str
    phase: int
    chama: bool
    head: tuple[float, float]
    body: tuple[float, float]
    foot_y: float
    lean: float
    crouch: float
    hand: tuple[float, float]
    staff_tip: tuple[float, float]
    staff_base: tuple[float, float]


def _hash01(n: float) -> float:
    return (math.sin(n * 127.1 + 311.7) * 43758.5453) % 1.0


def _snap(color: tuple[int, int, int]) -> tuple[int, int, int, int]:
    best = PALETTE[0]
    best_d = 1e12
    for candidate in PALETTE:
        d = (
            2 * (color[0] - candidate[0]) ** 2
            + 4 * (color[1] - candidate[1]) ** 2
            + 3 * (color[2] - candidate[2]) ** 2
        )
        if d < best_d:
            best = candidate
            best_d = d
    return best + (255,)


class Painter:
    def __init__(self) -> None:
        self.im = Image.new("RGBA", (SIZE * SS, SIZE * SS), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, col: tuple[int, int, int]) -> None:
        self.d.ellipse(
            [(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS],
            fill=col,
        )

    def poly(self, pts: list[tuple[float, float]], col: tuple[int, int, int]) -> None:
        self.d.polygon([(x * SS, y * SS) for x, y in pts], fill=col)

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
        ln = math.hypot(dx, dy) or 1.0
        nx = -dy / ln
        ny = dx / ln
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

    def stroke(self, pts: list[tuple[float, float]], width: float, col: tuple[int, int, int]) -> None:
        for a, b in zip(pts, pts[1:]):
            self.limb(a, b, width, width, col)

    def render(self) -> Image.Image:
        small = self.im.resize((SIZE, SIZE), Image.Resampling.BOX)
        px = small.load()
        for y in range(SIZE):
            for x in range(SIZE):
                r, g, b, a = px[x, y]
                if a < 112:
                    px[x, y] = (0, 0, 0, 0)
                else:
                    px[x, y] = _snap((r, g, b))
        return small


def _selout(img: Image.Image) -> dict[tuple[int, int], tuple[int, int, int]]:
    """Darken exterior edges (except glow). Returns original edge colors for rim."""
    px = img.load()
    edge: dict[tuple[int, int], tuple[int, int, int]] = {}
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = px[x, y]
            color = (r, g, b)
            if a == 0 or color in GLOW_COLORS:
                continue
            for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx = x + ox
                ny = y + oy
                if not (0 <= nx < SIZE and 0 <= ny < SIZE) or px[nx, ny][3] == 0:
                    edge[(x, y)] = color
                    break
    for (x, y), color in edge.items():
        px[x, y] = (
            (color[0] + OUTLINE[0]) // 3,
            (color[1] + OUTLINE[1]) // 3,
            (color[2] + OUTLINE[2]) // 3,
            255,
        )
    return edge


def _rim(
    img: Image.Image,
    edge: dict[tuple[int, int], tuple[int, int, int]],
    src: tuple[float, float],
    reach: float,
    rim_map: dict[tuple[int, int, int], tuple[int, int, int]],
    axis: tuple[int, int],
    dither: bool = False,
) -> None:
    """Light edges facing `axis` within `reach` of `src`. Rim wins over outline."""
    px = img.load()
    sx, sy = src
    hits: list[tuple[int, int, tuple[int, int, int]]] = []
    for y in range(SIZE):
        for x in range(SIZE):
            if px[x, y][3] == 0:
                continue
            orig = edge.get((x, y), px[x, y][:3])
            if orig in GLOW_COLORS or orig not in rim_map:
                continue
            nx = x + axis[0]
            ny = y + axis[1]
            if 0 <= nx < SIZE and 0 <= ny < SIZE:
                nb = px[nx, ny]
                open_lit = nb[3] == 0 or (nb[0], nb[1], nb[2]) in GLOW_COLORS
            else:
                open_lit = True
            if not open_lit or math.hypot(x - sx, y - sy) >= reach:
                continue
            if dither and (x + y) % 2 != 0:
                continue
            hits.append((x, y, rim_map[orig]))
    for x, y, color in hits:
        px[x, y] = color + (255,)


def _ramp_dither(img: Image.Image, ramp: list[tuple[int, int, int]]) -> None:
    order = {c: i for i, c in enumerate(ramp)}
    px = img.load()
    swaps: list[tuple[int, int, tuple[int, int, int]]] = []
    for y in range(SIZE - 1):
        for x in range(SIZE):
            r, g, b, a = px[x, y]
            color = (r, g, b)
            if a == 0 or color not in order or (x + y) % 2 != 0:
                continue
            below = px[x, y + 1]
            below_color = (below[0], below[1], below[2])
            if below[3] != 0 and below_color in order and order[below_color] == order[color] - 1:
                swaps.append((x, y, below_color))
    for x, y, color in swaps:
        px[x, y] = color + (255,)


def _lerp(a: tuple[float, float], b: tuple[float, float], t: float) -> tuple[float, float]:
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def _rig(pose: str, phase: int, chama: bool) -> Rig:
    crouch_by_pose = {"idle": 0.0, "walk": 0.0, "windup": 4.8, "strike": -1.5, "recover": 2.1}
    lean_by_pose = {"idle": 0.0, "walk": 1.3, "windup": -2.1, "strike": 6.9, "recover": 0.8}
    crouch = crouch_by_pose[pose]
    lean = lean_by_pose[pose] + (phase * 0.5 if pose == "walk" else 0.0)
    body = (46.0 + lean, 63.5 + crouch)
    head = (48.0 + lean * 0.72, 33.0 + crouch * 0.82)
    foot_y = 89.0 + crouch * 0.35

    if pose == "windup":
        hand = (body[0] + 13.0, body[1] - 22.0)
        tip = (hand[0] + 6.0, hand[1] - 24.0)
        base = (hand[0] - 7.0, hand[1] + 25.0)
    elif pose == "strike":
        hand = (body[0] + 14.0, body[1] - 10.0)
        tip = (hand[0] + 20.0, hand[1] - 4.0)
        base = (hand[0] - 15.0, hand[1] + 7.0)
    else:
        swing = phase * 1.7 if pose == "walk" else 0.0
        tilt = 4.0 if pose == "walk" else 0.0
        drop = 3.0 if pose == "recover" else 0.0
        hand = (body[0] + 19.0 - swing, body[1] - 8.0)
        tip = (hand[0] + 1.5 + tilt, hand[1] - 32.0 + drop)
        base = (hand[0] - 1.0 - tilt * 0.6, foot_y - 1.0)
    return Rig(pose, phase, chama, head, body, foot_y, lean, crouch, hand, tip, base)


def _mane_spine(rig: Rig) -> tuple[list[tuple[float, float]], list[float]]:
    hx, hy = rig.head
    if rig.pose == "strike":
        pts = [(hx + 2, hy - 14), (hx - 11, hy - 12), (hx - 24, hy - 9), (hx - 35, hy - 5), (hx - 42, hy + 1)]
        radii = [11.0, 13.0, 10.5, 7.5, 4.5]
    elif rig.pose == "windup":
        pts = [(hx - 1, hy - 18), (hx - 10, hy - 14), (hx - 16, hy - 1), (hx - 19, hy + 14), (hx - 20, hy + 26)]
        radii = [11.0, 13.5, 11.0, 8.0, 5.0]
    else:
        bounce = rig.phase * 0.9 if rig.pose == "walk" else 0.0
        droop = 2.5 if rig.pose == "recover" else 0.0
        pts = [
            (hx + 4, hy - 14 + bounce * 0.4),
            (hx - 9, hy - 10 - bounce),
            (hx - 18, hy + 6 + droop * 0.4),
            (hx - 22, hy + 23 + droop * 0.8),
            (hx - 24, hy + 37 + droop),
        ]
        radii = [11.0, 14.0, 12.0, 9.5, 6.5]
    return pts, radii


def _draw_mane_back(p: Painter, rig: Rig) -> None:
    ramp = HAIR_RAMP_CHAMA if rig.chama else HAIR_RAMP_BASE
    spine, radii = _mane_spine(rig)
    blown = 1.0 if rig.pose == "strike" else 0.0
    lift = 1.0 if rig.pose == "windup" else 0.0

    # Mass, tail first so the crown lobes overlap it.
    for (cx, cy), r in list(zip(spine, radii))[::-1]:
        p.ellipse(cx, cy, r, r * 0.92, ramp[0])
    for (cx, cy), r in list(zip(spine, radii))[::-1]:
        p.ellipse(cx + r * 0.20, cy - r * 0.14, r * 0.70, r * 0.64, ramp[1])
    for (cx, cy), r in zip(spine[:2], radii[:2]):
        p.ellipse(cx + r * 0.30, cy - r * 0.18, r * 0.42, r * 0.40, ramp[2])
    if rig.chama:
        p.ellipse(spine[0][0] + 1.0, spine[0][1] - 0.5, radii[0] * 0.30, radii[0] * 0.26, F_CORE)

    # Hair framing the hood on the staff side (the mane surrounds the face).
    hx, hy = rig.head
    if rig.pose != "strike":
        p.ellipse(hx + 9.0, hy - 7.0, 6.0, 6.5, ramp[0])
        p.ellipse(hx + 10.0, hy - 8.0, 4.2, 4.6, ramp[1])
        p.limb((hx + 11.0, hy - 2.0), (hx + 12.5, hy + 12.0), 4.6, 1.4, ramp[0])
        p.limb((hx + 11.5, hy - 2.0), (hx + 12.0, hy + 7.0), 2.4, 0.9, ramp[1])

    # Flow strands: a dark separation streak and a hot streak along the spine.
    p.stroke([(x - 3.5, y + 3.0) for x, y in spine], 2.0, ramp[0])
    p.stroke([(x + 1.5, y - 3.0) for x, y in spine[:4]], 1.4, ramp[min(2, len(ramp) - 1)])

    # Tapered tongues flicking off the silhouette.
    hx, hy = rig.head
    tongues = [
        ((hx + 3.0, hy - 12.0 - lift * 2.0), (hx + 6.5 - blown * 4.0, hy - 19.5 - lift * 4.0), 2.6),
        ((hx - 5.0, hy - 14.0), (hx - 9.0 - blown * 5.0, hy - 22.5 - lift * 4.0), 3.0),
        ((hx - 14.0, hy - 8.0), (hx - 22.5 - blown * 6.0, hy - 14.5 - lift * 2.0), 3.2),
        ((spine[2][0] - radii[2] * 0.6, spine[2][1] - 2.0), (spine[2][0] - radii[2] - 6.0 - blown * 4.0, spine[2][1] + 1.0), 3.0),
        ((spine[-1][0], spine[-1][1] + 1.0), (spine[-1][0] - 3.5 - blown * 4.0, spine[-1][1] + 5.5 - blown * 5.0), 2.4),
    ]
    for i, (a, b, w) in enumerate(tongues):
        col = ramp[1] if i % 2 == 0 else ramp[0]
        p.limb(a, b, w, 0.7, col)
        p.limb(a, _lerp(a, b, 0.55), w * 0.5, 0.5, ramp[min(2, len(ramp) - 1)])


def _draw_mane_front(p: Painter, rig: Rig) -> None:
    if rig.pose == "strike":
        return
    hx, hy = rig.head
    sway = rig.phase * 0.7 if rig.pose == "walk" else 0.0
    ramp = HAIR_RAMP_CHAMA if rig.chama else HAIR_RAMP_BASE
    # Loose strands draped over the cloak, framing the hood.
    p.limb((hx - 8.5, hy + 2.0), (hx - 10.5 + sway, hy + 17.0), 3.0, 1.0, ramp[1])
    p.limb((hx - 8.5, hy + 2.0), (hx - 9.5 + sway, hy + 11.0), 1.6, 0.7, ramp[min(2, len(ramp) - 1)])
    p.limb((hx + 8.0, hy + 3.0), (hx + 9.5 - sway, hy + 15.0), 2.4, 0.9, ramp[1])
    p.limb((hx + 8.2, hy + 3.5), (hx + 8.8 - sway, hy + 9.5), 1.3, 0.6, ramp[0])


def _draw_horns(p: Painter, rig: Rig) -> None:
    hx, hy = rig.head
    lift = 1.2 if rig.pose == "windup" else 0.0
    for side, length in ((-1, 12.0), (1, 16.0)):
        base = (hx + side * 6.5, hy - 9.0)
        mid = (hx + side * 12.0, hy - 16.5 - lift * 0.5)
        tip = (hx + side * 16.0, hy - 22.0 - length * 0.55 - lift)
        p.limb(base, mid, 6.6, 4.6, WOOD_DK)
        p.limb(mid, tip, 4.6, 1.4, WOOD_DK)
        p.limb((base[0] + side * 0.5, base[1] - 1.4), (mid[0], mid[1] - 1.2), 4.2, 2.8, WOOD)
        p.limb((mid[0], mid[1] - 1.2), (tip[0] - side * 0.6, tip[1] + 1.0), 2.8, 0.9, WOOD)
        p.limb((base[0], base[1] - 2.2), (mid[0] - side * 1.2, mid[1] - 2.0), 1.8, 1.0, SK_DK)
        # Ridge notches along the horn.
        for t in (0.35, 0.65):
            rx_, ry_ = _lerp(base, mid, t + 0.2)
            p.limb((rx_, ry_), (rx_ - side * 2.0, ry_ + 1.4), 1.0, 0.5, WOOD_DK)
        p.ellipse(base[0], base[1] + 1.6, 3.2, 1.9, LF_DK)


def _draw_legs_feet(p: Painter, rig: Rig) -> None:
    bx, by = rig.body
    step = rig.phase if rig.pose == "walk" else 0
    left_foot = (bx - 6.0 + step * 3.0, rig.foot_y)
    right_foot = (bx + 6.0 - step * 2.2, rig.foot_y)
    if rig.pose == "windup":
        left_foot = (bx - 9.0, rig.foot_y + 0.7)
        right_foot = (bx + 7.5, rig.foot_y + 0.3)
    elif rig.pose == "strike":
        left_foot = (bx - 6.7, rig.foot_y + 0.7)
        right_foot = (bx + 15.7, rig.foot_y - 0.7)

    p.limb((bx - 4.2, by + 12.0), (left_foot[0] - 1.5, left_foot[1] - 5.5), 5.4, 3.4, SK_DK)
    p.limb((left_foot[0] - 1.5, left_foot[1] - 5.5), left_foot, 3.4, 3.0, SK_DK)
    p.poly([(left_foot[0] - 4.2, left_foot[1] - 1.8), (left_foot[0] + 6.0, left_foot[1] - 1.1),
            (left_foot[0] + 6.4, left_foot[1] + 1.6), (left_foot[0] - 4.2, left_foot[1] + 1.6)], SK_DK)

    p.limb((bx + 3.5, by + 12.2), (right_foot[0] - 1.6, right_foot[1] - 5.8), 6.0, 3.9, SK)
    p.limb((right_foot[0] - 1.6, right_foot[1] - 5.8), right_foot, 3.9, 3.5, SK)
    p.poly([(right_foot[0] - 4.5, right_foot[1] - 2.0), (right_foot[0] + 6.8, right_foot[1] - 1.1),
            (right_foot[0] + 7.3, right_foot[1] + 1.6), (right_foot[0] - 4.5, right_foot[1] + 1.6)], SK)
    # Toe cuts on the near foot.
    p.limb((right_foot[0] + 3.5, right_foot[1] - 1.2), (right_foot[0] + 3.5, right_foot[1] + 1.2), 0.6, 0.6, SK_DK)


def _draw_cloak(p: Painter, rig: Rig) -> None:
    bx, by = rig.body
    top = by - 16.5
    # Poncho mass: one readable dark trapezoid, wider at the shoulders.
    p.poly(
        [
            (bx - 14.5, top + 3.5),
            (bx - 7.0, top),
            (bx + 8.0, top),
            (bx + 14.5, top + 4.0),
            (bx + 12.5, by + 10.0),
            (bx + 6.5, by + 15.0),
            (bx - 6.5, by + 15.5),
            (bx - 12.0, by + 9.0),
        ],
        LF_DK,
    )
    # Form shadow on the back third (mane side).
    p.poly(
        [
            (bx - 14.5, top + 3.5),
            (bx - 7.5, top + 0.5),
            (bx - 5.5, by + 15.2),
            (bx - 6.5, by + 15.5),
            (bx - 12.0, by + 9.0),
        ],
        LF_DK2,
    )
    # Lit panel facing the crystal.
    p.poly(
        [
            (bx + 1.0, top + 0.5),
            (bx + 8.0, top),
            (bx + 14.0, top + 4.5),
            (bx + 11.5, by + 5.5),
            (bx + 2.0, by + 8.5),
        ],
        LF,
    )
    # Shoulder collar: leaf points draped over the chest.
    for i, ox in enumerate((-9.0, -4.5, 0.0, 4.5, 9.0)):
        drop = 4.0 + _hash01(i * 5.3) * 2.0
        col = LF if i % 2 == 0 else LF_DK
        p.poly([(bx + ox - 2.4, top + 1.5), (bx + ox + 2.4, top + 1.5), (bx + ox + 0.2, top + 1.5 + drop)], col)
    # Three scalloped rows of hanging leaves.
    for row, ry in enumerate((by + 0.5, by + 7.0, by + 13.5)):
        for i, ox in enumerate((-10.0, -6.0, -2.0, 2.0, 6.0, 10.0)):
            drop = 4.5 + _hash01(i * 3.1 + row * 7.7 + rig.phase) * 2.8
            if ox < -6.5:
                col = LF_DK2
            else:
                col = LF_DK if (i + row) % 2 == 0 else LF
            p.poly([(bx + ox - 2.3, ry), (bx + ox + 2.3, ry), (bx + ox + 0.3, ry + drop)], col)
        # One highlight tip per row, on the staff side.
        hx_ = bx + 8.0 - row * 1.5
        p.poly([(hx_ - 1.8, ry), (hx_ + 1.8, ry), (hx_ + 0.2, ry + 3.8)], LF_HL)


def _draw_pouch(p: Painter, rig: Rig) -> None:
    bx, by = rig.body
    px_, py_ = bx - 6.0, by + 6.5
    # Strap across the cloak, then the leather bag with its flap.
    p.limb((bx + 7.0, by - 13.0), (px_ + 1.0, py_ - 2.5), 1.6, 1.3, WOOD_DK)
    p.ellipse(px_, py_, 3.6, 3.2, SK_DK)
    p.ellipse(px_ - 1.0, py_ + 0.8, 2.2, 1.8, WOOD_DK)
    p.poly([(px_ - 3.2, py_ - 2.4), (px_ + 3.2, py_ - 2.4), (px_ + 2.0, py_ + 0.6), (px_ - 2.2, py_ + 0.6)], SK)


def _draw_staff(p: Painter, rig: Rig) -> None:
    bx_, by_ = rig.staff_base
    tx, ty = rig.staff_tip
    dx, dy = tx - bx_, ty - by_
    ln = math.hypot(dx, dy) or 1.0
    nx, ny = -dy / ln, dx / ln
    neck = (tx - dx / ln * 4.5, ty - dy / ln * 4.5)
    p1 = (bx_ + dx * 0.35 + nx * 1.3, by_ + dy * 0.35 + ny * 1.3)
    p2 = (bx_ + dx * 0.68 - nx * 1.1, by_ + dy * 0.68 - ny * 1.1)
    p.stroke([(bx_, by_), p1, p2, neck], 3.4, WOOD_DK)
    p.stroke(
        [(bx_ + nx * 0.7, by_ + ny * 0.7), (p1[0] + nx * 0.7, p1[1] + ny * 0.7), (p2[0] + nx * 0.7, p2[1] + ny * 0.7), (neck[0] + nx * 0.7, neck[1] + ny * 0.7)],
        2.0,
        WOOD,
    )
    p.stroke(
        [(bx_ + nx * 1.4, by_ + ny * 1.4), (p1[0] + nx * 1.4, p1[1] + ny * 1.4), (p2[0] + nx * 1.4, p2[1] + ny * 1.4)],
        0.8,
        SK_DK,
    )
    # Knot bump.
    kx, ky = bx_ + dx * 0.52 + nx * 2.0, by_ + dy * 0.52 + ny * 2.0
    p.ellipse(kx, ky, 1.6, 1.3, WOOD)
    p.ellipse(kx + 0.4, ky - 0.3, 0.7, 0.6, SK_DK)
    # Vine wrap below the crystal.
    p.limb((neck[0] - 2.0, neck[1] + 1.5), (neck[0] + 2.0, neck[1] + 3.5), 1.6, 1.1, LF)
    p.limb((neck[0] + 1.2, neck[1] + 3.2), (neck[0] + 3.2, neck[1] + 6.0), 1.0, 0.6, LF_DK)
    _draw_crystal(p, rig)


def _draw_crystal(p: Painter, rig: Rig) -> None:
    tx, ty = rig.staff_tip
    flare = 1.3 if rig.pose == "windup" else 1.0
    rx, ry = 3.0 * flare, 5.6 * flare
    # Soft halo: a slightly larger glow disc that survives as a 1-2px rim.
    p.ellipse(tx, ty - ry * 0.1, rx * 1.18, ry * 1.06, CR)
    # Faceted diamond: dark facet / emerald / hot facet.
    top = (tx, ty - ry)
    bottom = (tx + 0.4, ty + ry)
    left = (tx - rx, ty - ry * 0.15)
    right = (tx + rx, ty - ry * 0.15)
    p.poly([top, left, bottom], LF_DK2)
    p.poly([top, right, bottom], CR)
    p.poly([top, (tx - rx * 0.40, ty - ry * 0.05), bottom, (tx + rx * 0.45, ty)], CR_HL)
    p.ellipse(tx + 0.9, ty - ry * 0.45, 1.0, 1.5, EYE_WHITE)
    if rig.pose == "windup":
        # Charging: spark rays + hot core.
        for ang in (0.4, 1.6, 2.9, 4.2, 5.4):
            ax = tx + math.cos(ang) * rx * 2.2
            ay = ty + math.sin(ang) * ry * 1.5
            p.limb((tx + math.cos(ang) * rx * 1.3, ty + math.sin(ang) * ry * 0.9), (ax, ay), 1.0, 0.4, CR_HL)
        p.ellipse(tx, ty - 0.5, 1.6, 2.2, EYE_WHITE)
    # Falling drips.
    drips = 3 if rig.pose == "recover" else 1
    for i in range(drips):
        ddx = (_hash01(i * 9.7 + ty) - 0.5) * 4.0
        p.ellipse(tx + ddx, ty + ry + 2.5 + i * 3.0, 0.7, 0.9, CR_HL)
    # Ambient motes.
    p.ellipse(tx - rx - 1.8, ty + 2.5, 0.6, 0.6, CR_HL)
    p.ellipse(tx + rx + 1.6, ty - 3.0, 0.5, 0.5, CR)


def _draw_smear(p: Painter, rig: Rig) -> None:
    if rig.pose != "strike":
        return
    bx, by = rig.body
    tx, ty = rig.staff_tip
    arcs = [(-1.8, CR, 2.2), (0.0, CR_HL, 1.3), (1.4, EYE_WHITE, 0.7)]
    if rig.chama:
        arcs.insert(0, (-3.6, F_MID, 1.4))
    for off, col, width in arcs:
        p.stroke(
            [
                (bx - 6.0, by - 31.0 + off),
                (bx + 10.0, by - 35.0 + off),
                (tx - 6.0, ty - 9.0 + off),
                (tx + 1.5, ty + off),
            ],
            width,
            col,
        )


def _draw_arm(p: Painter, rig: Rig) -> None:
    bx, by = rig.body
    hand = rig.hand
    if rig.pose == "windup":
        shoulder = (bx + 8.0, by - 13.0)
    elif rig.pose == "strike":
        shoulder = (bx + 9.0, by - 12.0)
    else:
        shoulder = (bx + 8.0, by - 11.0)
    elbow = _lerp(shoulder, hand, 0.5)
    elbow = (elbow[0] + 1.0, elbow[1] + 2.0)
    p.limb(shoulder, elbow, 4.8, 3.8, SK)
    p.limb(elbow, hand, 3.8, 3.2, SK)
    # Wrapped grip over the staff.
    p.ellipse(hand[0], hand[1], 2.7, 2.4, SK_DK)
    p.ellipse(hand[0], hand[1] + 2.2, 2.4, 1.4, LF_DK)


def _draw_head(p: Painter, rig: Rig) -> None:
    hx, hy = rig.head
    # Leaf hood framing the void face, with a chin mantle bridging to the cloak.
    p.ellipse(hx, hy - 1.0, 12.2, 11.5, LF_DK)
    p.ellipse(hx, hy + 9.5, 9.0, 4.5, LF_DK)
    p.ellipse(hx - 2.8, hy + 1.0, 10.2, 9.6, LF_DK2)
    # Hood rim leaves (brow and sides).
    p.limb((hx - 7.0, hy - 8.0), (hx + 7.0, hy - 8.8), 3.6, 3.4, LF)
    p.poly([(hx + 5.5, hy - 10.5), (hx + 10.5, hy - 7.5), (hx + 6.5, hy - 5.0)], LF_HL)
    p.poly([(hx - 6.5, hy - 10.5), (hx - 11.0, hy - 7.0), (hx - 7.0, hy - 5.0)], LF)
    p.poly([(hx + 10.0, hy - 3.5), (hx + 13.5, hy + 1.0), (hx + 9.0, hy + 3.0)], LF)
    p.poly([(hx - 10.5, hy - 3.0), (hx - 14.0, hy + 1.5), (hx - 9.5, hy + 3.5)], LF_DK)
    # Leaf crest between the horns, with one blood-red accent.
    p.poly([(hx - 5.0, hy - 10.5), (hx - 2.0, hy - 16.0), (hx + 0.5, hy - 10.5)], LF)
    p.poly([(hx + 0.5, hy - 11.0), (hx + 3.0, hy - 17.0), (hx + 5.5, hy - 11.0)], LF_HL)
    p.poly([(hx - 2.0, hy - 10.8), (hx + 0.5, hy - 14.0), (hx + 2.5, hy - 10.8)], HAIR)
    # Void face.
    p.ellipse(hx + 1.0, hy + 1.4, 7.4, 6.8, VOID)
    # Two glowing white eyes; the near eye is larger (it found you).
    wide = 1.25 if rig.pose == "windup" else 1.0
    squash = 0.55 if rig.pose == "strike" else 1.0
    p.ellipse(hx + 4.2, hy + 0.8, 2.9 * wide, 2.9 * wide * squash, EYE_GLOW)
    p.ellipse(hx - 2.0, hy + 0.6, 2.4 * wide, 2.4 * wide * squash, EYE_GLOW)
    p.ellipse(hx + 4.2, hy + 0.8, 1.7 * wide, 1.7 * wide * squash, EYE_WHITE)
    p.ellipse(hx - 2.0, hy + 0.6, 1.4 * wide, 1.4 * wide * squash, EYE_WHITE)


def _ember(p: Painter, x: float, y: float, s: float, hot: bool) -> None:
    p.ellipse(x, y, s, s, F_LOW)
    p.ellipse(x + 0.3, y + 0.3, s * 0.62, s * 0.62, F_MID)
    if hot:
        p.ellipse(x + 0.4, y + 0.2, s * 0.3, s * 0.3, F_HOT)


def _draw_embers(p: Painter, rig: Rig) -> None:
    hx, hy = rig.head
    seed = sum(map(ord, rig.pose)) + (rig.phase + 2) * 41
    for i in range(8):
        angle = _hash01(seed + i * 4.7) * math.tau
        radius = 13.0 + _hash01(seed + i * 2.2) * 13.0
        x = hx - 6.0 + math.cos(angle) * radius * 1.15
        y = hy - 4.0 + math.sin(angle) * radius * 0.9
        if hx - 11.0 < x < hx + 13.0 and hy - 9.0 < y < hy + 11.0:
            continue
        if not (4.0 < x < SIZE - 4.0 and 4.0 < y < SIZE - 4.0):
            continue
        _ember(p, x, y, 1.2, i % 2 == 0)


def caipora(pose: str = "idle", leg_phase: int = 0, chama: bool = False) -> Image.Image:
    rig = _rig(pose, leg_phase, chama)
    p = Painter()

    _draw_mane_back(p, rig)
    _draw_legs_feet(p, rig)
    _draw_cloak(p, rig)
    _draw_pouch(p, rig)
    _draw_staff(p, rig)
    _draw_arm(p, rig)
    _draw_head(p, rig)
    _draw_horns(p, rig)
    _draw_mane_front(p, rig)
    _draw_smear(p, rig)
    if chama:
        _draw_embers(p, rig)

    img = p.render()
    edge = _selout(img)
    mane_heart = (rig.head[0] - 6.0, rig.head[1] - 8.0)
    warm_reach = 34.0 if chama else 30.0
    _rim(img, edge, mane_heart, warm_reach, RIM_MAP, (0, -1))
    _rim(img, edge, mane_heart, warm_reach * 1.25, RIM_MAP, (-1, 0), dither=True)
    cold_reach = 20.0 if pose == "windup" else 15.0
    _rim(img, edge, rig.staff_tip, cold_reach, CRYSTAL_RIM, (1, 0), dither=True)
    ramp = HAIR_RAMP_CHAMA + [F_CORE] if chama else HAIR_RAMP_BASE
    _ramp_dither(img, ramp)
    return img


POSES = [
    ("player_idle.png", "idle", 0),
    ("player_walk_1.png", "walk", -1),
    ("player_walk_2.png", "walk", 1),
    ("player_windup.png", "windup", 0),
    ("player_strike.png", "strike", 0),
    ("player_recover.png", "recover", 0),
]


def _make_contact_sheet() -> None:
    frames: list[tuple[str, Image.Image, Image.Image]] = []
    for name, pose, phase in POSES:
        base = caipora(pose, phase)
        chama = caipora(pose, phase, chama=True)
        frames.append((name.replace("player_", "").replace(".png", ""), base, chama))

    cell = 208
    label_h = 14
    sheet = Image.new("RGBA", (cell * len(frames), cell * 2 + label_h), (18, 14, 15, 255))
    draw = ImageDraw.Draw(sheet)
    for i, (label, base, chama) in enumerate(frames):
        x = i * cell
        for row, img in enumerate((base, chama)):
            big = img.resize((SIZE * 2, SIZE * 2), Image.Resampling.NEAREST)
            sheet.alpha_composite(big, (x + 8, label_h + row * cell + 8))
        draw.text((x + 6, 1), label, fill=(230, 210, 180, 255))
    sheet.save(os.path.join(OUT, "caipora_pop_dark_contact_sheet.png"))


def generate_all() -> None:
    os.makedirs(OUT, exist_ok=True)
    for name, pose, phase in POSES:
        caipora(pose, phase).save(os.path.join(OUT, name))
        caipora(pose, phase, chama=True).save(os.path.join(OUT, name.replace(".png", "_chama.png")))
    _make_contact_sheet()
    print("[gen_caipora] Guardia da Mata generated: 6 base + 6 CHAMA + contact sheet")


if __name__ == "__main__":
    generate_all()

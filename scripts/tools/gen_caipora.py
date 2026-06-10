#!/usr/bin/env python3
"""Generate the Caipora protagonist sprites.

Concept: "Caipora Brasa" (see docs/PLANO-redesign-caipora-pop-dark.md).
The goal is a pop-dark, readable protagonist: larger iconic head, ember eyes,
compact cloak/leaf body, fire silhouette, and a living vine whip.

Output contract is intentionally stable:
  player_idle/walk_1/walk_2/windup/strike/recover.png
  player_idle/walk_1/walk_2/windup/strike/recover_chama.png

The PNGs are generated assets. Do not hand-edit them as source of truth.
"""

from __future__ import annotations

import math
import os
from dataclasses import dataclass

from PIL import Image, ImageDraw


OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")
SIZE = 64
SS = 8

# Closed palette. Fire is the only high-saturation accent.
F_DEEP = (130, 24, 10)
F_LOW = (206, 50, 8)
F_MID = (255, 104, 8)
F_HOT = (255, 176, 50)
F_CORE = (255, 239, 178)

SK_DK2 = (42, 24, 20)
SK_DK = (76, 43, 31)
SK = (116, 72, 48)
SK_HL = (168, 108, 64)

LF_DK2 = (10, 19, 14)
LF_DK = (22, 39, 23)
LF = (48, 78, 38)
LF_HL = (92, 122, 56)

WOOD_DK = (28, 17, 17)
WOOD = (58, 34, 29)
JENIPAPO = (17, 13, 18)
URUCUM = (190, 41, 22)
EYE = (255, 213, 78)
EYE_CORE = (255, 255, 218)
OUTLINE = (8, 7, 10)

FIRE_RAMP = [F_DEEP, F_LOW, F_MID, F_HOT, F_CORE]
GLOW_COLORS = set(FIRE_RAMP) | {EYE, EYE_CORE}
PALETTE = FIRE_RAMP + [
    SK_DK2,
    SK_DK,
    SK,
    SK_HL,
    LF_DK2,
    LF_DK,
    LF,
    LF_HL,
    WOOD_DK,
    WOOD,
    JENIPAPO,
    URUCUM,
    EYE,
    EYE_CORE,
]
RIM_MAP = {
    SK_DK2: SK_DK,
    SK_DK: SK,
    SK: SK_HL,
    LF_DK2: LF_DK,
    LF_DK: LF,
    LF: LF_HL,
    WOOD_DK: WOOD,
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


def _selout(img: Image.Image) -> None:
    px = img.load()
    edge: list[tuple[int, int, tuple[int, int, int]]] = []
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
                    edge.append((x, y, color))
                    break
    for x, y, color in edge:
        px[x, y] = (
            (color[0] + OUTLINE[0]) // 3,
            (color[1] + OUTLINE[1]) // 3,
            (color[2] + OUTLINE[2]) // 3,
            255,
        )


def _rim_light(img: Image.Image, fire: tuple[float, float], reach: float = 24.0) -> None:
    px = img.load()
    hits: list[tuple[int, int, tuple[int, int, int]]] = []
    fx, fy = fire
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = px[x, y]
            color = (r, g, b)
            if a == 0 or color in GLOW_COLORS or color not in RIM_MAP:
                continue
            up = px[x, y - 1] if y > 0 else (0, 0, 0, 0)
            side = px[x - 1, y] if x > 0 else (0, 0, 0, 0)
            open_to_light = up[3] == 0 or (up[0], up[1], up[2]) in GLOW_COLORS
            open_back = side[3] == 0 and x <= fx + 5
            dist = math.hypot(x - fx, y - fy)
            if open_to_light and dist < reach:
                hits.append((x, y, RIM_MAP[color]))
            elif open_back and dist < reach * 1.3 and (x + y) % 2 == 0:
                hits.append((x, y, RIM_MAP[color]))
    for x, y, color in hits:
        px[x, y] = color + (255,)


def _fire_dither(img: Image.Image) -> None:
    order = {c: i for i, c in enumerate(FIRE_RAMP)}
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


def _rig(pose: str, phase: int, chama: bool) -> Rig:
    crouch_by_pose = {"idle": 0.0, "walk": 0.0, "windup": 3.2, "strike": -1.0, "recover": 1.4}
    lean_by_pose = {"idle": 0.0, "walk": 0.9, "windup": -1.4, "strike": 4.6, "recover": 0.5}
    crouch = crouch_by_pose[pose]
    lean = lean_by_pose[pose] + (phase * 0.35 if pose == "walk" else 0.0)
    body = (31.0 + lean, 41.5 + crouch)
    head = (32.5 + lean * 0.72, 24.0 + crouch * 0.82)
    return Rig(pose, phase, chama, head, body, 59.5 + crouch * 0.35, lean, crouch)


def _fire_blob(p: Painter, x: float, y: float, sx: float, sy: float, hot: bool) -> None:
    p.ellipse(x, y, sx, sy, F_DEEP)
    p.ellipse(x + 0.2, y + 0.4, sx * 0.72, sy * 0.72, F_LOW)
    p.ellipse(x + 0.5, y + 0.8, sx * 0.48, sy * 0.48, F_MID)
    if hot:
        p.ellipse(x + 0.6, y + 0.7, sx * 0.24, sy * 0.24, F_HOT)


def _draw_mane(p: Painter, rig: Rig) -> None:
    hx, hy = rig.head
    blown = 1.0 if rig.pose == "strike" else 0.0
    lift = 2.8 if rig.pose == "windup" else 0.0
    heat = 1.45 if rig.chama else 1.0

    p.ellipse(hx - 3.8 - blown * 2.0, hy - 8.4 - lift, 9.2 * heat, 7.0 * heat, F_DEEP)
    p.ellipse(hx - 3.0 - blown * 2.8, hy - 8.7 - lift, 6.8 * heat, 5.1 * heat, F_LOW)
    p.ellipse(hx - 1.6 - blown * 3.3, hy - 8.4 - lift, 4.5 * heat, 3.4 * heat, F_MID)
    p.ellipse(hx - 0.4 - blown * 3.6, hy - 8.2 - lift, 2.0 * heat, 1.6 * heat, F_HOT)

    tail = 1.2 if rig.chama else 0.0
    tongues = [
        (hx - 10.5 - blown * 5.5 - tail, hy - 10.5 - lift * 0.3, 4.6, 2.2),
        (hx - 7.6 - blown * 5.0 - tail, hy - 15.4 - lift, 2.7, 5.0),
        (hx - 2.2 - blown * 3.0, hy - 17.0 - lift * 0.9, 2.2, 4.8),
        (hx + 3.2 - blown * 1.3, hy - 14.3 - lift * 0.6, 2.0, 3.8),
    ]
    for i, (x, y, sx, sy) in enumerate(tongues):
        col = F_MID if i % 2 == 0 else F_LOW
        p.limb((x + sx * 0.2, y + sy * 0.7), (x - sx * 0.4, y - sy * 0.7), sx, 0.7, col)
        p.limb((x + sx * 0.1, y + sy * 0.4), (x - sx * 0.18, y - sy * 0.25), sx * 0.5, 0.5, F_HOT)
    if rig.chama:
        p.ellipse(hx - 3.0, hy - 9.5 - lift, 2.1, 1.4, F_CORE)


def _draw_shadow_limbs(p: Painter, rig: Rig) -> None:
    bx, by = rig.body
    step = rig.phase if rig.pose == "walk" else 0
    left_foot = (bx - 4.0 + step * 2.0, rig.foot_y)
    right_foot = (bx + 4.0 - step * 1.5, rig.foot_y)
    if rig.pose == "windup":
        left_foot = (bx - 6.0, rig.foot_y + 0.5)
        right_foot = (bx + 5.0, rig.foot_y + 0.2)
    elif rig.pose == "strike":
        left_foot = (bx - 4.5, rig.foot_y + 0.5)
        right_foot = (bx + 10.5, rig.foot_y - 0.5)

    p.limb((bx - 2.8, by + 8.0), (left_foot[0] - 1.0, left_foot[1] - 5.0), 4.0, 2.4, SK_DK)
    p.limb((left_foot[0] - 1.0, left_foot[1] - 5.0), left_foot, 2.4, 2.2, SK_DK)
    p.poly([(left_foot[0] - 3.0, left_foot[1] - 1.3), (left_foot[0] + 4.2, left_foot[1] - 0.8),
            (left_foot[0] + 4.5, left_foot[1] + 1.2), (left_foot[0] - 3.0, left_foot[1] + 1.2)], SK_DK)

    p.limb((bx + 2.3, by + 8.2), (right_foot[0] - 1.1, right_foot[1] - 5.2), 4.4, 2.8, SK)
    p.limb((right_foot[0] - 1.1, right_foot[1] - 5.2), right_foot, 2.8, 2.5, SK)
    p.poly([(right_foot[0] - 3.2, right_foot[1] - 1.4), (right_foot[0] + 4.8, right_foot[1] - 0.8),
            (right_foot[0] + 5.2, right_foot[1] + 1.2), (right_foot[0] - 3.2, right_foot[1] + 1.2)], SK)


def _draw_body(p: Painter, rig: Rig) -> None:
    bx, by = rig.body
    # Compact poncho/gourd body: one readable dark mass.
    p.poly(
        [
            (bx - 9.0, by - 10.0),
            (bx + 8.0, by - 10.5),
            (bx + 11.0, by + 1.5),
            (bx + 6.2, by + 12.0),
            (bx - 5.8, by + 12.4),
            (bx - 10.5, by + 2.0),
        ],
        LF_DK,
    )
    p.poly(
        [
            (bx - 8.4, by - 9.4),
            (bx - 1.2, by - 10.0),
            (bx - 2.5, by + 12.0),
            (bx - 6.0, by + 12.4),
            (bx - 10.0, by + 2.0),
        ],
        LF_DK2,
    )
    p.poly(
        [
            (bx - 2.6, by - 10.2),
            (bx + 8.0, by - 10.5),
            (bx + 10.3, by + 0.8),
            (bx + 5.0, by + 8.6),
            (bx - 1.2, by + 5.2),
        ],
        LF,
    )
    p.limb((bx - 7.8, by - 8.2), (bx + 7.3, by + 5.0), 2.5, 1.8, JENIPAPO)
    p.limb((bx + 4.5, by - 7.0), (bx + 9.0, by - 2.0), 3.2, 2.4, LF_HL)
    for i, ox in enumerate((-7.0, -3.5, 0.2, 4.2, 7.2)):
        drop = 10.0 + _hash01(i + rig.phase * 2.0) * 3.2
        p.poly([(bx + ox - 1.8, by + 6.0), (bx + ox + 1.9, by + 6.0), (bx + ox, by + drop)], LF_DK if i % 2 else LF)


def _draw_head(p: Painter, rig: Rig) -> None:
    hx, hy = rig.head
    jaw = 1.0 if rig.pose == "strike" else 0.0
    p.ellipse(hx, hy, 8.4, 8.0, SK)
    p.poly([(hx - 7.4, hy + 1.0), (hx + 8.6 + jaw, hy + 1.0), (hx + 5.7 + jaw, hy + 7.6), (hx - 3.8, hy + 7.5)], SK)
    p.poly([(hx - 7.4, hy + 0.5), (hx - 1.8, hy + 0.8), (hx - 2.2, hy + 7.2), (hx - 5.6, hy + 6.0)], SK_DK)

    # Big mask and ember eyes: the pop-dark read.
    p.poly([(hx - 8.1, hy - 2.5), (hx + 8.8 + jaw, hy - 2.4), (hx + 8.5 + jaw, hy + 2.2), (hx - 8.2, hy + 2.4)], JENIPAPO)
    p.ellipse(hx + 3.2 + jaw * 0.5, hy - 0.3, 2.0, 1.55, EYE)
    p.ellipse(hx - 2.5, hy - 0.35, 1.75, 1.45, EYE)
    p.ellipse(hx + 3.65 + jaw * 0.5, hy - 0.55, 0.8, 0.65, EYE_CORE)
    p.ellipse(hx - 2.2, hy - 0.6, 0.62, 0.52, EYE_CORE)

    p.limb((hx + 2.2, hy + 4.0), (hx + 5.6 + jaw, hy + 3.4), 0.8, 0.65, URUCUM)
    if rig.pose == "windup":
        p.limb((hx + 1.0, hy + 6.0), (hx + 3.2, hy + 5.5), 0.55, 0.5, SK_DK2)


def _draw_crown_front(p: Painter, rig: Rig) -> None:
    hx, hy = rig.head
    lift = 2.4 if rig.pose == "windup" else 0.0
    blown = 1.0 if rig.pose == "strike" else 0.0
    heat = 1.25 if rig.chama else 1.0
    p.ellipse(hx - 0.5 - blown * 1.2, hy - 8.0 - lift, 7.0 * heat, 3.7 * heat, F_DEEP)
    p.ellipse(hx - 0.2 - blown * 1.5, hy - 8.2 - lift, 5.0 * heat, 2.5 * heat, F_LOW)
    p.ellipse(hx + 0.7 - blown * 1.7, hy - 8.4 - lift, 3.3 * heat, 1.6 * heat, F_MID)
    for i, ox in enumerate((-4.4, -1.6, 1.6, 4.0)):
        height = (5.5, 7.3, 6.2, 4.4)[i] + lift
        bend = -1.4 - blown * 2.0 + (_hash01(i * 8.1) - 0.5)
        p.limb((hx + ox, hy - 8.0), (hx + ox + bend, hy - 8.2 - height), 2.0, 0.55, F_MID)
        p.limb((hx + ox, hy - 8.2), (hx + ox + bend * 0.65, hy - 8.0 - height * 0.6), 1.0, 0.45, F_HOT)
    p.ellipse(hx - 0.4, hy - 10.0 - lift, 1.6, 1.0, F_CORE)


def _draw_arms_and_whip(p: Painter, rig: Rig) -> None:
    bx, by = rig.body
    if rig.pose == "windup":
        near_sh = (bx + 6.3, by - 8.0)
        near_el = (bx + 9.0, by - 12.0)
        hand = (bx + 8.0, by - 17.0)
        far_hand = (bx - 8.5, by + 3.0)
    elif rig.pose == "strike":
        near_sh = (bx + 7.0, by - 7.0)
        near_el = (bx + 12.0, by - 2.0)
        hand = (bx + 17.0, by + 1.0)
        far_hand = (bx - 10.0, by - 2.0)
    else:
        swing = rig.phase * 1.3 if rig.pose == "walk" else 0.0
        near_sh = (bx + 6.5, by - 7.4)
        near_el = (bx + 8.0 - swing, by - 0.5)
        hand = (bx + 7.0 - swing, by + 7.2)
        far_hand = (bx - 7.2 + swing, by + 5.5)

    far_sh = (bx - 6.5, by - 7.0)
    p.limb(far_sh, (far_sh[0] - 2.5, far_sh[1] + 5.0), 3.0, 2.4, SK_DK)
    p.limb((far_sh[0] - 2.5, far_sh[1] + 5.0), far_hand, 2.4, 2.0, SK_DK)
    p.limb(near_sh, near_el, 3.3, 2.8, SK)
    p.limb(near_el, hand, 2.8, 2.2, SK)
    p.limb((near_el[0] - 1.4, near_el[1] + 1.2), (near_el[0] + 1.7, near_el[1] + 2.0), 1.2, 1.2, LF_DK)

    if rig.pose == "windup":
        pts = [hand, (hand[0] - 2.0, hand[1] - 6.0), (hand[0] - 9.0, hand[1] - 6.0), (hand[0] - 13.0, hand[1] - 1.0)]
        _vine(p, pts, rig.chama)
    elif rig.pose == "strike":
        for dy, col, width in [(-1.5, F_DEEP, 1.4), (0.0, F_MID, 2.2), (1.5, F_HOT, 1.4)]:
            p.stroke([hand, (hand[0] + 6.0, hand[1] + dy), (hand[0] + 13.5, hand[1] + 3.0 + dy), (hand[0] + 18.5, hand[1] + 7.0 + dy)], width, col)
        p.ellipse(hand[0] + 19.5, hand[1] + 8.0, 2.1 if rig.chama else 1.6, 2.1 if rig.chama else 1.6, F_HOT)
        p.ellipse(hand[0] + 19.5, hand[1] + 8.0, 1.0, 1.0, F_CORE)
    else:
        pts = [hand, (hand[0] + 2.3, hand[1] + 3.8), (hand[0] + 0.3, hand[1] + 7.4), (hand[0] + 3.0, hand[1] + 10.8), (hand[0] + 1.2, hand[1] + 14.0)]
        _vine(p, pts, rig.chama)


def _vine(p: Painter, pts: list[tuple[float, float]], chama: bool) -> None:
    p.stroke(pts, 1.9, WOOD_DK)
    p.stroke(pts[:3], 1.0, LF_DK)
    if len(pts) >= 3:
        p.ellipse(pts[2][0] + 1.2, pts[2][1], 1.3, 0.9, LF)
    tip = pts[-1]
    p.ellipse(tip[0], tip[1], 1.6 if chama else 1.2, 1.6 if chama else 1.2, F_LOW)
    p.ellipse(tip[0], tip[1], 0.75 if chama else 0.55, 0.75 if chama else 0.55, F_HOT)
    if chama:
        p.ellipse(tip[0], tip[1], 0.35, 0.35, F_CORE)


def _draw_embers(p: Painter, rig: Rig) -> None:
    hx, hy = rig.head
    seed = sum(map(ord, rig.pose)) + (rig.phase + 2) * 41
    for i in range(7):
        angle = _hash01(seed + i * 4.7) * math.tau
        radius = 9.0 + _hash01(seed + i * 2.2) * 9.0
        x = hx + math.cos(angle) * radius * 1.15
        y = hy - 8.0 + math.sin(angle) * radius * 0.8
        if hx - 8.0 < x < hx + 9.0 and hy - 4.0 < y < hy + 7.5:
            continue
        _fire_blob(p, x, y, 0.9, 0.9, i % 2 == 0)


def caipora(pose: str = "idle", leg_phase: int = 0, chama: bool = False) -> Image.Image:
    rig = _rig(pose, leg_phase, chama)
    p = Painter()

    _draw_mane(p, rig)
    _draw_shadow_limbs(p, rig)
    _draw_body(p, rig)
    _draw_arms_and_whip(p, rig)

    neck_top = (rig.head[0] - 0.5, rig.head[1] + 6.0)
    neck_bottom = (rig.body[0] + 0.4, rig.body[1] - 9.0)
    p.limb(neck_bottom, neck_top, 4.0, 3.4, SK)
    _draw_head(p, rig)
    _draw_crown_front(p, rig)
    if chama:
        _draw_embers(p, rig)

    img = p.render()
    _selout(img)
    _rim_light(img, (rig.head[0] - 2.0, rig.head[1] - 10.0), 25.0 if chama else 22.0)
    _fire_dither(img)
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

    cell = 96
    label_h = 12
    sheet = Image.new("RGBA", (cell * len(frames), cell * 2 + label_h), (18, 14, 15, 255))
    draw = ImageDraw.Draw(sheet)
    for i, (label, base, chama) in enumerate(frames):
        x = i * cell
        for row, img in enumerate((base, chama)):
            big = img.resize((64, 64), Image.Resampling.NEAREST)
            sheet.alpha_composite(big, (x + 16, label_h + row * cell + 16))
        draw.text((x + 6, 1), label, fill=(230, 210, 180, 255))
    sheet.save(os.path.join(OUT, "caipora_pop_dark_contact_sheet.png"))


def generate_all() -> None:
    os.makedirs(OUT, exist_ok=True)
    for name, pose, phase in POSES:
        caipora(pose, phase).save(os.path.join(OUT, name))
        caipora(pose, phase, chama=True).save(os.path.join(OUT, name.replace(".png", "_chama.png")))
    _make_contact_sheet()
    print("[gen_caipora] Caipora Brasa generated: 6 base + 6 CHAMA + contact sheet")


if __name__ == "__main__":
    generate_all()

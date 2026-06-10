#!/usr/bin/env python3
"""Generate the Caipora protagonist sprites.

Concept: "A Guardia da Mata" (see docs/CONCEITO-protagonista.md).
Chibi guardian faithful to the approved reference (caipora.jpg): vivid orange
mane surrounding the leaf hood and falling almost to the ground, void face
with two equal round white eyes, brown horns breaking the mane silhouette,
medium-green leaf tunic with single-leaf accents, bare feet, and a straight
staff crowned by a green faceted crystal.

Finish: flat fills + 1px dark outline, max 2 tones per material.

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

# Closed flat palette: 2 tones per material, reference colors.
OUTLINE = (26, 18, 10)
MANE_DK = (168, 67, 26)
MANE = (217, 95, 35)
SK_DK = (94, 58, 31)
SK = (138, 90, 50)
LF_DK = (60, 95, 38)
LF = (93, 139, 58)
VOID = (12, 10, 12)
EYE_WHITE = (255, 255, 255)
CR = (29, 167, 92)
CR_HL = (138, 240, 176)
F_MID = (255, 104, 8)
F_HOT = (255, 176, 50)
F_CORE = (255, 239, 178)

MANE_RAMP_BASE = [MANE_DK, MANE]
MANE_RAMP_CHAMA = [F_MID, F_HOT]
PALETTE = [
    MANE_DK,
    MANE,
    SK_DK,
    SK,
    LF_DK,
    LF,
    VOID,
    EYE_WHITE,
    CR,
    CR_HL,
    F_MID,
    F_HOT,
    F_CORE,
]


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


def _outline(img: Image.Image) -> None:
    """Flat finish: every opaque pixel touching transparency becomes OUTLINE."""
    px = img.load()
    edge: list[tuple[int, int]] = []
    for y in range(SIZE):
        for x in range(SIZE):
            if px[x, y][3] == 0:
                continue
            for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx = x + ox
                ny = y + oy
                if not (0 <= nx < SIZE and 0 <= ny < SIZE) or px[nx, ny][3] == 0:
                    edge.append((x, y))
                    break
    for x, y in edge:
        px[x, y] = OUTLINE + (255,)


def _lerp(a: tuple[float, float], b: tuple[float, float], t: float) -> tuple[float, float]:
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def _rig(pose: str, phase: int, chama: bool) -> Rig:
    crouch_by_pose = {"idle": 0.0, "walk": 0.0, "windup": 3.0, "strike": -1.0, "recover": 1.5}
    lean_by_pose = {"idle": 0.0, "walk": 0.8, "windup": -1.5, "strike": 5.0, "recover": 0.5}
    crouch = crouch_by_pose[pose]
    lean = lean_by_pose[pose] + (phase * 0.4 if pose == "walk" else 0.0)
    body = (47.0 + lean, 66.0 + crouch)
    head = (50.0 + lean * 0.7, 36.0 + crouch * 0.8)
    foot_y = 89.0 + crouch * 0.35

    if pose == "windup":
        hand = (body[0] + 14.0, body[1] - 18.0)
        tip = (hand[0] + 5.0, hand[1] - 22.0)
        base = (hand[0] - 6.0, hand[1] + 20.0)
    elif pose == "strike":
        hand = (body[0] + 14.0, body[1] - 8.0)
        tip = (hand[0] + 20.0, hand[1] - 4.0)
        base = (hand[0] - 14.0, hand[1] + 6.0)
    else:
        swing = phase * 1.5 if pose == "walk" else 0.0
        tilt = 3.0 if pose == "walk" else 0.0
        drop = 3.0 if pose == "recover" else 0.0
        # Idle staff is straight and vertical; tip pinned at (66.5, 23.5) so
        # FuriaVisual.CRYSTAL_ANCHOR stays valid.
        hand = (66.0 + lean - swing, 56.0 + crouch)
        tip = (66.5 + lean + tilt * 0.5, 23.5 + crouch + drop)
        base = (66.5 + lean - tilt * 0.3, foot_y - 2.0)
    return Rig(pose, phase, chama, head, body, foot_y, lean, crouch, hand, tip, base)


def _mane_spine(rig: Rig) -> tuple[list[tuple[float, float]], list[float]]:
    hx, hy = rig.head
    if rig.pose == "strike":
        pts = [(hx + 2, hy - 12), (hx - 12, hy - 11), (hx - 25, hy - 8), (hx - 36, hy - 4), (hx - 43, hy + 2)]
        radii = [13.0, 14.0, 11.0, 8.0, 5.0]
    elif rig.pose == "windup":
        pts = [(hx - 1, hy - 15), (hx - 11, hy - 12), (hx - 17, hy + 1), (hx - 20, hy + 16), (hx - 21, hy + 28)]
        radii = [13.0, 15.0, 12.0, 8.5, 5.5]
    else:
        bounce = rig.phase * 0.9 if rig.pose == "walk" else 0.0
        droop = 2.0 if rig.pose == "recover" else 0.0
        pts = [
            (hx + 4, hy - 13 + bounce * 0.4),
            (hx - 11, hy - 10 - bounce),
            (hx - 19, hy + 8 + droop * 0.4),
            (hx - 22, hy + 26 + droop * 0.8),
            (hx - 23, hy + 40 + droop),
        ]
        radii = [14.0, 16.0, 12.0, 9.5, 7.0]
    return pts, radii


def _draw_mane_back(p: Painter, rig: Rig) -> None:
    ramp = MANE_RAMP_CHAMA if rig.chama else MANE_RAMP_BASE
    spine, radii = _mane_spine(rig)
    blown = 1.0 if rig.pose == "strike" else 0.0
    lift = 1.0 if rig.pose == "windup" else 0.0

    # Mass, tail first so the crown lobes overlap it.
    for (cx, cy), r in list(zip(spine, radii))[::-1]:
        p.ellipse(cx, cy, r, r * 0.92, ramp[0])
    for (cx, cy), r in list(zip(spine, radii))[::-1]:
        p.ellipse(cx + r * 0.18, cy - r * 0.12, r * 0.66, r * 0.60, ramp[1])
    if rig.chama:
        p.ellipse(spine[0][0] + 1.0, spine[0][1] - 0.5, radii[0] * 0.34, radii[0] * 0.30, F_CORE)

    # Hair framing the hood on the staff side (the mane surrounds the face).
    hx, hy = rig.head
    if rig.pose != "strike":
        p.ellipse(hx + 12.0, hy - 6.0, 6.5, 7.0, ramp[0])
        p.ellipse(hx + 13.0, hy - 7.0, 4.4, 4.8, ramp[1])
        p.limb((hx + 14.0, hy - 1.0), (hx + 15.5, hy + 14.0), 5.0, 1.6, ramp[0])

    # Tapered tufts flicking off the silhouette (flat, alternating tones).
    tufts = [
        ((hx + 4.0, hy - 13.0 - lift * 2.0), (hx + 8.0 - blown * 4.0, hy - 21.0 - lift * 4.0), 3.0),
        ((hx - 5.0, hy - 15.0), (hx - 9.0 - blown * 5.0, hy - 24.0 - lift * 4.0), 3.4),
        ((hx - 15.0, hy - 9.0), (hx - 24.0 - blown * 6.0, hy - 16.0 - lift * 2.0), 3.6),
        ((spine[2][0] - radii[2] * 0.6, spine[2][1] - 2.0), (spine[2][0] - radii[2] - 6.5 - blown * 4.0, spine[2][1] + 1.0), 3.4),
        ((spine[3][0] - radii[3] * 0.5, spine[3][1] + 2.0), (spine[3][0] - radii[3] - 5.0 - blown * 3.0, spine[3][1] + 6.0), 2.8),
        ((spine[-1][0], spine[-1][1] + 1.0), (spine[-1][0] - 4.0 - blown * 4.0, spine[-1][1] + 6.0 - blown * 5.0), 2.6),
    ]
    for i, (a, b, w) in enumerate(tufts):
        p.limb(a, b, w, 0.8, ramp[i % 2])


def _draw_mane_front(p: Painter, rig: Rig) -> None:
    if rig.pose == "strike":
        return
    hx, hy = rig.head
    sway = rig.phase * 0.7 if rig.pose == "walk" else 0.0
    ramp = MANE_RAMP_CHAMA if rig.chama else MANE_RAMP_BASE
    # Crown tufts over the hood top: the mane wraps the head (reference look).
    p.ellipse(hx - 7.0, hy - 11.5, 5.5, 4.5, ramp[0])
    p.ellipse(hx + 1.0, hy - 13.0, 6.0, 4.5, ramp[1])
    p.ellipse(hx + 8.5, hy - 10.5, 4.5, 3.8, ramp[0])
    if rig.chama:
        p.ellipse(hx + 1.0, hy - 13.5, 3.0, 2.2, F_CORE)
    # One leaf dangling at the crown center, over the hair.
    p.poly([(hx - 2.2, hy - 14.5), (hx + 2.2, hy - 14.5), (hx + 0.2, hy - 8.5)], LF_DK)
    # Loose strands draped over the tunic, framing the hood.
    p.limb((hx - 12.0, hy + 4.0), (hx - 14.0 + sway, hy + 21.0), 3.6, 1.2, ramp[1])
    p.limb((hx + 12.0, hy + 5.0), (hx + 13.5 - sway, hy + 19.0), 3.0, 1.0, ramp[1])
    p.limb((hx + 12.4, hy + 5.5), (hx + 13.0 - sway, hy + 12.0), 1.6, 0.7, ramp[0])


def _draw_horns(p: Painter, rig: Rig) -> None:
    hx, hy = rig.head
    lift = 1.2 if rig.pose == "windup" else 0.0
    for side, length in ((-1, 8.0), (1, 5.0)):
        base = (hx + side * 6.5, hy - 9.0)
        mid = (hx + side * 14.0, hy - 16.0 - lift * 0.5)
        tip = (hx + side * 19.0, hy - 19.5 - length * 0.55 - lift)
        p.limb(base, mid, 7.2, 5.0, SK)
        p.limb(mid, tip, 5.0, 1.8, SK)
        p.limb((base[0], base[1] + 1.6), (mid[0] - side * 0.5, mid[1] + 1.6), 2.6, 1.6, SK_DK)


def _draw_legs_feet(p: Painter, rig: Rig) -> None:
    bx, by = rig.body
    step = rig.phase if rig.pose == "walk" else 0
    left_foot = (bx - 6.5, rig.foot_y)
    right_foot = (bx + 6.5, rig.foot_y)
    if rig.pose == "walk":
        left_foot = (bx - 6.5 + step * 3.0, rig.foot_y)
        right_foot = (bx + 6.5 - step * 2.2, rig.foot_y)
    elif rig.pose == "windup":
        left_foot = (bx - 9.0, rig.foot_y + 0.5)
        right_foot = (bx + 7.5, rig.foot_y + 0.3)
    elif rig.pose == "strike":
        left_foot = (bx - 7.0, rig.foot_y + 0.5)
        right_foot = (bx + 15.0, rig.foot_y - 0.5)

    # Far leg/foot in shade, near leg/foot flat SK.
    p.limb((bx - 4.5, by + 10.0), (left_foot[0] - 1.0, left_foot[1] - 4.5), 5.4, 3.6, SK_DK)
    p.poly([(left_foot[0] - 4.4, left_foot[1] - 2.2), (left_foot[0] + 5.6, left_foot[1] - 1.4),
            (left_foot[0] + 6.0, left_foot[1] + 1.6), (left_foot[0] - 4.4, left_foot[1] + 1.6)], SK_DK)

    p.limb((bx + 4.0, by + 10.0), (right_foot[0] - 1.2, right_foot[1] - 4.8), 6.0, 4.0, SK)
    p.poly([(right_foot[0] - 4.6, right_foot[1] - 2.4), (right_foot[0] + 6.6, right_foot[1] - 1.4),
            (right_foot[0] + 7.0, right_foot[1] + 1.6), (right_foot[0] - 4.6, right_foot[1] + 1.6)], SK)


def _draw_cloak(p: Painter, rig: Rig) -> None:
    bx, by = rig.body
    top = by - 16.0
    hem = by + 14.0
    # Tunic mass: one readable green trapezoid, gently notched hem.
    p.poly(
        [
            (bx - 13.0, top + 3.0),
            (bx - 6.0, top),
            (bx + 7.0, top),
            (bx + 13.5, top + 3.5),
            (bx + 14.5, hem - 1.0),
            (bx + 10.0, hem - 3.0),
            (bx + 5.5, hem),
            (bx - 0.5, hem - 2.5),
            (bx - 6.5, hem),
            (bx - 11.0, hem - 3.0),
            (bx - 14.0, hem - 1.0),
        ],
        LF,
    )
    # Form shadow on the back third (mane side).
    p.poly(
        [
            (bx - 13.0, top + 3.0),
            (bx - 7.0, top + 0.5),
            (bx - 6.0, hem - 0.5),
            (bx - 6.5, hem),
            (bx - 11.0, hem - 3.0),
            (bx - 14.0, hem - 1.0),
        ],
        LF_DK,
    )
    # Single-leaf accents on chest and hem (reference style).
    leaves = [
        (bx + 4.0, top + 7.0, 1.0),
        (bx - 1.0, by + 2.0, -1.0),
        (bx + 7.5, by + 6.5, 1.0),
        (bx + 1.5, hem - 6.0, -1.0),
    ]
    for lx, ly, flip in leaves:
        p.poly(
            [
                (lx, ly - 3.2),
                (lx + 2.4 * flip, ly),
                (lx, ly + 3.2),
                (lx - 1.6 * flip, ly),
            ],
            LF_DK,
        )
        p.limb((lx, ly - 2.4), (lx, ly + 2.4), 0.6, 0.6, LF)


def _draw_staff(p: Painter, rig: Rig) -> None:
    bx_, by_ = rig.staff_base
    tx, ty = rig.staff_tip
    dx, dy = tx - bx_, ty - by_
    ln = math.hypot(dx, dy) or 1.0
    nx, ny = -dy / ln, dx / ln
    neck = (tx - dx / ln * 5.0, ty - dy / ln * 5.0)
    # Straight thin shaft: flat dark wood with one light edge.
    p.limb((bx_, by_), neck, 3.0, 3.0, SK_DK)
    p.limb((bx_ + nx * 0.8, by_ + ny * 0.8), (neck[0] + nx * 0.8, neck[1] + ny * 0.8), 1.2, 1.2, SK)
    _draw_crystal(p, rig)


def _draw_crystal(p: Painter, rig: Rig) -> None:
    tx, ty = rig.staff_tip
    flare = 1.3 if rig.pose == "windup" else 1.0
    rx, ry = 3.7 * flare, 6.8 * flare
    # Faceted leaf-diamond: flat body + light facet + glint.
    top = (tx, ty - ry)
    bottom = (tx + 0.4, ty + ry)
    left = (tx - rx, ty - ry * 0.15)
    right = (tx + rx, ty - ry * 0.15)
    p.poly([top, left, bottom], CR)
    p.poly([top, right, bottom], CR)
    p.poly([top, (tx - rx * 0.40, ty - ry * 0.05), bottom, (tx + rx * 0.45, ty)], CR_HL)
    p.ellipse(tx + 0.9, ty - ry * 0.45, 0.9, 1.4, EYE_WHITE)
    if rig.pose == "windup":
        # Charging: spark rays + hot core (the perfect-window flash anchors here).
        for ang in (0.4, 1.6, 2.9, 4.2, 5.4):
            ax = tx + math.cos(ang) * rx * 2.2
            ay = ty + math.sin(ang) * ry * 1.5
            p.limb((tx + math.cos(ang) * rx * 1.3, ty + math.sin(ang) * ry * 0.9), (ax, ay), 1.0, 0.4, CR_HL)
        p.ellipse(tx, ty - 0.5, 1.6, 2.2, EYE_WHITE)


def _draw_smear(p: Painter, rig: Rig) -> None:
    if rig.pose != "strike":
        return
    bx, by = rig.body
    tx, ty = rig.staff_tip
    for off, col, width in ((-1.4, CR, 2.2), (0.4, CR_HL, 1.2)):
        p.stroke(
            [
                (bx - 6.0, by - 29.0 + off),
                (bx + 10.0, by - 33.0 + off),
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
        shoulder = (bx + 8.0, by - 12.0)
    elif rig.pose == "strike":
        shoulder = (bx + 9.0, by - 11.0)
    else:
        shoulder = (bx + 8.0, by - 10.0)
    elbow = _lerp(shoulder, hand, 0.5)
    elbow = (elbow[0] + 1.0, elbow[1] + 2.0)
    p.limb(shoulder, elbow, 4.8, 3.8, SK)
    p.limb(elbow, hand, 3.8, 3.4, SK)
    p.ellipse(hand[0], hand[1], 2.8, 2.6, SK)


def _draw_head(p: Painter, rig: Rig) -> None:
    hx, hy = rig.head
    # Leaf hood framing the void face, with a chin mantle bridging to the tunic.
    p.ellipse(hx, hy - 1.0, 13.0, 12.5, LF)
    p.ellipse(hx, hy + 10.0, 10.0, 5.0, LF)
    # Inner shadow ring framing the face.
    p.ellipse(hx, hy + 0.5, 11.0, 10.0, LF_DK)
    # Leaf points at the brow.
    p.poly([(hx - 6.0, hy - 9.5), (hx - 2.5, hy - 15.5), (hx + 0.5, hy - 9.5)], LF_DK)
    p.poly([(hx + 1.5, hy - 10.0), (hx + 4.5, hy - 15.0), (hx + 7.0, hy - 10.0)], LF_DK)
    # Void face.
    p.ellipse(hx, hy + 1.5, 9.5, 8.5, VOID)
    # Two equal glowing white eyes (no halo): the last thing the hunter sees.
    wide = 1.25 if rig.pose == "windup" else 1.0
    squash = 0.55 if rig.pose == "strike" else 1.0
    for ex in (hx - 4.2, hx + 4.2):
        p.ellipse(ex, hy + 0.8, 3.0 * wide, 3.0 * wide * squash, EYE_WHITE)


def _ember(p: Painter, x: float, y: float, s: float, hot: bool) -> None:
    p.ellipse(x, y, s, s, F_MID)
    if hot:
        p.ellipse(x + 0.3, y + 0.2, s * 0.5, s * 0.5, F_HOT)


def _draw_embers(p: Painter, rig: Rig) -> None:
    hx, hy = rig.head
    seed = sum(map(ord, rig.pose)) + (rig.phase + 2) * 41
    for i in range(8):
        angle = _hash01(seed + i * 4.7) * math.tau
        radius = 16.0 + _hash01(seed + i * 2.2) * 13.0
        x = hx - 6.0 + math.cos(angle) * radius * 1.15
        y = hy - 4.0 + math.sin(angle) * radius * 0.9
        if hx - 14.0 < x < hx + 16.0 and hy - 12.0 < y < hy + 14.0:
            continue
        if not (4.0 < x < SIZE - 4.0 and 4.0 < y < SIZE - 4.0):
            continue
        _ember(p, x, y, 1.3, i % 2 == 0)


def caipora(pose: str = "idle", leg_phase: int = 0, chama: bool = False) -> Image.Image:
    rig = _rig(pose, leg_phase, chama)
    p = Painter()

    _draw_mane_back(p, rig)
    _draw_legs_feet(p, rig)
    _draw_cloak(p, rig)
    _draw_staff(p, rig)
    _draw_arm(p, rig)
    _draw_head(p, rig)
    _draw_mane_front(p, rig)
    _draw_horns(p, rig)
    _draw_smear(p, rig)
    if chama:
        _draw_embers(p, rig)

    img = p.render()
    _outline(img)
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

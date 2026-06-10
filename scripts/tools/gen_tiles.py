#!/usr/bin/env python3
"""Generate map tiles in the approved Caipora visual identity.

Canonical read: the protagonist is the brand. Map tiles should feel like the
same hostile organism: hard silhouettes, serrated organic shapes, black/brown
mass, dry blood, restrained orange, and a flat pixel-art finish.

Outputs:
  assets/sprites/tile_floor.png          128x32, 4 forest floor variants
  assets/sprites/tile_wall.png            64x32, 2 dense forest wall variants
  assets/sprites/tile_floor_church.png   128x32, 4 corrupted church floor variants
  assets/sprites/tile_wall_church.png     64x32, 2 corrupted church wall variants
  assets/sprites/tile_identity_contact_sheet.png  preview sheet for art review
  assets/sprites/light_radial.png
  assets/sprites/light_vitral.png

Do not hand-edit the PNG outputs. Edit this file and regenerate.
"""

from __future__ import annotations

import os
import random
from PIL import Image, ImageDraw

SIZE = 32
FLOOR_VARIANTS = 4
WALL_VARIANTS = 2
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")

BLACK = (0, 0, 0)
NIGHT = (13, 17, 23)
VOID_BROWN = (24, 12, 10)
EARTH_DARK = (34, 15, 12)
EARTH = (61, 31, 31)
EARTH_WET = (48, 23, 22)
BARK = (46, 27, 13)
BARK_DARK = (20, 12, 6)
MOSS_DARK = (12, 28, 11)
MOSS = (26, 47, 18)
LEAF_DARK = (20, 38, 16)
ORANGE_DK = (139, 42, 0)
ORANGE = (255, 69, 0)
FIRE = (255, 104, 8)
FIRE_HOT = (255, 176, 50)
BLOOD_DARK = (66, 0, 0)
BLOOD = (139, 0, 0)
BONE_DARK = (66, 58, 47)
BONE = (175, 164, 134)
WATER = (14, 22, 26)
WATER_LIGHT = (32, 48, 56)

STONE_DARK = (30, 30, 38)
STONE = (74, 74, 84)
STONE_LIGHT = (112, 108, 96)
LIME_DARK = (86, 78, 66)
LIME = (150, 140, 120)
WAX = (190, 170, 128)


def _new_tile(base: tuple[int, int, int]) -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), base + (255,))


def _noise(px, rng: random.Random, colors: list[tuple[int, int, int]], chance: float) -> None:
    for y in range(SIZE):
        for x in range(SIZE):
            if rng.random() < chance:
                px[x, y] = rng.choice(colors) + (255,)


def _poly(draw: ImageDraw.ImageDraw, pts: list[tuple[int, int]], color: tuple[int, int, int]) -> None:
    draw.polygon(pts, fill=color + (255,))


def _line(draw: ImageDraw.ImageDraw, pts: list[tuple[int, int]], color: tuple[int, int, int], width: int = 1) -> None:
    draw.line(pts, fill=color + (255,), width=width, joint="curve")


def _ellipse(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color: tuple[int, int, int]) -> None:
    draw.ellipse(box, fill=color + (255,))


def _jagged_leaf(draw: ImageDraw.ImageDraw, x: int, y: int, flip: int, color: tuple[int, int, int]) -> None:
    pts = [
        (x, y),
        (x + flip * 7, y - 3),
        (x + flip * 13, y),
        (x + flip * 8, y + 2),
        (x + flip * 14, y + 6),
        (x + flip * 5, y + 4),
        (x + flip * 1, y + 8),
    ]
    _poly(draw, pts, color)


def _root(draw: ImageDraw.ImageDraw, rng: random.Random, start: tuple[int, int],
          color: tuple[int, int, int], width: int) -> None:
    x, y = start
    pts = [(x, y)]
    for _ in range(rng.randint(3, 6)):
        x = max(0, min(SIZE - 1, x + rng.randint(-5, 6)))
        y = max(0, min(SIZE - 1, y + rng.randint(-3, 5)))
        pts.append((x, y))
    _line(draw, pts, color, width)
    if width > 1:
        _line(draw, pts, BARK, 1)


def _blood_smear(draw: ImageDraw.ImageDraw, rng: random.Random, cx: int, cy: int, radius: int) -> None:
    pts = []
    for i in range(10):
        dx = rng.randint(-radius, radius)
        dy = rng.randint(-radius, radius)
        pts.append((cx + dx, cy + dy))
    _poly(draw, pts, BLOOD_DARK)
    _ellipse(draw, (cx - radius // 2, cy - 2, cx + radius // 2, cy + radius // 2), BLOOD)
    for _ in range(3):
        x = cx + rng.randint(-12, 12)
        y = cy + rng.randint(-10, 10)
        rx = rng.randint(1, 3)
        ry = rng.randint(1, 3)
        _ellipse(draw, (x - rx, y - ry, x + rx, y + ry), BLOOD_DARK)


def _bone_chip(draw: ImageDraw.ImageDraw, x: int, y: int, angle: int = 0) -> None:
    if angle == 0:
        _line(draw, [(x - 4, y), (x + 4, y)], BONE, 2)
        _ellipse(draw, (x - 6, y - 2, x - 2, y + 2), BONE)
        _ellipse(draw, (x + 2, y - 2, x + 6, y + 2), BONE)
    else:
        _line(draw, [(x - 3, y + 3), (x + 4, y - 4)], BONE, 2)
        _ellipse(draw, (x - 5, y + 1, x - 1, y + 5), BONE)
        _ellipse(draw, (x + 2, y - 6, x + 6, y - 2), BONE)


def _forest_floor_variant(v: int) -> Image.Image:
    rng = random.Random(3026 + v * 101)
    img = _new_tile(EARTH_DARK)
    px = img.load()
    draw = ImageDraw.Draw(img)
    _noise(px, rng, [VOID_BROWN, EARTH, EARTH_WET, BARK_DARK], 0.24)

    if v == 0:
        # Wet soil crossed by living roots.
        for start in [(0, 7), (2, 26), (31, 14)]:
            _root(draw, rng, start, BARK_DARK, 3)
        _jagged_leaf(draw, 20, 7, 1, LEAF_DARK)
    elif v == 1:
        # Serrated leaf litter, echoing the Caipora cloak edge.
        for _ in range(7):
            _jagged_leaf(draw, rng.randint(1, 28), rng.randint(5, 28),
                         rng.choice([-1, 1]), rng.choice([MOSS_DARK, LEAF_DARK, MOSS]))
        _line(draw, [(3, 28), (12, 23), (25, 25)], BARK_DARK, 2)
    elif v == 2:
        # Dry blood and clawed roots.
        _blood_smear(draw, rng, 17, 16, 8)
        _root(draw, rng, (0, 18), BLACK, 3)
        _root(draw, rng, (31, 4), BARK_DARK, 2)
    else:
        # Black puddle with bone and orange rot.
        _ellipse(draw, (4, 8, 27, 24), WATER)
        _ellipse(draw, (9, 11, 22, 19), BLACK)
        _line(draw, [(8, 13), (19, 12)], WATER_LIGHT, 1)
        _bone_chip(draw, 22, 22, 1)
        _jagged_leaf(draw, 3, 7, 1, ORANGE_DK)

    # A few restrained orange scars keep the Caipora mark in the ground.
    for _ in range(2):
        x = rng.randint(2, 29)
        y = rng.randint(2, 29)
        _line(draw, [(x, y), (x + rng.randint(-2, 3), y + rng.randint(2, 5))], ORANGE_DK, 1)
    return img


def _forest_wall_variant(v: int) -> Image.Image:
    rng = random.Random(705 + v * 73)
    img = _new_tile(BLACK)
    px = img.load()
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        for x in range(SIZE):
            if rng.random() < 0.18 + y * 0.004:
                px[x, y] = rng.choice([NIGHT, MOSS_DARK, VOID_BROWN]) + (255,)

    trunks = [(6, -3, 12, 35), (20, -2, 27, 34)] if v == 0 else [(1, -2, 8, 34), (14, -4, 22, 35), (26, 0, 32, 33)]
    for box in trunks:
        draw.rectangle(box, fill=BARK_DARK + (255,))
        x0, y0, x1, y1 = box
        _line(draw, [(x0 + 2, y0 + 2), (x0 + 1, y1 - 2)], BARK, 1)
        _line(draw, [(x1 - 2, y0), (x1 - 3, y1)], BLACK, 1)

    # Leaf teeth and thorn silhouettes.
    for _ in range(12 if v == 0 else 16):
        x = rng.randint(0, 31)
        y = rng.randint(0, 31)
        _jagged_leaf(draw, x, y, rng.choice([-1, 1]), rng.choice([MOSS_DARK, LEAF_DARK, BLACK]))
    for _ in range(4):
        x = rng.randint(2, 29)
        y = rng.randint(4, 26)
        _poly(draw, [(x - 2, y + 5), (x, y - 5), (x + 3, y + 5)], BLACK)

    # Small orange wounds, not a blanket tint.
    for _ in range(3 if v == 0 else 2):
        x = rng.randint(3, 27)
        y = rng.randint(4, 26)
        _line(draw, [(x, y), (x + rng.randint(-1, 2), y + rng.randint(3, 7))], ORANGE_DK, 2)
        _line(draw, [(x, y), (x, y + 2)], ORANGE, 1)
    return img


def _church_floor_variant(v: int) -> Image.Image:
    rng = random.Random(1549 + v * 89)
    img = _new_tile(STONE_DARK)
    px = img.load()
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        for x in range(SIZE):
            joint = x % 16 == 0 or y % 16 == 0
            if joint:
                px[x, y] = BLACK + (255,)
            else:
                px[x, y] = rng.choice([STONE_DARK, STONE, LIME_DARK]) + (255,)

    if v == 0:
        _line(draw, [(4, 0), (7, 9), (5, 18), (12, 31)], BLACK, 2)
        _line(draw, [(5, 0), (8, 9), (6, 18), (13, 31)], STONE_LIGHT, 1)
    elif v == 1:
        for _ in range(4):
            _root(draw, rng, (rng.choice([0, 31]), rng.randint(2, 30)), BLACK, 2)
        _jagged_leaf(draw, 17, 9, 1, MOSS_DARK)
    elif v == 2:
        _blood_smear(draw, rng, 16, 15, 9)
        for _ in range(5):
            x = rng.randint(2, 29)
            y = rng.randint(2, 29)
            rx = rng.randint(1, 3)
            ry = rng.randint(1, 3)
            _ellipse(draw, (x - rx, y - ry, x + rx, y + ry), BLOOD_DARK)
    else:
        # Wax, ash, and a broken tile edge.
        _ellipse(draw, (6, 8, 14, 18), WAX)
        _ellipse(draw, (16, 17, 23, 25), WAX)
        _line(draw, [(0, 24), (7, 21), (15, 23), (28, 19)], BLACK, 2)
        _jagged_leaf(draw, 24, 6, -1, ORANGE_DK)
    return img


def _church_wall_variant(v: int) -> Image.Image:
    rng = random.Random(1701 + v * 91)
    img = _new_tile(BLACK)
    px = img.load()
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        base = LIME_DARK if t > 0.35 else STONE_DARK
        for x in range(SIZE):
            if rng.random() < 0.18:
                px[x, y] = rng.choice([BLACK, STONE_DARK, LIME_DARK, VOID_BROWN]) + (255,)
            else:
                px[x, y] = base + (255,)

    # Black roots invade the church wall.
    for start in [(0, 4), (31, 10), (8, 0)]:
        _root(draw, rng, start, BLACK, 3)

    if v == 0:
        # Crooked cross shadow and blood tears.
        draw.rectangle((14, 3, 18, 27), fill=BLACK + (255,))
        draw.rectangle((8, 10, 24, 14), fill=BLACK + (255,))
        _line(draw, [(16, 14), (15, 28)], BLOOD, 2)
        _line(draw, [(10, 14), (9, 22)], BLOOD_DARK, 1)
    else:
        # Broken arch/altar stone bitten by foliage.
        _ellipse(draw, (6, 2, 27, 27), STONE)
        draw.rectangle((6, 15, 27, 31), fill=BLACK + (255,))
        _line(draw, [(7, 15), (26, 15)], STONE_LIGHT, 1)
        for _ in range(5):
            _jagged_leaf(draw, rng.randint(0, 30), rng.randint(16, 30),
                         rng.choice([-1, 1]), rng.choice([MOSS_DARK, BLACK]))
    return img


def _make_atlas(name: str, variants: list[Image.Image]) -> Image.Image:
    atlas = Image.new("RGBA", (SIZE * len(variants), SIZE), (0, 0, 0, 0))
    for i, img in enumerate(variants):
        atlas.paste(img, (i * SIZE, 0))
    atlas.save(os.path.join(OUT, name))
    return atlas


def gen_floor() -> Image.Image:
    return _make_atlas("tile_floor.png", [_forest_floor_variant(v) for v in range(FLOOR_VARIANTS)])


def gen_wall() -> Image.Image:
    return _make_atlas("tile_wall.png", [_forest_wall_variant(v) for v in range(WALL_VARIANTS)])


def gen_floor_church() -> Image.Image:
    return _make_atlas("tile_floor_church.png", [_church_floor_variant(v) for v in range(FLOOR_VARIANTS)])


def gen_wall_church() -> Image.Image:
    return _make_atlas("tile_wall_church.png", [_church_wall_variant(v) for v in range(WALL_VARIANTS)])


def gen_contact_sheet(atlases: list[tuple[str, Image.Image]]) -> None:
    scale = 4
    label_h = 14
    gap = 8
    width = max(img.width for _, img in atlases) * scale + gap * 2
    height = sum(img.height * scale + label_h + gap for _, img in atlases) + gap
    sheet = Image.new("RGBA", (width, height), (18, 13, 10, 255))
    draw = ImageDraw.Draw(sheet)
    y = gap
    for label, img in atlases:
        draw.text((gap, y), label, fill=(230, 220, 190, 255))
        y += label_h
        preview = img.resize((img.width * scale, img.height * scale), Image.Resampling.NEAREST)
        sheet.paste(preview, (gap, y))
        y += preview.height + gap
    sheet.save(os.path.join(OUT, "tile_identity_contact_sheet.png"))


def gen_light() -> None:
    """Radial white-to-transparent texture for PointLight2D."""
    n = 256
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = img.load()
    c = (n - 1) / 2.0
    for y in range(n):
        for x in range(n):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5 / c
            a = max(0.0, 1.0 - d)
            a = a * a
            px[x, y] = (255, 255, 255, int(a * 255))
    img.save(os.path.join(OUT, "light_radial.png"))


def gen_light_beam() -> None:
    """Stained-glass beam texture for the final church phase."""
    w, h = 128, 256
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx = (w - 1) / 2.0
    for y in range(h):
        t = y / (h - 1)
        half = (0.10 + 0.38 * t) * w
        fall = 1.0 - t * 0.45
        for x in range(w):
            d = abs(x - cx) / half
            if d >= 1.0:
                continue
            edge = (1.0 - d * d) ** 2
            px[x, y] = (255, 255, 255, int(edge * fall * 210))
    img.save(os.path.join(OUT, "light_vitral.png"))


if __name__ == "__main__":
    floor = gen_floor()
    wall = gen_wall()
    church_floor = gen_floor_church()
    church_wall = gen_wall_church()
    gen_contact_sheet([
        ("forest floor: living soil / roots / blood / black water", floor),
        ("forest wall: dense hostile silhouette", wall),
        ("church floor: stone infected by forest and blood", church_floor),
        ("church wall: altar shadow, roots, corrupted lime", church_wall),
    ])
    gen_light()
    gen_light_beam()
    print("[gen_tiles] organic Caipora-identity tiles generated")

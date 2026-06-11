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
  assets/sprites/tile_shade.png           96x32, 3 floor AO shade tiles
  assets/sprites/tile_identity_contact_sheet.png  preview sheet for art review
  assets/sprites/tile_identity_value_sheet.png    grayscale value review sheet
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
VOID_BROWN = (12, 6, 5)
EARTH_DEEP = (8, 4, 4)
EARTH_DARK = (13, 7, 6)
EARTH = (24, 13, 11)
EARTH_WET = (16, 8, 8)
BARK = (25, 14, 7)
BARK_DARK = (10, 6, 3)
MOSS_DARK = (5, 14, 6)
MOSS = (12, 24, 10)
LEAF_DARK = (8, 17, 8)
ORANGE_DK = (139, 42, 0)
ORANGE = (255, 69, 0)
FIRE = (255, 104, 8)
FIRE_HOT = (255, 176, 50)
BLOOD_DARK = (66, 0, 0)
BLOOD = (139, 0, 0)
WATER = (6, 10, 13)

STONE_DARK = (11, 11, 15)
STONE = (23, 22, 27)
STONE_LIGHT = (38, 35, 31)
LIME_DARK = (21, 18, 16)
LIME = (45, 39, 31)
WAX = (82, 66, 44)

SHADE = (0, 0, 0)
SHADE_EDGE_ALPHA = (115, 77, 38)       # 0.45 / 0.30 / 0.15
SHADE_DEEP_ALPHA = (153, 102, 51)      # deeper corridor lip


def _new_tile(base: tuple[int, int, int]) -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), base + (255,))


def _poly(draw: ImageDraw.ImageDraw, pts: list[tuple[int, int]], color: tuple[int, int, int]) -> None:
    draw.polygon(pts, fill=color + (255,))


def _line(draw: ImageDraw.ImageDraw, pts: list[tuple[int, int]], color: tuple[int, int, int], width: int = 1) -> None:
    draw.line(pts, fill=color + (255,), width=width, joint="curve")


def _ellipse(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color: tuple[int, int, int]) -> None:
    draw.ellipse(box, fill=color + (255,))


def _ellipse_rgba(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int],
                  color: tuple[int, int, int], alpha: int) -> None:
    draw.ellipse(box, fill=color + (alpha,))


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


# ─── Forest floor (fase 1–4 + acampamento) ──────────────────────────────────
# Redesign 2026-06 seguindo o padrão de tiles top-down (SLYNYRD Pixelblog 20/43):
#   1. O piso é a camada de MENOR contraste da cena — faixa de valor estreita,
#      sem branco de osso, laranja puro, teal ou highlights de água no chão.
#   2. Textura por CLUSTERS orgânicos com espaço negativo, nunca ruído
#      sal-e-pimenta de pixels isolados e saturados.
#   3. O grid fica escondido: nenhum motivo repetido por tile (a antiga
#      "cicatriz laranja por tile" virava papel de parede no acampamento);
#      os clusters dão a volta no tile (wrap), então toda borda emenda.
#   4. Identidade Caipora segue presente, mas afundada no solo: sangue seco
#      e pouquíssimas brasas ORANGE_DK — acento, nunca confete.

SOIL_BASE = EARTH_DARK     # leito de serrapilheira
SOIL_LOW = EARTH_DEEP      # depressão úmida
SOIL_HIGH = EARTH          # torrão seco (topo da faixa de valor do piso)
LITTER = (19, 18, 10)      # folha morta dessaturada
LITTER_DARK = (11, 12, 7)  # folha morta na sombra

FLOOR_CLUSTERS_LOW = 7     # manchas escuras largas por tile
FLOOR_CLUSTERS_HIGH = 7    # torrões claros por tile
FLOOR_LITTER_PATCHES = 9   # aglomerados de folha morta por tile


def _wrap_px(px, x: int, y: int, color: tuple[int, int, int]) -> None:
    px[x % SIZE, y % SIZE] = color + (255,)


def _wrap_blob(px, rng: random.Random, cx: int, cy: int, r: int,
               color: tuple[int, int, int], density: float) -> None:
    """Mancha orgânica que dá a volta no tile — mantém o atlas seamless."""
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r and rng.random() < density:
                _wrap_px(px, cx + dx, cy + dy, color)


def _soil_bed(rng: random.Random) -> Image.Image:
    """Leito comum de solo: mesma densidade em todo variant, seed diferente —
    o campo fica uniforme e o padrão do grid desaparece."""
    img = _new_tile(SOIL_BASE)
    px = img.load()
    for _ in range(FLOOR_CLUSTERS_LOW):
        _wrap_blob(px, rng, rng.randrange(SIZE), rng.randrange(SIZE),
                   rng.randint(3, 6), rng.choice([SOIL_LOW, VOID_BROWN, EARTH_WET]), 0.8)
    for _ in range(FLOOR_CLUSTERS_HIGH):
        _wrap_blob(px, rng, rng.randrange(SIZE), rng.randrange(SIZE),
                   rng.randint(2, 4), SOIL_HIGH, 0.65)
    for _ in range(FLOOR_LITTER_PATCHES):
        x = rng.randrange(SIZE)
        y = rng.randrange(SIZE)
        color = LITTER if rng.random() < 0.45 else LITTER_DARK
        for _ in range(rng.randint(2, 4)):
            _wrap_px(px, x + rng.randint(-1, 1), y + rng.randint(-1, 1), color)
    return img


def _ember_pair(px, x: int, y: int) -> None:
    """Brasa mínima da Caipora: 2px ORANGE_DK afundados no solo."""
    _wrap_px(px, x, y, ORANGE_DK)
    _wrap_px(px, x + 1, y, ORANGE_DK)


def _forest_floor_variant(v: int) -> Image.Image:
    rng = random.Random(3026 + v * 101)
    img = _soil_bed(rng)
    px = img.load()
    draw = ImageDraw.Draw(img)

    if v == 0:
        # Raiz morta pressionada no solo — só silhueta escura, sem highlight.
        _root(draw, rng, (6, 9), BARK_DARK, 2)
        _root(draw, rng, (18, 22), BARK_DARK, 2)
    elif v == 1:
        # Serrapilheira mais densa: a mancha de folha morta cresce, sem teal.
        for _ in range(6):
            x = rng.randint(4, 27)
            y = rng.randint(4, 27)
            _wrap_blob(px, rng, x, y, 2, LITTER_DARK, 0.7)
            _wrap_px(px, x, y, LITTER)
        _ember_pair(px, rng.randint(6, 24), rng.randint(6, 24))
    elif v == 2:
        # Sangue seco encharcado na terra: rastro de arrasto BLOOD_DARK,
        # descentralizado e irregular, com pouquíssimos pixels BLOOD vivos —
        # assinatura hostil sem virar bolinha repetida no grid.
        trail_x, trail_y = 9, 21
        for step in range(5):
            _wrap_blob(px, rng, trail_x, trail_y, rng.randint(1, 3), BLOOD_DARK, 0.8)
            if step % 2 == 0:
                _wrap_blob(px, rng, trail_x, trail_y, 1, BLOOD, 0.85)
            trail_x += rng.randint(2, 5)
            trail_y -= rng.randint(1, 4)
    else:
        # Solo encharcado: manchas úmidas irregulares afundando no leito —
        # lêem como chão fundo, sem highlight de água, osso ou elipse perfeita.
        for _ in range(3):
            cx = rng.randint(6, 26)
            cy = rng.randint(6, 26)
            _wrap_blob(px, rng, cx, cy, rng.randint(3, 5), EARTH_WET, 0.8)
            _wrap_blob(px, rng, cx, cy, rng.randint(1, 3), WATER, 0.85)
        _ember_pair(px, rng.randint(4, 8), rng.randint(24, 28))
    return img


def _forest_wall_variant(v: int) -> Image.Image:
    rng = random.Random(705 + v * 73)
    img = _new_tile(BLACK)
    px = img.load()
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        for x in range(SIZE):
            if rng.random() < 0.22 + y * 0.005:
                px[x, y] = rng.choice([BLACK, BLACK, BLACK, NIGHT, VOID_BROWN]) + (255,)

    trunks = [(6, -3, 12, 35), (20, -2, 27, 34)] if v == 0 else [(1, -2, 8, 34), (14, -4, 22, 35), (26, 0, 32, 33)]
    for box in trunks:
        draw.rectangle(box, fill=BLACK + (255,))
        x0, y0, x1, y1 = box
        _line(draw, [(x0 + 2, y0 + 2), (x0 + 1, y1 - 2)], BARK_DARK, 1)
        _line(draw, [(x1 - 2, y0), (x1 - 3, y1)], BLACK, 1)
        # A dark base lip helps the wall read as blocking depth against the
        # lighter playable floor.
        draw.rectangle((x0 - 1, 26, x1 + 1, 31), fill=BLACK + (255,))

    # Leaf teeth and thorn silhouettes.
    for _ in range(12 if v == 0 else 16):
        x = rng.randint(0, 31)
        y = rng.randint(0, 31)
        _jagged_leaf(draw, x, y, rng.choice([-1, 1]), rng.choice([BLACK, BLACK, MOSS_DARK, LEAF_DARK]))
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
    img = _new_tile(BLACK)
    px = img.load()
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        for x in range(SIZE):
            joint = x % 16 == 0 or y % 16 == 0
            if joint:
                px[x, y] = BLACK + (255,) if rng.random() < 0.78 else STONE_DARK + (255,)
            else:
                px[x, y] = rng.choice([BLACK, STONE_DARK, STONE_DARK, STONE, LIME_DARK]) + (255,)

    # Fuligem em degraus duros nos cantos: a igreja continua caminhavel, mas
    # parece consumida pela mata e pelo sangue.
    soot_corners = [(0, 0), (SIZE - 1, 0), (0, SIZE - 1), (SIZE - 1, SIZE - 1)]
    for cx, cy in soot_corners:
        for y in range(SIZE):
            for x in range(SIZE):
                d = abs(x - cx) + abs(y - cy)
                if d < 6:
                    px[x, y] = BLACK + (255,)
                elif d < 12 and rng.random() < 0.70:
                    px[x, y] = BLACK + (255,)

    if v == 0:
        _line(draw, [(4, 0), (7, 9), (5, 18), (12, 31)], STONE_DARK, 2)
        _line(draw, [(5, 0), (8, 9), (6, 18), (13, 31)], STONE, 1)
    elif v == 1:
        for _ in range(4):
            _root(draw, rng, (rng.choice([0, 31]), rng.randint(2, 30)), BLACK, 2)
        _jagged_leaf(draw, 17, 9, 1, MOSS_DARK)
    elif v == 2:
        _blood_smear(draw, rng, 16, 15, 9)
        _line(draw, [(8, 7), (16, 13), (24, 12)], BLOOD, 2)
        _line(draw, [(12, 22), (21, 25), (28, 23)], BLOOD_DARK, 2)
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
        _line(draw, [(0, 24), (7, 21), (15, 23), (28, 19)], STONE_DARK, 2)
        _jagged_leaf(draw, 24, 6, -1, ORANGE_DK)
    return img


def _church_wall_variant(v: int) -> Image.Image:
    rng = random.Random(1701 + v * 91)
    img = _new_tile(BLACK)
    px = img.load()
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        base = STONE_DARK if t > 0.45 else BLACK
        for x in range(SIZE):
            if rng.random() < 0.24:
                px[x, y] = rng.choice([BLACK, BLACK, STONE_DARK, LIME_DARK, VOID_BROWN]) + (255,)
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


def gen_tile_shade() -> Image.Image:
    atlas = Image.new("RGBA", (SIZE * 3, SIZE), (0, 0, 0, 0))

    edge = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(edge)
    draw.rectangle((0, 0, 31, 4), fill=SHADE + (SHADE_EDGE_ALPHA[0],))
    draw.rectangle((0, 5, 31, 8), fill=SHADE + (SHADE_EDGE_ALPHA[1],))
    draw.rectangle((0, 9, 31, 11), fill=SHADE + (SHADE_EDGE_ALPHA[2],))
    atlas.paste(edge, (0, 0))

    corner = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(corner)
    draw.rectangle((0, 0, 31, 3), fill=SHADE + (SHADE_EDGE_ALPHA[1],))
    draw.rectangle((0, 0, 3, 31), fill=SHADE + (SHADE_EDGE_ALPHA[1],))
    draw.rectangle((0, 0, 15, 7), fill=SHADE + (SHADE_EDGE_ALPHA[0],))
    draw.rectangle((0, 0, 7, 15), fill=SHADE + (SHADE_EDGE_ALPHA[0],))
    _ellipse_rgba(draw, (2, 2, 21, 21), SHADE, SHADE_EDGE_ALPHA[2])
    atlas.paste(corner, (SIZE, 0))

    edge_deep = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(edge_deep)
    draw.rectangle((0, 0, 31, 6), fill=SHADE + (SHADE_DEEP_ALPHA[0],))
    draw.rectangle((0, 7, 31, 11), fill=SHADE + (SHADE_DEEP_ALPHA[1],))
    draw.rectangle((0, 12, 31, 15), fill=SHADE + (SHADE_DEEP_ALPHA[2],))
    atlas.paste(edge_deep, (SIZE * 2, 0))

    atlas.save(os.path.join(OUT, "tile_shade.png"))
    return atlas


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


def gen_value_sheet(atlases: list[tuple[str, Image.Image]]) -> None:
    scale = 4
    label_h = 14
    gap = 8
    width = max(img.width for _, img in atlases) * scale + gap * 2
    height = sum(img.height * scale + label_h + gap for _, img in atlases) + gap
    sheet = Image.new("RGBA", (width, height), (18, 18, 18, 255))
    draw = ImageDraw.Draw(sheet)
    y = gap
    for label, img in atlases:
        draw.text((gap, y), label, fill=(230, 230, 230, 255))
        y += label_h
        gray = img.convert("LA").convert("RGBA")
        preview = gray.resize((img.width * scale, img.height * scale), Image.Resampling.NEAREST)
        sheet.paste(preview, (gap, y))
        y += preview.height + gap
    sheet.save(os.path.join(OUT, "tile_identity_value_sheet.png"))


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
    gen_tile_shade()
    gen_contact_sheet([
        ("forest floor: serrapilheira / raiz / sangue seco / solo encharcado", floor),
        ("forest wall: dense hostile silhouette", wall),
        ("church floor: stone infected by forest and blood", church_floor),
        ("church wall: altar shadow, roots, corrupted lime", church_wall),
    ])
    gen_value_sheet([
        ("forest floor value", floor),
        ("forest wall value", wall),
        ("church floor value", church_floor),
        ("church wall value", church_wall),
    ])
    gen_light()
    gen_light_beam()
    print("[gen_tiles] organic Caipora-identity tiles generated")

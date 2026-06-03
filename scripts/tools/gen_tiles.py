#!/usr/bin/env python3
"""Gera tiles 32x32 da floresta amazônica na paleta de horror folk.

Algorítmico (não-IA, determinístico via seed), espelhando o precedente de
gen_sfx.py. Saídas:
  assets/sprites/tile_floor.png  — atlas 128x32 = 4 variantes de chão
  assets/sprites/tile_wall.png   — atlas 64x32  = 2 variantes de mata densa
  assets/sprites/light_radial.png — 256x256 gradiente radial (luz 2D)

As variantes de chão quebram o padrão de grade repetido (o ExplorationManager
escolhe uma variante por célula de forma determinística). Tudo permanece pixel-art
NEAREST e some poucos KB no total (export web ≤10MB).

Paleta (constants.gd):
  EARTH #3d1f1f  MOSS #1a2f1a  NIGHT #0d1117  BLOOD #8b0000  AMBER #ff6b00
"""
import os
import random
from PIL import Image

SIZE = 32
FLOOR_VARIANTS = 4
WALL_VARIANTS = 2
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")

EARTH = (61, 31, 31)
EARTH_DARK = (40, 20, 20)
EARTH_LIGHT = (82, 44, 40)
MOSS = (26, 47, 26)
MOSS_DARK = (16, 30, 16)
MOSS_LIGHT = (40, 66, 36)
NIGHT = (13, 17, 23)
LEAF = (34, 58, 30)
LEAF_DARK = (20, 38, 20)
WATER = (18, 28, 34)
WATER_LIGHT = (32, 48, 56)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _base_earth(px, rng):
    """Pinta a base terrosa com pontilhado escuro/claro (úmida)."""
    for y in range(SIZE):
        for x in range(SIZE):
            r = rng.random()
            if r < 0.10:
                px[x, y] = EARTH_DARK + (255,)
            elif r < 0.16:
                px[x, y] = EARTH_LIGHT + (255,)


def _blob(px, rng, cx, cy, rad, col, alpha, density=0.7):
    for y in range(max(0, cy - rad), min(SIZE, cy + rad)):
        for x in range(max(0, cx - rad), min(SIZE, cx + rad)):
            if (x - cx) ** 2 + (y - cy) ** 2 <= rad * rad and rng.random() < density:
                px[x, y] = col + (alpha,)


def _twigs(px, rng, count):
    for _ in range(count):
        x0 = rng.randint(0, SIZE - 1)
        y0 = rng.randint(0, SIZE - 1)
        for k in range(rng.randint(3, 7)):
            xx = min(SIZE - 1, max(0, x0 + k))
            yy = min(SIZE - 1, max(0, y0 + rng.randint(-1, 1)))
            px[xx, yy] = EARTH_DARK + (255,)


def gen_floor():
    """Atlas de chão: 4 variantes terrosas para quebrar o padrão de grade."""
    atlas = Image.new("RGBA", (SIZE * FLOOR_VARIANTS, SIZE), (0, 0, 0, 0))

    for v in range(FLOOR_VARIANTS):
        img = Image.new("RGBA", (SIZE, SIZE), EARTH + (255,))
        px = img.load()
        rng = random.Random(1311 + v * 97)
        _base_earth(px, rng)

        if v == 0:
            # terra limpa: só musgo esparso nos cantos
            for _ in range(4):
                _blob(px, rng, rng.randint(0, SIZE - 1), rng.randint(0, SIZE - 1),
                      rng.randint(2, 3), rng.choice([MOSS_DARK, LEAF_DARK]), 190)
        elif v == 1:
            # terra com folhas caídas
            for _ in range(10):
                _blob(px, rng, rng.randint(0, SIZE - 1), rng.randint(0, SIZE - 1),
                      rng.randint(1, 3), rng.choice([LEAF, LEAF_DARK, MOSS]), 210, 0.85)
        elif v == 2:
            # terra com raízes/gravetos
            _twigs(px, rng, 6)
            for _ in range(3):
                _blob(px, rng, rng.randint(0, SIZE - 1), rng.randint(0, SIZE - 1),
                      rng.randint(2, 3), MOSS_DARK, 180)
        else:
            # terra com poça/musgo úmido
            cx, cy = rng.randint(8, 24), rng.randint(8, 24)
            _blob(px, rng, cx, cy, rng.randint(5, 7), WATER, 150, 0.9)
            _blob(px, rng, cx, cy, rng.randint(2, 4), WATER_LIGHT, 120, 0.7)
            for _ in range(4):
                _blob(px, rng, rng.randint(0, SIZE - 1), rng.randint(0, SIZE - 1),
                      rng.randint(2, 3), MOSS, 190)

        atlas.paste(img, (v * SIZE, 0))

    atlas.save(os.path.join(OUT, "tile_floor.png"))


def gen_wall():
    """Atlas de parede = mata densa: 2 variantes de folhagem sobreposta."""
    atlas = Image.new("RGBA", (SIZE * WALL_VARIANTS, SIZE), (0, 0, 0, 0))

    for v in range(WALL_VARIANTS):
        img = Image.new("RGBA", (SIZE, SIZE), MOSS_DARK + (255,))
        px = img.load()
        rng = random.Random(7 + v * 53)
        # gradiente vertical: topo mais escuro (copa), base levemente mais clara
        for y in range(SIZE):
            t = y / SIZE
            base = lerp(NIGHT, MOSS, 0.3 + t * 0.4)
            for x in range(SIZE):
                px[x, y] = base + (255,)
        # camadas de folhas (elipses) sobrepostas — v1 mais denso
        leaf_count = 26 if v == 0 else 34
        for _ in range(leaf_count):
            cx, cy = rng.randint(0, SIZE - 1), rng.randint(0, SIZE - 1)
            rw, rh = rng.randint(3, 7), rng.randint(2, 4)
            col = rng.choice([MOSS, MOSS_LIGHT, LEAF, LEAF_DARK])
            for y in range(max(0, cy - rh), min(SIZE, cy + rh)):
                for x in range(max(0, cx - rw), min(SIZE, cx + rw)):
                    dx = (x - cx) / max(1, rw)
                    dy = (y - cy) / max(1, rh)
                    if dx * dx + dy * dy <= 1.0:
                        px[x, y] = col + (255,)
        # nervura clara + pontos escuros (profundidade)
        for _ in range(40):
            x, y = rng.randint(0, SIZE - 1), rng.randint(0, SIZE - 1)
            px[x, y] = (MOSS_LIGHT if rng.random() < 0.5 else MOSS_DARK) + (255,)
        atlas.paste(img, (v * SIZE, 0))

    atlas.save(os.path.join(OUT, "tile_wall.png"))


def gen_light():
    """Gradiente radial branco→transparente para PointLight2D (luz 2D suave)."""
    n = 256
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = img.load()
    c = (n - 1) / 2.0
    for y in range(n):
        for x in range(n):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5 / c
            # falloff suave (quadrático), corta na borda do círculo
            a = max(0.0, 1.0 - d)
            a = a * a
            px[x, y] = (255, 255, 255, int(a * 255))
    img.save(os.path.join(OUT, "light_radial.png"))


if __name__ == "__main__":
    gen_floor()
    gen_wall()
    gen_light()
    print("[gen_tiles] tile_floor.png (4) + tile_wall.png (2) + light_radial.png gerados")

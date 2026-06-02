#!/usr/bin/env python3
"""Gera tiles 32x32 da floresta amazônica na paleta de horror folk.

Algorítmico (não-IA, determinístico via seed), espelhando o precedente de
gen_sfx.py. Saída: assets/sprites/tile_floor.png e tile_wall.png.

Paleta (constants.gd):
  EARTH #3d1f1f  MOSS #1a2f1a  NIGHT #0d1117  BLOOD #8b0000  AMBER #ff6b00
"""
import os
import random
from PIL import Image

SIZE = 32
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


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gen_floor():
    """Chão de terra úmida amazônica: base terrosa + manchas escuras + folhas/musgo."""
    rng = random.Random(1311)
    img = Image.new("RGBA", (SIZE, SIZE), EARTH + (255,))
    px = img.load()
    # ruído de terra: pontilhado escuro/claro
    for y in range(SIZE):
        for x in range(SIZE):
            r = rng.random()
            if r < 0.10:
                px[x, y] = EARTH_DARK + (255,)
            elif r < 0.16:
                px[x, y] = EARTH_LIGHT + (255,)
    # manchas de musgo úmido nos cantos (folhagem rastejante)
    for _ in range(6):
        cx, cy = rng.randint(0, SIZE - 1), rng.randint(0, SIZE - 1)
        rad = rng.randint(2, 4)
        col = rng.choice([MOSS_DARK, LEAF_DARK])
        for y in range(max(0, cy - rad), min(SIZE, cy + rad)):
            for x in range(max(0, cx - rad), min(SIZE, cx + rad)):
                if (x - cx) ** 2 + (y - cy) ** 2 <= rad * rad and rng.random() < 0.7:
                    px[x, y] = col + (200,)
    # raízes/gravetos esparsos
    for _ in range(3):
        x0 = rng.randint(0, SIZE - 1)
        y0 = rng.randint(0, SIZE - 1)
        for k in range(rng.randint(3, 7)):
            xx = min(SIZE - 1, max(0, x0 + k))
            yy = min(SIZE - 1, max(0, y0 + rng.randint(-1, 1)))
            px[xx, yy] = EARTH_DARK + (255,)
    img.save(os.path.join(OUT, "tile_floor.png"))


def gen_wall():
    """Parede = mata densa: folhagem escura sobreposta, leitura de bloqueio."""
    rng = random.Random(7)
    img = Image.new("RGBA", (SIZE, SIZE), MOSS_DARK + (255,))
    px = img.load()
    # gradiente vertical: topo mais escuro (copa), base levemente mais clara
    for y in range(SIZE):
        t = y / SIZE
        base = lerp(NIGHT, MOSS, 0.3 + t * 0.4)
        for x in range(SIZE):
            px[x, y] = base + (255,)
    # camadas de folhas (elipses) sobrepostas
    for _ in range(26):
        cx, cy = rng.randint(0, SIZE - 1), rng.randint(0, SIZE - 1)
        rw, rh = rng.randint(3, 7), rng.randint(2, 4)
        col = rng.choice([MOSS, MOSS_LIGHT, LEAF, LEAF_DARK])
        for y in range(max(0, cy - rh), min(SIZE, cy + rh)):
            for x in range(max(0, cx - rw), min(SIZE, cx + rw)):
                dx = (x - cx) / max(1, rw)
                dy = (y - cy) / max(1, rh)
                if dx * dx + dy * dy <= 1.0:
                    px[x, y] = col + (255,)
    # nervura central clara em algumas folhas + pontos escuros (profundidade)
    for _ in range(40):
        x, y = rng.randint(0, SIZE - 1), rng.randint(0, SIZE - 1)
        if rng.random() < 0.5:
            px[x, y] = MOSS_LIGHT + (255,)
        else:
            px[x, y] = MOSS_DARK + (255,)
    img.save(os.path.join(OUT, "tile_wall.png"))


if __name__ == "__main__":
    gen_floor()
    gen_wall()
    print("[gen_tiles] tile_floor.png + tile_wall.png gerados")

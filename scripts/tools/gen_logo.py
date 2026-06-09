#!/usr/bin/env python3
"""Gera o logotipo pixel-art do título: "CAIPORA" em madeira lascada.

Letras chunky (bitmaps 6x7 escalados 4x) com veios de madeira, contorno de
treva, lascas arrancadas nas bordas, escorridos de sangue na base e o par de
olhos da Caipora brilhando dentro do "O" — 2 frames (aberto/piscando) para o
flicker no menu.

Paleta de constants.gd: WOOD/WOOD_DARK, BLOOD, EYE/âmbar, NIGHT.
Determinístico (seed fixa). Saída: assets/sprites/logo_title.png +
logo_title_blink.png (256x96, ≤512px conforme limites de asset).
"""
import os
import random
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")

WOOD = (82, 43, 10)
WOOD_DARK = (41, 18, 3)
WOOD_LIGHT = (118, 66, 22)
OUTLINE = (10, 6, 8)
BLOOD = (139, 0, 0)
BLOOD_DARK = (84, 0, 0)
EYE = (255, 214, 84)
EYE_HOT = (255, 255, 210)

SCALE = 4
GAP = 8

LETTERS = {
    "C": [".####.", "##..##", "##....", "##....", "##....", "##..##", ".####."],
    "A": [".####.", "##..##", "##..##", "######", "##..##", "##..##", "##..##"],
    "I": ["######", "..##..", "..##..", "..##..", "..##..", "..##..", "######"],
    "P": ["#####.", "##..##", "##..##", "#####.", "##....", "##....", "##...."],
    "O": [".####.", "##..##", "##..##", "##..##", "##..##", "##..##", ".####."],
    "R": ["#####.", "##..##", "##..##", "#####.", "##.##.", "##..##", "##..##"],
}
WORD = "CAIPORA"
EYE_LETTER_INDEX = 4   # o "O" — a mata olha de volta


def _glyph_mask(letter):
    rows = LETTERS[letter]
    w, h = len(rows[0]) * SCALE, len(rows) * SCALE
    mask = [[rows[y // SCALE][x // SCALE] == "#" for x in range(w)] for y in range(h)]
    return mask, w, h


def _chip_edges(mask, w, h, rng):
    """Arranca lascas das bordas do glifo (madeira castigada)."""
    for _ in range(10):
        x, y = rng.randrange(w), rng.randrange(h)
        if not mask[y][x]:
            continue
        edge = (x == 0 or y == 0 or x == w - 1 or y == h - 1
                or not mask[y][x - 1] or not mask[y][x + 1]
                or not mask[y - 1][x] or not mask[y + 1][x])
        if edge:
            mask[y][x] = False


def draw_logo(blink=False):
    img = Image.new("RGBA", (256, 96), (0, 0, 0, 0))
    px = img.load()
    rng = random.Random(7331)
    x0 = (256 - (len(WORD) * 6 * SCALE + (len(WORD) - 1) * GAP)) // 2
    y0 = 26

    for i, letter in enumerate(WORD):
        mask, w, h = _glyph_mask(letter)
        _chip_edges(mask, w, h, rng)
        # contorno de treva (1px ao redor do glifo)
        for y in range(h):
            for x in range(w):
                if not mask[y][x]:
                    continue
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    gx, gy = x0 + x + dx, y0 + y + dy
                    yy, xx = y + dy, x + dx
                    inside = 0 <= xx < w and 0 <= yy < h and mask[yy][xx]
                    if not inside and 0 <= gx < 256 and 0 <= gy < 96:
                        px[gx, gy] = OUTLINE + (255,)
        # preenchimento com veios de madeira
        for y in range(h):
            for x in range(w):
                if not mask[y][x]:
                    continue
                if y < 3:
                    col = WOOD_LIGHT          # luz rasante no topo
                elif (y // 3 + i) % 4 == 0:
                    col = WOOD_DARK           # veio escuro
                elif y > h - 4:
                    col = WOOD_DARK           # base na sombra
                else:
                    col = WOOD
                px[x0 + x, y0 + y] = col + (255,)
        # escorridos de sangue na base (1–2 por letra, determinístico)
        for _ in range(rng.randint(1, 2)):
            dx = rng.randrange(2, w - 2)
            if not mask[h - 1][dx]:
                continue
            drip = rng.randint(5, 14)
            for dy in range(drip):
                gy = y0 + h + dy
                if gy >= 96:
                    continue
                col = (BLOOD if dy < drip - 2 else BLOOD_DARK) + (255,)
                px[x0 + dx, gy] = col
                if dy < drip - 3:           # escorrido engrossa no topo
                    px[x0 + dx + 1, gy] = col
            # poça encharcando a base da letra
            for bx in range(max(0, dx - 2), min(w, dx + 3)):
                if mask[h - 1][bx]:
                    px[x0 + bx, y0 + h - 1] = BLOOD + (255,)
                    px[x0 + bx, y0 + h - 2] = BLOOD_DARK + (255,)
        # olhos dentro do "O"
        if i == EYE_LETTER_INDEX and not blink:
            cx, cy = x0 + w // 2, y0 + h // 2
            for ex in (cx - 7, cx + 3):
                for dx in range(4):
                    for dy in range(3):
                        px[ex + dx, cy - 1 + dy] = EYE + (255,)
                px[ex + 1, cy] = EYE_HOT + (255,)
                px[ex + 2, cy] = EYE_HOT + (255,)
        x0 += w + GAP
    return img


if __name__ == "__main__":
    draw_logo(False).save(os.path.join(OUT, "logo_title.png"))
    draw_logo(True).save(os.path.join(OUT, "logo_title_blink.png"))
    print("[gen_logo] logo_title.png + logo_title_blink.png (256x96) gerados")

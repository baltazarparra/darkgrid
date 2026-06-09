#!/usr/bin/env python3
"""Gera as LUTs de color grading por fase (gradient map 256x1).

O shader gradient_map.gdshader converte a luminância da tela em cor da LUT:
sombras→meios-tons→altas-luzes viram uma paleta autoral por fase, unificando
sprites, partículas e cenário sob a mesma direção de cor.

Derivadas da paleta de constants.gd (NIGHT/EARTH/MOSS/BLOOD/AMBER), uma LUT
por fase:
  P1 noite na mata    — azul-noite → musgo → terra → âmbar
  P2 mata queimando   — carvão → sangue seco → brasa → fogo claro
  P3 mata profunda    — breu verde → musgo → verde doentio → névoa clara
  P4 mata morta       — cinza-morte → sangue → ferida aberta → osso quente
  P5 igreja podre     — treva → madeira podre → ouro corrompido → cal

Saída: assets/sprites/grade_p1..p5.png (256x1 RGB, determinístico).
"""
import os
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")

# Stops (posição 0..1, cor RGB) por fase — sombras nunca pretas puras (treva
# com cor), altas-luzes nunca brancas puras (o mundo é sujo).
GRADES = {
    1: [(0.00, (5, 8, 16)), (0.40, (24, 40, 36)),
        (0.75, (110, 70, 38)), (1.00, (255, 176, 97))],
    2: [(0.00, (11, 4, 2)), (0.45, (74, 18, 6)),
        (0.82, (196, 71, 14)), (1.00, (255, 208, 138))],
    3: [(0.00, (4, 10, 8)), (0.45, (21, 48, 31)),
        (0.82, (93, 138, 90)), (1.00, (216, 255, 208))],
    4: [(0.00, (7, 3, 4)), (0.45, (58, 13, 16)),
        (0.80, (139, 26, 26)), (1.00, (255, 201, 160))],
    5: [(0.00, (7, 6, 10)), (0.45, (58, 49, 34)),
        (0.82, (160, 138, 77)), (1.00, (255, 243, 208))],
}


def _sample(stops, t):
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        if t <= p1:
            f = 0.0 if p1 == p0 else (t - p0) / (p1 - p0)
            return tuple(round(a + (b - a) * f) for a, b in zip(c0, c1))
    return stops[-1][1]


def gen_grade(phase, stops):
    img = Image.new("RGB", (256, 1))
    px = img.load()
    for x in range(256):
        px[x, 0] = _sample(stops, x / 255.0)
    img.save(os.path.join(OUT, f"grade_p{phase}.png"))


if __name__ == "__main__":
    for phase, stops in GRADES.items():
        gen_grade(phase, stops)
    print("[gen_grades] grade_p1..p5.png (256x1) gerados")

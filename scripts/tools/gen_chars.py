#!/usr/bin/env python3
"""Gera sprites 48x48 dos personagens na paleta de horror folk amazônico.

Pixel art autoral algorítmica (determinística), priorizando traços-assinatura
que tornam cada personagem identificável:

  Caipora  — cabelo de fogo, pele escura, PÉS VIRADOS PRA TRÁS, pequena/ágil
  Caçador  — chapéu, poncho, espingarda (inimigo humano predador)
  Bruxo    — capuz, cajado com gema, olhos brilhando (boss)

Saída: player_idle/walk_1/walk_2.png, enemy_idle.png, boss_idle.png
"""
import os
from PIL import Image

S = 48
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")

# ── Paleta ────────────────────────────────────────
SKIN = (122, 74, 46)
SKIN_DK = (84, 48, 28)
HAIR = (255, 107, 0)
HAIR_HOT = (255, 168, 56)
HAIR_DEEP = (188, 42, 0)
EYE = (255, 214, 84)
EARTH = (61, 31, 31)
EARTH_DK = (40, 20, 20)
LEAF = (34, 58, 30)
LEAF_DK = (20, 38, 20)

HAT = (38, 25, 16)
HAT_DK = (24, 15, 9)
HAT_BAND = (96, 30, 18)
PONCHO = (74, 42, 30)
PONCHO_DK = (50, 28, 20)
HUMAN_SKIN = (150, 112, 82)
HUMAN_SKIN_DK = (108, 78, 54)
GUN = (28, 24, 22)
GUN_HL = (70, 64, 58)

HOOD = (47, 16, 62)
HOOD_DK = (28, 9, 40)
ROBE = (33, 13, 48)
ROBE_DK = (20, 7, 30)
STAFF = (74, 44, 22)
GEM = (255, 107, 0)
GEM_HOT = (255, 190, 90)
GLOW_EYE = (255, 80, 30)


class C:
    def __init__(self):
        self.im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        self.p = self.im.load()

    def px(self, x, y, c):
        if 0 <= x < S and 0 <= y < S:
            self.p[x, y] = (c[0], c[1], c[2], 255) if len(c) == 3 else c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.px(x, y, c)

    def disc(self, cx, cy, r, c):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.px(x, y, c)

    def save(self, name):
        self.im.save(os.path.join(OUT, name))


def caipora(leg_phase=0):
    """leg_phase: 0 idle, -1/+1 passos. Pés virados pra trás (toes p/ trás)."""
    c = C()
    # ── Cabelo de fogo (chamas subindo) ──
    c.rect(17, 8, 30, 16, HAIR_DEEP)
    for (x, top) in [(16, 6), (19, 2), (22, 4), (25, 1), (28, 4), (31, 3), (33, 7)]:
        c.rect(x, top, x + 1, 12, HAIR)
    for (x, top) in [(20, 4), (24, 3), (27, 5), (30, 5)]:
        c.rect(x, top, x, top + 5, HAIR_HOT)
    c.rect(18, 12, 31, 15, HAIR)
    # ── Cabeça (pele escura) ──
    c.disc(24, 19, 6, SKIN)
    c.rect(19, 16, 29, 22, SKIN)
    c.rect(19, 22, 29, 23, SKIN_DK)  # queixo sombreado
    # olhos brilhando (encara o jogador)
    c.rect(21, 19, 22, 20, EYE)
    c.rect(26, 19, 27, 20, EYE)
    c.px(21, 19, (255, 255, 200))
    c.px(26, 19, (255, 255, 200))
    # ── Torso (terra + cinto de folhas) ──
    c.rect(19, 24, 29, 34, EARTH)
    c.rect(19, 24, 20, 34, EARTH_DK)
    c.rect(18, 30, 30, 33, LEAF)        # cinto de folhas
    c.rect(18, 33, 30, 34, LEAF_DK)
    # braços finos (ágil)
    c.rect(15, 25, 18, 33, SKIN_DK)
    c.rect(30, 25, 33, 33, SKIN_DK)
    # ── Pernas ──
    lx = 21 + leg_phase
    rx = 25 - leg_phase
    c.rect(lx, 35, lx + 2, 43, SKIN)
    c.rect(rx, 35, rx + 2, 43, SKIN)
    c.rect(lx, 35, lx, 43, SKIN_DK)
    c.rect(rx, 35, rx, 43, SKIN_DK)
    # ── PÉS VIRADOS PRA TRÁS (calcanhar à frente, dedos pra trás) ──
    # corpo "encara" o jogador; os pés apontam para LONGE (pra cima/trás na tela)
    for fx in (lx, rx):
        c.rect(fx - 3, 43, fx + 2, 44, SKIN)      # planta
        c.rect(fx - 3, 40, fx - 2, 44, SKIN_DK)   # dedos esticados pra trás (frente do pé)
        c.px(fx - 3, 40, SKIN)
        c.px(fx - 2, 39, SKIN)
    return c


def hunter():
    """Caçador humano: chapéu, poncho, espingarda apontada."""
    c = C()
    # ── Chapéu de aba larga ──
    c.rect(14, 13, 33, 15, HAT_DK)      # aba
    c.rect(13, 14, 34, 15, HAT_DK)
    c.rect(18, 6, 29, 13, HAT)          # copa
    c.rect(18, 11, 29, 12, HAT_BAND)    # fita
    c.rect(18, 6, 19, 13, HAT_DK)
    # ── Rosto na sombra do chapéu ──
    c.rect(19, 16, 28, 23, HUMAN_SKIN)
    c.rect(19, 16, 28, 17, HUMAN_SKIN_DK)  # sombra da aba
    c.rect(20, 19, 21, 20, (20, 10, 8))    # olhos fundos
    c.rect(26, 19, 27, 20, (20, 10, 8))
    c.rect(22, 22, 25, 23, HUMAN_SKIN_DK)  # barba/queixo
    # ── Poncho ──
    c.rect(15, 24, 32, 38, PONCHO)
    c.rect(15, 24, 17, 38, PONCHO_DK)
    c.rect(30, 24, 32, 38, PONCHO_DK)
    c.rect(22, 24, 25, 38, PONCHO_DK)   # vinco central
    for y in range(38, 41):             # franja
        for x in range(15, 33, 2):
            c.px(x, y, PONCHO_DK)
    # ── Pernas/botas ──
    c.rect(19, 40, 22, 46, EARTH_DK)
    c.rect(25, 40, 28, 46, EARTH_DK)
    c.rect(18, 45, 23, 46, HAT_DK)
    c.rect(24, 45, 29, 46, HAT_DK)
    # ── Espingarda (atravessada, apontando p/ frente-baixo) ──
    c.rect(30, 27, 45, 29, GUN)         # cano
    c.rect(30, 26, 45, 26, GUN_HL)
    c.rect(27, 28, 33, 33, EARTH_DK)    # coronha
    c.px(45, 27, GUN_HL)
    # mãos segurando
    c.rect(30, 29, 32, 31, HUMAN_SKIN)
    c.rect(36, 28, 38, 30, HUMAN_SKIN)
    return c


def wizard():
    """Bruxo: capuz, túnica, cajado com gema, olhos brilhando no vazio."""
    c = C()
    # ── Cajado (à direita) ──
    c.rect(36, 10, 38, 46, STAFF)
    c.rect(36, 10, 36, 46, EARTH_DK)
    # gema âmbar no topo, brilhando
    c.disc(37, 8, 4, GEM)
    c.disc(37, 8, 2, GEM_HOT)
    c.px(36, 7, (255, 255, 220))
    # ── Capuz ──
    c.rect(16, 10, 31, 14, HOOD)
    c.disc(23, 14, 9, HOOD)
    c.rect(14, 14, 32, 26, HOOD)
    c.rect(14, 14, 16, 26, HOOD_DK)
    c.rect(30, 14, 32, 26, HOOD_DK)
    # pico do capuz
    c.rect(21, 6, 26, 12, HOOD)
    c.rect(22, 4, 24, 8, HOOD_DK)
    # ── Vazio do rosto + olhos brilhando ──
    c.rect(18, 17, 29, 25, (8, 3, 12))
    c.rect(20, 20, 22, 22, GLOW_EYE)
    c.rect(25, 20, 27, 22, GLOW_EYE)
    c.px(21, 21, (255, 180, 120))
    c.px(26, 21, (255, 180, 120))
    # ── Túnica longa ──
    c.rect(13, 26, 33, 46, ROBE)
    c.rect(13, 26, 15, 46, ROBE_DK)
    c.rect(31, 26, 33, 46, ROBE_DK)
    c.rect(22, 26, 24, 46, ROBE_DK)     # dobra central
    # mangas/braço segurando o cajado
    c.rect(30, 28, 37, 32, ROBE)
    c.rect(30, 31, 38, 33, HOOD_DK)
    # barra esfarrapada
    for x in range(13, 34, 3):
        c.px(x, 46, ROBE_DK)
        c.px(x + 1, 45, ROBE_DK)
    # símbolo ritual no peito (pentagrama simplificado em sangue)
    c.rect(22, 34, 24, 40, (90, 0, 0))
    c.rect(20, 36, 26, 37, (90, 0, 0))
    return c


if __name__ == "__main__":
    caipora(0).save("player_idle.png")
    caipora(-1).save("player_walk_1.png")
    caipora(1).save("player_walk_2.png")
    hunter().save("enemy_idle.png")
    wizard().save("boss_idle.png")
    print("[gen_chars] caipora + caçador + bruxo gerados (48x48)")

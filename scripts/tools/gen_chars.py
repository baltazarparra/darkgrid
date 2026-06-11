#!/usr/bin/env python3
"""Gera sprites dos personagens na paleta de horror folk amazônico.

Pixel art autoral algorítmica (determinística), priorizando traços-assinatura
que tornam cada personagem identificável:

  Caipora  — PROTAGONISTA: gerada por gen_caipora.py (pipeline premium próprio,
             ver docs/CONCEITO-protagonista.md). Este módulo apenas delega.
  Caçador & Bruxo — INIMIGOS COMUNS: gerados por gen_inimigos.py (pipeline
             premium 112px arena + 56px mapa, ver docs/CONCEITO-inimigos.md). Delega.
  Curupira — BOSS P3 e Jesuíta — BOSS FINAL P5: gerados por gen_bosses.py
             (pipeline premium 128px arena + 48px mapa, ver
             docs/CONCEITO-curupira.md e docs/CONCEITO-jesuita.md). Delega.
  Boitatá — BOSS P2: gerado por gen_boitata.py (pipeline premium 160x128). Delega.
  Caçador c/ machados — 48x48: capuz, manto, dois machados, olhos brilhando (boss base)
  Mula sem Cabeça     — 192x192 via gen_mula.py: sem cabeça, jato de fogo no toco,
                        ferraduras de ferro, arreio amaldiçoado (boss da Fase 1)

Saída: player_* via gen_caipora (96x96), enemy/bruxo_* via gen_inimigos
       (112x112 + 56x56 mapa), curupira_*/jesuita_* via gen_bosses
       (128x128 + 48x48 mapa), boitata_* via gen_boitata (160x128),
       saci_* via gen_saci (128x128), mula_* via gen_mula (192x192),
       boss_idle/windup.png (48x48 legado).
"""
import os
from PIL import Image

import gen_caipora
import gen_inimigos
import gen_mula
import gen_saci
import gen_bosses
import gen_boitata

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

HOOD = (47, 16, 62)
HOOD_DK = (28, 9, 40)
ROBE = (33, 13, 48)
ROBE_DK = (20, 7, 30)
STAFF = (74, 44, 22)
GLOW_EYE = (255, 80, 30)
AXE_HAFT = (58, 34, 18)        # cabo de madeira escura
AXE_HAFT_DK = (38, 22, 12)
AXE_STEEL = (60, 56, 52)       # lâmina de aço sombrio
AXE_EDGE = (140, 138, 146)     # fio reluzente da lâmina
STRAP = (96, 30, 18)           # correia/couro cruzada do boss


class C:
    def __init__(self, size=S):
        self.S = size
        self.im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        self.p = self.im.load()

    def px(self, x, y, c):
        if 0 <= x < self.S and 0 <= y < self.S:
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

    def line(self, x0, y0, x1, y1, c):
        """Bresenham simples — usado pelo cipó/chicote."""
        dx = abs(x1 - x0)
        dy = abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx - dy
        while True:
            self.px(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x0 += sx
            if e2 < dx:
                err += dx
                y0 += sy

    def save(self, name):
        self.im.save(os.path.join(OUT, name))

    def shift(self, dx, dy):
        """Desloca o desenho inteiro (linguagem corporal: agachar, avançar)."""
        im2 = Image.new("RGBA", (self.S, self.S), (0, 0, 0, 0))
        im2.paste(self.im, (dx, dy))
        self.im = im2
        self.p = im2.load()


def _axe(c, haft_x, blade_side, dy=0):
    """Machado de cabo longo. haft_x = coluna do cabo; blade_side -1 esq / +1 dir;
    dy desloca o machado inteiro (erguer no windup).

    Lâmina larga no topo (single-bit) voltada pra fora, fio reluzente — leitura
    clara de 'machado' e separa o boss do caçador-espingarda.
    """
    # ── Cabo (vertical, madeira escura) ──
    c.rect(haft_x, 9 + dy, haft_x + 1, 41 + dy, AXE_HAFT)
    c.rect(haft_x, 9 + dy, haft_x, 41 + dy, AXE_HAFT_DK)
    # ── Cabeça da lâmina (no topo do cabo, voltada pra fora) ──
    if blade_side > 0:
        bx0, bx1 = haft_x + 2, haft_x + 7        # cresce pra direita
        c.rect(bx0, 7 + dy, bx1, 16 + dy, AXE_STEEL)
        c.rect(bx0, 9 + dy, bx1 + 1, 14 + dy, AXE_STEEL)   # barriga da lâmina
        c.rect(bx1 + 1, 9 + dy, bx1 + 1, 14 + dy, AXE_EDGE)
        c.rect(bx0, 7 + dy, bx0, 16 + dy, AXE_EDGE)        # topo do gume
    else:
        bx0, bx1 = haft_x - 5, haft_x            # cresce pra esquerda
        c.rect(bx0, 7 + dy, bx1, 16 + dy, AXE_STEEL)
        c.rect(bx0 - 1, 9 + dy, bx1, 14 + dy, AXE_STEEL)   # barriga da lâmina
        c.rect(bx0 - 1, 9 + dy, bx0 - 1, 14 + dy, AXE_EDGE)
        c.rect(bx1, 7 + dy, bx1, 16 + dy, AXE_EDGE)        # topo do gume


def axe_hunter(pose="idle"):
    """Caçador com machados (boss): capuz, manto, dois machados, olhos no vazio.

    pose "windup": machados içados acima da cabeça — o golpe duplo vem aí.

    Predador humano amaldiçoado — silhueta imponente, encapuzado na sombra,
    empunhando um machado em cada mão. A aura de sombra fica a cargo do boss.gd.
    """
    c = C()
    # ── Machados (um de cada lado; içados no windup) ──
    axe_dy = -5 if pose == "windup" else 0
    _axe(c, 9, -1, axe_dy)
    _axe(c, 38, +1, axe_dy)
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
    # ── Manto longo ──
    c.rect(13, 26, 33, 46, ROBE)
    c.rect(13, 26, 15, 46, ROBE_DK)
    c.rect(31, 26, 33, 46, ROBE_DK)
    c.rect(22, 26, 24, 46, ROBE_DK)     # dobra central
    # ── Braços estendidos segurando os machados ──
    c.rect(10, 28, 16, 31, ROBE)        # braço esq
    c.rect(9, 30, 12, 33, HOOD_DK)      # mão esq no cabo
    c.rect(30, 28, 38, 31, ROBE)        # braço dir
    c.rect(36, 30, 39, 33, HOOD_DK)     # mão dir no cabo
    # barra esfarrapada
    for x in range(13, 34, 3):
        c.px(x, 46, ROBE_DK)
        c.px(x + 1, 45, ROBE_DK)
    # ── Correia de couro cruzada no peito (caçador, sem tema mágico) ──
    c.line(17, 28, 28, 38, STRAP)
    c.line(17, 29, 28, 39, AXE_HAFT_DK)
    if pose == "windup":
        c.shift(0, 1)   # afunda na base antes de descer os machados
    return c


if __name__ == "__main__":
    gen_caipora.generate_all()   # protagonista (pipeline premium próprio)
    gen_inimigos.generate_all()  # caçador/bruxo (pipeline premium 112px+56px)
    gen_bosses.generate_all()    # curupira (pipeline premium 128px+48px)
    gen_boitata.generate_all()   # boitatá (pipeline premium 160x128)
    axe_hunter().save("boss_idle.png")
    axe_hunter("windup").save("boss_windup.png")
    gen_saci.generate_all()      # saci (pipeline premium 128x128)
    gen_mula.generate_all()      # mula (pipeline premium 192x192)
    print("[gen_chars] caipora (via gen_caipora) + caçador/bruxo (via gen_inimigos) + curupira/jesuíta (via gen_bosses) + boitatá (via gen_boitata) + saci (via gen_saci) + mula (via gen_mula) + caçador-de-machados (48x48) gerados")

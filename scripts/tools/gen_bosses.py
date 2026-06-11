#!/usr/bin/env python3
"""Generate the boss sprites — premium organic pipeline (KI-012, one boss per session).

Same recipe as the protagonist/invaders (`gen_inimigos.py` Painter): organic
vector shapes supersampled 8× → area downsample → closed-palette snap (per
boss) → continuous 1px dark outline. Arena canvas 128×128 (node scale 1.2,
uniform texels) + 48×48 map variant re-rendered from the SAME vectors.

Curupira — art law: `docs/PLANO-redesign-curupira.md` (§2) / consolidated in
`docs/CONCEITO-curupira.md`. The oldest protector of the forest, the Caipora's
kin: deep-green body, blood-red serrated crest (dead fire — "sem fogo"),
pitch void face with leaf-green slit eyes, BACKWARDS FEET. Brand locks: no
pure-white round eyes, no protagonist orange (#ff4500/#8b2a00), no crystal
green (#00fa9a). Bosses face LEFT, toward the Caipora.
"""

from __future__ import annotations

import os

from gen_inimigos import (
    BLOOD,
    BONE_DK,
    OUT,
    OUTLINE,
    Painter,
    _outline,
)
from PIL import Image, ImageDraw

# A Caipora é uma CRIANÇA da mata e o Curupira é o parente mais antigo — MESMO
# porte (contrato: 0.9–1.1× a altura visual dela, test_boss_scale_proportions).
# Arena: canvas 128, figura ~78px (×1.2 ≈ 94px visuais, herdando os ~92px do
# legado 48×2.0). Mapa: re-render 48×48 dos mesmos vetores, figura ~43px
# (a Caipora anda o mapa a ~42px visuais).
ARENA_SIZE = 128
MAP_SIZE = 48
MAP_GRID = 32.0
MAP_SHIFT = (-7.0, -14.5)

# ── Curupira (o parente mais antigo) ──────────────
SKIN_DK = (20, 56, 28)          # #14381c verde profundo (sombra, família da aura)
SKIN = (42, 107, 52)            # #2a6b34 verde da mata
CRISTA_DK = (90, 16, 10)        # #5a100a vermelho-sangue (raiz da crista)
CRISTA = (168, 40, 30)          # #a8281e fogo morto — nunca o laranja da juba
VOID = (10, 13, 8)              # #0a0d08 breu do rosto
EYE = (47, 168, 56)             # #2fa838 verde-FOLHA (fendas) — nunca #00fa9a
EYE_HOT = (102, 212, 78)        # #66d44e ponto vivo da fenda

CURUPIRA_PALETTE = [
    OUTLINE, SKIN_DK, SKIN, CRISTA_DK, CRISTA, VOID, EYE, EYE_HOT, BONE_DK, BLOOD,
]


# ════════════════════════════════════════════════════
# Curupira — leitura a 32px: pés ao contrário + crista
# ════════════════════════════════════════════════════

def _curupira_pegadas(p: Painter) -> None:
    # Pegadas invertidas de sangue: manchas no chão PARA ONDE ELE NÃO FOI
    # (eco do padrão RASTRO ←→←→). Encara a esquerda; o rastro engana à frente.
    p.ellipse(13.6, 45.0, 1.6, 0.6, BLOOD)
    p.ellipse(17.2, 45.3, 1.2, 0.5, BLOOD)


def _curupira_pes(p: Painter, windup: bool = False) -> None:
    # PÉS AO CONTRÁRIO — A assinatura. Encara a esquerda; os dedos apontam
    # para TRÁS (direita), calcanhar na frente, garras de osso na ponta.
    # Pé distante primeiro (sombra), pé próximo por cima: duas lâminas
    # horizontais paralelas que rompem a silhueta para trás. No windup os
    # joelhos dobram (mola comprimida) mas os pés CRAVAM na mesma linha de chão.
    if windup:
        p.limb((26.8, 39.0), (28.8, 41.6), 2.5, 2.0, SKIN_DK)  # coxa distante
        p.limb((28.8, 41.6), (27.8, 44.2), 2.0, 1.6, SKIN_DK)  # canela
        p.ellipse(26.1, 45.3, 1.0, 0.8, SKIN_DK)               # calcanhar
        p.limb((26.8, 45.2), (33.2, 45.1), 2.0, 1.5, SKIN_DK)  # pé distante
        p.limb((33.2, 44.8), (35.4, 44.5), 0.8, 0.3, BONE_DK)  # garras
        p.limb((33.3, 45.4), (35.5, 45.6), 0.8, 0.3, BONE_DK)
        p.limb((20.4, 39.2), (18.6, 41.4), 2.5, 2.0, SKIN)     # coxa próxima
        p.limb((18.6, 41.4), (19.4, 43.6), 2.0, 1.6, SKIN)     # canela
        p.ellipse(17.4, 43.8, 1.1, 0.85, SKIN)                 # calcanhar
        p.limb((18.2, 43.8), (25.8, 43.7), 1.8, 1.4, SKIN)     # pé próximo
        p.limb((25.8, 43.1), (28.2, 42.7), 0.8, 0.3, BONE_DK)  # garras abertas
        p.limb((26.0, 43.8), (28.5, 43.8), 0.85, 0.35, BONE_DK)
        p.limb((25.8, 44.4), (28.0, 44.8), 0.8, 0.3, BONE_DK)
        return
    p.limb((26.4, 37.2), (27.2, 44.0), 2.4, 1.6, SKIN_DK)     # perna distante
    p.ellipse(25.3, 45.3, 1.0, 0.8, SKIN_DK)                  # calcanhar distante
    p.limb((26.0, 45.2), (32.4, 45.1), 2.0, 1.5, SKIN_DK)     # pé distante
    p.limb((32.4, 44.9), (34.6, 44.6), 0.8, 0.3, BONE_DK)     # garras
    p.limb((32.5, 45.5), (34.7, 45.7), 0.8, 0.3, BONE_DK)
    p.limb((21.0, 37.2), (20.4, 42.8), 2.4, 1.6, SKIN)        # perna próxima
    p.ellipse(18.6, 43.6, 1.1, 0.85, SKIN)                    # calcanhar próximo
    p.limb((19.4, 43.6), (26.6, 43.5), 1.8, 1.4, SKIN)        # pé próximo
    p.limb((26.6, 42.9), (28.9, 42.5), 0.8, 0.3, BONE_DK)     # garras abertas
    p.limb((26.8, 43.6), (29.2, 43.6), 0.85, 0.35, BONE_DK)
    p.limb((26.6, 44.2), (28.7, 44.6), 0.8, 0.3, BONE_DK)


def _curupira_corpo(p: Painter, windup: bool = False) -> None:
    if windup:
        # Mola comprimida: tronco agachado, inclinado sobre a Caipora
        p.poly([(18.4, 32.2), (26.6, 31.6), (27.8, 39.2), (18.0, 39.4)], SKIN)
        p.poly([(24.6, 32.0), (27.8, 39.2), (24.8, 39.2), (23.6, 32.4)], SKIN_DK)
        p.limb((19.8, 33.8), (22.4, 36.4), 0.9, 0.7, BLOOD)
        p.limb((22.2, 33.4), (20.2, 35.8), 0.7, 0.6, BLOOD)
        return
    # Tronco curto, peso assentado — a indiferença de quem é mais antigo
    p.poly([(19.6, 29.5), (27.4, 29.5), (28.2, 37.6), (19.0, 37.6)], SKIN)
    p.poly([(25.8, 29.8), (28.2, 37.6), (25.2, 37.6), (24.6, 30.2)], SKIN_DK)
    # Talhos de machado cicatrizados no peito (os invasores tentaram)
    p.limb((20.8, 31.6), (23.2, 34.4), 0.9, 0.7, BLOOD)
    p.limb((23.0, 31.2), (21.2, 33.8), 0.7, 0.6, BLOOD)


def _curupira_bracos(p: Painter, windup: bool = False) -> None:
    if windup:
        # A indiferença quebrou: braços abertos, garras em leque
        p.limb((27.6, 33.0), (31.2, 35.2), 2.3, 1.6, SKIN_DK)
        for tip in ((33.4, 33.8), (33.9, 35.8), (33.0, 37.4)):
            p.limb((31.4, 35.5), tip, 0.75, 0.35, BONE_DK)
        p.limb((18.6, 33.4), (14.8, 35.8), 2.3, 1.6, SKIN_DK)
        for tip in ((12.6, 34.4), (12.4, 36.6), (13.4, 38.4)):
            p.limb((14.6, 36.0), tip, 0.75, 0.35, BONE_DK)
        return
    # Braços longos caídos FORA da silhueta do tronco, parados — nem guarda,
    # nem bote. Escuros contra o tronco claro; garras de osso penduradas.
    p.limb((28.0, 30.6), (30.6, 38.6), 2.3, 1.6, SKIN_DK)     # distante
    for tip in ((30.2, 41.0), (31.2, 41.3), (32.0, 40.7)):
        p.limb((30.7, 39.0), tip, 0.75, 0.35, BONE_DK)
    p.limb((19.0, 30.6), (16.4, 38.8), 2.3, 1.6, SKIN_DK)     # próximo
    for tip in ((15.6, 41.2), (16.6, 41.6), (17.6, 41.1)):
        p.limb((16.4, 39.2), tip, 0.75, 0.35, BONE_DK)


def _curupira_crista(p: Painter, hx: float = 0.0, hy: float = 0.0,
                     ericada: bool = False) -> None:
    # Crista serrilhada vermelho-sangue: eco da juba da Caipora na LINGUAGEM
    # (massa serrilhada envolvendo a cabeça), nunca na cor. Fogo que já apagou.
    # No windup ela ERIÇA: picos esticados e abertos (telegraph de silhueta).
    kx = 1.4 if ericada else 1.0
    ky = 1.5 if ericada else 1.0

    def at(x: float, y: float) -> tuple[float, float]:
        return (x + hx, y + hy)

    p.ellipse(23.5 + hx, 24.8 + hy, 8.4, 6.0, CRISTA)
    # raiz escura (lado de trás, direita — ele encara a esquerda)
    p.poly([at(26.0, 19.6), at(31.6, 22.0), at(32.0, 28.4), at(27.0, 30.0), at(25.4, 24.0)], CRISTA_DK)
    # picos serrilhados varridos para TRÁS (direita) — sobem mortos, sem chama
    spikes = [
        ((16.2, 24.0), (13.8, 21.2)),
        ((18.2, 21.0), (16.8, 18.0)),
        ((21.0, 19.4), (20.6, 16.0)),
        ((24.2, 19.0), (25.0, 15.4)),
        ((27.2, 19.8), (29.4, 16.6)),
        ((29.8, 22.0), (33.2, 19.2)),
        ((31.4, 25.0), (35.0, 23.2)),
    ]
    for (bx, by), (tx, ty) in spikes:
        tip = at(bx + (tx - bx) * kx, by + (ty - by) * ky)
        p.poly([at(bx - 1.9, by + 1.4), at(bx + 1.9, by + 1.4), tip], CRISTA)
    # picos mortos entre os vivos (profundidade da serrilha)
    for (bx, by), (tx, ty) in (
        ((19.6, 20.0), (18.4, 17.4)),
        ((25.8, 19.2), (27.4, 16.2)),
        ((30.6, 23.4), (33.8, 21.4)),
    ):
        tip = at(bx + (tx - bx) * kx, by + (ty - by) * ky)
        p.poly([at(bx - 1.2, by + 1.2), at(bx + 1.2, by + 1.2), tip], CRISTA_DK)
    # mechas caindo nos ombros (moldura serrilhada do rosto, dos dois lados)
    p.poly([at(15.0, 24.6), at(18.2, 24.0), at(17.0, 31.8), at(14.6, 28.6)], CRISTA)
    p.poly([at(17.6, 28.0), at(19.2, 27.2), at(18.8, 32.6)], CRISTA_DK)
    p.poly([at(31.8, 25.2), at(29.0, 25.0), at(31.6, 32.0), at(32.6, 28.6)], CRISTA_DK)
    p.poly([at(29.0, 27.6), at(27.6, 27.6), at(28.6, 32.2)], CRISTA_DK)


def _curupira_rosto(p: Painter, hx: float = 0.0, hy: float = 0.0,
                    windup: bool = False) -> None:
    # Vazio de breu emoldurado pela crista — parente da Caipora: sem boca,
    # sem dente, sem expressão humana. O horror é a ausência.
    p.ellipse(22.6 + hx, 26.8 + hy, 4.9, 4.1, VOID)
    # Fendas verde-folha semicerradas: a indiferença de quem é mais antigo
    # que o medo. NUNCA redondas, NUNCA brancas (assinatura da Caipora).
    # O ponto vivo pende pra esquerda — o olhar já está na Caipora.
    # No windup as fendas ESCANCARAM (mas seguem fendas, nunca círculos).
    ry = 1.0 if windup else 0.6
    ry_hot = 0.62 if windup else 0.38
    p.ellipse(20.1 + hx, 26.7 + hy, 1.85, ry, EYE)
    p.ellipse(25.1 + hx, 26.7 + hy, 1.85, ry, EYE)
    p.ellipse(19.6 + hx, 26.7 + hy, 0.95, ry_hot, EYE_HOT)
    p.ellipse(24.6 + hx, 26.7 + hy, 0.95, ry_hot, EYE_HOT)


def curupira(pose: str = "idle", size: int = ARENA_SIZE, grid: float = 48.0,
             shift: tuple[float, float] = (0.0, 0.0)) -> Image.Image:
    p = Painter(size, grid, shift)
    windup = pose == "windup"
    # Cabeça no windup: desce (agachamento) e avança sobre a Caipora
    hx, hy = (-1.2, 2.6) if windup else (0.0, 0.0)
    _curupira_pegadas(p)
    _curupira_pes(p, windup)
    _curupira_bracos(p, windup)
    _curupira_corpo(p, windup)
    _curupira_crista(p, hx, hy, ericada=windup)
    _curupira_rosto(p, hx, hy, windup=windup)
    img = p.render(CURUPIRA_PALETTE)
    _outline(img)
    return img


def curupira_map() -> Image.Image:
    # Re-render dos MESMOS vetores na moldura do mapa (48×48, figura ~43px ≈
    # a Caipora a ~42px visuais) — nunca downscale NEAREST do asset grande.
    return curupira("idle", MAP_SIZE, MAP_GRID, MAP_SHIFT)


# ════════════════════════════════════════════════════
# Prancha de conceito
# ════════════════════════════════════════════════════

def _contact_sheet(frames: list[tuple[str, Image.Image]]) -> None:
    """Prancha: boss 2× + leitura 32px + Caipora e caçador 2× (hierarquia)."""
    zoom = 2
    label_h = 14
    refs: list[tuple[str, Image.Image]] = []
    for ref_name, ref_label in (("player_idle.png", "caipora (ref)"),
                                ("enemy_idle.png", "cacador (ref)")):
        path = os.path.join(OUT, ref_name)
        if os.path.exists(path):
            refs.append((ref_label, Image.open(path).convert("RGBA")))
    cells = frames + refs
    cell_ws = [img.width * zoom + 16 for _, img in cells]
    width = sum(cell_ws)
    height = label_h + max(img.height * zoom for _, img in cells) + 60
    sheet = Image.new("RGBA", (width, height), (18, 14, 15, 255))
    draw = ImageDraw.Draw(sheet)
    base_y = height - 44
    x = 0
    for i, (label, img) in enumerate(cells):
        big = img.resize((img.width * zoom, img.height * zoom), Image.Resampling.NEAREST)
        sheet.alpha_composite(big, (x + 8, base_y - big.height))
        draw.text((x + 8, 1), label, fill=(230, 210, 180, 255))
        if i < len(frames):
            # leitura 32px (checklist da skill §5)
            tiny = img.resize((32, 32), Image.Resampling.BOX)
            sheet.alpha_composite(tiny, (x + 8, base_y + 8))
        x += cell_ws[i]
    sheet.save(os.path.join(OUT, "curupira_contact_sheet.png"))


def generate_all() -> None:
    os.makedirs(OUT, exist_ok=True)
    idle = curupira("idle")
    windup = curupira("windup")
    idle.save(os.path.join(OUT, "curupira_idle.png"))
    windup.save(os.path.join(OUT, "curupira_windup.png"))
    curupira_map().save(os.path.join(OUT, "curupira_map.png"))
    _contact_sheet([("curupira idle", idle), ("curupira windup", windup)])
    print("[gen_bosses] curupira idle/windup (128x128) + variante de mapa (48x48) + prancha gerados")


if __name__ == "__main__":
    generate_all()

"""Gera assets/sprites/weapon_forca3.png — Tronco Buster 64x112.

Espada do aprimoramento final de força (`forca_3` — "Fúria Ancestral"): um TRONCO
de madeira maciço com a silhueta 100% inspirada na Buster Sword do Cloud (FF7) —
lâmina larga e chata, chanfro central, guarda e cabo enrolado — porém esculpido em
madeira, maior que a Caipora. Os dois "slots de materia" viram NÓS escuros naturais
da madeira (sem brilho). A aura de ouro dark + fumaça é feita em runtime por
WeaponVisual (partículas), não no sprite.

Geometria 100% determinística (sem dependências externas: struct/zlib puros).
"""
import struct, zlib, os

W, H = 64, 112
CX = 32  # centro X (eixo de simetria da lâmina)


def png_chunk(tag: bytes, data: bytes) -> bytes:
    c = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", c)


def encode_png(pixels: list[list[tuple[int, int, int, int]]]) -> bytes:
    h, w = len(pixels), len(pixels[0])
    raw = b""
    for row in pixels:
        raw += b"\x00"
        for r, g, b, a in row:
            raw += bytes([r, g, b, a])
    ihdr = struct.pack(">II", w, h) + bytes([8, 6, 0, 0, 0])  # RGBA, 8-bit
    compressed = zlib.compress(raw, 9)
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", ihdr)
        + png_chunk(b"IDAT", compressed)
        + png_chunk(b"IEND", b"")
    )


# ─── Paleta madeira (r, g, b, a) ──────────────────────────────────────────────
TRANSP     = (  0,   0,   0,   0)
WOOD_DARK  = ( 41,  18,   3, 255)   # sombra interna / 2º px da borda
WOOD_MID   = ( 82,  43,  10, 255)   # corpo da lâmina
WOOD_LIGHT = (163,  94,  36, 255)   # luz lateral do chanfro
WOOD_HI    = (212, 152,  80, 255)   # highlight do flat central
BARK_DARK  = ( 25,  15,   5, 255)   # borda de casca / cabo escuro
BARK_MID   = ( 46,  28,  13, 255)   # cabo / guarda médio
BARK_HI    = ( 92,  62,  30, 255)   # topo iluminado da guarda
VEIN       = ( 55,  28,   5, 255)   # veio de madeira
KNOT_RING  = ( 60,  33,   9, 255)   # anel externo do nó
KNOT_CORE  = ( 18,  10,   3, 255)   # miolo escuro do nó


def blank() -> list[list[tuple]]:
    return [[TRANSP] * W for _ in range(H)]


grid = blank()


# ─── Larguras por região ──────────────────────────────────────────────────────
BLADE_TOP, BLADE_BOT = 0, 80     # lâmina chata estilo Buster
GUARD_TOP, GUARD_BOT = 81, 86    # crossguard
GRIP_TOP,  GRIP_BOT  = 87, 104   # cabo enrolado
POMMEL_TOP, POMMEL_BOT = 105, 111

BLADE_MAX_W = 44   # largura cheia da lâmina (chata e larga)
TIP_END     = 9    # linha onde a ponta termina de abrir


def blade_width(row: int) -> int:
    if row < TIP_END:
        # ponta chanfrada larga (não pontuda): abre de 18 -> 44
        return int(round(18 + (BLADE_MAX_W - 18) * (row / float(TIP_END))))
    if row <= 70:
        return BLADE_MAX_W
    # leve afilada perto da guarda: 44 -> 38
    return int(round(BLADE_MAX_W - 6 * ((row - 70) / 10.0)))


def paint_blade() -> None:
    veins = (-9, 6, 13)  # colunas (offset de CX) com veio de madeira
    for row in range(BLADE_TOP, BLADE_BOT + 1):
        w = blade_width(row)
        left = CX - w // 2
        right = left + w
        half = max(1, w // 2)
        for x in range(left, right):
            t = abs(x - CX) / float(half)  # 0 centro, 1 borda
            if x == left or x == right - 1:
                col = BARK_DARK
            elif x == left + 1 or x == right - 2:
                col = WOOD_DARK
            elif t < 0.14:
                col = WOOD_HI
            elif t < 0.42:
                col = WOOD_LIGHT
            else:
                col = WOOD_MID
            # veios verticais (só sobre madeira, não na borda)
            if col in (WOOD_MID, WOOD_LIGHT) and (x - CX) in veins:
                col = VEIN
            grid[row][x] = col


def paint_knot(cx: int, cy: int, rx: int, ry: int) -> None:
    """Nó escuro natural: elipse com anel + miolo, sobrescrevendo a lâmina."""
    for y in range(cy - ry, cy + ry + 1):
        if y < BLADE_TOP or y > BLADE_BOT:
            continue
        for x in range(cx - rx, cx + rx + 1):
            if x < 0 or x >= W or grid[y][x] == TRANSP:
                continue
            dx = (x - cx) / float(rx)
            dy = (y - cy) / float(ry)
            d = dx * dx + dy * dy
            if d <= 1.0:
                grid[y][x] = KNOT_CORE if d <= 0.45 else KNOT_RING


def paint_guard() -> None:
    w = 30
    left = CX - w // 2
    right = left + w
    for row in range(GUARD_TOP, GUARD_BOT + 1):
        for x in range(left, right):
            if x == left or x == right - 1:
                col = BARK_DARK
            elif row == GUARD_TOP:
                col = BARK_HI  # topo iluminado
            elif row == GUARD_BOT:
                col = BARK_DARK
            else:
                col = BARK_MID
            grid[row][x] = col


def paint_grip() -> None:
    w = 10
    left = CX - w // 2
    right = left + w
    for row in range(GRIP_TOP, GRIP_BOT + 1):
        band = ((row - GRIP_TOP) // 2) % 2  # faixas de enrolamento
        for x in range(left, right):
            if x == left or x == right - 1:
                col = BARK_DARK
            else:
                col = BARK_MID if band == 0 else BARK_DARK
            grid[row][x] = col


def paint_pommel() -> None:
    # pomo arredondado: largura cresce e decresce
    widths = [10, 12, 14, 14, 12, 10, 8]
    for i, row in enumerate(range(POMMEL_TOP, POMMEL_BOT + 1)):
        w = widths[min(i, len(widths) - 1)]
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            grid[row][x] = BARK_DARK if (x == left or x == right - 1) else BARK_MID


paint_blade()
# Dois nós empilhados, levemente deslocados para leitura "natural".
paint_knot(CX - 4, 48, 4, 6)
paint_knot(CX + 5, 64, 3, 5)
paint_guard()
paint_grip()
paint_pommel()

out = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "weapon_forca3.png")
out = os.path.normpath(out)
with open(out, "wb") as f:
    f.write(encode_png(grid))
print(f"Gerado: {out}  ({W}x{H}px)")

"""Gera assets/sprites/weapon_forca3_fogo.png — Tronco Buster FLAMEJANTE 64x112.

Variante da espada `forca_3` ("Raiz-de-Ira") com o elemento fogo da CHAMA: a MESMA
silhueta/geometria do Tronco Buster (`gen_weapon_forca3.py`), porém a madeira está
carbonizada e as rachaduras/veios viram brasas INCANDESCENTES. A aura dourada + as
partículas de chama são feitas em runtime por WeaponVisual; aqui só o sprite estático,
no mesmo formato 64×112 para o WEAPON_OFFSET continuar válido.

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


# ─── Paleta madeira CARBONIZADA + brasa (r, g, b, a) ──────────────────────────
TRANSP     = (  0,   0,   0,   0)
CHAR_EDGE  = ( 14,   6,   3, 255)   # borda externa carbonizada (quase preta)
CHAR_DARK  = ( 34,  14,   6, 255)   # 2º px da borda / sombra interna
CHAR_MID   = ( 64,  26,  11, 255)   # corpo carbonizado da lâmina
EMBER_LOW  = (140,  52,  14, 255)   # luz lateral aquecida do chanfro
EMBER_MID  = (210,  92,  22, 255)   # highlight quente do flat central
EMBER_HOT  = (255, 150,  45, 255)   # miolo bem quente
CRACK_HOT  = (255, 196,  90, 255)   # rachadura incandescente (brasa viva)
CRACK_CORE = (255, 232, 150, 255)   # núcleo branco-quente da rachadura
BARK_DARK  = ( 20,  10,   5, 255)   # cabo escuro carbonizado
BARK_MID   = ( 40,  20,  10, 255)   # cabo / guarda médio (carvão)
BARK_HI    = ( 96,  46,  18, 255)   # topo iluminado/aquecido da guarda
KNOT_RING  = ( 70,  30,  10, 255)   # anel externo do nó
KNOT_CORE  = ( 16,   8,   3, 255)   # miolo escuro do nó


def blank() -> list[list[tuple]]:
    return [[TRANSP] * W for _ in range(H)]


grid = blank()


# ─── Larguras por região (idênticas ao Tronco Buster) ─────────────────────────
BLADE_TOP, BLADE_BOT = 0, 80
GUARD_TOP, GUARD_BOT = 81, 86
GRIP_TOP,  GRIP_BOT  = 87, 104
POMMEL_TOP, POMMEL_BOT = 105, 111

BLADE_MAX_W = 44
TIP_END     = 9


def blade_width(row: int) -> int:
    if row < TIP_END:
        return int(round(18 + (BLADE_MAX_W - 18) * (row / float(TIP_END))))
    if row <= 70:
        return BLADE_MAX_W
    return int(round(BLADE_MAX_W - 6 * ((row - 70) / 10.0)))


def paint_blade() -> None:
    cracks = (-9, 6, 13)  # colunas (offset de CX) onde a brasa atravessa a lâmina
    for row in range(BLADE_TOP, BLADE_BOT + 1):
        w = blade_width(row)
        left = CX - w // 2
        right = left + w
        half = max(1, w // 2)
        for x in range(left, right):
            t = abs(x - CX) / float(half)  # 0 centro, 1 borda
            if x == left or x == right - 1:
                col = CHAR_EDGE
            elif x == left + 1 or x == right - 2:
                col = CHAR_DARK
            elif t < 0.14:
                col = EMBER_HOT
            elif t < 0.30:
                col = EMBER_MID
            elif t < 0.55:
                col = EMBER_LOW
            else:
                col = CHAR_MID
            # rachaduras incandescentes (só sobre madeira, não na borda).
            # O núcleo só "acende" forte em linhas alternadas → aspecto de brasa viva.
            if col in (CHAR_MID, EMBER_LOW, EMBER_MID) and (x - CX) in cracks:
                col = CRACK_CORE if (row % 3 == 0) else CRACK_HOT
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
                col = CHAR_EDGE
            elif row == GUARD_TOP:
                col = BARK_HI  # topo iluminado/aquecido
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
    widths = [10, 12, 14, 14, 12, 10, 8]
    for i, row in enumerate(range(POMMEL_TOP, POMMEL_BOT + 1)):
        w = widths[min(i, len(widths) - 1)]
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            grid[row][x] = BARK_DARK if (x == left or x == right - 1) else BARK_MID


paint_blade()
paint_knot(CX - 4, 48, 4, 6)
paint_knot(CX + 5, 64, 3, 5)
paint_guard()
paint_grip()
paint_pommel()

out = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "weapon_forca3_fogo.png")
out = os.path.normpath(out)
with open(out, "wb") as f:
    f.write(encode_png(grid))
print(f"Gerado: {out}  ({W}x{H}px)")

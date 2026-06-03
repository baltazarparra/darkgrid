#!/usr/bin/env python3
"""Gera os SFX de combate de caipora com DNA percussivo do maracatu (baque virado).

Fallback para jsfxr (indisponível via CLI). Usa apenas a stdlib (wave/math/struct)
para modelar instrumentos do maracatu nação e texturas amazônicas, e compor a partir
deles os 7 SFX de combate. Cada som é gerado em 3 variantes (primário + _2 + _3) com
seeds distintas — o SfxSystem faz round-robin entre elas para nunca soar idêntico.

Paleta tímbrica:
  alfaia  — bumbo grave de pele (impacto carnudo)
  caixa   — tarol/caixa com esteira (estalo seco, brilhante)
  ganza   — chocalho metálico (chiado filtrado, sopro)
  agogo   — sino de dois bocais (parciais inarmônicos, "ding" da recompensa)
  gongue  — sino de ferro grave (chamada metálica)
  assovio — leitmotif da Caipora (seno com vibrato + sopro)

Saída: WAV mono 22050Hz 16-bit em assets/audio/sfx/.
Uso: python3 scripts/tools/gen_sfx.py
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 22050
AUDIO_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")

# Seeds das variantes. A 1ª mantém os nomes originais (attack.wav...); as demais
# viram attack_2.wav / attack_3.wav e alimentam o round-robin do SfxSystem.
VARIANT_SEEDS = [42, 1337, 2024]


# ─── IO ────────────────────────────────────────────
def _write(name, samples, subdir="sfx"):
    out_dir = os.path.join(AUDIO_DIR, subdir)
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            v = int(max(-1.0, min(1.0, s)) * 32767)
            frames += struct.pack("<h", v)
        w.writeframes(frames)
    print(f"  {name}: {len(samples)} samples ({len(samples) * 2} bytes)")


# ─── Helpers de síntese ────────────────────────────
def _noise():
    return random.uniform(-1.0, 1.0)


def _jit(amount):
    """Aleatoriedade simétrica (±amount) por variante."""
    return 1.0 + random.uniform(-amount, amount)


def _env(i, n, attack=0.01, release=0.3):
    """Envelope ataque/decay linear simples (0..1) em fração de duração."""
    t = i / n
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = 1.0 - max(0.0, (t - (1.0 - release)) / release) if release > 0 else 1.0
    return max(0.0, a * r)


def _mix(*layers):
    """Soma camadas de tamanhos diferentes (zero-pad nas curtas)."""
    n = max(len(layer) for layer in layers)
    out = [0.0] * n
    for layer in layers:
        for i, s in enumerate(layer):
            out[i] += s
    return out


def _normalize(samples, peak=0.92):
    """Normaliza para um pico-alvo, evitando clipping ao empilhar camadas."""
    hi = max((abs(s) for s in samples), default=0.0)
    if hi <= 1e-6:
        return samples
    g = peak / hi
    return [s * g for s in samples]


# ─── Instrumentos do maracatu ──────────────────────
def alfaia(dur=0.18, base=64.0, punch=1.0):
    """Bumbo grave de pele: transiente de baqueta + fundamental com pitch-down +
    corpo ressonante (sub-oitava). É o impacto 'carnudo'."""
    n = int(SAMPLE_RATE * dur)
    base *= _jit(0.05)
    body = []
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # fundamental que afunda (~18%): a pancada assenta.
        f = base * (1.0 - 0.18 * (i / n))
        fund = math.sin(2 * math.pi * f * t)
        sub = 0.5 * math.sin(2 * math.pi * f * 0.5 * t)  # sub reforça o grave
        # transiente de baqueta: ruído lowpass forte só no ataque.
        lp = lp * 0.6 + _noise() * 0.4
        thwack = lp * math.exp(-38.0 * t) * 0.6 * punch
        e = _env(i, n, 0.003, 0.8)
        body.append((0.7 * fund + sub) * e + thwack)
    return body


def caixa(dur=0.1, bright=1.0):
    """Caixa/tarol: ruído de esteira (highpass por subtração de lowpass) + estalo
    de pele mid. Seco e brilhante."""
    n = int(SAMPLE_RATE * dur)
    out = []
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        raw = _noise()
        lp = lp * 0.5 + raw * 0.5
        hp = raw - lp  # componente alta = chiado da esteira
        crack = math.sin(2 * math.pi * 330.0 * t) * math.exp(-40.0 * t)
        e = math.exp(-30.0 * t)
        out.append((0.7 * hp * bright + 0.3 * crack) * e * 0.8)
    return out


def ganza(dur=0.18, rising=True):
    """Chocalho: ruído filtrado com swell de amplitude/brilho. 'rising' faz o
    chiado abrir (tensão antes do golpe); senão é um sopro curto e limpo."""
    n = int(SAMPLE_RATE * dur)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / n
        cut = (0.25 + 0.6 * t) if rising else (0.55 - 0.2 * t)
        prev = prev * (1.0 - cut) + _noise() * cut
        if rising:
            amp = t  # abre
        else:
            amp = max(0.0, 1.0 - t ** 0.5)  # fecha
        out.append(prev * amp * 0.6)
    return out


def _inharmonic(dur, freq, partials, decay, fm=0.0):
    """Sino genérico: soma de parciais inarmônicos com decaimento exponencial e
    leve FM para cintilar. 'partials' = lista de (mult_freq, amp)."""
    n = int(SAMPLE_RATE * dur)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        mod = 1.0 + fm * math.sin(2 * math.pi * 5.0 * t)
        s = 0.0
        for mult, amp in partials:
            s += amp * math.sin(2 * math.pi * freq * mult * mod * t)
        e = math.exp(-decay * t)
        # ataque muito curto p/ não estalar
        a = min(1.0, t / 0.004) if t < 0.004 else 1.0
        out.append(s * e * a)
    return out


def agogo(dur=0.2, freq=1320.0, bend=0.05):
    """Sino agudo de dois bocais: parciais inarmônicos brilhantes + leve bend
    ascendente. O 'ding' cultural da recompensa."""
    freq *= _jit(0.02) * (1.0 + bend)
    return _inharmonic(
        dur, freq,
        [(1.0, 0.5), (2.76, 0.28), (5.40, 0.15), (8.93, 0.07)],
        decay=14.0, fm=0.004,
    )


def gongue(dur=0.16, freq=620.0):
    """Sino de ferro grave: parciais mais baixos e secos. Chamada metálica."""
    freq *= _jit(0.02)
    return _inharmonic(
        dur, freq,
        [(1.0, 0.5), (2.4, 0.25), (3.9, 0.12)],
        decay=22.0, fm=0.0,
    )


def assovio(dur=0.5, freq=900.0):
    """Leitmotif da Caipora: seno com vibrato + fiapo de sopro. Suave nas pontas."""
    n = int(SAMPLE_RATE * dur)
    freq *= _jit(0.02)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        vib = 1.0 + 0.012 * math.sin(2 * math.pi * 6.0 * t)
        tone = math.sin(2 * math.pi * freq * vib * t)
        breath = _noise() * 0.05
        e = _env(i, n, 0.15, 0.4)
        out.append((tone + breath) * e * 0.5)
    return out


# ─── Composição dos 7 SFX ──────────────────────────
def attack_wav():
    # Tensão antes do golpe: rufo curto de caixa + chiado de ganzá abrindo.
    layer_caixa = caixa(0.12, bright=0.8)
    layer_ganza = ganza(0.18, rising=True)
    return _normalize(_mix(layer_caixa, layer_ganza), 0.7)


def hit_wav():
    # Impacto carnudo: alfaia grave + estalo de caixa por cima.
    return _normalize(_mix(alfaia(0.18, base=64.0, punch=1.0), caixa(0.09, bright=1.0)), 0.95)


def dodge_wav():
    # Alívio aéreo: chocalho rápido, limpo e curto.
    return _normalize(ganza(0.18, rising=False), 0.55)


def timing_perfect_wav():
    # Recompensa: ding de agogô brilhante com bend ascendente.
    return _normalize(agogo(0.22, freq=1320.0, bend=0.05), 0.7)


def timing_alert_wav():
    # Vulnerabilidade: gonguê em duas batidas ("agora!"), seco e metálico.
    first = gongue(0.08, freq=560.0)
    gap = [0.0] * int(SAMPLE_RATE * 0.02)
    second = gongue(0.10, freq=760.0)  # 2ª mais aguda = sobe
    return _normalize(first + gap + second, 0.7)


def death_wav():
    # Terror: alfaia sub-grave + growl descendente (saw com pitch caindo) +
    # cauda de ruído modulado. Sem suavizar o gore.
    n = int(SAMPLE_RATE * 0.45)
    growl = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 190.0 * (1.0 - 0.72 * (i / n))
        phase = (t * freq) % 1.0
        saw = 2.0 * phase - 1.0
        tremolo = 0.7 + 0.3 * math.sin(2 * math.pi * 28.0 * t)
        e = _env(i, n, 0.02, 0.5)
        growl.append((0.6 * saw + 0.3 * _noise() * tremolo) * e * 0.6)
    return _normalize(_mix(alfaia(0.45, base=52.0, punch=0.7), growl), 0.9)


def ui_click_wav():
    # Micro-feedback: rim de caixa muito curto e seco.
    return _normalize(caixa(0.045, bright=1.1), 0.5)


GENERATORS = {
    "attack": attack_wav,
    "hit": hit_wav,
    "dodge": dodge_wav,
    "timing_perfect": timing_perfect_wav,
    "timing_alert": timing_alert_wav,
    "death": death_wav,
    "ui_click": ui_click_wav,
}


# ─── Ambiência (loops costurados) ──────────────────
def _loopify(render, n, fade):
    """Costura um loop sem emenda com crossfade de coseno (zero artefatos de emenda)."""
    out = list(render[:n])
    for i in range(fade):
        w = 0.5 - 0.5 * math.cos(math.pi * i / fade)  # cosine fade-in
        out[i] = render[i] * w + render[n + i] * (1.0 - w)
    return out


def amb_forest(dur=10.0):
    """Floresta amazônica: hum grave + insetos filtrados (mais leve) + rio +
    assovio-leitmotif âncora em dois pontos do loop. Bed da exploração."""
    fade = int(SAMPLE_RATE * 0.6)
    n = int(SAMPLE_RATE * dur)
    total = n + fade
    out = [0.0] * total
    hp = 0.0
    lp = 0.0
    # assovio entra em 20% e 70% do loop para âncora melódica definida.
    whistle_a = int(n * 0.20)
    whistle_b = int(n * 0.70)
    whistle = assovio(1.4, freq=820.0)
    for i in range(total):
        t = i / SAMPLE_RATE
        hum = 0.10 * math.sin(2 * math.pi * 70.0 * t) + 0.06 * math.sin(2 * math.pi * 112.0 * t)
        hum *= 0.8 + 0.2 * math.sin(2 * math.pi * 0.12 * t)
        raw = _noise()
        lp = lp * 0.5 + raw * 0.5
        hp = raw - lp
        # insetos: amplitude reduzida (×0.6) para textura menos saturada
        insects = hp * (0.03 + 0.03 * abs(math.sin(2 * math.pi * 7.0 * t))) * (0.6 + 0.4 * math.sin(2 * math.pi * 0.4 * t))
        river = lp * 0.06 * (0.5 + 0.5 * math.sin(2 * math.pi * 0.2 * t + 1.0))
        s = hum + insects + river
        pos = i % n  # posição no loop (ignora overhang para colocar assobios)
        if whistle_a <= pos < whistle_a + len(whistle):
            s += whistle[pos - whistle_a] * 0.12
        if whistle_b <= pos < whistle_b + len(whistle):
            s += whistle[pos - whistle_b] * 0.12
        out[i] = s
    return _normalize(_loopify(out, n, fade), 0.5)


def amb_dread(dur=8.0):
    """Arena: drone grave com batimento hipnótico + saw escuro + pulso sub de
    respiração. Cintilação reduzida para continuidade. Opressivo."""
    fade = int(SAMPLE_RATE * 0.6)
    n = int(SAMPLE_RATE * dur)
    total = n + fade
    out = [0.0] * total
    lp = 0.0
    for i in range(total):
        t = i / SAMPLE_RATE
        # batimento 2.5 Hz (55.0 + 57.5): mais lento = mais hipnótico
        drone = 0.16 * math.sin(2 * math.pi * 55.0 * t) + 0.14 * math.sin(2 * math.pi * 57.5 * t)
        # pulso sub grave: respiração lenta do ambiente
        sub_pulse = 0.05 * math.sin(2 * math.pi * 0.08 * t)
        # saw escuro filtrado
        phase = (t * 41.0) % 1.0
        saw = (2.0 * phase - 1.0)
        lp = lp * 0.92 + saw * 0.08
        dark = lp * 0.12
        # shimmer reduzido (×0.4) para não quebrar continuidade
        shimmer = _noise() * 0.008 * max(0.0, math.sin(2 * math.pi * 0.07 * t))
        out[i] = drone + sub_pulse + dark + shimmer
    return _normalize(_loopify(out, n, fade), 0.6)


AMBIENCES = {
    "amb_forest": amb_forest,
    "amb_dread": amb_dread,
}


# ─── Maracatu adaptativo (stems sincronizados) ─────
# Baque virado: 2 compassos em 4/4 a 100 BPM = 8 tempos = 4.8s = 32 semicolcheias.
# Stems compartilham o mesmo loop_dur para tocarem em fase no AudioDirector.
BPM = 100
BEAT = 60.0 / BPM
LOOP_BARS = 4
LOOP_DUR = BEAT * 4 * LOOP_BARS  # 9.6s
STEP = BEAT / 4  # semicolcheia


def _loop_buffer():
    return [0.0] * int(SAMPLE_RATE * LOOP_DUR)


def _place(buf, sample, step, gain=1.0):
    """Soma um som no grid de semicolcheias, com wrap (cauda volta ao início =
    loop sem emenda)."""
    n = len(buf)
    at = int(step * STEP * SAMPLE_RATE)
    for i, s in enumerate(sample):
        buf[(at + i) % n] += s * gain


def mar_alfaia():
    """Marcação grave com arco dramático: compassos 1-2 = padrão base,
    3-4 = virada mais densa com ghost notes crescentes."""
    buf = _loop_buffer()
    bar1 = [(0, 1.0), (6, 0.7), (10, 0.8), (12, 0.6)]
    bar2 = [(0, 1.0), (6, 0.7), (10, 0.8), (12, 0.6), (14, 0.55), (15, 0.7)]
    bar3 = [(0, 1.0), (4, 0.4), (6, 0.7), (10, 0.8), (12, 0.6), (13, 0.4)]
    bar4 = [(0, 1.0), (4, 0.4), (6, 0.7), (8, 0.45), (10, 0.8), (12, 0.6), (14, 0.55), (15, 0.75)]
    for bar_offset, pattern in zip([0, 16, 32, 48], [bar1, bar2, bar3, bar4]):
        for step, vel in pattern:
            _place(buf, alfaia(0.2, base=58.0, punch=vel), step + bar_offset, vel)
    return _normalize(buf, 0.85)


def mar_ganza():
    """Chiado em semicolcheias com acento alternado por compasso (push-pull)."""
    buf = _loop_buffer()
    # Padrão A: acento nos tempos (1,3). Padrão B: acento nos contratempos (2,4).
    for step in range(64):
        bar = step // 16
        beat_in_bar = (step % 16) // 4
        if bar % 2 == 0:
            accent = 0.85 if beat_in_bar % 2 == 0 else 0.45
        else:
            accent = 0.85 if beat_in_bar % 2 == 1 else 0.45
        _place(buf, ganza(0.07, rising=False), step, accent)
    return _normalize(buf, 0.6)


def mar_agogo():
    """Ostinato melódico: padrão base 2 compassos + 3º compasso com pitch médio."""
    buf = _loop_buffer()
    lo, hi, mid = 880.0, 1320.0, 1100.0
    pattern_base = [(0, hi), (2, lo), (4, hi), (6, hi), (8, lo), (10, hi), (12, lo), (14, hi)]
    pattern_mid  = [(0, hi), (2, mid), (4, hi), (6, lo), (8, mid), (10, hi), (12, lo), (14, mid)]
    for bar in range(LOOP_BARS):
        pattern = pattern_mid if bar == 2 else pattern_base
        for step, pitch in pattern:
            _place(buf, agogo(0.16, freq=pitch, bend=0.0), step + bar * 16, 0.5)
    return _normalize(buf, 0.7)


STEMS = {
    "mar_alfaia": mar_alfaia,
    "mar_ganza": mar_ganza,
    "mar_agogo": mar_agogo,
}


# ─── Stingers de estado (one-shot) ─────────────────
def _seq(*events):
    """Monta um one-shot a partir de (som, atraso_s, ganho)."""
    rendered = [(s, int(d * SAMPLE_RATE), g) for s, d, g in events]
    n = max(off + len(s) for s, off, g in rendered)
    out = [0.0] * n
    for s, off, g in rendered:
        for i, v in enumerate(s):
            out[off + i] += v * g
    return out


def sting_arena_enter():
    # Chamada à batalha: gonguê grave + tríade rápida de agogô + alfaia.
    return _normalize(_seq(
        (gongue(0.16, 520.0), 0.0, 0.8),
        (agogo(0.16, 990.0), 0.10, 0.6),
        (agogo(0.16, 1320.0), 0.18, 0.6),
        (alfaia(0.24, 58.0), 0.26, 1.0),
    ), 0.85)


def sting_victory():
    # Resolução luminosa: agogô ascendente + assovio-leitmotif sobindo.
    return _normalize(_seq(
        (agogo(0.18, 990.0), 0.0, 0.6),
        (agogo(0.18, 1320.0), 0.12, 0.6),
        (agogo(0.30, 1760.0), 0.24, 0.7),
        (assovio(0.7, 1320.0), 0.30, 0.4),
    ), 0.8)


def sting_game_over():
    # Queda: alfaia sub + gonguê descendente + cauda escura.
    return _normalize(_seq(
        (alfaia(0.35, 50.0), 0.0, 1.0),
        (gongue(0.5, 300.0), 0.05, 0.7),
        (gongue(0.6, 180.0), 0.30, 0.6),
    ), 0.85)


def sting_chest():
    # Brilho de recompensa: cintilação de agogô.
    return _normalize(_seq(
        (agogo(0.16, 1320.0), 0.0, 0.6),
        (agogo(0.16, 1760.0), 0.07, 0.6),
        (agogo(0.24, 2093.0), 0.14, 0.5),
    ), 0.7)


STINGERS = {
    "sting_arena_enter": sting_arena_enter,
    "sting_victory": sting_victory,
    "sting_game_over": sting_game_over,
    "sting_chest": sting_chest,
}


def main():
    print("Gerando SFX de combate (maracatu / Amazônia)...")
    for variant, seed in enumerate(VARIANT_SEEDS):
        random.seed(seed)
        suffix = "" if variant == 0 else f"_{variant + 1}"
        for name, gen in GENERATORS.items():
            _write(f"{name}{suffix}.wav", gen())

    print("Gerando ambiências (loops)...")
    for name, gen in AMBIENCES.items():
        random.seed(7)
        _write(f"{name}.wav", gen(), subdir="ambience")

    print("Gerando stems de maracatu (loops sincronizados)...")
    for name, gen in STEMS.items():
        random.seed(11)
        _write(f"{name}.wav", gen(), subdir="music")

    print("Gerando stingers de estado...")
    for name, gen in STINGERS.items():
        random.seed(13)
        _write(f"{name}.wav", gen(), subdir="stingers")
    print("Pronto.")


if __name__ == "__main__":
    main()

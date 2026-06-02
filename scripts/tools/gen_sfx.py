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
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "sfx")

# Seeds das variantes. A 1ª mantém os nomes originais (attack.wav...); as demais
# viram attack_2.wav / attack_3.wav e alimentam o round-robin do SfxSystem.
VARIANT_SEEDS = [42, 1337, 2024]


# ─── IO ────────────────────────────────────────────
def _write(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
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


def main():
    print("Gerando SFX de combate (maracatu / Amazônia)...")
    for variant, seed in enumerate(VARIANT_SEEDS):
        random.seed(seed)
        suffix = "" if variant == 0 else f"_{variant + 1}"
        for name, gen in GENERATORS.items():
            _write(f"{name}{suffix}.wav", gen())
    print("Pronto.")


if __name__ == "__main__":
    main()

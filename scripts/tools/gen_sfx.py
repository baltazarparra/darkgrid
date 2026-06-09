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
# As faixas de música (loops longos) saem em SR reduzido — o grão lo-fi é parte da
# estética 8-bit e corta o peso a ~metade (browser-first, .wav versionados).
MUSIC_RATE = 11025
AUDIO_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")

# Seeds das variantes. A 1ª mantém os nomes originais (attack.wav...); as demais
# viram attack_2.wav / attack_3.wav e alimentam o round-robin do SfxSystem.
VARIANT_SEEDS = [42, 1337, 2024]


# ─── IO ────────────────────────────────────────────
def _write(name, samples, subdir="sfx", rate=SAMPLE_RATE):
    out_dir = os.path.join(AUDIO_DIR, subdir)
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, name)
    if rate != SAMPLE_RATE:
        samples = _resample(samples, SAMPLE_RATE, rate)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
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


def bitcrush(samples, bits=8, rate_div=1):
    """Grão 8-bit: quantiza a amplitude em 2^bits degraus e (opcional) segura cada
    'rate_div' amostras (sample-and-hold = redução de taxa). Cola o híbrido orgânico
    + chiptune num timbre só."""
    levels = float(1 << (bits - 1))
    out = []
    held = 0.0
    for i, s in enumerate(samples):
        if rate_div <= 1 or i % rate_div == 0:
            held = round(max(-1.0, min(1.0, s)) * levels) / levels
        out.append(held)
    return out


def _resample(samples, src_rate, dst_rate):
    """Reamostragem linear (decimação) src->dst. Usado para gravar música a MUSIC_RATE
    sem mexer na matemática de síntese (que roda toda em SAMPLE_RATE)."""
    if dst_rate == src_rate or not samples:
        return samples
    ratio = dst_rate / float(src_rate)
    n_out = max(1, int(len(samples) * ratio))
    out = [0.0] * n_out
    step = src_rate / float(dst_rate)
    for i in range(n_out):
        pos = i * step
        j = int(pos)
        frac = pos - j
        a = samples[j]
        b = samples[j + 1] if j + 1 < len(samples) else samples[j]
        out[i] = a + (b - a) * frac
    return out


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


# ─── Vozes chiptune (canais estilo NES) ────────────
# Lead/harmonia em pulso, baixo em triângulo, percussão metálica no canal de ruído.
# São a metade "8-bit" do híbrido; o maracatu orgânico acima é a metade "terra".
def pulse(dur, freq, duty=0.5, vib=0.0, attack=0.005, release=0.25):
    """Onda de pulso (square com duty variável). duty 0.5=oco, 0.25/0.125=nasal/fino."""
    n = int(SAMPLE_RATE * dur)
    freq *= _jit(0.004)  # micro-detune por variante, sem soar desafinado
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = freq * (1.0 + vib * math.sin(2 * math.pi * 5.5 * t))
        phase += f / SAMPLE_RATE
        ph = phase % 1.0
        s = 1.0 if ph < duty else -1.0
        out.append(s * _env(i, n, attack, release) * 0.5)
    return out


def triangle(dur, freq, attack=0.004, release=0.2):
    """Onda triângulo: baixo/sub redondo do NES, sem o brilho áspero do pulso."""
    n = int(SAMPLE_RATE * dur)
    freq *= _jit(0.004)
    out = []
    phase = 0.0
    for i in range(n):
        phase += freq / SAMPLE_RATE
        ph = phase % 1.0
        tri = 4.0 * abs(ph - 0.5) - 1.0  # -1..1
        out.append(tri * _env(i, n, attack, release) * 0.6)
    return out


def nes_noise(dur, decay=40.0, lp=0.0, gain=0.5):
    """Canal de ruído (LFSR de 15 bits, como o NES). 'lp' (0..1) escurece o chiado;
    'decay' molda hat curto vs. crash. Percussão metálica 8-bit."""
    n = int(SAMPLE_RATE * dur)
    reg = 0x7FFF
    out = []
    prev = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        bit = (reg ^ (reg >> 1)) & 1
        reg = (reg >> 1) | (bit << 14)
        raw = 1.0 if (reg & 1) else -1.0
        prev = prev * lp + raw * (1.0 - lp)
        out.append(prev * math.exp(-decay * t) * gain)
    return out


# ─── Teoria mínima p/ coesão melódica ──────────────
# Tônica por contexto (Hz) + graus de escala (semitons) → notas chiptune coerentes.
# Menor harmônica dá a cor "folk sombrio"; o ♭2 (frígio) entra nas fases mais densas.
SEMI = 2.0 ** (1.0 / 12.0)
MINOR_HARM = [0, 2, 3, 5, 7, 8, 11, 12]      # menor harmônica
PHRYGIAN = [0, 1, 3, 5, 7, 8, 10, 12]        # frígio (♭2 = tensão/névoa)


def note(root_hz, semitones):
    """Frequência de uma nota a 'semitones' da tônica."""
    return root_hz * (SEMI ** semitones)


def scale_note(root_hz, degree, scale=MINOR_HARM):
    """Nota pelo grau na escala (com oitavas para graus fora de 0..len-1)."""
    octs, idx = divmod(degree, len(scale) - 1)
    return note(root_hz, scale[idx] + 12 * octs)


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
    # Alívio aéreo: chocalho rápido + sopro de pulso descendente (whoosh 8-bit), crush leve.
    swoosh = pulse(0.12, 660.0, duty=0.5, vib=0.0, release=0.7)
    return _normalize(bitcrush(_mix(ganza(0.18, rising=False), [s * 0.3 for s in swoosh]), bits=7), 0.55)


def timing_perfect_wav():
    # Recompensa híbrida: ding de agogô + arpejo ascendente de pulso (o "8-bit ding").
    bell = agogo(0.22, freq=1320.0, bend=0.05)
    arp = _seq(
        (pulse(0.05, 880.0, duty=0.25, release=0.5), 0.0, 0.5),
        (pulse(0.05, 1108.0, duty=0.25, release=0.5), 0.04, 0.5),
        (pulse(0.10, 1760.0, duty=0.25, release=0.6), 0.08, 0.55),
    )
    return _normalize(bitcrush(_mix(bell, arp), bits=7), 0.7)


def timing_alert_wav():
    # Vulnerabilidade: gonguê em duas batidas ("agora!") + blip de pulso p/ legibilidade.
    first = gongue(0.08, freq=560.0)
    gap = [0.0] * int(SAMPLE_RATE * 0.02)
    second = gongue(0.10, freq=760.0)  # 2ª mais aguda = sobe
    metal = first + gap + second
    blip = pulse(0.06, 988.0, duty=0.125, release=0.5)
    return _normalize(bitcrush(_mix(metal, blip), bits=7), 0.7)


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
    # Micro-feedback: rim de caixa seco + blip de pulso curtíssimo (toque 8-bit de menu).
    blip = pulse(0.03, 1320.0, duty=0.125, attack=0.001, release=0.4)
    return _normalize(bitcrush(_mix(caixa(0.045, bright=1.1), [s * 0.4 for s in blip]), bits=6), 0.5)


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


def amb_fire(dur=9.0):
    """Fase 2 (floresta em chamas): crepitar de fogo (estalos de ruído aleatórios) +
    rugido grave filtrado + brasas agudas esparsas. Quente e inquieto."""
    fade = int(SAMPLE_RATE * 0.6)
    n = int(SAMPLE_RATE * dur)
    total = n + fade
    out = [0.0] * total
    lp = 0.0
    for i in range(total):
        t = i / SAMPLE_RATE
        raw = _noise()
        lp = lp * 0.85 + raw * 0.15
        roar = lp * 0.12 * (0.7 + 0.3 * math.sin(2 * math.pi * 0.15 * t))
        # estalos: bursts curtos e aleatórios (crepitar da lenha)
        crackle = 0.0
        if random.random() < 0.06:
            crackle = _noise() * 0.5 * math.exp(-random.uniform(20.0, 60.0) * 0.0)
        ember = (raw - lp) * 0.04 * abs(math.sin(2 * math.pi * 3.0 * t))
        out[i] = roar + crackle + ember
    return _normalize(_loopify(out, n, fade), 0.55)


def amb_fog(dur=9.0):
    """Fase 3 (névoa): drone abafado e detuneado, sopro de vento grave e sussurros
    filtrados. Opressivo e desorientador (lowpass pesado)."""
    fade = int(SAMPLE_RATE * 0.6)
    n = int(SAMPLE_RATE * dur)
    total = n + fade
    out = [0.0] * total
    lp = 0.0
    lp2 = 0.0
    for i in range(total):
        t = i / SAMPLE_RATE
        # drone detuneado (batimento lento, dissonância de névoa)
        drone = 0.12 * math.sin(2 * math.pi * 98.0 * t) + 0.10 * math.sin(2 * math.pi * 100.7 * t)
        drone += 0.06 * math.sin(2 * math.pi * 146.5 * t)  # 5ª turva
        wind = _noise()
        lp = lp * 0.97 + wind * 0.03  # vento muito abafado
        breath = lp * 0.18 * (0.5 + 0.5 * math.sin(2 * math.pi * 0.09 * t))
        # sussurros: ruído de banda média pulsando devagar
        lp2 = lp2 * 0.8 + wind * 0.2
        whisper = (lp2 - lp) * 0.05 * max(0.0, math.sin(2 * math.pi * 0.13 * t))
        out[i] = drone * (0.8 + 0.2 * math.sin(2 * math.pi * 0.05 * t)) + breath + whisper
    return _normalize(_loopify(out, n, fade), 0.55)


AMBIENCES = {
    "amb_forest": amb_forest,
    "amb_dread": amb_dread,
    "amb_fire": amb_fire,
    "amb_fog": amb_fog,
}


# ─── Música por contexto (loops híbridos: maracatu + chiptune) ─────
# Cada faixa é um loop ÚNICO (não mais 3 stems): percussão orgânica do baque virado
# somada a canais chiptune (lead em pulso, baixo em triângulo, ruído NES). Renderizada
# em SAMPLE_RATE e gravada a MUSIC_RATE (grão lo-fi 8-bit + arquivo leve).
# Grid de semicolcheias em 4/4; o loop é periódico (caudas dão wrap = sem emenda).

# Tônicas graves por contexto (Hz) — registro de baixo; o lead sobe uma 8ª (grau +7).
A2, AS2, G2, F2, E2, ES2, D2, C2, DS2 = 110.0, 116.54, 98.0, 87.31, 82.41, 77.78, 73.42, 65.41, 146.83


def _new_buf(bpm, bars):
    step = (60.0 / bpm) / 4.0
    n = int(round(SAMPLE_RATE * step * 16 * bars))
    return [0.0] * n, step


def _put(buf, sample, step_idx, step_dur, gain=1.0):
    """Soma um som no grid de semicolcheias, com wrap (loop sem emenda)."""
    n = len(buf)
    at = int(step_idx * step_dur * SAMPLE_RATE)
    for i, s in enumerate(sample):
        buf[(at + i) % n] += s * gain


def _drums(buf, step_dur, voice, events):
    """events: lista de (step, gain). voice() é zero-arg (ex.: lambda: alfaia(...))."""
    for st, g in events:
        _put(buf, voice(), st, step_dur, g)


def _melody(buf, step_dur, root, scale, voice, notes):
    """notes: lista de (step, degree, len_steps, gain). voice(dur, freq)->samples."""
    for st, deg, ln, g in notes:
        f = scale_note(root, deg, scale)
        _put(buf, voice(ln * step_dur * 0.92, f), st, step_dur, g)


def _shaker_run(bars, sub=1):
    """Ganzá em semicolcheias com acento no tempo. sub>1 rareia (1 a cada sub)."""
    ev = []
    for st in range(16 * bars):
        if st % sub != 0:
            continue
        ev.append((st, 0.7 if st % 4 == 0 else 0.36))
    return ev


def _baque_alfaia(bars):
    """Marcação do baque virado: compasso par = base, ímpar = virada densa."""
    base = [(0, 1.0), (6, 0.7), (10, 0.8), (12, 0.6)]
    turn = [(0, 1.0), (4, 0.4), (6, 0.7), (8, 0.45), (10, 0.8), (12, 0.6), (14, 0.55), (15, 0.75)]
    ev = []
    for b in range(bars):
        pat = turn if b % 2 == 1 else base
        ev += [(st + b * 16, g) for st, g in pat]
    return ev


# Vozes melódicas reutilizáveis (lead em pulso, baixo em triângulo).
def _lead(duty=0.25, vib=0.0):
    return lambda d, f: pulse(d, f, duty=duty, vib=vib, release=0.3)


def _bass():
    return lambda d, f: triangle(d, f, release=0.15)


def _arena_track(bpm, root, scale, density):
    """Baque virado de combate: alfaia + caixa + ganzá + lead-ostinato chiptune + baixo.
    'density' (1..3) adiciona hats de ruído NES e ghost notes — intensidade por fase."""
    buf, step = _new_buf(bpm, 4)
    _drums(buf, step, lambda: alfaia(0.18, base=root * 0.5, punch=0.9), _baque_alfaia(4))
    _drums(buf, step, lambda: caixa(0.08, bright=1.0),
           [(st, 0.55) for b in range(4) for st in (b * 16 + 4, b * 16 + 12)])
    _drums(buf, step, lambda: ganza(0.06, rising=False), _shaker_run(4))
    if density >= 2:
        _drums(buf, step, lambda: nes_noise(0.05, decay=55.0, lp=0.4, gain=0.35),
               [(st, 0.4) for st in range(64) if st % 2 == 1])
    # baixo: tônica/quinta pulsando nos tempos
    bass_notes = []
    for b in range(4):
        deg = 0 if b % 2 == 0 else 4
        bass_notes += [(b * 16, deg, 4, 0.8), (b * 16 + 8, deg, 4, 0.7)]
    _melody(buf, step, root, scale, _bass(), bass_notes)
    # lead ostinato (8ª acima): motivo de agogô traduzido para pulso
    lo, hi, md, top = 7, 11, 9, 14
    base_pat = [(0, hi, 2), (2, lo, 2), (4, hi, 2), (6, top, 2), (8, lo, 2), (10, hi, 2), (12, md, 2), (14, top, 2)]
    var_pat = [(0, hi, 2), (2, md, 2), (4, top, 2), (6, lo, 2), (8, md, 2), (10, hi, 2), (12, lo, 2), (14, md, 2)]
    lead_notes = []
    for b in range(4):
        pat = var_pat if b == 2 else base_pat
        lead_notes += [(st + b * 16, deg, ln, 0.4) for st, deg, ln in pat]
    _melody(buf, step, root, scale, _lead(duty=0.25), lead_notes)
    return _normalize(bitcrush(buf, bits=7), 0.85)


# ─── Faixas: telas ─────────────────────────────────
def mus_menu():
    """Menu: lento e sombrio. Leitmotif da Caipora em pulso; alfaia esparsa como
    coração lento; baixo em triângulo descendo a tríade menor."""
    buf, step = _new_buf(76, 2)
    _drums(buf, step, lambda: alfaia(0.24, base=A2 * 0.5, punch=0.7),
           [(0, 0.7), (16, 0.7), (24, 0.4)])
    _drums(buf, step, lambda: ganza(0.05, rising=False), _shaker_run(2, sub=4))
    _melody(buf, step, A2, MINOR_HARM, _bass(),
            [(0, 0, 8, 0.8), (8, 2, 8, 0.7), (16, 3, 8, 0.8), (24, 0, 8, 0.7)])
    _melody(buf, step, A2, MINOR_HARM, _lead(duty=0.5, vib=0.01),
            [(2, 9, 3, 0.42), (6, 7, 2, 0.36), (10, 11, 4, 0.48),
             (16, 10, 2, 0.4), (20, 9, 2, 0.38), (24, 7, 7, 0.46)])
    return _normalize(bitcrush(buf, bits=7), 0.8)


def mus_hub():
    """Acampamento: calmo e quente. Ganzá macio, melodia de pulso doce, baixo
    arpejado lento. Sem kick agressivo — descanso entre fases."""
    buf, step = _new_buf(84, 2)
    _drums(buf, step, lambda: ganza(0.05, rising=False), _shaker_run(2, sub=2))
    _drums(buf, step, lambda: alfaia(0.2, base=DS2 * 0.5, punch=0.5), [(0, 0.45), (16, 0.45)])
    _melody(buf, step, DS2, MINOR_HARM, _bass(),
            [(0, 0, 6, 0.7), (8, 4, 6, 0.6), (16, 2, 6, 0.7), (24, 4, 6, 0.6)])
    _melody(buf, step, DS2, MINOR_HARM, _lead(duty=0.5),
            [(0, 7, 4, 0.34), (4, 9, 4, 0.34), (10, 8, 2, 0.3), (12, 7, 4, 0.32),
             (16, 9, 4, 0.34), (20, 11, 4, 0.36), (28, 7, 4, 0.32)])
    return _normalize(bitcrush(buf, bits=7), 0.72)


def mus_explore_p1():
    """Fase 1 — mata noturna: misterioso, médio, espaçoso. Batida-coração de alfaia,
    ganzá leve, lead de pulso esparso deixando o ar respirar."""
    buf, step = _new_buf(92, 2)
    _drums(buf, step, lambda: alfaia(0.2, base=E2 * 0.5, punch=0.8),
           [(0, 0.8), (10, 0.5), (16, 0.8), (26, 0.5)])
    _drums(buf, step, lambda: ganza(0.05, rising=False), _shaker_run(2, sub=2))
    _melody(buf, step, E2, MINOR_HARM, _bass(),
            [(0, 0, 8, 0.7), (16, 3, 8, 0.7)])
    _melody(buf, step, E2, MINOR_HARM, _lead(duty=0.25),
            [(4, 7, 2, 0.36), (8, 9, 2, 0.34), (14, 11, 3, 0.4),
             (20, 9, 2, 0.34), (28, 7, 3, 0.36)])
    return _normalize(bitcrush(buf, bits=7), 0.8)


def mus_explore_p2():
    """Fase 2 — floresta em chamas: urgente, mais rápido, frígio. Pulso de baixo em
    colcheias, hats de ruído (brasas), lead nervoso."""
    buf, step = _new_buf(108, 2)
    _drums(buf, step, lambda: alfaia(0.16, base=F2 * 0.5, punch=0.9),
           [(0, 0.9), (6, 0.5), (8, 0.8), (14, 0.5), (16, 0.9), (22, 0.5), (24, 0.8), (30, 0.6)])
    _drums(buf, step, lambda: nes_noise(0.04, decay=70.0, lp=0.3, gain=0.4),
           [(st, 0.4) for st in range(32) if st % 2 == 1])
    _drums(buf, step, lambda: ganza(0.05, rising=False), _shaker_run(2))
    _melody(buf, step, F2, PHRYGIAN, _bass(),
            [(st, 0 if (st // 8) % 2 == 0 else 1, 2, 0.75) for st in range(0, 32, 4)])
    _melody(buf, step, F2, PHRYGIAN, _lead(duty=0.25),
            [(0, 7, 1, 0.4), (2, 8, 1, 0.38), (4, 10, 2, 0.42), (8, 7, 1, 0.4),
             (10, 11, 1, 0.4), (12, 8, 2, 0.4), (16, 7, 1, 0.4), (20, 10, 2, 0.42),
             (24, 8, 1, 0.38), (28, 7, 3, 0.42)])
    return _normalize(bitcrush(buf, bits=7), 0.82)


def mus_explore_p3():
    """Fase 3 — névoa: lento, dissonante, detuneado. Lead de pulso com vibrato e ♭2
    (frígio), percussão mínima. Desorienta."""
    buf, step = _new_buf(72, 2)
    _drums(buf, step, lambda: alfaia(0.26, base=DS2 * 0.25, punch=0.6), [(0, 0.6), (16, 0.55)])
    _melody(buf, step, DS2, PHRYGIAN, _bass(),
            [(0, 0, 10, 0.7), (12, 1, 4, 0.5), (16, 0, 10, 0.7), (28, 1, 4, 0.45)])
    _melody(buf, step, DS2, PHRYGIAN, _lead(duty=0.5, vib=0.03),
            [(2, 8, 4, 0.36), (8, 7, 3, 0.34), (14, 9, 4, 0.36),
             (18, 8, 4, 0.34), (26, 7, 5, 0.36)])
    return _normalize(bitcrush(buf, bits=6), 0.78)


def mus_explore_p4():
    """Fase 4 — ossos e ruína: frio e mínimo. Drone grave de triângulo, sino esparso
    (agogô) como ossos batendo, alfaia sub rara."""
    buf, step = _new_buf(66, 2)
    _drums(buf, step, lambda: alfaia(0.3, base=C2 * 0.5, punch=0.6), [(0, 0.6), (20, 0.4)])
    _drums(buf, step, lambda: agogo(0.16, freq=880.0, bend=0.0),
           [(6, 0.3), (14, 0.25), (24, 0.3)])
    _melody(buf, step, C2, MINOR_HARM, _bass(),
            [(0, 0, 16, 0.75), (16, 5, 16, 0.6)])
    _melody(buf, step, C2, MINOR_HARM, _lead(duty=0.125),
            [(8, 7, 3, 0.3), (18, 10, 2, 0.28), (28, 7, 4, 0.3)])
    return _normalize(bitcrush(buf, bits=6), 0.78)


# ─── Faixas: arenas (intensidade crescente por fase) ───
def mus_arena_p1():
    return _arena_track(100, A2, MINOR_HARM, density=1)


def mus_arena_p2():
    return _arena_track(106, AS2, PHRYGIAN, density=2)


def mus_arena_p3():
    return _arena_track(104, G2, PHRYGIAN, density=2)


def mus_arena_p4():
    return _arena_track(112, F2, PHRYGIAN, density=3)


# ─── Faixas: bosses (tema próprio) ─────────────────
def mus_boss_mula():
    """Mula Sem Cabeça: galope (kick em tercinas) e lead agressivo. Jatos de fogo no
    canal de ruído."""
    buf, step = _new_buf(120, 4)
    gallop = [(st, 0.9 if st % 4 == 0 else 0.55) for b in range(4) for st in (b * 16, b * 16 + 3, b * 16 + 4, b * 16 + 8, b * 16 + 11, b * 16 + 12)]
    _drums(buf, step, lambda: alfaia(0.14, base=D2 * 0.5, punch=1.0), gallop)
    _drums(buf, step, lambda: nes_noise(0.06, decay=40.0, lp=0.2, gain=0.4),
           [(b * 16 + 6, 0.45) for b in range(4)] + [(b * 16 + 14, 0.4) for b in range(4)])
    _drums(buf, step, lambda: ganza(0.05, rising=False), _shaker_run(4))
    _melody(buf, step, D2, MINOR_HARM, _bass(),
            [(st, 0, 2, 0.8) for st in range(0, 64, 4)])
    _melody(buf, step, D2, MINOR_HARM, _lead(duty=0.25),
            [(st, deg, 1, 0.42) for b in range(4) for st, deg in
             ((b * 16, 7), (b * 16 + 2, 10), (b * 16 + 4, 11), (b * 16 + 6, 10),
              (b * 16 + 8, 7), (b * 16 + 10, 12), (b * 16 + 12, 11), (b * 16 + 14, 9))])
    return _normalize(bitcrush(buf, bits=7), 0.86)


def mus_boss_boitata():
    """Boitatá: serpenteante e veloz. Lead cromático com vibrato (a cobra desliza),
    ruído denso (fogo), baixo em semicolcheias."""
    buf, step = _new_buf(132, 4)
    _drums(buf, step, lambda: alfaia(0.12, base=E2 * 0.5, punch=0.95), _baque_alfaia(4))
    _drums(buf, step, lambda: nes_noise(0.04, decay=80.0, lp=0.35, gain=0.4),
           [(st, 0.4) for st in range(64) if st % 2 == 1])
    _drums(buf, step, lambda: caixa(0.07, bright=1.1),
           [(b * 16 + 4, 0.5) for b in range(4)] + [(b * 16 + 12, 0.55) for b in range(4)])
    _melody(buf, step, E2, PHRYGIAN, _bass(),
            [(st, (st // 4) % 3, 1, 0.7) for st in range(0, 64, 2)])
    serp = [0, 1, 2, 1, 3, 2, 4, 3]  # subir e escorregar
    _melody(buf, step, E2, PHRYGIAN, _lead(duty=0.25, vib=0.04),
            [(b * 16 + i * 2, 7 + serp[i], 1, 0.42) for b in range(4) for i in range(8)])
    return _normalize(bitcrush(buf, bits=7), 0.86)


def mus_boss_curupira():
    """Curupira: tribal e telúrico. Alfaia pesada, agogô ritualístico e o leitmotif do
    assovio (protetor da mata) por cima."""
    buf, step = _new_buf(116, 4)
    _drums(buf, step, lambda: alfaia(0.16, base=A2 * 0.5, punch=1.0),
           [(st, 0.9 if st % 8 == 0 else 0.6) for b in range(4) for st in (b * 16, b * 16 + 3, b * 16 + 6, b * 16 + 8, b * 16 + 11, b * 16 + 14)])
    _drums(buf, step, lambda: agogo(0.14, freq=1100.0, bend=0.0),
           [(b * 16 + st, 0.4) for b in range(4) for st in (2, 10)])
    _drums(buf, step, lambda: ganza(0.05, rising=False), _shaker_run(4))
    _melody(buf, step, A2, MINOR_HARM, _bass(),
            [(b * 16, 0, 8, 0.8) for b in range(4)])
    # leitmotif do assovio (a voz da floresta) em dois pontos
    for at in (0, 32):
        _put(buf, assovio(1.0, freq=note(A2, 19)), at, step, 0.34)
    _melody(buf, step, A2, MINOR_HARM, _lead(duty=0.25),
            [(b * 16 + st, deg, 2, 0.36) for b in range(4) for st, deg in ((4, 9), (12, 11))])
    return _normalize(bitcrush(buf, bits=7), 0.86)


def mus_boss_saci():
    """Saci: redemoinho travesso e épico-dark (boss final). Tudo denso — alfaia, ruído
    em varreduras (vento), lead frenético frígio, baixo motor."""
    buf, step = _new_buf(126, 4)
    _drums(buf, step, lambda: alfaia(0.13, base=C2 * 0.5, punch=1.0), _baque_alfaia(4))
    _drums(buf, step, lambda: nes_noise(0.08, decay=18.0, lp=0.5, gain=0.35),
           [(b * 16, 0.45) for b in range(4)])  # varredura de vento por compasso
    _drums(buf, step, lambda: caixa(0.06, bright=1.2),
           [(st, 0.45) for st in range(64) if st % 4 == 2])
    _drums(buf, step, lambda: ganza(0.05, rising=False), _shaker_run(4))
    _melody(buf, step, C2, PHRYGIAN, _bass(),
            [(st, 0 if (st // 8) % 2 == 0 else 1, 1, 0.78) for st in range(0, 64, 2)])
    whirl = [7, 8, 10, 11, 12, 11, 10, 8]
    _melody(buf, step, C2, PHRYGIAN, _lead(duty=0.125, vib=0.02),
            [(b * 16 + i * 2, whirl[(i + b) % 8], 1, 0.44) for b in range(4) for i in range(8)])
    return _normalize(bitcrush(buf, bits=7), 0.87)


def mus_ending():
    """Final: contemplativo, pôr do sol. Resolve a tensão — assovio-leitmotif sereno,
    pulso doce, baixo morno, batida-coração desacelerando. Esperança."""
    buf, step = _new_buf(70, 2)
    _drums(buf, step, lambda: alfaia(0.26, base=A2 * 0.5, punch=0.5), [(0, 0.5), (20, 0.35)])
    _drums(buf, step, lambda: ganza(0.05, rising=False), _shaker_run(2, sub=4))
    _melody(buf, step, A2, MINOR_HARM, _bass(),
            [(0, 0, 8, 0.7), (8, 4, 8, 0.6), (16, 3, 8, 0.65), (24, 4, 8, 0.6)])
    _melody(buf, step, A2, MINOR_HARM, _lead(duty=0.5),
            [(2, 7, 3, 0.34), (8, 9, 3, 0.34), (14, 11, 4, 0.38), (24, 9, 3, 0.34)])
    _put(buf, assovio(1.6, freq=note(A2, 19)), 4, step, 0.3)
    return _normalize(bitcrush(buf, bits=7), 0.76)


MUSIC = {
    "mus_menu": mus_menu,
    "mus_hub": mus_hub,
    "mus_explore_p1": mus_explore_p1,
    "mus_explore_p2": mus_explore_p2,
    "mus_explore_p3": mus_explore_p3,
    "mus_explore_p4": mus_explore_p4,
    "mus_arena_p1": mus_arena_p1,
    "mus_arena_p2": mus_arena_p2,
    "mus_arena_p3": mus_arena_p3,
    "mus_arena_p4": mus_arena_p4,
    "mus_boss_mula": mus_boss_mula,
    "mus_boss_boitata": mus_boss_boitata,
    "mus_boss_curupira": mus_boss_curupira,
    "mus_boss_saci": mus_boss_saci,
    "mus_ending": mus_ending,
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


def sting_boss_intro():
    # Revelação do boss (estilo Mega Man): gonguê grave de ameaça + acorde de pulso
    # crescente + alfaia de impacto. Tensão antes do nome aparecer.
    chord = _mix(
        pulse(0.45, 220.0, duty=0.5, attack=0.05, release=0.4),
        pulse(0.45, note(220.0, 3), duty=0.5, attack=0.08, release=0.4),
        pulse(0.45, note(220.0, 7), duty=0.5, attack=0.11, release=0.4),
    )
    return _normalize(bitcrush(_seq(
        (gongue(0.4, 300.0), 0.0, 0.8),
        (chord, 0.06, 0.5),
        (alfaia(0.3, 48.0, punch=1.0), 0.34, 1.0),
        (agogo(0.2, 1320.0), 0.40, 0.4),
    ), bits=7), 0.86)


def sting_chama():
    # Elemento CHAMA (raro): sopro de fogo no canal de ruído + arpejo de pulso
    # ascendente brilhante (ganho de poder).
    return _normalize(bitcrush(_seq(
        (nes_noise(0.3, decay=10.0, lp=0.4, gain=0.5), 0.0, 0.5),
        (pulse(0.08, 880.0, duty=0.25, release=0.5), 0.04, 0.5),
        (pulse(0.08, 1320.0, duty=0.25, release=0.5), 0.10, 0.5),
        (pulse(0.18, 1760.0, duty=0.25, release=0.6), 0.16, 0.55),
    ), bits=7), 0.78)


STINGERS = {
    "sting_arena_enter": sting_arena_enter,
    "sting_victory": sting_victory,
    "sting_game_over": sting_game_over,
    "sting_chest": sting_chest,
    "sting_boss_intro": sting_boss_intro,
    "sting_chama": sting_chama,
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

    print("Gerando música por contexto (maracatu 8-bits dark)...")
    for name, gen in MUSIC.items():
        random.seed(11)
        _write(f"{name}.wav", gen(), subdir="music", rate=MUSIC_RATE)

    print("Gerando stingers de estado...")
    for name, gen in STINGERS.items():
        random.seed(13)
        _write(f"{name}.wav", gen(), subdir="stingers")
    print("Pronto.")


if __name__ == "__main__":
    main()

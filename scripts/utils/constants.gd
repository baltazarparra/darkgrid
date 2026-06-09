class_name Constants
extends RefCounted

# ─── Grid ──────────────────────────────────────────
const TILE_SIZE := 32
const GRID_WIDTH := 26
const GRID_HEIGHT := 18

# ─── Viewport / Orientação ─────────────────────────
# Fonte ÚNICA da lógica de orientação: guard, D-pad e câmera consultam isto em vez de
# comparar vp.x/vp.y soltos. Telefone = lado curto abaixo deste limite (tablet/desktop isento).
const PHONE_SHORT_SIDE_MAX := 640.0

## True quando o viewport está em retrato (mais alto que largo).
static func is_portrait(vp: Vector2) -> bool:
	return vp.y > vp.x

# ─── Combat ────────────────────────────────────────
const TIMING_WINDOW_FRAMES := 12
const TIMING_PERFECT_FRAMES := 3
const ATTACK_COOLDOWN_SECONDS := 0.0
const DODGE_COOLDOWN_SECONDS := 0.5
const TIMING_WINDOW_ATTACK := 0.8
const TIMING_PERFECT_START := 0.65
const TIMING_PERFECT_END := 0.85
const TIMING_DOUBLE_CHANCE := 0.30
const TIMING_DOUBLE_INTERVAL := 0.5
const TIMING_DOUBLE_BUBBLE_SPREAD_MIN := 60.0
const TIMING_DOUBLE_BUBBLE_SPREAD_MAX := 80.0
const TIMING_DOUBLE_BLOCK_DURATION := 0.55  # TIMING_WINDOW_ATTACK (0.8) - 0.25

# ─── Damage ────────────────────────────────────────
const DAMAGE_BASE := 1
const DAMAGE_CRIT_MULTIPLIER := 1.0
const DAMAGE_COUNTER_MULTIPLIER := 1.0

# ─── Health ────────────────────────────────────────
const FIRE_TILE_DAMAGE := 2

# Comuns (não-boss) têm HP UNIFORME por banda de fase: 5 nas fases 1-2, 8 nas 3-4.
# O dano de CADA golpe da Caipora escala com a fase (1/2/3/4…), segurando o TTK
# (~5 trocas na P1, ~2 na P4). Bosses mantêm HP próprio (marco de fase).
# Ver docs/PRD-economia-v2.md §7.
const CAIPORA_MAX_HEALTH := 2
const COMMON_HEALTH_EARLY := 5    # comuns das fases 1-2
const COMMON_HEALTH_LATE := 8     # comuns das fases 3-4
const BOSS_MAX_HEALTH := 12       # boss P1 (Mula sem Cabeça)
const BOITATA_MAX_HEALTH := 22    # boss P2
const CURUPIRA_MAX_HEALTH := 30   # boss P3
const SACI_MAX_HEALTH := 36       # boss P4
const JESUITA_MAX_HEALTH := 44    # boss final P5 (Jesuíta Bandeirante Catequizador)

## HP uniforme do comum (não-boss) para a fase dada (5 nas fases 1-2, 8 nas 3-4).
static func common_health_for_phase(phase: int) -> int:
	return COMMON_HEALTH_LATE if phase >= 3 else COMMON_HEALTH_EARLY

## Dano-base de CADA golpe da Caipora na fase dada (1 na P1, 2 na P2, 3 na P3…).
static func caipora_base_damage_for_phase(phase: int) -> int:
	return maxi(phase, 1)

# ─── Economia: recompensas de combate (PRD-economia-v2) ──
# Snowball in-run pela metade: kill comum dá meio HP máx. (materializa +1 coração a cada
# 2 kills, via acúmulo em GameState.caipora_max_hp); boss dá +1 HP máx. como marco.
const COMMON_KILL_HP_GROWTH := 0.5
const BOSS_KILL_HP_GROWTH := 1.0
const COMMON_KILL_HEAL := 1.0
const BOSS_KILL_HEAL := 2.0
# Fragmentos inteiros, escalando com a profundidade (chave 1..4 = fase).
const COMMON_FRAGMENT_REWARD := { 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 }
const BOSS_FRAGMENT_BOUNTY := { 1: 3, 2: 5, 3: 8, 4: 12, 5: 20 }

# ─── Colors (Horror Folk Palette) ──────────────────
# Fonte ÚNICA de cor do jogo. Qualquer Color() novo deve referenciar/derivar daqui —
# não inventar tons soltos nos scripts. (doom_fire.gd é a única exceção: gradiente próprio.)
#
# Tons-base (paleta amazônica de horror folk):
const COLOR_NIGHT := Color("#0d1117")    # fundo / noite
const COLOR_ARENA_BG := Color("#1a0f0f") # fundo da arena
const COLOR_EARTH := Color("#3d1f1f")    # terra / trilha
const COLOR_MOSS := Color("#1a2f1a")     # folhagem / musgo
const COLOR_BLOOD := Color("#8b0000")    # sangue / dano
const COLOR_AMBER := Color("#ff6b00")    # destaque / fogo / cue
const COLOR_TEXT := Color("#c9d1d9")     # texto / branco sujo

# Vida (ícones): ativo usa COLOR_BLOOD/COLOR_AMBER; "vazio" = tom apagado translúcido.
const COLOR_BLOOD_EMPTY := Color(0.25, 0.04, 0.04, 0.35)
const COLOR_AMBER_EMPTY := Color(0.3, 0.18, 0.02, 0.35)

# Entidades no mapa (encantado/maligno → roxo).
const COLOR_ENEMY_TINT := Color(0.7, 0.5, 0.9, 1.0)   # criatura comum (modulate)
const COLOR_BOSS_TINT := Color(0.08, 0.0, 0.14, 1.0)  # boss caçador amaldiçoado (modulate)
const COLOR_AURA_BOSS := Color(0.18, 0.0, 0.28, 0.75) # aura de partículas do boss
const COLOR_EXIT := Color(1.0, 0.42, 0.0, 0.85)       # marcador de saída (âmbar)

# Fogo procedural (fogueira do mapa) — gradiente quente.
const COLOR_FIRE_GLOW := Color(0.55, 0.08, 0.0, 0.35)
const COLOR_FIRE_HOT := Color(1.00, 0.55, 0.05)
const COLOR_FIRE_MID := Color(0.85, 0.30, 0.0)
const COLOR_FIRE_LOW := Color(0.75, 0.20, 0.0)

# Materiais de props/decoração (derivados intencionais da paleta).
const COLOR_GOLD := Color(0.92, 0.78, 0.12)
const COLOR_GOLD_DARK := Color(0.55, 0.42, 0.04)
const COLOR_AURA_BUSTER_DARK := Color(0.45, 0.30, 0.04, 0.0)  # fim do ramp da aura (fade)
const COLOR_SMOKE_DARK := Color(0.09, 0.07, 0.05, 0.42)        # fumaça murky do tronco
const COLOR_WOOD := Color(0.32, 0.17, 0.04)
const COLOR_WOOD_DARK := Color(0.16, 0.07, 0.01)
const COLOR_METAL := Color(0.48, 0.38, 0.10)
const COLOR_BARK := Color(0.18, 0.11, 0.05)
const COLOR_BARK_DARK := Color(0.10, 0.06, 0.02)
const COLOR_BONE := Color(0.78, 0.74, 0.62)
const COLOR_BONE_HOLLOW := Color(0.12, 0.10, 0.08)
const COLOR_STONE := Color(0.34, 0.34, 0.38)
const COLOR_STONE_DARK := Color(0.20, 0.20, 0.24)
const COLOR_MOSS_DECO := Color(0.13, 0.24, 0.10, 0.7)
const COLOR_MOSS_DECO_DARK := Color(0.08, 0.16, 0.06, 0.7)
const COLOR_BLOOD_POOL := Color(0.42, 0.02, 0.02, 0.75)
const COLOR_BLOOD_POOL_DARK := Color(0.24, 0.0, 0.0, 0.8)
const COLOR_PENTAGRAM := Color(0.50, 0.0, 0.0)
# Novas decorações da floresta (Fase 1).
const COLOR_MUSHROOM := Color(0.78, 0.70, 0.64, 0.95)      # chapéu pálido/doentio
const COLOR_MUSHROOM_GLOW := Color(0.55, 0.85, 0.70, 0.9)  # bioluminescência encantada
const COLOR_WATER := Color(0.10, 0.16, 0.20, 0.8)          # poça refletindo a noite
const COLOR_WATER_LIGHT := Color(0.20, 0.30, 0.36, 0.7)    # brilho da superfície

# Cues de combate (telegraph/bolhas). Valores >1 são overbright p/ glow intencional.
const COLOR_TELEGRAPH_ENEMY := Color(1.4, 0.4, 0.4)     # wind-up da criatura (vermelho)
const COLOR_TELEGRAPH_ENEMY_ALT := Color(1.4, 0.9, 0.2) # flash de ataque duplo (âmbar)
const COLOR_TELEGRAPH_BOSS := Color(0.5, 0.05, 1.0)     # wind-up do boss (roxo)
const COLOR_BUBBLE_BOSS := Color(0.55, 0.05, 0.95, 1.0) # bolha de timing do boss
const COLOR_TELEGRAPH_BOITATA_WHITE := Color(2.0, 2.0, 2.0) # especial branco do Boitatá (overbright)
const COLOR_AURA_BOITATA := Color(1.0, 0.45, 0.05, 0.75)    # aura de fogo do Boitatá
const COLOR_TELEGRAPH_CURUPIRA := Color(0.1, 1.5, 0.35)     # telegraph do Curupira (verde-mata overbright)
const COLOR_AURA_CURUPIRA := Color(0.0, 0.28, 0.06, 0.72)   # aura do Curupira (verde profundo da floresta)
const COLOR_TELEGRAPH_SACI := Color(2.0, 0.7, 0.15)         # telegraph do Saci (fogo overbright)
const COLOR_AURA_SACI := Color(0.35, 0.10, 0.02, 0.75)      # aura do Saci (brasa escura, casa consumida pelo fogo)
const COLOR_TELEGRAPH_MULA := Color(2.0, 0.55, 0.1)         # telegraph da Mula sem Cabeça (jato de fogo overbright)
const COLOR_AURA_MULA := Color(0.55, 0.12, 0.02, 0.72)      # aura de brasas da Mula (fogo escuro subindo do toco)
const COLOR_TELEGRAPH_JESUITA := Color(1.7, 1.4, 0.6)       # telegraph do Jesuíta (ouro de incenso corrompido, overbright)
const COLOR_AURA_JESUITA := Color(0.42, 0.34, 0.10, 0.75)   # aura do Jesuíta (fumaça de incenso podre, dourado-acinzentado)

# Cores de diálogo (speaker labels nos pre-boss dialogues).
const COLOR_DIALOGUE_CAIPORA  := Color(0.55, 0.90, 0.60, 1.0)  # voz da Caipora (verde floresta)
const COLOR_DIALOGUE_BOITATA  := Color(1.0,  0.42, 0.0,  1.0)  # voz do Boitatá (fogo)
const COLOR_DIALOGUE_CURUPIRA := Color(0.1,  0.85, 0.30, 1.0)  # voz do Curupira (verde mata)
const COLOR_DIALOGUE_SACI     := Color(1.0,  0.55, 0.12, 1.0)  # voz do Saci (fogo)
const COLOR_DIALOGUE_MULA     := Color(1.0,  0.50, 0.10, 1.0)  # voz da Mula sem Cabeça (fogo)
const COLOR_DIALOGUE_JESUITA  := Color(0.92, 0.82, 0.45, 1.0)  # voz do Jesuíta (ouro litúrgico corrompido)

# Partículas de feedback de combate (>1 = overbright p/ glow aditivo intencional).
const COLOR_PARTICLE_SPARK := Color(1.0, 0.92, 0.6, 1.0)  # faísca de crítico (dourado)
const COLOR_PARTICLE_DODGE := Color(0.9, 0.95, 1.0, 0.95) # flash de esquiva (azul-claro)
const COLOR_PARTICLE_FAIL := Color(0.20, 0.18, 0.22, 0.9) # estilhaço de erro (cinza-fumaça morto, deriva de COLOR_STONE_DARK)

# ─── UI Design Tokens (escala de espaçamento / tipografia) ──
# Padronização AAA: telas e HUD consomem estes tokens, nunca números soltos.
const SPACE_XS := 8
const SPACE_SM := 16
const SPACE_MD := 24
const SPACE_LG := 40
const SPACE_XL := 64

const FONT_SM := 12
const FONT_MD := 18
const FONT_LG := 28
const FONT_TITLE := 48

# Direção de arte da UI (scenes/AGENTS.md): cantos retos, bordas duras — sem arredondar.
const UI_CORNER_RADIUS := 0
const UI_BORDER_WIDTH := 2
const UI_PADDING_H := 20  # padding horizontal interno de botões/painéis
const UI_PADDING_V := 12  # padding vertical interno

# ─── Fase 2 ────────────────────────────────────────
# Toda janela de ação (ataque e defesa) encurta 0.1s — a floresta fica mais
# impiedosa. Cada golpe de inimigo também bate +1 (PHASE2_ENEMY_DAMAGE_BONUS).
const PHASE2_TIMING_REDUCTION := 0.1
const PHASE2_ENEMY_DAMAGE_BONUS := 1.0

# ─── Fase 3 ────────────────────────────────────────
const PHASE3_TIMING_REDUCTION := 0.15

# ─── Fase 4 ────────────────────────────────────────
# A casa arde. A janela de ação encurta ainda mais que a Fase 3 (0.15 + 0.15 =
# 0.30 "mais rápido") e cada golpe de inimigo bate +1 (PHASE4_ENEMY_DAMAGE_BONUS).
const PHASE4_TIMING_REDUCTION := 0.30
const PHASE4_ENEMY_DAMAGE_BONUS := 1.0

# ─── Fase 5 (A Igreja na Mata) ─────────────────────
# A fase FINAL: a mais impiedosa. A janela de ação encurta 0.2s ALÉM da Fase 4
# (0.30 + 0.20 = 0.50 "mais rápido", travado no piso de 0.2s em _phase_window) e
# cada golpe de inimigo bate +1 (PHASE5_ENEMY_DAMAGE_BONUS). Vale igualmente para
# os 4 chefes-monstro convertidos e para o Jesuíta — "o mesmo comportamento".
const PHASE5_TIMING_REDUCTION := 0.50
const PHASE5_ENEMY_DAMAGE_BONUS := 1.0

# ─── Physics Layers ────────────────────────────────
const LAYER_PLAYER := 1
const LAYER_ENEMY := 2
const LAYER_WALL := 3
const LAYER_TRIGGER := 4

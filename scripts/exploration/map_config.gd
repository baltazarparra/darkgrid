class_name MapConfig
extends Resource

# Parametriza UMA geração de mapa. Cada fase tem uma config que codifica sua
# identidade — a referência dos mapas estáticos (PLAN.md §11, Fases 1–4):
#   Fase 1: arena aberta, pilares, sala-chokepoint do boss, baú+chave, 4 inimigos.
#   Fase 2: mesma topologia encharcada de fogo, 6 inimigos (Boitatá).
#   Fase 3: "Ventre da Mata" — corredores estreitos, fog of war, 4 inimigos (Curupira).
#   Fase 4: casa em chamas — fogo denso, 6 inimigos (Saci).
#
# É um Resource para virar .tres tunável por game design (sem números mágicos no
# gerador). MapGenerator consome isto + um seed e devolve um GeneratedMap.

enum TopologyMode {
	OPEN,      # região aberta com obstáculos + sala do boss (Fases 1, 2, 4)
	CORRIDOR,  # túneis sinuosos via drunkard's walk (Fase 3)
}

# ─── Identidade ────────────────────────────────────
@export var phase: int = 1
@export var topology_mode: TopologyMode = TopologyMode.OPEN
@export var boss_type: String = "generico"

# ─── Dimensões ─────────────────────────────────────
@export var grid_width: int = Constants.GRID_WIDTH
@export var grid_height: int = Constants.GRID_HEIGHT

# ─── Inimigos ──────────────────────────────────────
@export var enemy_count: int = 4           # inclui o boss
@export var min_spawn_distance: int = 5    # inimigo regular longe do spawn (manhattan via BFS)
@export var min_enemy_spacing: int = 3     # espaçamento mínimo entre inimigos

# ─── Hazards (R=fogo, S=espinho) ───────────────────
@export var hazard_chars: PackedStringArray = PackedStringArray()
@export var hazard_density: float = 0.0    # fração das células de chão alcançáveis

# ─── Topologia OPEN ────────────────────────────────
@export var pillar_density: float = 0.06   # fração de candidatos vira pilar de 1 tile

# ─── Topologia CORRIDOR ────────────────────────────
@export var corridor_openness: float = 0.4 # fração do interior escavada em corredores
@export var corridor_width: int = 1

# ─── Conteúdo opcional ─────────────────────────────
@export var has_chest: bool = false
@export var has_key: bool = false
@export var has_fog: bool = false
@export var decoration_count: int = 0       # ambientação visual espalhada no chão

# ─── Factory por fase ──────────────────────────────
# Mantém a identidade das 4 fases num único ponto de tuning.
static func for_phase(target_phase: int) -> MapConfig:
	var c := MapConfig.new()
	c.phase = target_phase
	match target_phase:
		1:
			c.topology_mode = TopologyMode.OPEN
			c.boss_type = "generico"
			c.enemy_count = 4
			c.hazard_chars = PackedStringArray(["R", "S"])
			c.hazard_density = 0.04
			c.pillar_density = 0.06
			c.has_chest = true
			c.has_key = true
			c.decoration_count = 40
		2:
			c.topology_mode = TopologyMode.OPEN
			c.boss_type = "boitata"
			c.enemy_count = 4
			c.hazard_chars = PackedStringArray(["R"])
			c.hazard_density = 0.12
			c.pillar_density = 0.05
			c.decoration_count = 40
		3:
			c.topology_mode = TopologyMode.CORRIDOR
			c.boss_type = "curupira"
			c.enemy_count = 6
			c.hazard_chars = PackedStringArray()
			c.hazard_density = 0.0
			c.corridor_openness = 0.36
			c.corridor_width = 1
			c.has_fog = true
			c.decoration_count = 24
		4:
			c.topology_mode = TopologyMode.OPEN
			c.boss_type = "saci"
			c.enemy_count = 6
			c.hazard_chars = PackedStringArray(["R"])
			c.hazard_density = 0.16
			c.pillar_density = 0.05
			c.decoration_count = 40
	return c

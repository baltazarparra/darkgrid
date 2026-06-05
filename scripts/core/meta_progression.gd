extends Node

# Persists meta-progression between runs: unlocks, stats, fragments, upgrades.
# Saved to user://savegame.json (platform-agnostic path).

var SAVE_PATH := "user://savegame.json"

# Versão do formato de save. Incrementar ao mudar o schema; migrar em load_progress().
const SAVE_VERSION: int = 1

# True se user:// é persistente (no Web = IndexedDB disponível; false em aba anônima/quota).
var is_persistent: bool = true

# Cada aprimoramento é uma ERVA que a Caipora põe no cachimbo para fumar. Duas trilhas:
# "furia" (dano) e "cura" (HP). As KEYS são imutáveis (compatibilidade de save); só os
# nomes/metadados de exibição mudam. Metadados de UI (line/tier/phase/icon) são lidos pelo
# Hub para montar os cards de forma data-driven.
#
# FONTE NUMÉRICA ÚNICA (PRD-economia-v2): o campo "dmg" (Fúria) ou "hp" (Cura) é a verdade
# da matemática; o texto do efeito é DERIVADO via effect_text() (mata a classe de bug do
# KI-006, em que o label desincronizava do bônus real). Curva de custo crescente e teto
# deliberado: Fúria leva o dano de 1 a 5 (6 com a CHAMA); Cura leva o HP de 2 a 14.
const UPGRADE_DEFS := {
	"forca":   { "name": "Folha-Brasa",      "max_level": 1, "fragment_cost": 5,  "line": "furia", "tier": 1, "phase": 1, "dmg": 1, "icon": "res://assets/sprites/erva_folha_brasa.png" },
	"forca_2": { "name": "Cinza-Viva",       "max_level": 1, "fragment_cost": 10, "line": "furia", "tier": 2, "phase": 2, "dmg": 1, "icon": "res://assets/sprites/erva_cinza_viva.png", "requires": "forca" },
	"forca_3": { "name": "Raiz-de-Ira",      "max_level": 1, "fragment_cost": 16, "line": "furia", "tier": 3, "phase": 3, "dmg": 1, "icon": "res://assets/sprites/erva_raiz_de_ira.png", "requires": "forca_2" },
	"forca_4": { "name": "Breu-Ancestral",   "max_level": 1, "fragment_cost": 24, "line": "furia", "tier": 4, "phase": 4, "dmg": 1, "icon": "res://assets/sprites/erva_breu_ancestral.png", "requires": "forca_3" },
	"saude":   { "name": "Seiva-Mãe",        "max_level": 1, "fragment_cost": 6,  "line": "cura",  "tier": 1, "phase": 1, "hp": 2,  "icon": "res://assets/sprites/erva_seiva_mae.png" },
	"saude_2": { "name": "Casca-Boa",        "max_level": 1, "fragment_cost": 12, "line": "cura",  "tier": 2, "phase": 2, "hp": 3,  "icon": "res://assets/sprites/erva_casca_boa.png" },
	"saude_3": { "name": "Folha-de-Sangue",  "max_level": 1, "fragment_cost": 20, "line": "cura",  "tier": 3, "phase": 3, "hp": 3,  "icon": "res://assets/sprites/erva_folha_de_sangue.png", "requires": "saude_2" },
	"saude_4": { "name": "Coração-de-Cerne", "max_level": 1, "fragment_cost": 30, "line": "cura",  "tier": 4, "phase": 4, "hp": 4,  "icon": "res://assets/sprites/erva_coracao_de_cerne.png", "requires": "saude_3" },
}

# Dano base da Caipora (espelha Constants.DAMAGE_BASE) — usado para derivar os totais
# exibidos na trilha Fúria.
const BASE_DAMAGE: int = 1

# Ordem de exibição por trilha (o Hub itera sem hardcode de keys).
const FURIA_KEYS: Array[String] = ["forca", "forca_2", "forca_3", "forca_4"]
const CURA_KEYS: Array[String]  = ["saude", "saude_2", "saude_3", "saude_4"]

# ─── CHAMA (elemento fogo) ─────────────────────────
# Depois que a espada (forca_3, "Raiz-de-Ira" da Fase 3) já existe, a cada
# KILLS_PER_CHAMA_ROLL monstros comuns derrotados há UM sorteio: com CHAMA_DROP_CHANCE de
# chance, a espada ganha o elemento fogo (permanente) no lugar do fragmento daquela morte:
# +CHAMA_DAMAGE_BONUS de dano e visual de chama (na arena e na exploração).
const KILLS_PER_CHAMA_ROLL: int = 10
# `var` (não const) de propósito: ponto único de tuning e overridable nos testes (1.0/0.0).
var CHAMA_DROP_CHANCE: float = 0.5
# +1 de dano (respeita o teto da trilha Fúria: 5 → 6 com a CHAMA). Ver PRD-economia-v2.
const CHAMA_DAMAGE_BONUS: int = 1

# ─── State ─────────────────────────────────────────
var unlocked_characters: Array[String] = ["caipora"]
var unlocked_modifiers: Array[String] = []
var total_runs: int = 0
var total_wins: int = 0
var upgrades: Dictionary = {}
var fragments: float = 0.0
var phase_reached: int = 1
var touch_controls_mode: String = "auto"
# CHAMA: elemento fogo desbloqueado (permanente) + contador acumulado rumo ao próximo sorteio.
var has_chama: bool = false
var kills_toward_chama: int = 0

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	# No Web, a engine sincroniza IndexedDB→memfs antes do main loop, então user://
	# já está disponível aqui. Carregar no autoload torna o save independente da cena de boot.
	is_persistent = OS.is_userfs_persistent()
	if not is_persistent:
		push_warning("MetaProgression: user:// não é persistente (aba anônima/quota?); o save não vai colar.")
	load_progress()

# ─── Fragments ─────────────────────────────────────
func add_fragments(amount: float) -> void:
	fragments += amount
	save_progress()
	SignalBus.fragment_gained.emit(fragments, amount)

func add_fragment() -> void:
	add_fragments(1.0)

# ─── Upgrades ──────────────────────────────────────
func get_upgrade_level(key: String) -> int:
	return int(upgrades.get(key, 0))

func get_damage_bonus() -> int:
	# Soma o "dmg" de cada erva de Fúria comprada (fonte numérica única). Cada tier soma
	# +1 (teto +4 → dano 5). A CHAMA (elemento fogo na espada) soma +CHAMA_DAMAGE_BONUS.
	var bonus := 0
	for key in FURIA_KEYS:
		bonus += get_upgrade_level(key) * int(UPGRADE_DEFS[key].get("dmg", 0))
	if has_chama:
		bonus += CHAMA_DAMAGE_BONUS
	return bonus

## Registra uma morte de monstro comum para o sistema da CHAMA. Só conta se a espada
## (forca_3) já existe e a CHAMA ainda não foi obtida. A cada KILLS_PER_CHAMA_ROLL mortes
## faz UM sorteio. Retorna true se a CHAMA foi conquistada NESTA morte (recompensa = CHAMA
## no lugar do fragmento).
func register_kill_for_chama() -> bool:
	if has_chama or get_upgrade_level("forca_3") < 1:
		return false
	kills_toward_chama += 1
	if kills_toward_chama < KILLS_PER_CHAMA_ROLL:
		save_progress()
		return false
	kills_toward_chama = 0
	if randf() < CHAMA_DROP_CHANCE:
		has_chama = true
		save_progress()
		SignalBus.chama_gained.emit()
		return true
	save_progress()
	return false

func get_health_bonus() -> int:
	# Soma o "hp" de cada erva de Cura comprada (fonte numérica única). Incrementos
	# crescentes 2/3/3/4 (teto +12 → HP máx. 14). Ver PRD-economia-v2.
	var bonus := 0
	for key in CURA_KEYS:
		bonus += get_upgrade_level(key) * int(UPGRADE_DEFS[key].get("hp", 0))
	return bonus

## Texto de efeito DERIVADO da matemática (não há string solta a desincronizar — KI-006).
## Fúria: "Dano +N/hit (total T)"; Cura: "+N HP (total T)". T é o valor acumulado da trilha
## somando todas as ervas até esta (inclusive), partindo do base (dano 1 / HP base 2).
func effect_text(key: String) -> String:
	if not UPGRADE_DEFS.has(key):
		return ""
	var def: Dictionary = UPGRADE_DEFS[key]
	var line: String = String(def.get("line", ""))
	if line == "furia":
		var inc: int = int(def.get("dmg", 0))
		var total := BASE_DAMAGE + _cumulative(FURIA_KEYS, key, "dmg")
		return "Dano +%d/hit (total %d)" % [inc, total]
	var inc_hp: int = int(def.get("hp", 0))
	var total_hp := Constants.CAIPORA_MAX_HEALTH + _cumulative(CURA_KEYS, key, "hp")
	return "+%d HP (total %d)" % [inc_hp, total_hp]

## Soma o campo `field` de todas as ervas de `order` até `key` (inclusive).
func _cumulative(order: Array[String], key: String, field: String) -> int:
	var sum := 0
	for k in order:
		sum += int(UPGRADE_DEFS[k].get(field, 0))
		if k == key:
			break
	return sum

func get_touch_controls_mode() -> String:
	return touch_controls_mode

func set_touch_controls_mode(mode: String) -> void:
	if mode in ["auto", "always", "never"]:
		touch_controls_mode = mode
		save_progress()

## Consome fragmentos e incrementa o nível. Retorna false se não puder comprar.
func purchase_upgrade(key: String) -> bool:
	if not UPGRADE_DEFS.has(key):
		return false
	var def: Dictionary = UPGRADE_DEFS[key]
	var req: String = def.get("requires", "")
	if req != "" and get_upgrade_level(req) < 1:
		return false
	var cost: int = int(def.get("fragment_cost", 0))
	var level := get_upgrade_level(key)
	if level >= int(def["max_level"]) or fragments < cost:
		return false
	fragments -= cost
	upgrades[key] = level + 1
	save_progress()
	return true

# ─── Public API ────────────────────────────────────
func save_progress() -> void:
	var data := {
		"version": SAVE_VERSION,
		"unlocked_characters": unlocked_characters,
		"unlocked_modifiers": unlocked_modifiers,
		"total_runs": total_runs,
		"total_wins": total_wins,
		"upgrades": upgrades,
		"fragments": fragments,
		"phase_reached": phase_reached,
		"touch_controls_mode": touch_controls_mode,
		"has_chama": has_chama,
		"kills_toward_chama": kills_toward_chama
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("MetaProgression: failed to open save file for writing")
		return
	file.store_string(JSON.stringify(data))
	file.flush()  # garante que o buffer foi gravado antes do close (sincronização do IndexedDB no Web)
	file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("MetaProgression: failed to open save file for reading")
		return
	var text := file.get_as_text()
	file.close()
	# JSON.parse() (instância) retorna código de erro sem logar no console — diferente de
	# JSON.parse_string(), que emite um erro de engine em texto inválido.
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK or not (json.data is Dictionary):
		# Save corrompido/truncado: mantém os defaults em memória. Não sobrescreve o
		# arquivo — o próximo save_progress() válido regrava o conteúdo correto.
		push_warning("MetaProgression: save corrompido em %s; usando defaults." % SAVE_PATH)
		return
	var data: Dictionary = json.data
	# Gancho de migração: saves sem "version" (v0) carregam com defaults nos campos ausentes,
	# então v0→v1 é no-op. Migrações futuras entram aqui antes de ler os campos.
	var _version := int(data.get("version", 0))
	unlocked_characters = _to_string_array(data.get("unlocked_characters", ["caipora"]))
	unlocked_modifiers = _to_string_array(data.get("unlocked_modifiers", []))
	total_runs = data.get("total_runs", 0)
	total_wins = data.get("total_wins", 0)
	upgrades = _to_int_dict(data.get("upgrades", {}))
	fragments = float(data.get("fragments", 0.0))
	phase_reached = int(data.get("phase_reached", 1))
	touch_controls_mode = data.get("touch_controls_mode", "auto")
	has_chama = bool(data.get("has_chama", false))
	kills_toward_chama = int(data.get("kills_toward_chama", 0))

## Zera todo o progresso e apaga o arquivo de save. Não toca em user://settings.cfg (áudio).
func reset_save() -> void:
	unlocked_characters = ["caipora"]
	unlocked_modifiers = []
	total_runs = 0
	total_wins = 0
	upgrades = {}
	fragments = 0.0
	phase_reached = 1
	touch_controls_mode = "auto"
	has_chama = false
	kills_toward_chama = 0
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _to_int_dict(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for key in value:
			if key is String and UPGRADE_DEFS.has(key):
				result[key] = int(value[key])
	return result

func _to_string_array(value: Variant) -> Array[String]:
	if value is Array:
		var result: Array[String] = []
		for item in value:
			if item is String:
				result.append(item)
		return result
	return []

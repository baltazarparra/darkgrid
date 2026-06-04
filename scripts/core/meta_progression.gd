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
# nomes/metadados de exibição mudam. Metadados de UI (line/tier/phase/effect/icon) são
# lidos pelo Hub para montar os cards de forma data-driven.
const UPGRADE_DEFS := {
	"forca":   { "name": "Folha-Brasa",      "max_level": 1, "fragment_cost": 4,  "line": "furia", "tier": 1, "phase": 1, "effect": "Dano +1/hit",          "icon": "res://assets/sprites/erva_folha_brasa.png" },
	"forca_2": { "name": "Cinza-Viva",       "max_level": 1, "fragment_cost": 6,  "line": "furia", "tier": 2, "phase": 2, "effect": "Dano +1/hit (total 3)", "icon": "res://assets/sprites/erva_cinza_viva.png", "requires": "forca" },
	"forca_3": { "name": "Raiz-de-Ira",      "max_level": 1, "fragment_cost": 8,  "line": "furia", "tier": 3, "phase": 3, "effect": "Dano +3/hit (total 6)", "icon": "res://assets/sprites/erva_raiz_de_ira.png", "requires": "forca_2" },
	"forca_4": { "name": "Breu-Ancestral",   "max_level": 1, "fragment_cost": 10, "line": "furia", "tier": 4, "phase": 4, "effect": "Dano +2/hit (total 8)", "icon": "res://assets/sprites/erva_breu_ancestral.png", "requires": "forca_3" },
	"saude":   { "name": "Seiva-Mãe",        "max_level": 1, "fragment_cost": 6,  "line": "cura",  "tier": 1, "phase": 1, "effect": "+2 HP",                "icon": "res://assets/sprites/erva_seiva_mae.png" },
	"saude_2": { "name": "Casca-Boa",        "max_level": 1, "fragment_cost": 9,  "line": "cura",  "tier": 2, "phase": 2, "effect": "+2 HP",                "icon": "res://assets/sprites/erva_casca_boa.png" },
	"saude_3": { "name": "Folha-de-Sangue",  "max_level": 1, "fragment_cost": 12, "line": "cura",  "tier": 3, "phase": 3, "effect": "+2 HP",                "icon": "res://assets/sprites/erva_folha_de_sangue.png", "requires": "saude_2" },
	"saude_4": { "name": "Coração-de-Cerne", "max_level": 1, "fragment_cost": 15, "line": "cura",  "tier": 4, "phase": 4, "effect": "+2 HP",                "icon": "res://assets/sprites/erva_coracao_de_cerne.png", "requires": "saude_3" },
}

# Ordem de exibição por trilha (o Hub itera sem hardcode de keys).
const FURIA_KEYS: Array[String] = ["forca", "forca_2", "forca_3", "forca_4"]
const CURA_KEYS: Array[String]  = ["saude", "saude_2", "saude_3", "saude_4"]

# ─── State ─────────────────────────────────────────
var unlocked_characters: Array[String] = ["caipora"]
var unlocked_modifiers: Array[String] = []
var total_runs: int = 0
var total_wins: int = 0
var upgrades: Dictionary = {}
var fragments: float = 0.0
var phase_reached: int = 1
var touch_controls_mode: String = "auto"

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
	# "Raiz-de-Ira" (forca_3) bate 2 hits a mais que as anteriores: soma +3 em vez de +1.
	# "Breu-Ancestral" (forca_4, recompensa de Fase 4) soma +2.
	return get_upgrade_level("forca") + get_upgrade_level("forca_2") \
		+ get_upgrade_level("forca_3") * 3 + get_upgrade_level("forca_4") * 2

func get_health_bonus() -> int:
	# Cada erva de cura soma +2 HP (a multiplicação por 2 cobre as 4 trilhas).
	return (get_upgrade_level("saude") + get_upgrade_level("saude_2") \
		+ get_upgrade_level("saude_3") + get_upgrade_level("saude_4")) * 2

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
		"touch_controls_mode": touch_controls_mode
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

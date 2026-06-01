extends Node

# Persists meta-progression between runs: unlocks, stats.
# Saved to user://savegame.json (platform-agnostic path).

# var (não const) para permitir isolamento de save nos testes.
var SAVE_PATH := "user://savegame.json"

# Definição declarativa dos upgrades: chave → nome de exibição + cap de níveis.
const UPGRADE_DEFS := {
	"max_hp": { "name": "Vigor", "max_level": 3 },      # +10 HP por nível
	"cooldown": { "name": "Reflexos", "max_level": 2 },  # -0.1s cooldown por nível
}

# ─── State ─────────────────────────────────────────
var unlocked_characters: Array[String] = ["caipora"]
var unlocked_modifiers: Array[String] = []
var total_runs: int = 0
var total_wins: int = 0
var upgrades: Dictionary = {}  # { chave: nível:int } — default 0 por chave

# ─── Upgrades ──────────────────────────────────────
func get_upgrade_level(key: String) -> int:
	return int(upgrades.get(key, 0))

## Compra livre (sem custo): incrementa o nível até o cap. Retorna false no cap.
func purchase_upgrade(key: String) -> bool:
	if not UPGRADE_DEFS.has(key):
		return false
	var level := get_upgrade_level(key)
	if level >= int(UPGRADE_DEFS[key]["max_level"]):
		return false
	upgrades[key] = level + 1
	return true

func get_bonus_max_hp() -> int:
	return get_upgrade_level("max_hp") * 10

func get_cooldown_reduction() -> float:
	return get_upgrade_level("cooldown") * 0.1

# ─── Public API ────────────────────────────────────
func save_progress() -> void:
	var data := {
		"unlocked_characters": unlocked_characters,
		"unlocked_modifiers": unlocked_modifiers,
		"total_runs": total_runs,
		"total_wins": total_wins,
		"upgrades": upgrades
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("MetaProgression: failed to open save file for writing")
		return
	file.store_string(JSON.stringify(data))
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
	var data: Variant = JSON.parse_string(text)
	if data is Dictionary:
		unlocked_characters = _to_string_array(data.get("unlocked_characters", ["caipora"]))
		unlocked_modifiers = _to_string_array(data.get("unlocked_modifiers", []))
		total_runs = data.get("total_runs", 0)
		total_wins = data.get("total_wins", 0)
		upgrades = _to_int_dict(data.get("upgrades", {}))  # retrocompatível: ausente = {}

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

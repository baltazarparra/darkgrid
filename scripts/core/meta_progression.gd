extends Node

# Persists meta-progression between runs: unlocks, stats, fragments, upgrades.
# Saved to user://savegame.json (platform-agnostic path).

var SAVE_PATH := "user://savegame.json"

const UPGRADE_DEFS := {
	"forca": { "name": "Força", "max_level": 1, "fragment_cost": 4 },
	"saude": { "name": "Saúde", "max_level": 1, "fragment_cost": 6 }
}

# ─── State ─────────────────────────────────────────
var unlocked_characters: Array[String] = ["caipora"]
var unlocked_modifiers: Array[String] = []
var total_runs: int = 0
var total_wins: int = 0
var upgrades: Dictionary = {}
var fragments: int = 0

# ─── Fragments ─────────────────────────────────────
func add_fragment() -> void:
	fragments += 1
	save_progress()
	SignalBus.fragment_gained.emit(fragments)

# ─── Upgrades ──────────────────────────────────────
func get_upgrade_level(key: String) -> int:
	return int(upgrades.get(key, 0))

func get_damage_bonus() -> int:
	return get_upgrade_level("forca")

func get_health_bonus() -> int:
	return get_upgrade_level("saude") * 2

## Consome fragmentos e incrementa o nível. Retorna false se não puder comprar.
func purchase_upgrade(key: String) -> bool:
	if not UPGRADE_DEFS.has(key):
		return false
	var def: Dictionary = UPGRADE_DEFS[key]
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
		"unlocked_characters": unlocked_characters,
		"unlocked_modifiers": unlocked_modifiers,
		"total_runs": total_runs,
		"total_wins": total_wins,
		"upgrades": upgrades,
		"fragments": fragments
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
		upgrades = _to_int_dict(data.get("upgrades", {}))
		fragments = int(data.get("fragments", 0))

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

extends Node

# Persists meta-progression between runs: unlocks, stats.
# Saved to user://savegame.json (platform-agnostic path).

const SAVE_PATH := "user://savegame.json"

# ─── State ─────────────────────────────────────────
var unlocked_characters: Array[String] = ["caipora"]
var unlocked_modifiers: Array[String] = []
var total_runs: int = 0
var total_wins: int = 0

# ─── Public API ────────────────────────────────────
func save_progress() -> void:
	var data := {
		"unlocked_characters": unlocked_characters,
		"unlocked_modifiers": unlocked_modifiers,
		"total_runs": total_runs,
		"total_wins": total_wins
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

func _to_string_array(value: Variant) -> Array[String]:
	if value is Array:
		var result: Array[String] = []
		for item in value:
			if item is String:
				result.append(item)
		return result
	return []

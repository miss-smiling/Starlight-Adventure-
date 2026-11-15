extends Node

const SaveModel = preload("res://scripts/model/save_model.gd")

var save_path := "user://starlight_adventure_save.json"
var settings_path := "user://starlight_adventure_settings.json"
var board_path := "user://starlight_adventure_leaderboard.json"
var state: Dictionary = SaveModel.default_state("Explorer")
var settings := {
	"text_speed": 48,
	"instant_text": false,
	"fullscreen": false,
	"volume": 1.0,
}
var leaderboard: Array = []
var replay_backup: Dictionary = {}

func _ready() -> void:
	load_settings()
	load_leaderboard()
	apply_settings()


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func new_game(callsign: String, gender := "") -> void:
	state = SaveModel.default_state(callsign)
	state["gender"] = gender
	save_game()


func load_game() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {"ok": false, "error": "No saved campaign."}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	var mission_ids: Array = CampaignManager.mission_ids()
	var result: Dictionary = SaveModel.validate(parsed, mission_ids, ProfessionManager.ids())
	if not result.ok:
		return result
	state = result.state
	TechnologyManager.sync()
	save_game()
	return {"ok": true, "error": ""}


func save_game() -> void:
	if bool(state.get("replay", false)):
		return
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write the save file.")
		return
	file.store_string(JSON.stringify(state, "\t"))


func delete_save() -> void:
	state = SaveModel.default_state("Explorer")
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func load_settings() -> void:
	if not FileAccess.file_exists(settings_path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(settings_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for key in settings.keys():
		if parsed.has(key):
			settings[key] = parsed[key]


func save_settings() -> void:
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(settings, "\t"))
	apply_settings()


func apply_settings() -> void:
	var volume := float(settings.get("volume", 1.0))
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_mute(bus, volume <= 0.001)
		if volume > 0.001:
			AudioServer.set_bus_volume_db(bus, linear_to_db(volume))
	if DisplayServer.get_name() == "headless":
		return
	if bool(settings.get("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func load_leaderboard() -> void:
	leaderboard = []
	if not FileAccess.file_exists(board_path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(board_path))
	if typeof(parsed) == TYPE_ARRAY:
		leaderboard = parsed


func add_score(report: Dictionary) -> void:
	leaderboard.append({
		"callsign": state.get("callsign", "Explorer"),
		"mission_id": report.get("mission_id", ""),
		"mission": report.get("title", ""),
		"profession": report.get("profession", ""),
		"points": int(report.get("points", 0)),
		"grade": report.get("grade", ""),
		"year": int(report.get("year", 0)),
	})
	leaderboard.sort_custom(func(a, b): return int(a.get("points", 0)) > int(b.get("points", 0)))
	if leaderboard.size() > 20:
		leaderboard = leaderboard.slice(0, 20)
	var file := FileAccess.open(board_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(leaderboard, "\t"))


func begin_replay() -> void:
	replay_backup = state.duplicate(true)
	state["replay"] = true
	state["runtime"] = {}


func finish_replay() -> void:
	var achievements: Array = state.get("achievements", []).duplicate()
	var played: Array = state.get("professions_played", []).duplicate()
	state = replay_backup.duplicate(true)
	state["achievements"] = achievements
	state["professions_played"] = played
	state["replay"] = false
	state["runtime"] = {}
	replay_backup = {}
	save_game()

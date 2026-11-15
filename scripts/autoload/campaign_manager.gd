extends Node

const Validator = preload("res://scripts/model/content_validator.gd")

var years: Array = []
var dialogues := {}
var flags := {}
var achievements: Array = []
var mission_by_id := {}
var order: Array = []
var load_error := ""

func _ready() -> void:
	load_data()


func load_data() -> void:
	years = []
	mission_by_id = {}
	order = []
	load_error = ""
	for path in [
		"res://data/year_2026.json",
		"res://data/year_2027.json",
		"res://data/year_2028.json",
		"res://data/year_2029.json",
		"res://data/year_2030.json",
		"res://data/year_2031.json",
	]:
		var year_data = _read_dict(path)
		if year_data.is_empty():
			load_error = "Could not read " + path
			return
		years.append(year_data)
	dialogues = _read_dict("res://data/dialogues.json")
	flags = _read_dict("res://data/flag_lines.json")
	var ach = _read_any("res://data/achievements.json")
	achievements = ach if typeof(ach) == TYPE_ARRAY else []
	for year_data in years:
		for mission in year_data.get("missions", []):
			mission["year"] = int(year_data.year)
			mission["year_title"] = str(year_data.get("title", ""))
			mission["campaign_title"] = str(year_data.get("campaign", ""))
			mission_by_id[str(mission.id)] = mission
			order.append(str(mission.id))
	var errors: Array = Validator.check(years, dialogues, achievements)
	if not errors.is_empty():
		load_error = "\n".join(errors)
		push_error(load_error)


func mission_ids() -> Array:
	return order.duplicate()


func mission(id: String) -> Dictionary:
	return mission_by_id.get(id, {})


func dialogue(id: String) -> Dictionary:
	return dialogues.get(id, {})


func year_data(year: int) -> Dictionary:
	for item in years:
		if int(item.year) == year:
			return item
	return {}


func year_unlocked(year: int, completed: Array) -> bool:
	if year <= 2026:
		return true
	# Seasons beyond 2026 are still in development; they unlock as more
	# missions ship.
	return false


func next_mission_id(completed: Array) -> String:
	for id in order:
		if year_unlocked(int(mission(id).get("year", 2026)), completed) and not completed.has(id):
			return id
	return ""


func current_year_for(completed: Array) -> int:
	var nxt := next_mission_id(completed)
	if nxt == "":
		return 2031
	return int(mission(nxt).get("year", 2026))


func _read_dict(path: String) -> Dictionary:
	var parsed = _read_any(path)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _read_any(path: String):
	if not FileAccess.file_exists(path):
		push_error("Missing " + path)
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))

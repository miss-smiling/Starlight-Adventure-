extends Node

var professions: Array = []
var crew: Array = []
var by_id := {}
var crew_by_id := {}
var crew_by_profession := {}

func _ready() -> void:
	professions = _read("res://data/professions.json")
	crew = _read("res://data/crew.json")
	for item in professions:
		by_id[str(item.id)] = item
	for member in crew:
		crew_by_id[str(member.id)] = member
		crew_by_profession[str(member.profession)] = member


func ids() -> Array:
	var out: Array = []
	for item in professions:
		out.append(str(item.id))
	return out


func get_profession(id: String) -> Dictionary:
	return by_id.get(id, {})


func display_name(id: String) -> String:
	return str(get_profession(id).get("name", id))


func color_of(id: String) -> Color:
	var hex := str(get_profession(id).get("color", "#38c8ff"))
	return Color.html(hex)


func crew_for(profession_id: String) -> Dictionary:
	return crew_by_profession.get(profession_id, {})


func member(id: String) -> Dictionary:
	return crew_by_id.get(id, {})


func profession_of_crew(id: String) -> String:
	return str(member(id).get("profession", ""))


func others(player_profession: String) -> Array:
	var out: Array = []
	for member_data in crew:
		if str(member_data.profession) != player_profession:
			out.append(member_data)
	return out


func resolve_speaker(id: String) -> String:
	if id == "player":
		return "player"
	if profession_of_crew(id) != str(SaveManager.state.get("profession", "")):
		return id
	if id == "samira_shah":
		return "alex_rivera"
	return "samira_shah"


func _read(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Missing " + path)
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Bad JSON " + path)
		return []
	return parsed

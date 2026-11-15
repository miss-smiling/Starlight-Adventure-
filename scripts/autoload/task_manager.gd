extends Node

const SCRIPTS := {
	"astronaut": preload("res://scripts/ui/tasks/astronaut_task.gd"),
	"engineer": preload("res://scripts/ui/tasks/engineer_task.gd"),
	"physicist": preload("res://scripts/ui/tasks/physicist_task.gd"),
	"mathematician": preload("res://scripts/ui/tasks/mathematician_task.gd"),
	"biologist": preload("res://scripts/ui/tasks/biologist_task.gd"),
	"medical": preload("res://scripts/ui/tasks/medical_task.gd"),
	"comms": preload("res://scripts/ui/tasks/comms_task.gd"),
	"director": preload("res://scripts/ui/tasks/director_task.gd"),
}

# Shared puzzle-game modules. Every profession picks two of these (see
# data/puzzles.json); each module themes itself from its config.
const GAME_SCRIPTS := {
	"quiz": preload("res://scripts/ui/tasks/quiz_task.gd"),
	"matiks": preload("res://scripts/ui/tasks/matiks_task.gd"),
	"sudoku": preload("res://scripts/ui/tasks/sudoku_task.gd"),
	"pinpoint": preload("res://scripts/ui/tasks/pinpoint_task.gd"),
	"crossclimb": preload("res://scripts/ui/tasks/crossclimb_task.gd"),
	"tango": preload("res://scripts/ui/tasks/tango_task.gd"),
	"arcade": preload("res://scripts/ui/tasks/arcade_task.gd"),
}

var _puzzles: Dictionary = {}


func make(profession: String) -> Control:
	var script: Script = SCRIPTS.get(profession)
	if script == null:
		return Control.new()
	return script.new()


func make_game(type: String) -> Control:
	var script: Script = GAME_SCRIPTS.get(type)
	if script == null:
		return null
	return script.new()


# Puzzles for a profession: {"cross": {...}, "final": {...}} from
# data/puzzles.json. Cached; missing data returns {}.
func puzzle_config(profession: String, stage_key: String) -> Dictionary:
	if _puzzles.is_empty():
		var path := "res://data/puzzles.json"
		if FileAccess.file_exists(path):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
			if typeof(parsed) == TYPE_DICTIONARY:
				_puzzles = parsed
	var prof: Dictionary = _puzzles.get(profession, {})
	var stage: Dictionary = prof.get(stage_key, {})
	return stage if typeof(stage) == TYPE_DICTIONARY else {}

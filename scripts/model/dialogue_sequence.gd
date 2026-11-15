extends RefCounted

var lines: Array = []
var index := 0
var next_id := ""

func setup(data: Dictionary) -> void:
	lines = data.get("lines", [])
	index = 0
	next_id = str(data.get("next", ""))


func current() -> Dictionary:
	if index < 0 or index >= lines.size():
		return {}
	return lines[index]


func advance() -> String:
	index += 1
	if index >= lines.size():
		if next_id != "":
			return "goto"
		return "end"
	return "line"


func finished() -> bool:
	return index >= lines.size()

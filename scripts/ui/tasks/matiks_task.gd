extends "res://scripts/ui/tasks/task_base.gd"

# Matiks-style quick-math drill. Config may override:
# {"count": 5, "label": "fuel-burn arithmetic"} - otherwise five problems are
# generated fresh each shift. Wrong answers allow unlimited retries; each
# wrong try is one recorded mistake.

var problems: Array = []
var index := 0
var solved := 0

var progress: Label = null
var prompt_label: Label = null
var entry: LineEdit = null
var note: Label = null


func _build() -> void:
	build_frame(self)
	var cfg: Dictionary = config.get("puzzle", {})
	problems = cfg.get("problems", [])
	if problems.is_empty():
		problems = _generate(int(cfg.get("count", 5)))
	body.add_child(UIKit.banner("GOAL: solve %d quick figures. Wrong entries just ask you to retry - nothing locks you out." % problems.size(), Color("b08ef0")))
	var board := UIKit.game_panel(Color("b08ef0"))
	body.add_child(board)
	var console := VBoxContainer.new()
	console.add_theme_constant_override("separation", 10)
	board.add_child(console)
	progress = UIKit.heading("", 13, UIKit.ACCENT_2)
	console.add_child(progress)
	prompt_label = UIKit.heading("", 26, Color("b08ef0"))
	console.add_child(prompt_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	entry = LineEdit.new()
	entry.custom_minimum_size = Vector2(160, 46)
	entry.placeholder_text = "0"
	row.add_child(entry)
	row.add_child(UIKit.primary_button("COMMIT", _check))
	console.add_child(row)
	note = UIKit.wrapped("", 18, UIKit.DIM)
	body.add_child(note)
	_show()


func _generate(count: int) -> Array:
	var out: Array = []
	for i in count:
		var a := randi_range(6, 40)
		var b := randi_range(3, 19)
		match randi_range(0, 3):
			0: out.append({"q": "%d + %d" % [a, b], "answer": a + b})
			1: out.append({"q": "%d - %d" % [maxi(a, b), mini(a, b)], "answer": maxi(a, b) - mini(a, b)})
			2: out.append({"q": "%d x %d" % [mini(a, 12), mini(b, 9)], "answer": mini(a, 12) * mini(b, 9)})
			3:
				var s := a * 2
				out.append({"q": "half of %d" % s, "answer": a})
	return out


func _show() -> void:
	if index >= problems.size():
		return _finish()
	progress.text = "FIGURE %d / %d   -   %d solved" % [index + 1, problems.size(), solved]
	prompt_label.text = str(problems[index].q) + " = ?"
	entry.text = ""
	note.text = ""


func _check() -> void:
	var value := NumberGrader.parse(entry.text)
	if not value.ok:
		note.text = "Enter a number first."
		note.add_theme_color_override("font_color", UIKit.WARN)
		return
	if float(value.value) == float(problems[index].answer):
		solved += 1
		note.text = "Locked in."
		note.add_theme_color_override("font_color", UIKit.SUCCESS)
		index += 1
		_show()
	else:
		mistake("Math drill: wrong figure for %s" % str(problems[index].q))
		note.text = "Off by a bit - recheck and commit again."
		note.add_theme_color_override("font_color", UIKit.WARN)


func _finish() -> void:
	finish(true, {
		"decisions": [{"text": "Math drill: %d/%d figures locked" % [solved, problems.size()], "consequence": "Station figures confirmed.", "result": "pass"}],
		"science": "Fast, accurate arithmetic keeps systems balanced.",
	})


func tips() -> Array:
	return [
		"Type only the number - commas and spaces are stripped for you.",
		"A wrong commit just asks you to retry; nothing locks you out.",
		"SOLVE order does not matter - the console walks you through each figure.",
	]

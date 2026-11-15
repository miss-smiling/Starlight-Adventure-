extends "res://scripts/ui/tasks/task_base.gd"

# Power-grid tango (engineer): fill every cell ON/OFF with no three same
# cells in a row horizontally or vertically. Config: {"grid": ["11...", ...]}
# where 1 = fixed ON, 0 = fixed OFF, . = player cell. Missing data uses a
# built-in 5x5 board.

const SOLUTION := ["11010", "10101", "01011", "10100", "01101"]

var cells := {}
var fixed := {}
var values := {}
var note: Label = null


func _build() -> void:
	build_frame(self)
	var cfg: Dictionary = config.get("puzzle", {})
	var rows: Array = cfg.get("grid", SOLUTION)
	if rows.size() != 5:
		rows = SOLUTION
	body.add_child(UIKit.banner("GOAL: flip your cells ON or OFF so no three same cells line up in any row or column.", Color("ff7ab8")))
	body.add_child(UIKit.wrapped("Pink = ON, dark = OFF. Locked givens are dimmed. Red cells sit inside a forbidden run - flip one of them.", 18, UIKit.DIM))
	var board := UIKit.game_panel(Color("ff7ab8"))
	body.add_child(board)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	board.add_child(grid)
	for y in 5:
		for x in 5:
			var index := y * 5 + x
			var ch := str(rows[y]).substr(x, 1)
			var cell := UIKit.button("", Callable(), "bubble")
			cell.custom_minimum_size = Vector2(64, 64)
			if ch == "1" or ch == "0":
				fixed[index] = ch == "1"
				values[index] = ch == "1"
				cell.text = "ON" if ch == "1" else "OFF"
				cell.disabled = true
				cell.add_theme_stylebox_override("normal", UIKit._primary_style(Color("ff7ab8").darkened(0.22) if ch == "1" else UIKit.BG_SOFT, UIKit.PANEL_EDGE))
			else:
				values[index] = false
				cell.text = "OFF"
				cell.add_theme_stylebox_override("normal", cell_style(UIKit.BG, UIKit.PANEL_EDGE))
				cell.pressed.connect(_flip.bind(index, cell))
			cells[index] = cell
			grid.add_child(cell)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UIKit.primary_button("CHECK GRID", _check))
	body.add_child(row)
	note = UIKit.wrapped("", 18, UIKit.DIM)
	body.add_child(note)
	_tint()


func _flip(index: int, cell: Button) -> void:
	values[index] = not bool(values[index])
	cell.text = "ON" if values[index] else "OFF"
	note.text = ""
	_tint()


func _tint() -> void:
	for i in cells:
		var cell: Button = cells[i]
		if fixed.has(i):
			continue
		cell.remove_theme_stylebox_override("normal")
		if bool(values[i]):
			cell.add_theme_stylebox_override("normal", UIKit._primary_style(Color("ff7ab8").darkened(0.22), Color("ff7ab8")))
		else:
			cell.add_theme_stylebox_override("normal", cell_style(UIKit.BG, UIKit.PANEL_EDGE))


func _bad_runs() -> int:
	var bad := 0
	for y in 5:
		for x in 3:
			var a := bool(values[y * 5 + x])
			if a == bool(values[y * 5 + x + 1]) and a == bool(values[y * 5 + x + 2]):
				bad += 1
	for x in 5:
		for y in 3:
			var a := bool(values[y * 5 + x])
			if a == bool(values[(y + 1) * 5 + x]) and a == bool(values[(y + 2) * 5 + x]):
				bad += 1
	return bad


func _check() -> void:
	var bad := _bad_runs()
	for i in cells:
		var cell: Button = cells[i]
		if fixed.has(i):
			continue
		cell.remove_theme_stylebox_override("normal")
		if bool(values[i]):
			cell.add_theme_stylebox_override("normal", UIKit._primary_style(Color("ff7ab8").darkened(0.22), Color("ff7ab8")))
		elif _in_bad_run(i):
			cell.add_theme_stylebox_override("normal", UIKit._primary_style(UIKit.DANGER.darkened(0.6), UIKit.DANGER))
		else:
			cell.add_theme_stylebox_override("normal", cell_style(UIKit.BG, UIKit.PANEL_EDGE))
	if bad == 0:
		return _finish()
	mistake("Power grid: %d rule breaks" % bad)
	note.text = "%d three-in-a-row runs found - red cells are inside one." % bad
	note.add_theme_color_override("font_color", UIKit.WARN)


func _in_bad_run(index: int) -> bool:
	var y := index / 5
	var x := index % 5
	for offset: int in [-2, -1, 0]:
		var start: int = x + offset
		if start >= 0 and start <= 2:
			var a := bool(values[y * 5 + start])
			if a == bool(values[y * 5 + start + 1]) and a == bool(values[y * 5 + start + 2]):
				return true
	for offset: int in [-2, -1, 0]:
		var start_y: int = y + offset
		if start_y >= 0 and start_y <= 2:
			var a := bool(values[start_y * 5 + x])
			if a == bool(values[(start_y + 1) * 5 + x]) and a == bool(values[(start_y + 2) * 5 + x]):
				return true
	return false


func _finish() -> void:
	finish(true, {
		"decisions": [{"text": "Power grid balanced.", "consequence": "No three-in-a-row overload paths remain.", "result": "pass"}],
		"science": "Power routing: repeated states create overload runs.",
	})


func tips() -> Array:
	return [
		"Fixed cells are locked; only your cells can flip.",
		"Red cells sit inside a forbidden three-in-a-row run.",
		"There is only one rule - no three same cells in a line, rows or columns.",
	]

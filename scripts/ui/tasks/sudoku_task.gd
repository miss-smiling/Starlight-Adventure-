extends "res://scripts/ui/tasks/task_base.gd"

# Mini 4x4 Sudoku: every row, column and 2x2 box holds 1-4 exactly once.
# Config: {"puzzle": ["12..", "..3.", ...], "label": "..."} - '.' is empty.
# Click a cell to cycle its number; CHECK grades the board, wrong cells are
# flagged and each check with errors is one recorded mistake.

var cells := {}
var given := {}
var values := {}
var note: Label = null


func _build() -> void:
	build_frame(self)
	var cfg: Dictionary = config.get("puzzle", {})
	var rows: Array = cfg.get("puzzle", ["1234", "3412", "2143", "4321"])
	if rows.size() != 4:
		rows = ["1234", "3412", "2143", "4321"]
	body.add_child(UIKit.banner("GOAL: every row, column and 2x2 box needs 1-4 exactly once.", Color("ff9d4d")))
	body.add_child(UIKit.wrapped("Click a cell to cycle 1-4. Gold cells are locked givens; red means that number clashes with a twin. CHECK grades the board.", 18, UIKit.DIM))
	var board := UIKit.game_panel(Color("ff9d4d"))
	body.add_child(board)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	board.add_child(grid)
	for y in 4:
		for x in 4:
			var index := y * 4 + x
			var ch := str(rows[y]).substr(x, 1)
			var cell := UIKit.button("", Callable(), "bubble")
			cell.custom_minimum_size = Vector2(72, 72)
			if ch >= "1" and ch <= "4":
				given[index] = int(ch)
				values[index] = int(ch)
				cell.text = ch
				cell.disabled = true
				cell.add_theme_stylebox_override("normal", UIKit._primary_style(UIKit.PANEL_LIGHT, Color("ff9d4d")))
			else:
				cell.add_theme_stylebox_override("normal", cell_style(UIKit.BG, UIKit.PANEL_EDGE))
				cell.pressed.connect(_cycle.bind(index))
			cells[index] = cell
			grid.add_child(cell)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UIKit.primary_button("CHECK BOARD", _check))
	row.add_child(UIKit.button("CLEAR MY NUMBERS", _clear))
	body.add_child(row)
	note = UIKit.wrapped("", 18, UIKit.DIM)
	body.add_child(note)


func _cycle(index: int) -> void:
	var next := int(values.get(index, 0)) + 1
	if next > 4:
		next = 1
	values[index] = next
	var cell: Button = cells[index]
	cell.text = str(next)
	cell.add_theme_stylebox_override("normal", cell_style(UIKit.BG_SOFT, Color("ff9d4d")))
	note.text = ""


func _check() -> void:
	var wrong := 0
	for y in 4:
		for x in 4:
			var index := y * 4 + x
			var value := int(values.get(index, 0))
			if value == 0:
				wrong += 1
				continue
			for peer in _peers(index):
				if int(values.get(peer, 0)) == value:
					wrong += 1
					break
	for i in cells:
		var cell: Button = cells[i]
		if given.has(i):
			continue
		cell.remove_theme_stylebox_override("normal")
		if int(values.get(i, 0)) > 0 and _conflicts(i):
			cell.add_theme_stylebox_override("normal", UIKit._primary_style(UIKit.DANGER.darkened(0.6), UIKit.DANGER))
	if values.size() == 16 and wrong == 0:
		return _finish()
	mistake("Sudoku: board check found %d problems" % wrong)
	note.text = "%d conflicts - red cells clash with a twin in their row, column or box." % wrong
	note.add_theme_color_override("font_color", UIKit.WARN)


func _peers(index: int) -> Array:
	var out: Array = []
	var y := index / 4
	var x := index % 4
	for i in 16:
		if i == index:
			continue
		var py := i / 4
		var px := i % 4
		if py == y or px == x or (py / 2 == y / 2 and px / 2 == x / 2):
			out.append(i)
	return out


func _conflicts(index: int) -> bool:
	var value := int(values.get(index, 0))
	if value == 0:
		return false
	for peer in _peers(index):
		if int(values.get(peer, 0)) == value:
			return true
	return false


func _clear() -> void:
	for i in cells:
		if not given.has(i):
			values.erase(i)
			var cell: Button = cells[i]
			cell.text = ""
			cell.remove_theme_stylebox_override("normal")
	note.text = "Cleared. The fixed numbers stay."


func _finish() -> void:
	finish(true, {
		"decisions": [{"text": "Mini sudoku solved.", "consequence": "All sixteen slots consistent.", "result": "pass"}],
		"science": "Constraint grids: one rule broken anywhere breaks the whole board.",
	})


func tips() -> Array:
	return [
		"Cells with a fixed number are locked; everything else cycles 1-4.",
		"Red cells clash with a twin - look along the row, column and 2x2 box.",
		"CLEAR MY NUMBERS resets your picks without touching the locked cells.",
	]

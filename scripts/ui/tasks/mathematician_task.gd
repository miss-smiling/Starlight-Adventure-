extends "res://scripts/ui/tasks/task_base.gd"

# Mathematician duty: trajectory analysis worksheet. Given data panel, numeric
# solution, and an optional table pick. Pattern: figure.

var _status: Label = null


func _build() -> void:
	build_frame(self)
	_status = status_label()

	var given: Dictionary = config.get("given", {})
	if not given.is_empty():
		var given_panel := UIKit.panel()
		var given_box := VBoxContainer.new()
		given_box.add_theme_constant_override("separation", 4)
		given_panel.add_child(given_box)
		given_box.add_child(UIKit.tag("GIVEN DATA", UIKit.ACCENT_2))
		for key in given.keys():
			given_box.add_child(UIKit.kv_row(str(key).replace("_", " "), str(given[key]), UIKit.TEXT))
		body.add_child(given_panel)

	var entries: Array = []
	body.add_child(numeric_box(entries))

	var table: Dictionary = config.get("table", {})
	var table_choice := {"value": ""}
	if not table.is_empty():
		body.add_child(UIKit.heading("TABLE PICK", 10, UIKit.ACCENT))
		body.add_child(UIKit.wrapped(str(table.get("prompt", "")), 16, UIKit.TEXT))
		var columns: Array = table.get("columns", [])
		var table_panel := UIKit.panel()
		var table_box := VBoxContainer.new()
		table_box.add_theme_constant_override("separation", 6)
		table_panel.add_child(table_box)
		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 10)
		for column in columns:
			var header_label := UIKit.label(str(column), 15, UIKit.DIM)
			header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			header.add_child(header_label)
		table_box.add_child(header)
		table_box.add_child(HSeparator.new())
		var button_group := ButtonGroup.new()
		button_group.allow_unpress = false
		var table_rows: Array = table.get("rows", [])
		for table_row in table_rows:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			for i in table_row.cells.size():
				var cell := UIKit.label(str(table_row.cells[i]), 16)
				cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(cell)
			var pick := Button.new()
			pick.toggle_mode = true
			pick.button_group = button_group
			pick.text = "SELECT"
			pick.custom_minimum_size = Vector2(90, 38)
			pick.pressed.connect(func() -> void: table_choice["value"] = str(table_row.id))
			row.add_child(pick)
			table_box.add_child(row)
		body.add_child(table_panel)

	body.add_child(_status)
	body.add_child(UIKit.button("File the solution", func() -> void:
		if not table.is_empty() and str(table_choice["value"]) == "":
			_status.text = "Pick a row from the table first."
			return
		var scale := 2.0 if recovery_mode else 1.0
		var graded: Dictionary = NumberGrader.grade_parts(read_fields(entries), config.get("parts", []), scale)
		if not graded.ok:
			mistake(str(config.get("mistake", "A figure was wrong.")))
			_status.text = str(graded.reason)
			if mistakes.size() >= 5:
				finish(false)
			return
		if not table.is_empty() and str(table_choice["value"]) != str(table.get("answer", "")):
			mistake("Picked the wrong row of the table.")
			_status.text = failure_text()
			if mistakes.size() >= 5:
				finish(false)
			return
		finish(true)
	))


func tips() -> Array:
	return [
		"Read what the question asks before you compute - extra math wastes time.",
		"Check the unit on every number you type.",
		"If an answer is off by a factor of ten, re-check the formula order.",
		"Estimate first: a rough answer catches big slips before you commit.",
	]

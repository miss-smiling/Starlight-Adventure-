extends "res://scripts/ui/tasks/task_base.gd"

# Astronaut duties: EVA navigation map, launch sequence console, maneuver
# console. Patterns: route, switches, burn.

const RouteGrader = preload("res://scripts/model/route_grader.gd")
const DirectorGrader = preload("res://scripts/model/director_grader.gd")

const TILE_PLAIN := Color("182a4e")
const TILE_START := Color("2f8bff")
const TILE_GOAL := Color("4de8ff")
const TILE_HAZARD := Color("6b2a1e")
const TILE_PATH := Color("8a5a1c")

var _path: Array = []
var _path_label: Label = null
var _status: Label = null
var _tiles: Dictionary = {}
var _start: Array = []
var _goal: Array = []


func _build() -> void:
	build_frame(self)
	match str(config.get("pattern", "")):
		"route":
			_build_route()
		"switches":
			_build_switches()
		"burn":
			_build_burn()


# ---------------------------------------------------------------- route

func _build_route() -> void:
	var cols := int(config.get("cols", 8))
	var rows := int(config.get("rows", 6))
	var start: Array = config.get("start", [0, 5])
	var goal: Array = config.get("goal", [7, 0])
	_start = start
	_goal = goal
	var hazards: Array = config.get("hazards", [])
	var blocked := {}
	for hazard in hazards:
		blocked[RouteGrader.key_of(hazard)] = true

	_path = [RouteGrader.key_of(start)]
	_path_label = UIKit.label("PLANNED STEPS: 1", 16, UIKit.ACCENT_2)
	_status = status_label()

	body.add_child(_legend_row())

	var mapPanel := UIKit.panel()
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	mapPanel.add_child(grid)
	body.add_child(mapPanel)

	for y in rows:
		for x in cols:
			var cell := Vector2i(x, y)
			var key := RouteGrader.key_of([x, y])
			var text := ""
			var bg := TILE_PLAIN
			if key == RouteGrader.key_of(start):
				text = "S"
				bg = TILE_START
			elif key == RouteGrader.key_of(goal):
				text = "G"
				bg = TILE_GOAL
			elif blocked.has(key):
				text = "X"
				bg = TILE_HAZARD
			var tile := UIKit.tile(text, bg)
			tile.pressed.connect(_on_tile.bind(cell, key, blocked))
			_tiles[key] = tile
			grid.add_child(tile)

	body.add_child(_path_label)
	body.add_child(_status)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UIKit.button("Clear path", func() -> void:
		_path = [RouteGrader.key_of(_start)]
		_path_label.text = "PLANNED STEPS: 1"
		_status.text = ""
		_repaint_path()
	))
	row.add_child(UIKit.button("Confirm walk", func() -> void: _submit_route(start, goal, hazards)))
	body.add_child(row)


func _legend_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.add_child(UIKit.heading("EVA NAV", 11, UIKit.ACCENT))
	var legend := [
		["S  start", UIKit.ELECTRIC],
		["G  goal", UIKit.CYAN],
		["X  hazard", UIKit.DANGER],
		["gold  planned", UIKit.ACCENT],
	]
	for item in legend:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 6)
		pair.add_child(UIKit.lamp(item[1]))
		pair.add_child(UIKit.label(str(item[0]), 14, UIKit.DIM))
		row.add_child(pair)
	return row


func _set_tile_bg(tile: Button, bg: Color) -> void:
	var normal := tile.get_theme_stylebox("normal") as StyleBoxFlat
	if normal != null:
		normal.bg_color = bg
	var hover_style := tile.get_theme_stylebox("hover") as StyleBoxFlat
	if hover_style != null:
		hover_style.bg_color = bg.lightened(0.18)


func _repaint_path() -> void:
	for key in _tiles.keys():
		var tile: Button = _tiles[key]
		var bg := TILE_PLAIN
		if key == RouteGrader.key_of(_start):
			bg = TILE_START
		elif key == RouteGrader.key_of(_goal):
			bg = TILE_GOAL
		elif _path.has(str(key)):
			bg = TILE_PATH
		else:
			var blocked := false
			for hazard in config.get("hazards", []):
				if RouteGrader.key_of(hazard) == str(key):
					blocked = true
					break
			if blocked:
				bg = TILE_HAZARD
		_set_tile_bg(tile, bg)


func _on_tile(cell: Vector2i, key: String, blocked: Dictionary) -> void:
	var last: String = _path[_path.size() - 1]
	if key == last:
		if _path.size() > 1:
			_path.pop_back()
		_path_label.text = "PLANNED STEPS: %d" % _path.size()
		_repaint_path()
		_status.text = ""
		return
	if blocked.has(key):
		mistake(str(config.get("mistake", "Stepped onto a hazard tile.")))
		_status.text = "That tile is a hazard. Step back and go around."
		return
	var last_cell: PackedStringArray = last.split(",")
	if not RouteGrader.adjacent([int(last_cell[0]), int(last_cell[1])], [cell.x, cell.y]):
		_status.text = "Tiles must touch each other. Pick a neighbor of your last tile."
		return
	_path.append(key)
	_path_label.text = "PLANNED STEPS: %d" % _path.size()
	_status.text = ""
	_repaint_path()
	if key == RouteGrader.key_of(_goal):
		_status.text = "Goal reached. Confirm the walk to check it."


func _submit_route(start: Array, goal: Array, hazards: Array) -> void:
	var cells: Array = []
	for key in _path:
		var parts: PackedStringArray = str(key).split(",")
		cells.append([int(parts[0]), int(parts[1])])
	if RouteGrader.valid(cells, start, goal, hazards, int(config.get("cols", 8)), int(config.get("rows", 6))):
		finish(true)
	else:
		mistake(str(config.get("mistake", "Planned an invalid route.")))
		_status.text = failure_text()
		if mistakes.size() >= 5:
			finish(false, {"flags": {fail_flag(): true} if fail_flag() != "" else {}, "lasting": [fail_flag()] if fail_flag() != "" else []})


# ---------------------------------------------------------------- switches

func _build_switches() -> void:
	var steps: Array = config.get("steps", [])
	var order: Array = config.get("order", [])
	var total: int = order.size()
	_status = status_label()
	var next_index := {"i": 0}

	var seq_tag := UIKit.tag("SEQUENCE 0 / %d" % total, UIKit.ACCENT_2)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(UIKit.heading("LAUNCH SEQUENCE CONSOLE", 11, UIKit.ACCENT))
	var head_spacer := Control.new()
	head_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(head_spacer)
	head.add_child(seq_tag)
	body.add_child(head)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	for step in steps:
		var step_panel := UIKit.panel()
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lamp := UIKit.lamp(UIKit.DIM)
		row.add_child(lamp)
		row.add_child(UIKit.label(str(step.label), 16))
		var row_spacer := Control.new()
		row_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(row_spacer)
		var state_tag := UIKit.tag("PENDING", UIKit.DIM)
		row.add_child(state_tag)
		var set_button := UIKit.button("SET")
		set_button.pressed.connect(func() -> void:
			var i: int = next_index["i"]
			if i >= order.size():
				return
			if str(order[i]) == str(step.id):
				_set_lamp(lamp, UIKit.SUCCESS)
				state_tag = _replace_tag(row, state_tag, "SET", UIKit.SUCCESS)
				next_index["i"] = i + 1
				seq_tag = _replace_tag(head, seq_tag, "SEQUENCE %d / %d" % [int(next_index["i"]), total], UIKit.ACCENT_2)
				set_button.disabled = true
				_status.text = ""
				if next_index["i"] >= total:
					_status.text = "Sequence complete. Review the pad readings and make the call."
			else:
				mistake("Flipped switches out of order.")
				_status.text = "Wrong order. Follow the launch card from the top."
		)
		set_button.custom_minimum_size = Vector2(80, 38)
		row.add_child(set_button)
		step_panel.add_child(row)
		list.add_child(step_panel)
	body.add_child(list)

	var pad_reading: Array = config.get("abort", {}).get("readings", [])
	if not pad_reading.is_empty():
		body.add_child(UIKit.heading("PAD READINGS", 10, UIKit.ACCENT))
		for reading in pad_reading:
			body.add_child(UIKit.gauge(str(reading.label), float(reading.value), float(reading.lo), float(reading.hi), str(reading.unit), bool(reading.ok)))

	var abort: Dictionary = config.get("abort", {})
	body.add_child(UIKit.banner("GO / NO-GO DECISION", UIKit.DANGER))
	body.add_child(UIKit.wrapped(str(abort.get("rule", "")), 16, UIKit.TEXT))
	var decision := HBoxContainer.new()
	decision.add_theme_constant_override("separation", 14)
	var proceed := UIKit.button("PROCEED TO IGNITION", func() -> void: _judge_abort(false))
	proceed.custom_minimum_size = Vector2(220, 54)
	var abort_button := UIKit.button("ABORT THE LAUNCH", func() -> void: _judge_abort(true))
	abort_button.custom_minimum_size = Vector2(220, 54)
	decision.add_child(proceed)
	decision.add_child(abort_button)
	body.add_child(decision)
	body.add_child(_status)


func _replace_tag(parent: Control, old_tag: Control, text: String, color: Color) -> Control:
	var index: int = old_tag.get_index()
	parent.remove_child(old_tag)
	old_tag.queue_free()
	var new_tag := UIKit.tag(text, color)
	parent.add_child(new_tag)
	parent.move_child(new_tag, index)
	return new_tag


func _set_lamp(lamp: PanelContainer, color: Color) -> void:
	var style := lamp.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.bg_color = color


func _judge_abort(chosen_abort: bool) -> void:
	var abort: Dictionary = config.get("abort", {})
	var should := bool(abort.get("should_abort", false))
	if chosen_abort == should:
		finish(true)
	else:
		mistake("Made the wrong abort call.")
		_status.text = failure_text()
		if mistakes.size() >= 5:
			finish(false)


# ---------------------------------------------------------------- burn

func _build_burn() -> void:
	_status = status_label()
	var entries: Array = []
	body.add_child(numeric_box(entries))
	var timing: Dictionary = config.get("timing", {})
	var zone: Array = timing.get("zone", [0.45, 0.55])
	var speed := float(timing.get("speed", 0.8))

	body.add_child(UIKit.heading("MANEUVER CONSOLE", 11, UIKit.ACCENT))
	var readout := UIKit.label("BURN CLOCK MARKER: 0%", 18, UIKit.ACCENT_2)
	body.add_child(readout)
	body.add_child(UIKit.wrapped("Stop the burn clock when the marker is inside the cyan window.", 16, UIKit.DIM))

	var track := UIKit.timing_track(float(zone[0]), float(zone[1]), speed)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(track)

	var runner := Timer.new()
	runner.wait_time = 0.05
	runner.autostart = true
	add_child(runner)
	runner.timeout.connect(func() -> void:
		if track != null and is_instance_valid(track):
			readout.text = "BURN CLOCK MARKER: %d%%" % int(track.marker * 100.0)
	)

	track.locked_track.connect(func(_value: float, in_zone: bool) -> void:
		if in_zone:
			_status.text = "Timing good. Now confirm the numbers."
		else:
			mistake(str(config.get("mistake", "Burned outside the window.")))
			_status.text = "Missed the window. The clock reset - time it again."
			track.reset()
	)

	var stop_button := UIKit.button("STOP THE BURN CLOCK", func() -> void: track.stop())
	stop_button.custom_minimum_size = Vector2(0, 52)
	body.add_child(stop_button)

	var submit := UIKit.button("Confirm burn plan", func() -> void:
		if not bool(track.is_locked):
			_status.text = "Stop the burn clock first."
			return
		var values := read_fields(entries)
		var scale := 2.0 if recovery_mode else 1.0
		var graded: Dictionary = NumberGrader.grade_parts(values, config.get("parts", []), scale)
		if graded.ok:
			finish(true)
		else:
			mistake(str(config.get("mistake", "Entered a wrong burn figure.")))
			_status.text = str(graded.reason)
			if mistakes.size() >= 5:
				finish(false)
	)
	submit.custom_minimum_size = Vector2(0, 50)
	body.add_child(submit)
	body.add_child(_status)


func tips() -> Array:
	return [
		"Tiles must touch edge to edge - diagonal steps do not count.",
		"Red X tiles are hazards. One touch and the walk is over.",
		"The gold preview shows your planned route. Clear it if it looks wrong.",
		"Confirm only when the route runs from S to G with no gaps.",
	]

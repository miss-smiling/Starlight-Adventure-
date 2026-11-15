extends "res://scripts/ui/tasks/task_base.gd"

# Engineer duties: assembly bay with a live stack visualization, pad inspection
# gauges, diagnostic console. Patterns: build, inspect, repair.

var _status: Label = null


func _build() -> void:
	build_frame(self)
	match str(config.get("pattern", "")):
		"build":
			_build_assembly()
		"inspect":
			_build_inspect()
		"repair":
			_build_repair()


# ---------------------------------------------------------------- build

func _build_assembly() -> void:
	var parts: Array = config.get("parts", [])
	var order: Array = config.get("order", [])
	var installed: Array = []
	_status = status_label()

	body.add_child(UIKit.heading("ASSEMBLY BAY", 11, UIKit.ACCENT))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)

	# Left column: the live stack, bottom to top.
	var stack_panel := UIKit.panel()
	stack_panel.custom_minimum_size = Vector2(360, 0)
	var stack_box := VBoxContainer.new()
	stack_box.add_theme_constant_override("separation", 8)
	stack_panel.add_child(stack_box)
	var stack_title := HBoxContainer.new()
	stack_title.add_child(UIKit.tag("LIVE STACK", UIKit.ACCENT_2))
	stack_box.add_child(stack_title)
	var stack_slot := VBoxContainer.new()
	stack_slot.add_theme_constant_override("separation", 6)
	var empty_hint := UIKit.wrapped("Stack is empty. Install parts from the bottom of the vehicle upward.", 16, UIKit.DIM)
	stack_slot.add_child(empty_hint)
	stack_box.add_child(stack_slot)
	columns.add_child(stack_panel)

	# Right column: install controls.
	var install_panel := UIKit.panel()
	var install_box := VBoxContainer.new()
	install_box.add_theme_constant_override("separation", 8)
	install_panel.add_child(install_box)
	install_box.add_child(UIKit.tag("PARTS BIN", UIKit.ACCENT_2))
	for part in parts:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lamp := UIKit.lamp(UIKit.DIM)
		row.add_child(lamp)
		var install_button := UIKit.button("Install " + str(part.label), func() -> void:
			if installed.has(str(part.id)):
				return
			var expected: String = str(order[installed.size()])
			if str(part.id) == expected:
				installed.append(str(part.id))
				_recolor_lamp(lamp, UIKit.SUCCESS)
				_append_stack_cell(stack_slot, empty_hint, str(part.label), installed.size())
				_status.text = ""
				if installed.size() >= order.size():
					_status.text = "Stack complete. Check the gauges below and flag anything out of range."
			else:
				mistake("Installed stack out of order.")
				_status.text = str(config.get("malfunction", "That part goes in a different slot order."))
		)
		install_button.custom_minimum_size = Vector2(0, 44)
		row.add_child(install_button)
		install_box.add_child(row)
	columns.add_child(install_panel)
	body.add_child(columns)

	var gauges: Array = config.get("gauges", [])
	if not gauges.is_empty():
		body.add_child(UIKit.heading("GAUGE BOARD", 10, UIKit.ACCENT))
		var flagged := {}
		for gauge in gauges:
			var ok := bool(gauge.ok)
			var entry := HBoxContainer.new()
			entry.add_theme_constant_override("separation", 12)
			var gauge_view := UIKit.gauge(str(gauge.label), float(gauge.value), float(gauge.lo), float(gauge.hi), str(gauge.unit), ok)
			gauge_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			entry.add_child(gauge_view)
			var flag := CheckBox.new()
			flag.text = "FLAG"
			flag.toggled.connect(func(on: bool) -> void: flagged[str(gauge.id)] = on)
			entry.add_child(flag)
			body.add_child(entry)

		body.add_child(_status)
		body.add_child(UIKit.button("Confirm build", func() -> void:
			if installed.size() < order.size():
				_status.text = "The stack is not complete."
				return
			var bad: String = str(config.get("bad_gauge", ""))
			var flagged_bad := bool(flagged.get(bad, false))
			var extra_flags := 0
			for id in flagged.keys():
				if str(id) != bad and bool(flagged[id]):
					extra_flags += 1
			if flagged_bad and extra_flags == 0:
				finish(true)
			else:
				mistake("Misread the gauge board.")
				_status.text = failure_text()
				if mistakes.size() >= 5:
					finish(false)
		))


func _recolor_lamp(lamp: PanelContainer, color: Color) -> void:
	var style := lamp.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.bg_color = color


func _append_stack_cell(slot: VBoxContainer, placeholder: Label, part_label: String, position: int) -> void:
	if placeholder != null and is_instance_valid(placeholder):
		placeholder.queue_free()
	var cell := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UIKit.PANEL_LIGHT
	style.border_color = UIKit.ACCENT_2
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	cell.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var index := position
	row.add_child(UIKit.label(str(index), 14, UIKit.ACCENT_2))
	row.add_child(UIKit.label(part_label, 16, UIKit.TEXT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(UIKit.tag("INSTALLED", UIKit.SUCCESS))
	cell.add_child(row)
	slot.add_child(cell)


# ---------------------------------------------------------------- inspect

func _build_inspect() -> void:
	body.add_child(UIKit.banner(str(config.get("rule", "")), UIKit.ACCENT))
	var flagged := {}
	_status = status_label()
	for step in config.get("steps", []):
		var ok := bool(step.ok)
		var card := UIKit.panel()
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 6)
		card.add_child(card_box)
		card_box.add_child(UIKit.gauge(str(step.label), float(step.value), float(step.lo), float(step.hi), str(step.unit), ok))
		var flag := CheckBox.new()
		flag.text = "FLAG THIS CLAMP  -  outside limits"
		flag.toggled.connect(func(on: bool) -> void: flagged[str(step.id)] = on)
		card_box.add_child(flag)
		body.add_child(card)
	body.add_child(_status)
	body.add_child(UIKit.button("File inspection", func() -> void:
		var wrong := false
		for step in config.get("steps", []):
			var should: bool = config.get("must_flag", []).has(str(step.id))
			if bool(flagged.get(str(step.id), false)) != should:
				wrong = true
		if not wrong:
			finish(true)
		else:
			mistake(str(config.get("mistake", "Flagged the wrong clamps.")))
			_status.text = failure_text()
			if mistakes.size() >= 5:
				finish(false)
	))


# ---------------------------------------------------------------- repair

func _build_repair() -> void:
	body.add_child(UIKit.banner("SYMPTOM  -  " + str(config.get("symptom", "")), UIKit.DANGER))
	_status = status_label()
	for row_data in config.get("rows", []):
		var id := str(row_data.id)
		var card := UIKit.panel()
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 6)
		card.add_child(card_box)
		card_box.add_child(UIKit.label(str(row_data.component), 17, UIKit.TEXT))
		var clue := UIKit.wrapped("CLUE  -  " + str(row_data.clue), 15, UIKit.DIM)
		clue.visible = false
		card_box.add_child(clue)
		var pull := UIKit.button("Pull and replace this part", func() -> void:
			if id == str(config.get("answer", "")):
				finish(true)
			else:
				clue.visible = true
				mistake(str(config.get("mistake", "Replaced the wrong part.")))
				_status.text = str(row_data.clue) + " - that does not match the symptom."
				if mistakes.size() >= 5:
					finish(false)
		)
		pull.custom_minimum_size = Vector2(0, 44)
		card_box.add_child(pull)
		body.add_child(card)
	body.add_child(_status)


func tips() -> Array:
	return [
		"Install parts in checklist order - later parts bolt onto earlier ones.",
		"Compare every gauge reading to the limits printed on its card.",
		"Flag a gauge only when its number sits outside the safe range.",
		"Round only where the briefing says to. The console wants clean numbers.",
	]

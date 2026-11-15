extends "res://scripts/ui/tasks/task_base.gd"

# Medical duty: sickbay monitor wall. Every patient carries a live ECG strip
# that stays dark ("no signal") until you run a scan - then the trace animates
# and immediately reads calm-cyan or worried-gold, with the numbers underneath.
# Scan everyone before treating anyone, then pick the treatment for the
# abnormal case. Pattern: triage.

var _status: Label = null
var _scanned: Array = []


func _build() -> void:
	build_frame(self)
	_status = status_label()
	_scanned = []
	var patients: Array = config.get("patients", [])

	var instruction: String = "Scan every patient before you treat anyone." if bool(config.get("scan_first", true)) else "Assess the crew."
	body.add_child(UIKit.banner(instruction, UIKit.ACCENT))

	body.add_child(UIKit.heading("SICKBAY MONITOR WALL", 11, UIKit.ACCENT_2))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)

	for patient in patients:
		var id := str(patient.id)
		var abnormal := bool(patient.get("abnormal", false))
		var card := UIKit.panel()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 6)
		card.add_child(card_box)

		# Card header: name + live status lamp + tag.
		var card_head := HBoxContainer.new()
		card_head.add_theme_constant_override("separation", 8)
		var head_spacer := Control.new()
		head_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var state_lamp := UIKit.lamp(UIKit.DIM)
		var state_tag := UIKit.tag("NO SIGNAL", UIKit.DIM)
		card_head.add_child(UIKit.label(str(patient.name), 20, UIKit.TEXT))
		card_head.add_child(head_spacer)
		card_head.add_child(state_lamp)
		card_head.add_child(state_tag)
		card_box.add_child(card_head)

		# Live ECG strip - the heart of the monitor.
		var trace := UIKit.pulse_trace(abnormal)
		trace.custom_minimum_size = Vector2(0, 64)
		trace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var trace_frame := PanelContainer.new()
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color("091228")
		frame_style.border_color = UIKit.PANEL_EDGE
		frame_style.set_border_width_all(1)
		frame_style.set_corner_radius_all(0)
		frame_style.set_content_margin_all(4)
		trace_frame.add_theme_stylebox_override("panel", frame_style)
		trace_frame.add_child(trace)
		card_box.add_child(trace_frame)

		# Case note - visible before scanning as the admission complaint.
		card_box.add_child(UIKit.wrapped(str(patient.get("note", "")), 17, UIKit.TEXT if abnormal else UIKit.DIM))

		# Numeric vitals - only revealed by the scanner.
		var vitals: Dictionary = patient.get("vitals", {})
		var vitals_box := VBoxContainer.new()
		vitals_box.visible = false
		vitals_box.add_theme_constant_override("separation", 4)
		for key in vitals.keys():
			var value_color := UIKit.TEXT
			var key_low := str(key).to_lower()
			if abnormal and (key_low.contains("rate") or key_low.contains("temp")):
				value_color = UIKit.ACCENT
			vitals_box.add_child(UIKit.kv_row(str(key).replace("_", " ").capitalize(), str(vitals[key]), value_color))
		card_box.add_child(vitals_box)

		var scan_button := UIKit.button("Run scan - " + str(patient.name), func() -> void:
			var already := _scanned.has(id)
			if not already:
				_scanned.append(id)
				_set_lamp(state_lamp, UIKit.ACCENT if abnormal else UIKit.SUCCESS)
				state_tag = _replace_tag(card_head, state_tag, "SCANNED", UIKit.ACCENT if abnormal else UIKit.SUCCESS)
				_status.text = "%d of %d patients scanned." % [_scanned.size(), patients.size()]
			trace.set_active(true)
			vitals_box.visible = true
			if _scanned.size() >= patients.size() and patients.size() > 0:
				_status.text = "All scans complete. The gold trace is the one that needs help - choose the treatment."
		)
		scan_button.custom_minimum_size = Vector2(0, 40)
		card_box.add_child(scan_button)
		grid.add_child(card)

	body.add_child(UIKit.heading("TREATMENT ORDERS", 11, UIKit.ACCENT))
	var actions: Array = config.get("actions", [])
	for action in actions:
		var id := str(action.id)
		var action_button := UIKit.button(str(action.label), func() -> void: _treat(id, str(action.label)))
		action_button.custom_minimum_size = Vector2(0, 50)
		body.add_child(action_button)
	body.add_child(_status)


func _treat(id: String, label_text: String) -> void:
	if _scanned.size() < config.get("patients", []).size():
		mistake("Treated before completing the vitals scan.")
		_status.text = failure_text()
		if mistakes.size() >= 5:
			finish(false)
		return
	var correct := false
	for action in config.get("actions", []):
		if str(action.id) == id:
			correct = bool(action.correct)
	if correct:
		finish(true)
	else:
		mistake("Chose the wrong treatment (%s)." % label_text)
		_status.text = failure_text()
		if mistakes.size() >= 5:
			finish(false)


func _set_lamp(lamp: PanelContainer, color: Color) -> void:
	var style := lamp.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.bg_color = color


func _replace_tag(parent: Control, old_tag: Control, text: String, color: Color) -> Control:
	var index: int = old_tag.get_index()
	parent.remove_child(old_tag)
	old_tag.queue_free()
	var new_tag := UIKit.tag(text, color)
	parent.add_child(new_tag)
	parent.move_child(new_tag, index)
	return new_tag


func tips() -> Array:
	return [
		"A flat strip marked NO SIGNAL means that crew member is not scanned yet.",
		"An irregular gold trace is urgent - scan that patient first.",
		"Compare all three sets of vitals before you order treatment.",
		"Pick the gentlest treatment that answers the worst symptom.",
	]

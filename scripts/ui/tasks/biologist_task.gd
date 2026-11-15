extends "res://scripts/ui/tasks/task_base.gd"

# Biologist duty: life-science lab bench with an ordered procedure checklist,
# microscope viewer and log-entry conclusion. Contamination is recorded as a
# lasting flag when the run is confirmed. Pattern: procedure.

var _status: Label = null
var _step_index := 0
var _sterilized := false
var _recorded_early := false
var _sample_phase = false


func _build() -> void:
	build_frame(self)
	_status = status_label()
	_step_index = 0
	_sterilized = false
	_recorded_early = false
	_sample_phase = false

	var order: Array = config.get("order", [])
	var steps: Array = config.get("steps", [])

	body.add_child(UIKit.heading("PROCEDURE CARD  -  complete in order", 11, UIKit.ACCENT))
	var progress := UIKit.progress_bar(0.0, float(max(1, steps.size())), UIKit.ACCENT_2)
	body.add_child(progress)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	var lamps := {}
	for i in steps.size():
		var step: Dictionary = steps[i]
		var step_panel := UIKit.panel()
		var row_inner := HBoxContainer.new()
		row_inner.add_theme_constant_override("separation", 10)
		step_panel.add_child(row_inner)
		row_inner.add_child(UIKit.tag("STEP %d/%d" % [i + 1, steps.size()], UIKit.DIM))
		row_inner.add_child(UIKit.label(str(step.label), 16))
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_inner.add_child(spacer)
		var lamp := UIKit.lamp(UIKit.DIM)
		row_inner.add_child(lamp)
		var do_button := UIKit.button("DO", func() -> void:
			_do_step(str(step.id), str(step.label), order, lamps)
			progress.value = float(_step_index)
		)
		do_button.custom_minimum_size = Vector2(70, 40)
		row_inner.add_child(do_button)
		lamps[str(step.id)] = lamp
		list.add_child(step_panel)
	body.add_child(list)

	body.add_child(_status)
	body.add_child(UIKit.button("Confirm the run", func() -> void: _confirm()))


func _do_step(id: String, label_text: String, order: Array, lamps: Dictionary) -> void:
	var expected: String = str(order[_step_index]) if _step_index < order.size() else ""
	if id != expected:
		mistake("Did the procedure steps out of order.")
		_status.text = "Wrong order. %s is not next on the card." % label_text
		return
	if id == "record" and not _sterilized:
		_recorded_early = true
		mistake("Recorded a sample before sterilizing the tools.")
		_status.text = "Contamination risk! The note cannot be undone - re-sterilize and recollect."
	if id == "sterilize":
		_sterilized = true
	_set_lamp(lamps[id], UIKit.SUCCESS)
	_step_index += 1
	_status.text = ""


func _confirm() -> void:
	if _step_index < config.get("order", []).size():
		_status.text = "The procedure card is not finished."
		return
	_pick_sample()


func _pick_sample() -> void:
	if _sample_phase:
		return
	_sample_phase = true
	var viewer := UIKit.panel()
	var viewer_box := VBoxContainer.new()
	viewer_box.add_theme_constant_override("separation", 8)
	viewer.add_child(viewer_box)
	viewer_box.add_child(UIKit.tag("MICROSCOPE VIEWER", UIKit.ACCENT_2))
	viewer_box.add_child(UIKit.wrapped(str(config.get("question", "")), 17, UIKit.ACCENT))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	var samples: Array = config.get("samples", [])
	for sample in samples:
		var sample_button := UIKit.tile("%s\n%s" % [str(sample.label), str(sample.view)], UIKit.PANEL_LIGHT, func() -> void:
			if _sample_phase != "judging":
				return
			_sample_phase = "judged"
			_judge_sample(str(sample.id), str(config.get("answer", "")))
		)
		sample_button.custom_minimum_size = Vector2(150, 84)
		grid.add_child(sample_button)
	viewer_box.add_child(grid)
	body.add_child(viewer)
	_sample_phase = "judging"


func _judge_sample(chosen: String, correct: String) -> void:
	if chosen != correct:
		mistake("Picked the wrong microscope sample.")
		_status.text = failure_text()
		if mistakes.size() >= 5:
			finish(false)
		return
	body.add_child(UIKit.heading("LOG ENTRY  -  choose how to record the sample", 11, UIKit.ACCENT))
	var conclusions: Array = config.get("conclusions", [])
	for conclusion in conclusions:
		var id := str(conclusion.id)
		body.add_child(UIKit.button(str(conclusion.text), func() -> void:
			if bool(conclusion.ok):
				var flags := {}
				var lasting: Array = []
				if _recorded_early:
					flags["contamination_noted"] = true
					lasting.append("contamination_noted")
				finish(true, {"flags": flags, "lasting": lasting})
			else:
				mistake("Logged the wrong conclusion.")
				_status.text = failure_text()
				if mistakes.size() >= 5:
					finish(false)
		))


func _set_lamp(lamp: PanelContainer, color: Color) -> void:
	var style := lamp.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.bg_color = color


func tips() -> Array:
	return [
		"Sterilize before anything touches the bench - it is always step one.",
		"Work the checklist strictly in order, even when an assistant offers shortcuts.",
		"Match the microscope view to the ID card before you log the sample.",
		"A swapped or skipped step shows up at the end. Retrace, do not guess.",
	]

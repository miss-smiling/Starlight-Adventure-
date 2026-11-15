extends "res://scripts/ui/tasks/task_base.gd"

# Physicist duties: precision measurements with a timing shutter, a verdict
# call, and an optional AI suggestion that must be verified.
# Pattern: measure.

const TwistGrader = preload("res://scripts/model/twist_grader.gd")

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

	var bar: Dictionary = config.get("bar", {})
	if not bar.is_empty():
		_build_bar(bar)

	var verdict: Dictionary = config.get("verdict", {})
	var verdict_choice := {"value": ""}
	if not verdict.is_empty():
		body.add_child(UIKit.heading("VERDICT", 10, UIKit.ACCENT))
		body.add_child(UIKit.wrapped(str(verdict.get("prompt", "")), 16, UIKit.TEXT))
		var verdict_buttons: Array = []
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		for option in verdict.get("options", []):
			var value := str(option)
			var button := UIKit.button(value)
			button.pressed.connect(func() -> void:
				verdict_choice["value"] = value
				_status.text = "Verdict: " + value
				for other in verdict_buttons:
					if other != null and is_instance_valid(other) and other != button:
						var style := other.get_theme_stylebox("normal") as StyleBoxFlat
						if style != null:
							style.bg_color = UIKit.PANEL_LIGHT
				var chosen_style := button.get_theme_stylebox("normal") as StyleBoxFlat
				if chosen_style != null:
					chosen_style.bg_color = UIKit.ACCENT.darkened(0.25)
			)
			verdict_buttons.append(button)
			row.add_child(button)
		body.add_child(row)

	var ai: Dictionary = config.get("ai", {})
	if not ai.is_empty():
		var ai_panel := PanelContainer.new()
		var ai_style := StyleBoxFlat.new()
		ai_style.bg_color = UIKit.BG_SOFT
		ai_style.border_color = UIKit.ACCENT_2
		ai_style.set_border_width_all(1)
		ai_style.border_width_left = 5
		ai_style.set_corner_radius_all(8)
		ai_style.set_content_margin_all(12)
		ai_panel.add_theme_stylebox_override("panel", ai_style)
		var ai_box := VBoxContainer.new()
		ai_box.add_theme_constant_override("separation", 8)
		ai_panel.add_child(ai_box)
		var ai_head := HBoxContainer.new()
		ai_head.add_theme_constant_override("separation", 8)
		ai_head.add_child(UIKit.tag("AUTO-ADVISOR", UIKit.ACCENT_2))
		ai_head.add_child(UIKit.label("unverified suggestion", 13, UIKit.DIM))
		ai_box.add_child(ai_head)
		ai_box.add_child(UIKit.wrapped(str(ai.get("says", "")), 16, UIKit.TEXT))
		var ai_row := HBoxContainer.new()
		ai_row.add_theme_constant_override("separation", 10)
		ai_row.add_child(UIKit.button("Verify and accept", func() -> void: _judge_ai("accept", ai)))
		ai_row.add_child(UIKit.button("Reject the suggestion", func() -> void: _judge_ai("reject", ai)))
		ai_box.add_child(ai_row)
		body.add_child(ai_panel)

	body.add_child(_status)
	body.add_child(UIKit.button("Submit measurements", func() -> void:
		if not verdict.is_empty() and str(verdict_choice["value"]) == "":
			_status.text = "Give a verdict first."
			return
		var scale := 2.0 if recovery_mode else 1.0
		var graded: Dictionary = NumberGrader.grade_parts(read_fields(entries), config.get("parts", []), scale)
		if not graded.ok:
			mistake(str(config.get("mistake", "A measurement was wrong.")))
			_status.text = str(graded.reason)
			if mistakes.size() >= 5:
				finish(false)
			return
		if not verdict.is_empty() and not TwistGrader.choice_ok(str(verdict_choice["value"]), str(verdict.get("answer", ""))):
			mistake("Gave the wrong verdict.")
			_status.text = failure_text()
			if mistakes.size() >= 5:
				finish(false)
			return
		finish(true)
	))


func _judge_ai(choice: String, ai: Dictionary) -> void:
	if TwistGrader.bad_ai(choice) == (str(ai.get("answer", "reject")) == "reject"):
		var flags := {}
		if choice == "reject":
			flags[str(ai.get("flag", "ai_rejected"))] = true
		finish(true, {"flags": flags, "lasting": [str(ai.get("flag", "ai_rejected"))] if choice == "reject" else []})
	else:
		mistake("Trusted the AI without checking it." if choice == "accept" else "Rejected a correct AI suggestion.")
		_status.text = failure_text()
		if mistakes.size() >= 5:
			finish(false)


func _build_bar(bar: Dictionary) -> void:
	var zone: Array = bar.get("zone", [0.42, 0.58])
	var speed := float(bar.get("speed", 0.9))
	var readout := UIKit.label("SHUTTER MARKER: --", 16, UIKit.ACCENT_2)
	var zone_text := "Stop the shutter when the marker crosses the cyan window."
	body.add_child(UIKit.heading("TIMING SHUTTER", 11, UIKit.ACCENT))
	body.add_child(UIKit.wrapped(zone_text, 15, UIKit.DIM))
	body.add_child(readout)

	var track := UIKit.timing_track(float(zone[0]), float(zone[1]), speed)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(track)

	var runner := Timer.new()
	runner.wait_time = 0.05
	runner.autostart = true
	add_child(runner)
	runner.timeout.connect(func() -> void:
		if is_instance_valid(track):
			readout.text = "SHUTTER MARKER: %d%%" % int(track.marker * 100.0)
	)

	track.locked_track.connect(func(_value: float, in_zone: bool) -> void:
		if in_zone:
			_status.text = "Shutter timing good."
		else:
			mistake("Stopped the timing bar outside the zone.")
			_status.text = "Outside the window. The shutter reset - time it again."
			track.reset()
	)

	var stop := UIKit.button("STOP THE SHUTTER", func() -> void: track.stop())
	stop.custom_minimum_size = Vector2(0, 48)
	body.add_child(stop)


func tips() -> Array:
	return [
		"Use the constants given in the briefing, not values from memory.",
		"Write the formula, substitute the numbers, then compute step by step.",
		"Stop the timing bar inside the green zone - fast hands, calm timing.",
		"Keep one decimal unless the question says otherwise.",
	]

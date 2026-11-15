extends "res://scripts/ui/tasks/task_base.gd"

# Flight Director duties: alert board with countdown urgency bars and specialist
# assignment, then a go/no-go decision. Patterns: priority, decision.

const DirectorGrader = preload("res://scripts/model/director_grader.gd")
const TwistGrader = preload("res://scripts/model/twist_grader.gd")

var _status: Label = null


func _build() -> void:
	build_frame(self)
	_status = status_label()
	match str(config.get("pattern", "")):
		"priority":
			_build_priority()
		"decision":
			_build_decision()


# ---------------------------------------------------------------- priority

func _build_priority() -> void:
	var events: Array = config.get("events", [])
	var seconds_total := float(config.get("seconds_total", 45))
	var remaining := {}
	for event in events:
		remaining[str(event.id)] = float(event.get("seconds", seconds_total))

	body.add_child(UIKit.banner("ALERT BOARD  -  safety outranks mission, mission outranks science", UIKit.ACCENT))
	_status.text = "Clear the most life-critical alert first."

	var clock_label := UIKit.label("SHIFT CLOCK: %ds" % int(seconds_total), 16, UIKit.DANGER)
	body.add_child(clock_label)

	var done: Array = []
	var finished := {"flag": false}
	var assignment_phase := {"flag": false}
	var rows := {}

	for event in events:
		var id := str(event.id)
		var card := UIKit.panel()
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 6)
		card.add_child(card_box)

		var card_head := HBoxContainer.new()
		var head_spacer := Control.new()
		head_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var state_tag := UIKit.tag("OPEN", UIKit.WARN)
		var handle := UIKit.button("HANDLE ALERT")
		card_head.add_child(UIKit.label(str(event.label), 17))
		card_head.add_child(head_spacer)
		card_head.add_child(state_tag)
		card_box.add_child(card_head)

		var urgency := UIKit.progress_bar(1.0, 1.0, UIKit.WARN)
		var seconds_tag := UIKit.tag("%ds" % int(event.seconds), UIKit.WARN)
		var meter_row := HBoxContainer.new()
		meter_row.add_theme_constant_override("separation", 10)
		var meter_label := UIKit.label("URGENCY", 12, UIKit.DIM)
		var urgency_box := VBoxContainer.new()
		urgency_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		urgency_box.add_child(urgency)
		meter_row.add_child(meter_label)
		meter_row.add_child(urgency_box)
		meter_row.add_child(seconds_tag)
		card_box.add_child(meter_row)
		handle.pressed.connect(func() -> void:
			if bool(finished.flag) or bool(assignment_phase.flag):
				return
			var verdict: String = DirectorGrader.click(events, done, id)
			if verdict == "ok":
				done.append(id)
				handle.disabled = true
				_set_tag(card_head, state_tag, "HANDLED", UIKit.SUCCESS)
				_status.text = "Handled. %d alerts left." % (events.size() - done.size())
				if done.size() >= events.size():
					assignment_phase["flag"] = true
					_status.text = "All alerts handled. Now assign a specialist to each."
					_build_assignments(events, finished)
			elif verdict == "done":
				assignment_phase["flag"] = true
				_build_assignments(events, finished)
			else:
				mistake(str(config.get("mistake", "Answered a lower priority alert first.")))
				_status.text = failure_text()
		)
		handle.custom_minimum_size = Vector2(0, 44)
		card_box.add_child(handle)
		rows[id] = {"urgency": urgency, "seconds_tag": seconds_tag, "button": handle, "max": float(event.seconds)}
		body.add_child(card)
	body.add_child(_status)

	var runner := Timer.new()
	runner.wait_time = 1.0
	runner.autostart = true
	add_child(runner)
	runner.timeout.connect(func() -> void:
		if bool(finished.flag) or bool(assignment_phase.flag) or not is_visible_in_tree():
			return
		for event in events:
			var id := str(event.id)
			remaining[id] = float(remaining.get(id, 0.0)) - 1.0
			var row_data: Dictionary = rows[id]
			var frac := clampf(float(remaining[id]) / maxf(1.0, float(row_data["max"])), 0.0, 1.0)
			var urgency: ProgressBar = row_data["urgency"]
			urgency.value = frac
			var color := UIKit.WARN if frac > 0.34 else UIKit.DANGER
			urgency.add_theme_stylebox_override("fill", _fill(color))
			var tag: Control = row_data["seconds_tag"]
			if tag != null and is_instance_valid(tag) and tag.get_parent() != null:
				row_data["seconds_tag"] = _set_tag(tag.get_parent(), tag, "%ds" % max(0, int(remaining[id])), UIKit.WARN if frac > 0.34 else UIKit.DANGER)
		clock_label.text = "SHIFT CLOCK: %ds" % max(0, int(seconds_total))
		seconds_total = seconds_total - 1.0
		if DirectorGrader.expired(events, done, remaining):
			finished["flag"] = true
			runner.stop()
			mistake("Let a life-safety alert expire.")
			var flags := {}
			var lasting: Array = []
			var fail := fail_flag()
			if fail != "":
				flags[fail] = true
				lasting.append(fail)
			finish(false, {"flags": flags, "lasting": lasting})
	)


func _build_assignments(events: Array, finished: Dictionary) -> void:
	if bool(finished.flag):
		return
	body.add_child(UIKit.divider())
	body.add_child(UIKit.heading("SPECIALIST ASSIGNMENT", 10, UIKit.ACCENT))
	body.add_child(UIKit.wrapped("Assign the right specialist to each alert, then file the response plan.", 16, UIKit.DIM))
	var chosen := {}
	for event in events:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(UIKit.wrapped(str(event.label) + "  ->", 16))
		var pick := OptionButton.new()
		var options: Array = ["astronaut", "engineer", "physicist", "mathematician", "biologist", "medical", "comms", "director"]
		for option in options:
			pick.add_item(ProfessionManager.display_name(str(option)))
			pick.set_item_metadata(pick.item_count - 1, option)
		pick.selected = -1
		pick.item_selected.connect(func(_index: int) -> void: chosen[str(event.id)] = str(pick.get_selected_metadata()))
		pick.custom_minimum_size = Vector2(220, 40)
		row.add_child(pick)
		body.add_child(row)
	body.add_child(UIKit.button("File the response plan", func() -> void:
		var wrong := false
		for event in events:
			if str(chosen.get(str(event.id), "")) != str(event.get("needs", "")):
				wrong = true
		if not wrong:
			finished["flag"] = true
			finish(true)
		else:
			mistake("Assigned the wrong specialist to an alert.")
			_status.text = failure_text()
			if mistakes.size() >= 5:
				finished["flag"] = true
				finish(false)
	))


# ---------------------------------------------------------------- decision

func _build_decision() -> void:
	var decision_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UIKit.BG_SOFT
	style.border_color = UIKit.ACCENT
	style.set_border_width_all(1)
	style.border_width_left = 6
	style.set_corner_radius_all(0)
	style.set_content_margin_all(14)
	decision_panel.add_theme_stylebox_override("panel", style)
	var decision_box := VBoxContainer.new()
	decision_box.add_theme_constant_override("separation", 8)
	decision_panel.add_child(decision_box)
	decision_box.add_child(UIKit.tag("GO / NO-GO", UIKit.ACCENT))
	decision_box.add_child(UIKit.wrapped(str(config.get("prompt", "")), 19, UIKit.TEXT))
	body.add_child(decision_panel)
	_status = status_label()
	var answered := {"flag": false}
	for choice in config.get("choices", []):
		var id := str(choice.id)
		var choice_button := UIKit.button(str(choice.text), func() -> void:
			if bool(answered.flag):
				return
			answered["flag"] = true
			var decision := {"text": str(choice.text), "consequence": str(choice.get("consequence", "")), "result": str(choice.get("result", "fail"))}
			var flags: Dictionary = choice.get("flags", {})
			var lasting: Array = choice.get("lasting", [])
			if str(choice.get("result", "")) == "fail":
				finish(false, {"decisions": [decision], "flags": flags, "lasting": lasting, "warning": failure_text(), "emergency_id": emergency_id()})
			else:
				finish(true, {"decisions": [decision], "flags": flags, "lasting": lasting})
		)
		choice_button.custom_minimum_size = Vector2(0, 54)
		body.add_child(choice_button)
	body.add_child(_status)


# ---------------------------------------------------------------- helpers

func _fill(color: Color) -> StyleBoxFlat:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(0)
	return fill


func _set_lamp(tag_node: Control, color: Color) -> void:
	var style := tag_node.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.bg_color = color.darkened(0.72)
		style.border_color = color


func _set_tag(parent: Control, old_tag: Control, text: String, color: Color) -> Control:
	var index: int = old_tag.get_index()
	parent.remove_child(old_tag)
	old_tag.queue_free()
	var new_tag := UIKit.tag(text, color)
	parent.add_child(new_tag)
	parent.move_child(new_tag, index)
	return new_tag


func tips() -> Array:
	return [
		"Protect people first, property second, schedule last.",
		"Match each alert to the specialist trained for it.",
		"Read the urgency tag before you commit an assignment.",
		"One responder per alert - do not double-book a specialist.",
	]

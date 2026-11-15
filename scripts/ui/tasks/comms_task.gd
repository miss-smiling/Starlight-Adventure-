extends "res://scripts/ui/tasks/task_base.gd"

# Comms duties: radio room frequency lock with live interference scope, net
# status board, transmission composer. Patterns: tune, channels, link.

const CommsGrader = preload("res://scripts/model/comms_grader.gd")

var _status: Label = null


func _build() -> void:
	build_frame(self)
	_status = status_label()
	match str(config.get("pattern", "")):
		"tune":
			_build_tune()
		"channels":
			_build_channels()
		"link":
			_build_link()


# ---------------------------------------------------------------- tune

func _build_tune() -> void:
	var frequency: Dictionary = config.get("frequency", {})
	var target := float(frequency.get("target", 437.5))
	if recovery_mode:
		target = float(config.get("backup_frequency", target))
	var unit := str(frequency.get("unit", "MHz"))
	var band_note := "  (backup band - recover the signal)" if recovery_mode else ""
	body.add_child(UIKit.heading("RADIO ROOM", 11, UIKit.ACCENT))
	body.add_child(UIKit.wrapped("Lock onto %.1f %s%s." % [target, unit, band_note], 16, UIKit.ACCENT_2))

	var scope := UIKit.signal_scope()
	scope.custom_minimum_size = Vector2(0, 112)
	scope.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_interference_initial(scope, target, frequency)
	body.add_child(scope)

	var slider := HSlider.new()
	slider.min_value = float(frequency.get("min", 400.0))
	slider.max_value = float(frequency.get("max", 460.0))
	slider.step = float(frequency.get("step", 0.5))
	slider.value = slider.min_value
	slider.custom_minimum_size = Vector2(0, 40)
	body.add_child(slider)

	var readout = UIKit.tag("%.1f %s" % [slider.value, unit], UIKit.ACCENT_2)
	var readout_row := HBoxContainer.new()
	var readout_spacer := Control.new()
	readout_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	readout_row.add_child(readout_spacer)
	readout_row.add_child(readout)
	body.add_child(readout_row)

	slider.value_changed.connect(func(value: float) -> void:
		readout = _replace_tag(readout_row, readout, "%.1f %s" % [value, unit], UIKit.ACCENT_2)
		var span := maxf(1.0, float(frequency.get("max", 460.0)) - float(frequency.get("min", 400.0)))
		scope.set_interference(clampf(absf(value - target) / span, 0.03, 1.0))
	)

	var interference: Dictionary = config.get("interference", {})
	var filter_choice := {"value": ""}
	if not interference.is_empty():
		body.add_child(UIKit.heading("INTERFERENCE FILTER", 10, UIKit.ACCENT))
		var filter_buttons: Array = []
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		for option in interference.get("options", []):
			var value := str(option)
			var button := UIKit.button(value)
			button.pressed.connect(func() -> void:
				filter_choice["value"] = value
				for other in filter_buttons:
					if other != null and is_instance_valid(other):
						var style := other.get_theme_stylebox("normal") as StyleBoxFlat
						if style != null:
							style.bg_color = UIKit.ACCENT if other == button else UIKit.PANEL_LIGHT
			)
			filter_buttons.append(button)
			row.add_child(button)
		body.add_child(row)

	var cipher: Dictionary = config.get("cipher", {})
	var code_field := LineEdit.new()
	code_field.placeholder_text = "decoded word"
	code_field.custom_minimum_size = Vector2(220, 42)
	if not cipher.is_empty():
		var cipher_panel := UIKit.panel()
		var cipher_box := VBoxContainer.new()
		cipher_box.add_theme_constant_override("separation", 6)
		cipher_panel.add_child(cipher_box)
		var shift := int(cipher.get("shift", 1))
		var cipher_head := HBoxContainer.new()
		cipher_head.add_theme_constant_override("separation", 8)
		cipher_head.add_child(UIKit.tag("CIPHER", UIKit.WARN))
		cipher_head.add_child(UIKit.label("shift %d" % shift, 15, UIKit.DIM))
		cipher_box.add_child(cipher_head)
		cipher_box.add_child(UIKit.label(str(cipher.get("text", "")), 24, UIKit.ACCENT_2))
		cipher_box.add_child(UIKit.wrapped("Decode the word for the downlink log.", 14, UIKit.DIM))
		cipher_box.add_child(code_field)
		body.add_child(cipher_panel)

	body.add_child(_status)
	body.add_child(UIKit.button("Lock the signal", func() -> void:
		if not CommsGrader.frequency_ok(float(slider.value), target, float(frequency.get("tolerance", 0.5))):
			mistake(str(config.get("mistake", "Locked onto the wrong frequency.")))
			_status.text = failure_text()
			if mistakes.size() >= 5:
				finish(false)
			return
		if not interference.is_empty() and not CommsGrader.code_ok(str(filter_choice.value), str(interference.get("answer", ""))):
			mistake("Set the interference filter wrong.")
			_status.text = "Wrong filter setting. Try again."
			if mistakes.size() >= 5:
				finish(false)
			return
		if not cipher.is_empty() and not CommsGrader.cipher_ok(str(code_field.text), str(cipher.get("text", "")), int(cipher.get("shift", 1))):
			mistake("Decoded the cipher wrong.")
			_status.text = "That is not the word. Check the shift."
			if mistakes.size() >= 5:
				finish(false)
			return
		finish(true)
	))


func set_interference_initial(scope, target: float, frequency: Dictionary) -> void:
	var span := maxf(1.0, float(frequency.get("max", 460.0)) - float(frequency.get("min", 400.0)))
	scope.set_interference(clampf(absf(float(slider_min(frequency)) - target) / span, 0.03, 1.0))


func slider_min(frequency: Dictionary) -> float:
	return float(frequency.get("min", 400.0))


# ---------------------------------------------------------------- channels

func _build_channels() -> void:
	body.add_child(UIKit.banner(str(config.get("rule", "")), UIKit.ACCENT))
	var calls := {}
	for channel in config.get("channels", []):
		var id := str(channel.id)
		var card := UIKit.panel()
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 6)
		card.add_child(card_box)
		var card_head := HBoxContainer.new()
		var head_spacer := Control.new()
		head_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var state_lamp := UIKit.lamp(UIKit.DIM)
		var state_tag := UIKit.tag("NO CALL", UIKit.DIM)
		var title := UIKit.label(str(channel.label), 17)
		card_head.add_child(title)
		card_head.add_child(head_spacer)
		card_head.add_child(state_lamp)
		card_head.add_child(state_tag)
		card_box.add_child(card_head)
		card_box.add_child(UIKit.kv_row("Reading", str(channel.reading), UIKit.TEXT))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var go := UIKit.button("CALL GO", func() -> void: _call(id, "GO", calls, state_lamp, state_tag, row))
		var hold := UIKit.button("CALL HOLD", func() -> void: _call(id, "HOLD", calls, state_lamp, state_tag, row))
		row.add_child(go)
		row.add_child(hold)
		card_box.add_child(row)
		body.add_child(card)
	body.add_child(_status)
	body.add_child(UIKit.button("Report the net check", func() -> void:
		var wrong := false
		for channel in config.get("channels", []):
			if str(calls.get(str(channel.id), "")) != str(channel.expected):
				wrong = true
		if not wrong:
			finish(true)
		else:
			mistake(str(config.get("mistake", "Called a channel wrong.")))
			_status.text = failure_text()
			if mistakes.size() >= 5:
				finish(false)
	))


func _call(id: String, call: String, calls: Dictionary, lamp: PanelContainer, tag_node: Control, row: HBoxContainer) -> void:
	calls[id] = call
	_set_lamp(lamp, UIKit.SUCCESS if call == "GO" else UIKit.WARN)
	var parent := tag_node.get_parent()
	var index: int = tag_node.get_index()
	parent.remove_child(tag_node)
	tag_node.queue_free()
	var new_tag := UIKit.tag(call + " CALLED", UIKit.SUCCESS if call == "GO" else UIKit.WARN)
	parent.add_child(new_tag)
	parent.move_child(new_tag, index)
	for child in row.get_children():
		if child is Button:
			child.disabled = true


# ---------------------------------------------------------------- link

func _build_link() -> void:
	var entries: Array = []
	body.add_child(numeric_box(entries))
	var budget := int(config.get("budget_chars", 120))
	body.add_child(UIKit.heading("TRANSMISSION COMPOSER", 11, UIKit.ACCENT))

	var budget_label := UIKit.kv_row("Budget used", "0 / %d chars" % budget, UIKit.DIM)
	var budget_bar := UIKit.progress_bar(0.0, float(budget), UIKit.ACCENT)
	body.add_child(budget_bar)
	body.add_child(budget_label)

	var message_choice := {"value": "", "chars": 0}
	var picked_rows := {}
	for message in config.get("messages", []):
		var id := str(message.id)
		var chars := int(message.chars)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var text := UIKit.wrapped(str(message.text), 15)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		row.add_child(UIKit.tag("%d chars" % chars, UIKit.DIM))
		var send := UIKit.button("SELECT", func() -> void:
			message_choice["value"] = id
			message_choice["chars"] = chars
			_set_lamp(picked_rows[id]["lamp"], UIKit.ACCENT)
			for other_id in picked_rows.keys():
				if str(other_id) != id:
					_set_lamp(picked_rows[other_id]["lamp"], UIKit.DIM)
			budget_bar.value = float(chars)
			var over := chars > budget
			budget_bar.add_theme_stylebox_override("fill", _bar_fill(UIKit.DANGER if over else UIKit.ACCENT))
			budget_bar.max_value = float(chars if over else budget)
			(budget_label.get_child(0) as Label).text = "Budget used" if not over else "OVER BUDGET"
			(budget_label.get_child(2) as Label).text = "%d / %d chars" % [chars, budget]
			(budget_label.get_child(2) as Label).add_theme_color_override("font_color", UIKit.DANGER if over else UIKit.DIM)
		)
		row.add_child(send)
		var lamp := UIKit.lamp(UIKit.DIM)
		row.add_child(lamp)
		picked_rows[id] = {"lamp": lamp}
		body.add_child(row)

	body.add_child(_status)
	body.add_child(UIKit.button("Transmit", func() -> void:
		if str(message_choice.value) == "":
			_status.text = "Pick a message first."
			return
		var scale := 2.0 if recovery_mode else 1.0
		var graded: Dictionary = NumberGrader.grade_parts(read_fields(entries), config.get("parts", []), scale)
		if not graded.ok:
			mistake(str(config.get("mistake", "A delay figure was wrong.")))
			_status.text = str(graded.reason)
			if mistakes.size() >= 5:
				finish(false)
			return
		var picked := {}
		for message in config.get("messages", []):
			if str(message.id) == str(message_choice.value):
				picked = message
		if not bool(picked.get("ok", false)):
			mistake(str(config.get("mistake", "Sent an unusable message.")))
			_status.text = failure_text()
			if mistakes.size() >= 5:
				finish(false)
			return
		finish(true)
	))


func _set_lamp(lamp: PanelContainer, color: Color) -> void:
	var style := lamp.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.bg_color = color


func _bar_fill(color: Color) -> StyleBoxFlat:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	return fill


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
		"Drag the dial until the MHz readout sits inside the target band.",
		"Static hiss? Switch the interference filter on, then retune.",
		"Decode letter by letter - shift each character back by the briefing number.",
		"Log only what the data supports. Extra claims cost accuracy.",
	]

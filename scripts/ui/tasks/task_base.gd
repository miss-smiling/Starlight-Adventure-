extends Control

# Shared base for every profession task module.
# Contract: setup(config, recovery_mode) builds the UI; resolved(result) is
# emitted exactly once with the standard result dictionary that
# MissionManager.apply_task_result consumes.

signal resolved(result: Dictionary)

const UIKit = preload("res://scripts/ui/ui_kit.gd")
const NumberGrader = preload("res://scripts/model/number_grader.gd")

var config: Dictionary = {}
var recovery_mode := false
var stage_label := ""
var mistakes: Array = []
var body: VBoxContainer = null
var hint_panel: PanelContainer = null
var skip_confirm: PanelContainer = null


func setup(data: Dictionary, recovery: bool, stage_title: String = "") -> void:
	config = data
	recovery_mode = recovery
	stage_label = stage_title
	_build()


func _build() -> void:
	pass


# Extra on-screen guidance for the concrete controls of this task. Shown in
# the FIELD TIPS panel under the briefing; override in each task module.
func tips() -> Array:
	return []


# Load a section of a JSON data file under res://data/. Used by the quiz and
# puzzle game modules; missing file or section returns {} so callers must
# fall back to their built-in defaults.
static func puzzle_data(file: String, key: String) -> Dictionary:
	var path := "res://data/%s" % file
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var section = parsed.get(key, {})
	return section if typeof(section) == TYPE_DICTIONARY else {}


func build_frame(root: Control) -> void:
	# anchors_and_offsets (not anchors-only): when the task is already a child
	# of a plain Control, set_anchors_preset would preserve the current 0x0
	# rect by re-adjusting offsets, leaving the module collapsed.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_right = -18
	box.offset_top = 12
	box.offset_bottom = -12
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	root = box
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)

	# Build the toggleable panels first so the header buttons can bind to them.
	var tips_list: Array = tips()
	if not tips_list.is_empty():
		hint_panel = _tips_panel(tips_list)
	skip_confirm = _skip_confirm()
	skip_confirm.visible = false

	body.add_child(_header(str(config.get("title", "Station Duty"))))
	if stage_label != "":
		body.add_child(UIKit.banner(stage_label, UIKit.ACCENT_2))
	elif recovery_mode:
		body.add_child(UIKit.banner("Recovery check - fix the problem, then confirm again.", UIKit.SUCCESS))
	var hint: String = str(config.get("hint", ""))
	if hint != "":
		body.add_child(UIKit.hint_box(hint))
	if hint_panel != null:
		body.add_child(hint_panel)
	body.add_child(skip_confirm)


# Console-style title strip with a golden leading edge. The right side carries
# the two global controls: a HINT toggle for the tips panel and SKIP, which
# hands the duty to another crew member instead of hard-failing the stage.
func _header(title_text: String) -> PanelContainer:
	var item := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UIKit.BG_SOFT
	style.border_color = UIKit.PANEL_EDGE
	style.set_border_width_all(1)
	style.border_width_left = 5
	style.set_corner_radius_all(0)
	style.set_content_margin_all(11)
	item.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var duty_icon := UIKit.art("icons/%s.png" % str(SaveManager.state.get("profession", "")))
	if duty_icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = duty_icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(30, 30)
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon_rect)
	var title := UIKit.heading(title_text.to_upper(), 13, UIKit.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var hint_button := UIKit.button("HINT", Callable(), "soft")
	hint_button.toggle_mode = true
	hint_button.button_pressed = hint_panel != null
	hint_button.custom_minimum_size = Vector2(66, 34)
	var hint_icon := UIKit.art("icons/hint.png")
	if hint_icon != null:
		hint_button.icon = hint_icon
		hint_button.expand_icon = true
	hint_button.toggled.connect(func(on: bool) -> void:
		if hint_panel != null:
			hint_panel.visible = on
	)
	row.add_child(hint_button)
	var skip_button := UIKit.button("SKIP", Callable(), "soft")
	skip_button.custom_minimum_size = Vector2(66, 34)
	skip_button.pressed.connect(_toggle_skip)
	row.add_child(skip_button)
	item.add_child(row)
	return item


func _toggle_skip() -> void:
	if skip_confirm != null:
		skip_confirm.visible = not skip_confirm.visible


# Compact panel of task-specific field tips, tinted with the console accent.
func _tips_panel(tips_list: Array) -> PanelContainer:
	var item := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UIKit.BG_SOFT
	style.border_color = UIKit.ACCENT_2
	style.set_border_width_all(1)
	style.border_width_left = 5
	style.set_corner_radius_all(0)
	style.set_content_margin_all(10)
	item.add_theme_stylebox_override("panel", UIKit.texture_stylebox("ui/panel_accent.png", style))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.add_child(UIKit.heading("FIELD TIPS", 10, UIKit.ACCENT_2))
	for tip in tips_list:
		box.add_child(UIKit.wrapped("- " + str(tip), 17, UIKit.DIM))
	item.add_child(box)
	return item


# Confirmation strip for skipping: gold, explicit, and easy to back out of.
func _skip_confirm() -> PanelContainer:
	var item := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UIKit.ACCENT.darkened(0.72)
	style.border_color = UIKit.ACCENT
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(10)
	item.add_theme_stylebox_override("panel", UIKit.texture_stylebox("ui/panel_gold.png", style))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(UIKit.heading("HAND THIS DUTY OVER?", 12, UIKit.ACCENT))
	box.add_child(UIKit.wrapped("Another operator will finish this task. The mission log notes the skip - no task points and no science lesson from this stage.", 17, UIKit.WARN))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var hand_over := UIKit.primary_button("HAND IT OVER")
	row.add_child(hand_over)
	hand_over.pressed.connect(skip)
	var keep_working := UIKit.button("KEEP WORKING", Callable(), "soft")
	row.add_child(keep_working)
	keep_working.pressed.connect(func() -> void:
		if skip_confirm != null:
			skip_confirm.visible = false
	)
	box.add_child(row)
	item.add_child(box)
	return item


# Hand the duty to another crew member. The mission continues without the
# recovery loop; the log records the skip and no science is learned.
func skip() -> void:
	var title := str(config.get("title", "this duty"))
	resolved.emit({
		"success": false,
		"skipped": true,
		"mistakes": [],
		"decisions": [{
			"text": "Skipped: " + title,
			"consequence": "Duty handed to another operator.",
			"result": "skip",
		}],
		"flags": {"skipped_any": true},
		"lasting": [],
		"science": "",
		"recovery_needed": false,
		"assisted": true,
		"warning": "",
		"emergency_id": "",
	})


# Flat cell style for game boards: dark base with a visible edge, so gold
# (selected), cyan (next target) and red (conflict) always stand out.
func cell_style(bg: Color, edge: Color) -> StyleBoxFlat:
	var item := StyleBoxFlat.new()
	item.bg_color = bg
	item.border_color = edge
	item.set_border_width_all(1)
	item.set_corner_radius_all(0)
	return item


func mistake(text: String) -> void:
	if text != "" and not mistakes.has(text):
		mistakes.append(text)


func failure_text() -> String:
	var emergency: Dictionary = config.get("emergency", {})
	return str(emergency.get("warning", config.get("mistake", "Recheck your work and try again.")))


func emergency_id() -> String:
	var emergency: Dictionary = config.get("emergency", {})
	return str(emergency.get("id", "recovery"))


func fail_flag() -> String:
	var emergency: Dictionary = config.get("emergency", {})
	return str(emergency.get("fail_flag", ""))


func finish(success: bool, extra: Dictionary = {}) -> void:
	var result := {
		"success": success,
		"mistakes": mistakes.duplicate(),
		"decisions": [],
		"flags": {},
		"lasting": [],
		"science": str(config.get("science", "")),
		"recovery_needed": false,
		"assisted": false,
	}
	result.merge(extra, true)
	if not success and not bool(result.get("recovery_needed", false)):
		result["recovery_needed"] = true
		if str(result.get("warning", "")) == "":
			result["warning"] = failure_text()
		if str(result.get("emergency_id", "")) == "":
			result["emergency_id"] = emergency_id()
	resolved.emit(result)


# Data-entry block: labeled numeric fields with unit tags appended.
func numeric_box(entries: Array) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var parts: Array = config.get("parts", [])
	for i in parts.size():
		var part: Dictionary = parts[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var question := UIKit.wrapped(str(part.get("prompt", "")), 16)
		question.custom_minimum_size = Vector2(380, 0)
		row.add_child(question)
		var field := LineEdit.new()
		field.placeholder_text = "number"
		field.custom_minimum_size = Vector2(150, 42)
		field.text = str(entries[i]) if i < entries.size() else ""
		row.add_child(field)
		var unit := UIKit.tag(str("[" + str(part.get("unit", "")) + "]"), UIKit.DIM)
		row.add_child(unit)
		box.add_child(row)
		entries.append(field)
	return box


func read_fields(entries: Array) -> Array:
	var values: Array = []
	for field in entries:
		values.append(str(field.text))
	return values


func status_label() -> Label:
	return UIKit.status()

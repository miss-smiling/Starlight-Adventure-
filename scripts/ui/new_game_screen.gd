extends Control

const UIKit = preload("res://scripts/ui/ui_kit.gd")

var _callsign: LineEdit
var _gender: OptionButton


func _ready() -> void:
	var root := UIKit.screen("Operator Profile", "Fill in your station ID.")
	add_child(root)

	# The ID card itself: the "corner fold" upload frames it like a real badge.
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(640, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if UIKit.art("ui/panel corner fold.png") != null:
		card.add_theme_stylebox_override("panel", UIKit.texture_stylebox("ui/panel corner fold.png", StyleBoxFlat.new()))
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = UIKit.PANEL
		style.border_color = UIKit.ACCENT
		style.set_border_width_all(1)
		style.set_corner_radius_all(0)
		style.set_content_margin_all(16)
		card.add_theme_stylebox_override("panel", style)
	root.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(UIKit.heading("STATION ID", 12, UIKit.ACCENT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	head.add_child(UIKit.heading("MISSION CONTROL", 8, UIKit.DIM))
	box.add_child(head)
	box.add_child(HSeparator.new())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	# Photo slot with the callsign initial, like a badge photo.
	var photo_frame := PanelContainer.new()
	photo_frame.custom_minimum_size = Vector2(120, 150)
	var photo_style := StyleBoxFlat.new()
	photo_style.bg_color = UIKit.BG
	photo_style.border_color = UIKit.PANEL_EDGE
	photo_style.set_border_width_all(1)
	photo_style.set_corner_radius_all(0)
	photo_frame.add_theme_stylebox_override("panel", photo_style)
	row.add_child(photo_frame)
	var initial := UIKit.heading("?", 34, UIKit.ACCENT)
	initial.set_anchors_preset(Control.PRESET_FULL_RECT)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	photo_frame.add_child(initial)

	var fields := VBoxContainer.new()
	fields.add_theme_constant_override("separation", 10)
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fields)

	fields.add_child(_id_row_label("NAME"))
	_callsign = LineEdit.new()
	_callsign.text = str(SaveManager.state.get("callsign", "Explorer"))
	_callsign.max_length = 16
	_callsign.custom_minimum_size = Vector2(0, 44)
	fields.add_child(_callsign)
	_callsign.text_changed.connect(func(text: String) -> void:
		var first := text.strip_edges().left(1).to_upper()
		initial.text = first if first != "" else "?"
	)

	fields.add_child(_id_row_label("GENDER"))
	_gender = OptionButton.new()
	for item in ["Female", "Male", "Non-binary", "Undisclosed"]:
		_gender.add_item(item)
	_gender.selected = 3
	_gender.custom_minimum_size = Vector2(0, 44)
	fields.add_child(_gender)

	fields.add_child(_id_row_label("PROFESSION"))
	fields.add_child(UIKit.label("To be assigned on the next screen", 20, UIKit.DIM))
	fields.add_child(_id_row_label("MISSION DATE"))
	fields.add_child(UIKit.label(Time.get_date_string_from_system(), 20, UIKit.TEXT))

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	buttons.add_child(UIKit.primary_button("Start campaign", _start))
	buttons.add_child(UIKit.button("Back", func() -> void: GameManager.request("main_menu")))
	root.add_child(buttons)


func _id_row_label(title: String) -> Control:
	return UIKit.heading(title, 9, UIKit.DIM)


func _start() -> void:
	GameManager.start_new(_callsign.text, _gender.text)

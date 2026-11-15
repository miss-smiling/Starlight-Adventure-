extends Control

# Squad-building screen: a grid of operator slots on the left, a detailed
# operator file on the right, and a lineup bar along the bottom. Slot artwork
# uses uploaded pixel portraits from assets/art/portraits/<id>.png when
# present, and falls back to the code-drawn silhouette otherwise.

const UIKit = preload("res://scripts/ui/ui_kit.gd")

var _info: VBoxContainer
var _slots := {}
var _selected := ""
var _lineup_status: Label = null
var _take_button: Button = null


func _ready() -> void:
	var year := int(SaveManager.state.get("current_year", 2026))
	var locked_by := str(SaveManager.state.get("professions_by_year", {}).get(str(year), ""))
	var subtitle := "Choose your role for the %d campaign." % year
	if locked_by != "":
		subtitle = "Your role for the %d campaign is locked in as %s. It cannot change mid-year." % [year, ProfessionManager.display_name(locked_by)]

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 28
	root.offset_right = -28
	root.offset_top = 24
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	# ------------------------------------------------------------ header
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.add_child(UIKit.heading("BUILD YOUR SQUAD", 18, UIKit.ACCENT))
	var head_spacer := Control.new()
	head_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(head_spacer)
	head.add_child(UIKit.tag("%d SEASON" % year, UIKit.ACCENT_2))
	root.add_child(head)
	root.add_child(UIKit.wrapped(subtitle, 19, UIKit.DIM))
	root.add_child(HSeparator.new())

	# ------------------------------------------------------------ columns
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	root.add_child(columns)

	# Left: operator slot grid.
	var grid_holder := ScrollContainer.new()
	grid_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_holder.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(grid_holder)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid_holder.add_child(grid)

	# Right: operator file.
	var info_panel := UIKit.panel()
	info_panel.custom_minimum_size = Vector2(360, 0)
	info_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	# The "electric" upload dresses the operator file panel.
	if UIKit.art("ui/panel electric.png") != null:
		info_panel.add_theme_stylebox_override("panel", UIKit.texture_stylebox("ui/panel electric.png", StyleBoxFlat.new()))
	columns.add_child(info_panel)
	_info = VBoxContainer.new()
	_info.add_theme_constant_override("separation", 6)
	info_panel.add_child(_info)
	_info.add_child(_id_card(""))

	# Slots. Card labels are intentionally omitted - uploaded portraits carry
	# their own name captions, so the whole card is given to the artwork and
	# the operator file on the right identifies the role.
	for profession in ProfessionManager.professions:
		var id := str(profession.id)
		var locked := locked_by != "" and id != locked_by
		var slot := UIKit.button("", _select.bind(id))
		slot.disabled = locked
		slot.custom_minimum_size = Vector2(140, 185)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.tooltip_text = "Locked for this year" if locked else str(profession.get("short", ""))
		var slot_box := VBoxContainer.new()
		slot_box.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_box.offset_left = 8
		slot_box.offset_right = -8
		slot_box.offset_top = 8
		slot_box.offset_bottom = -8
		slot_box.add_theme_constant_override("separation", 4)
		slot_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var portrait := UIKit.OperatorPortrait.new(ProfessionManager.color_of(id), locked, UIKit.art("portraits/%s.png" % id))
		portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_box.add_child(portrait)
		slot.add_child(slot_box)
		_slots[id] = {"button": slot}
		grid.add_child(slot)

	if locked_by != "":
		_selected = locked_by

	# ------------------------------------------------------------ lineup bar
	root.add_child(HSeparator.new())
	var lineup := PanelContainer.new()
	var lineup_style := StyleBoxFlat.new()
	lineup_style.bg_color = UIKit.BG_SOFT
	lineup_style.border_color = UIKit.PANEL_EDGE
	lineup_style.set_border_width_all(1)
	lineup_style.border_width_left = 5
	lineup_style.set_corner_radius_all(0)
	lineup_style.set_content_margin_all(10)
	lineup.add_theme_stylebox_override("panel", lineup_style)
	root.add_child(lineup)
	var lineup_row := HBoxContainer.new()
	lineup_row.add_theme_constant_override("separation", 12)
	lineup.add_child(lineup_row)
	lineup_row.add_child(UIKit.heading("LINEUP", 11, UIKit.ACCENT_2))
	_lineup_status = UIKit.label("", 18, UIKit.WARN)
	_lineup_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lineup_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lineup_row.add_child(_lineup_status)
	_take_button = UIKit.primary_button("Take this role", func() -> void: GameManager.choose_profession(_selected))
	_take_button.custom_minimum_size = Vector2(200, 46)
	_take_button.disabled = _selected == ""
	lineup_row.add_child(_take_button)

	# ------------------------------------------------------------ back row
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UIKit.button("Back", func() -> void: GameManager.request("main_menu")))
	root.add_child(row)
	root.add_child(UIKit.wrapped("TIP: click a slot to read the operator file. Every profession plays the missions differently.", 16, UIKit.DIM))

	if _selected != "":
		_show_info(_selected)
	else:
		_show_info(str(ProfessionManager.professions[0].id))


func _select(id: String) -> void:
	_show_info(id)


func _show_info(id: String) -> void:
	_selected = id
	UIKit.clear(_info)
	var data := ProfessionManager.get_profession(id)
	if data.is_empty():
		return
	var color := ProfessionManager.color_of(id)

	_info.add_child(_id_card(id))
	_info.add_child(UIKit.heading("OPERATOR FILE", 10, UIKit.ACCENT_2))
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	var file_icon := UIKit.art("icons/%s.png" % id)
	if file_icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = file_icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(52, 52)
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_row.add_child(icon_rect)
	var chip := UIKit.lamp(color)
	chip.custom_minimum_size = Vector2(14, 14)
	name_row.add_child(chip)
	name_row.add_child(UIKit.heading(str(data.name).to_upper(), 13, color))
	_info.add_child(name_row)
	_info.add_child(UIKit.label(str(data.get("short", "")), 20, UIKit.DIM))
	_info.add_child(HSeparator.new())
	_info.add_child(UIKit.heading("STATION DUTY", 9, UIKit.DIM))
	_info.add_child(UIKit.wrapped(str(data.get("duty", "")), 20, UIKit.TEXT))
	_info.add_child(UIKit.heading("TOOLS OF THE ROLE", 9, UIKit.DIM))
	for tool in data.get("tools", []):
		var tool_row := HBoxContainer.new()
		tool_row.add_theme_constant_override("separation", 8)
		tool_row.add_child(UIKit.lamp(UIKit.ACCENT))
		tool_row.add_child(UIKit.label(str(tool), 19, UIKit.TEXT))
		_info.add_child(tool_row)
	_info.add_child(HSeparator.new())
	_info.add_child(UIKit.wrapped("You keep this role all year. You can switch after the debrief.", 18, UIKit.DIM))

	# Refresh slot highlight + lineup bar.
	var year := int(SaveManager.state.get("current_year", 2026))
	var locked_by := str(SaveManager.state.get("professions_by_year", {}).get(str(year), ""))
	for slot_id in _slots.keys():
		var parts: Dictionary = _slots[slot_id]
		var is_choice: bool = str(slot_id) == id
		var is_locked: bool = locked_by != "" and str(slot_id) != locked_by
		# Selection feedback on the card itself: a gentle brightness lift.
		var slot_button: Button = parts["button"]
		slot_button.modulate = Color(1.16, 1.16, 1.16) if is_choice and not is_locked else Color(1, 1, 1)
	if locked_by != "":
		_lineup_status.text = "Locked in as %s for the %d season." % [ProfessionManager.display_name(locked_by), year]
		_take_button.disabled = true
	else:
		_lineup_status.text = "Ready: %s. Confirm to lock the role for the year." % ProfessionManager.display_name(id)
		_take_button.disabled = false


# ------------------------------------------------------------ ID card

# The operator's station ID: photo slot, callsign, gender, role and the
# mission date stamp. Shown before a role is picked (unassigned) and above
# the operator file once a slot is selected.
func _id_card(profession_id: String) -> Control:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UIKit.BG_SOFT
	style.border_color = UIKit.ACCENT
	style.set_border_width_all(1)
	style.border_width_left = 4
	style.set_corner_radius_all(0)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	# Photo slot: profession portrait, else the icon, else the callsign initial.
	var photo := UIKit.art("portraits/%s.png" % profession_id) if profession_id != "" else UIKit.art("portraits/%s.png" % str(SaveManager.state.get("profession", "")))
	if photo == null and profession_id != "":
		photo = UIKit.art("icons/%s.png" % profession_id)
	var photo_frame := PanelContainer.new()
	photo_frame.custom_minimum_size = Vector2(96, 118)
	var photo_style := StyleBoxFlat.new()
	photo_style.bg_color = UIKit.BG
	photo_style.border_color = UIKit.PANEL_EDGE
	photo_style.set_border_width_all(1)
	photo_style.set_corner_radius_all(0)
	photo_frame.add_theme_stylebox_override("panel", photo_style)
	row.add_child(photo_frame)
	if photo != null:
		var photo_rect := TextureRect.new()
		photo_rect.texture = photo
		photo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		photo_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		photo_frame.add_child(photo_rect)
	else:
		var initials := UIKit.heading(str(SaveManager.state.get("callsign", "E")).left(1).to_upper(), 30, UIKit.ACCENT)
		initials.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		photo_frame.add_child(initials)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UIKit.heading("STATION ID", 10, UIKit.ACCENT))
	info.add_child(_id_row("NAME", str(SaveManager.state.get("callsign", "Explorer")), UIKit.TEXT))
	var gender := str(SaveManager.state.get("gender", ""))
	info.add_child(_id_row("GENDER", gender if gender != "" else "-", UIKit.TEXT))
	var prof_name := "UNASSIGNED"
	var prof_color := UIKit.DIM
	if profession_id != "":
		prof_name = str(ProfessionManager.get_profession(profession_id).get("name", profession_id)).to_upper()
		prof_color = ProfessionManager.color_of(profession_id)
	info.add_child(_id_row("PROFESSION", prof_name, prof_color))
	info.add_child(_id_row("MISSION DATE", Time.get_date_string_from_system(), UIKit.TEXT))
	return card


func _id_row(title: String, value: String, color: Color) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	line.add_child(UIKit.heading(title, 9, UIKit.DIM))
	var value_label := UIKit.label(value, 18, color)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.clip_text = true
	line.add_child(value_label)
	return line

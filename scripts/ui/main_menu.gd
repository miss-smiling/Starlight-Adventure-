extends Control

# Main menu: cinematic nighttime city backdrop with a centred layout, bold
# retro pixel typography and clean rectangular panels. Primary actions run
# golden-orange; secondary actions stay dark navy with blue borders.

const UIKit = preload("res://scripts/ui/ui_kit.gd")

var _confirm_row: HBoxContainer = null


func _ready() -> void:
	var city_art := UIKit.art("scenes/city.png")
	if city_art != null:
		# Uploaded pixel skyline wins over the code-drawn placeholder.
		var art_backdrop := TextureRect.new()
		art_backdrop.texture = city_art
		art_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(art_backdrop)
	else:
		var backdrop := UIKit.city_backdrop()
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(backdrop)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 60
	root.offset_right = -60
	root.offset_top = 44
	root.offset_bottom = -28
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# Push the stack down so it sits in the lower-centre of the skyline.
	var top_space := Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(top_space)

	var logo := UIKit.art("ui/logo.png")
	if logo != null:
		# An uploaded logo replaces the plain text title.
		var logo_rect := TextureRect.new()
		logo_rect.texture = logo
		logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_rect.custom_minimum_size = Vector2(0, 120)
		root.add_child(logo_rect)
	else:
		var title := UIKit.heading("STARLIGHT ADVENTURE", 30, UIKit.ACCENT)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		root.add_child(title)

	var tagline := UIKit.heading("STUDENT MISSION CONTROL", 12, UIKit.ACCENT_2)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(tagline)

	var subtitle := UIKit.label("Eight professions. One crew. Five missions across the 2026 season.", 22, UIKit.TEXT)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(subtitle)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	root.add_child(gap)

	var menu_panel := PanelContainer.new()
	menu_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.043, 0.09, 0.19, 0.82)
	style.border_color = UIKit.PANEL_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(18)
	style.content_margin_left = 26
	style.content_margin_right = 26
	menu_panel.add_theme_stylebox_override("panel", style)
	root.add_child(menu_panel)

	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(330, 0)
	menu.add_theme_constant_override("separation", 10)
	menu_panel.add_child(menu)

	var continue_button := UIKit.primary_button("Continue campaign", GameManager.continue_campaign)
	continue_button.disabled = not SaveManager.has_save()
	menu.add_child(continue_button)
	menu.add_child(UIKit.primary_button("New game", _new_game))

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 4)
	menu.add_child(gap2)

	for entry in [["Settings", func() -> void: GameManager.request("settings")], ["Achievements", func() -> void: GameManager.request("achievements")], ["Leaderboard", func() -> void: GameManager.request("leaderboard")]]:
		var item := UIKit.button(str(entry[0]), entry[1])
		menu.add_child(item)
	var quit_button := UIKit.button("Quit", func() -> void: get_tree().quit())
	menu.add_child(quit_button)

	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(bottom_space)

	if GameManager.notice != "":
		var notice := UIKit.banner(GameManager.notice, UIKit.DANGER)
		notice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		root.add_child(notice)
		GameManager.notice = ""

	var note := UIKit.label("Progress saves automatically. Missions can be paused and resumed at any time.", 18, UIKit.DIM)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(note)

	var tip := UIKit.label("TIP: press HINT inside any task for field tips, or SKIP to hand the duty to your crew.", 18, UIKit.DIM)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(tip)


func _new_game() -> void:
	if SaveManager.has_save():
		_ask_overwrite()
	else:
		GameManager.request("new_game")


func _ask_overwrite() -> void:
	if _confirm_row != null:
		return
	_confirm_row = HBoxContainer.new()
	_confirm_row.add_theme_constant_override("separation", 10)
	_confirm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_confirm_row.add_child(UIKit.label("Overwrite the saved campaign?", 22, UIKit.DANGER))
	_confirm_row.add_child(UIKit.primary_button("Yes, overwrite", func() -> void: GameManager.request("new_game")))
	_confirm_row.add_child(UIKit.button("No, keep it", func() -> void:
		_confirm_row.queue_free()
		_confirm_row = null
	))
	add_child(_confirm_row)
	_confirm_row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_confirm_row.offset_top = -110
	_confirm_row.offset_bottom = -60
	_confirm_row.offset_left = 40
	_confirm_row.offset_right = -40

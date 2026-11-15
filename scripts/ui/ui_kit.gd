extends RefCounted

# Shared widget library and theme builder for every screen and task module.
# Visual direction: cinematic night-city mission control. Deep navy panels,
# subtle blue borders, cyan console accents, warm golden-orange primary
# actions, strict retro pixel typography. Everything is drawn with plain
# rects and lines - deliberately light, deliberately 2D.

# ---------------------------------------------------------------- palette
# STRICT RULE - only these families may appear anywhere in the game:
# deep navy / dark blue / electric blue / cyan / white / warm golden-orange.
const BG := Color("081020")
const BG_SOFT := Color("0c1830")
const PANEL := Color("101f3c")
const PANEL_LIGHT := Color("182a4e")
const PANEL_EDGE := Color("2b4677")
const ACCENT := Color("ffa632")        # warm golden-orange - primary actions
const ACCENT_DIM := Color("c47f1e")
const ACCENT_2 := Color("38c8ff")      # electric blue / cyan console accent
const ELECTRIC := Color("2f8bff")      # electric blue
const CYAN := Color("4de8ff")
const DANGER := Color("ff6a4d")        # warm alert tone (golden-orange family)
const SUCCESS := Color("4de8ff")       # success reads as cyan in this palette
const WARN := Color("ffd166")          # golden yellow
const TEXT := Color("f2f7ff")          # white
const DIM := Color("6f86b5")           # muted blue-grey

# ---------------------------------------------------------------- typography
const FONT_HEAD := preload("res://assets/fonts/PressStart2P-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/VT323-Regular.ttf")

# ------------------------------------------------------------- uploaded art
# Drop-in pixel art folder. Any file that exists under assets/art/ is used
# automatically; anything missing falls back to the code-drawn placeholder,
# so the game keeps working before (and after) art is uploaded.
#   assets/art/portraits/<id>.png  - character portraits (profession ids and
#                                    dialogue speaker ids: astronaut,
#                                    engineer, physicist, mathematician,
#                                    biologist, medical, comms, director...)
#   assets/art/scenes/city.png     - main menu night-city backdrop override
#   assets/art/ui/<name>.png       - free decorations (unused automatically)
# See assets/art/README.md for the full guide.
const ART_ROOT := "res://assets/art"


static func art(relative_path: String) -> Texture2D:
	var path := ART_ROOT + "/" + relative_path
	if not ResourceLoader.exists(path, "Texture2D"):
		return null
	var resource := load(path)
	return resource if resource is Texture2D else null


# Turn an uploaded PNG into a 9-slice style box. The image is auto-trimmed to
# its opaque bounding box first (uploaded art often sits on a larger canvas
# with transparent padding), then 9-slice margins are derived from the trimmed
# size: rounded caps and corner ornaments stay crisp while the middle
# stretches. When the file is missing, the flat fallback style is returned
# (tinted where the caller asks), so uploads are always optional.
static func texture_stylebox(relative_path: String, flat: StyleBoxFlat, tint := Color(1, 1, 1)) -> StyleBox:
	var tex := art(relative_path)
	if tex == null:
		var fallback: StyleBoxFlat = flat.duplicate()
		if tint != Color(1, 1, 1):
			fallback.bg_color = Color(
				clampf(fallback.bg_color.r * tint.r, 0.0, 1.0),
				clampf(fallback.bg_color.g * tint.g, 0.0, 1.0),
				clampf(fallback.bg_color.b * tint.b, 0.0, 1.0),
				clampf(fallback.bg_color.a * tint.a, 0.0, 1.0)
			)
		return fallback
	var fitted: Dictionary = _fit_art_texture(tex)
	var box := StyleBoxTexture.new()
	box.texture = fitted.texture
	var bw := int(fitted.w)
	var bh := int(fitted.h)
	var elongated: bool = bw >= bh * 2.0 or bh >= bw * 2.0
	var margin: int = int(round(float(mini(bw, bh)) * (0.5 if elongated else 0.3)))
	margin = clampi(margin, 3, maxi(3, mini(bw, bh) / 2 - 1))
	box.set_texture_margin_all(float(margin))
	box.content_margin_left = flat.content_margin_left
	box.content_margin_right = flat.content_margin_right
	box.content_margin_top = flat.content_margin_top
	box.content_margin_bottom = flat.content_margin_bottom
	box.modulate_color = tint
	return box


# Trim transparent padding from an uploaded image and bake the result into a
# fresh ImageTexture. Returns {"texture": Texture2D, "w": int, "h": int}.
static func _fit_art_texture(tex: Texture2D) -> Dictionary:
	var image := tex.get_image()
	if image == null:
		return {"texture": tex, "w": tex.get_width(), "h": tex.get_height()}
	if image.is_compressed():
		image.decompress()
	var w := image.get_width()
	var h := image.get_height()
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	for y in h:
		for x in w:
			if image.get_pixel(x, y).a > 0.03:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	if max_x >= 0 and (max_x - min_x + 1 != w or max_y - min_y + 1 != h):
		image = image.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))
		w = image.get_width()
		h = image.get_height()
	return {"texture": ImageTexture.create_from_image(image), "w": w, "h": h}


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT_BODY
	theme.default_font_size = 22

	var panel := StyleBoxFlat.new()
	panel.bg_color = PANEL
	panel.border_color = PANEL_EDGE
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(0)
	panel.set_content_margin_all(14)
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 4
	# Airier text blocks: extra line spacing makes long body copy far easier
	# to read than the cramped terminal default.
	theme.set_constant("line_spacing", "Label", 7)
	theme.set_constant("line_spacing", "Button", 4)
	var panel_style := texture_stylebox("ui/panel.png", panel)
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	theme.set_stylebox("panel", "Panel", panel_style)

	# Secondary button: dark navy with a subtle blue border.
	var button := StyleBoxFlat.new()
	button.bg_color = PANEL_LIGHT
	button.border_color = PANEL_EDGE
	button.set_border_width_all(1)
	button.set_corner_radius_all(0)
	button.set_content_margin_all(10)
	button.content_margin_left = 18
	button.content_margin_right = 18
	theme.set_stylebox("normal", "Button", texture_stylebox("ui/button.png", button))

	var hover := button.duplicate()
	hover.bg_color = Color("1e3360")
	hover.border_color = ACCENT_2
	theme.set_stylebox("hover", "Button", texture_stylebox("ui/button_hover.png", hover, Color(1.12, 1.12, 1.12)))
	theme.set_color("font_hover_color", "Button", ACCENT)

	var pressed := button.duplicate()
	pressed.bg_color = Color("132244")
	pressed.border_color = ELECTRIC
	theme.set_stylebox("pressed", "Button", texture_stylebox("ui/button.png", pressed, Color(0.82, 0.82, 0.82)))
	theme.set_color("font_pressed_color", "Button", ACCENT_2)

	var disabled := button.duplicate()
	disabled.bg_color = Color("101c36")
	disabled.border_color = Color("1d2f52")
	theme.set_stylebox("disabled", "Button", texture_stylebox("ui/button.png", disabled, Color(1, 1, 1, 0.5)))
	theme.set_color("font_disabled_color", "Button", Color("51648c"))

	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = ACCENT
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(0)
	theme.set_stylebox("focus", "Button", focus)

	theme.set_font("font", "Button", FONT_HEAD)
	theme.set_font_size("font_size", "Button", 13)
	theme.set_color("font_color", "Button", TEXT)

	var line := StyleBoxFlat.new()
	line.bg_color = Color("091228")
	line.border_color = PANEL_EDGE
	line.set_border_width_all(1)
	line.set_corner_radius_all(0)
	line.set_content_margin_all(9)
	theme.set_stylebox("normal", "LineEdit", line)
	var line_focus := line.duplicate()
	line_focus.border_color = ACCENT_2
	theme.set_stylebox("focus", "LineEdit", line_focus)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("caret_color", "LineEdit", ACCENT)
	theme.set_font("font", "LineEdit", FONT_BODY)
	theme.set_font_size("font_size", "LineEdit", 20)

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "CheckBox", TEXT)
	theme.set_color("font_hover_color", "CheckBox", ACCENT)
	theme.set_font("font", "CheckBox", FONT_BODY)
	theme.set_font_size("font_size", "CheckBox", 19)

	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = Color("0a1428")
	scroll_bg.set_corner_radius_all(0)
	theme.set_stylebox("scroll", "VScrollBar", scroll_bg)
	theme.set_stylebox("scroll", "HScrollBar", scroll_bg)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = PANEL_EDGE
	grabber.set_corner_radius_all(0)
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber", "HScrollBar", grabber)
	var grabber_hover := grabber.duplicate()
	grabber_hover.bg_color = DIM
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber_hover)
	theme.set_stylebox("grabber_highlight", "HScrollBar", grabber_hover)

	var slider_track := StyleBoxFlat.new()
	slider_track.bg_color = Color("091228")
	slider_track.border_color = PANEL_EDGE
	slider_track.set_border_width_all(1)
	slider_track.set_corner_radius_all(0)
	slider_track.content_margin_top = 5
	slider_track.content_margin_bottom = 5
	theme.set_stylebox("slider", "HSlider", slider_track)
	var slider_fill := StyleBoxFlat.new()
	slider_fill.bg_color = Color(ACCENT_2.r, ACCENT_2.g, ACCENT_2.b, 0.35)
	slider_fill.set_corner_radius_all(0)
	theme.set_stylebox("grabber_area", "HSlider", slider_fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)

	theme.set_stylebox("normal", "OptionButton", button)
	theme.set_stylebox("hover", "OptionButton", hover)
	theme.set_stylebox("pressed", "OptionButton", pressed)
	theme.set_stylebox("focus", "OptionButton", focus)
	theme.set_color("font_hover_color", "OptionButton", ACCENT)
	theme.set_color("font_pressed_color", "OptionButton", ACCENT_2)
	theme.set_font("font", "OptionButton", FONT_HEAD)
	theme.set_font_size("font_size", "OptionButton", 12)

	var menu_panel := StyleBoxFlat.new()
	menu_panel.bg_color = PANEL_LIGHT
	menu_panel.border_color = PANEL_EDGE
	menu_panel.set_border_width_all(1)
	menu_panel.set_corner_radius_all(0)
	theme.set_stylebox("panel", "PopupMenu", menu_panel)
	theme.set_color("font_color", "PopupMenu", TEXT)
	theme.set_color("font_hover_color", "PopupMenu", BG)
	var menu_hover := StyleBoxFlat.new()
	menu_hover.bg_color = ACCENT
	theme.set_stylebox("hover", "PopupMenu", menu_hover)
	theme.set_font("font", "PopupMenu", FONT_BODY)
	theme.set_font_size("font_size", "PopupMenu", 19)

	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = Color("091228")
	progress_bg.border_color = PANEL_EDGE
	progress_bg.set_border_width_all(1)
	progress_bg.set_corner_radius_all(0)
	theme.set_stylebox("background", "ProgressBar", progress_bg)

	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = ACCENT
	progress_fill.set_corner_radius_all(0)
	theme.set_stylebox("fill", "ProgressBar", progress_fill)

	theme.set_color("font_color", "CheckButton", TEXT)
	theme.set_color("font_color", "OptionButton", TEXT)
	theme.set_font("font", "ItemList", FONT_BODY)
	return theme


# --------------------------------------------------------------- primitives

static func heading(text: String, size := 16, color := ACCENT) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_override("font", FONT_HEAD)
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	return item


static func label(text: String, size := 23, color := TEXT) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	return item


static func wrapped(text: String, size := 22, color := TEXT) -> Label:
	var item := label(text, size, color)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item


static func screen(title: String, subtitle := "") -> VBoxContainer:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 28
	root.offset_right = -28
	root.offset_top = 24
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 12)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	var title_size := 20
	if title.length() > 24:
		title_size = 15
	if title.length() > 38:
		title_size = 12
	title_row.add_child(heading(title.to_upper(), title_size, ACCENT))
	var title_spacer := Control.new()
	title_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_spacer)
	title_row.add_child(tag("MISSION CONTROL", ACCENT_2))
	root.add_child(title_row)
	if subtitle != "":
		var sub := wrapped(subtitle, 22, DIM)
		root.add_child(sub)
	root.add_child(HSeparator.new())
	return root


static func button(text: String, on_pressed: Callable = Callable(), click := "") -> Button:
	# Secondary action: dark navy, subtle blue border (from the theme).
	# Short labels get the chunky pixel font; sentence-length labels
	# automatically fall back to the readable terminal font so they never
	# overflow the panel.
	var item := Button.new()
	item.text = text.to_upper()
	_style_button_font(item, text)
	item.custom_minimum_size = Vector2(0, 44)
	if on_pressed.is_valid():
		item.pressed.connect(on_pressed)
	if click == "":
		click = "soft" if item.toggle_mode else "simple"
	item.pressed.connect(_click.bind(click))
	return item


# Play a UI click. Resolved through the scene tree so this file still
# compiles in -s test mode, where autoloads do not exist.
static func _click(id: String) -> void:
	var tree := Engine.get_main_loop()
	if tree != null and tree.root != null:
		var manager: Node = tree.root.get_node_or_null("AudioManager")
		if manager != null:
			manager.sfx(id)


static func _style_button_font(item: Button, text: String) -> void:
	if text.length() > 26:
		# Sentence-length labels: terminal font + word wrap + expand so
		# choices always fit their column.
		item.add_theme_font_override("font", FONT_BODY)
		item.add_theme_font_size_override("font_size", 20)
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL


static func primary_button(text: String, on_pressed: Callable = Callable()) -> Button:
	# Primary action: warm golden-orange with dark navy pixel text.
	var item := Button.new()
	item.text = text.to_upper()
	_style_button_font(item, text)
	item.custom_minimum_size = Vector2(0, 46)
	item.add_theme_stylebox_override("normal", texture_stylebox("ui/button_primary.png", _primary_style(ACCENT, ACCENT_DIM)))
	item.add_theme_stylebox_override("hover", texture_stylebox("ui/button_primary_hover.png", _primary_style(Color("ffc258"), ACCENT), Color(1.08, 1.08, 1.08)))
	item.add_theme_stylebox_override("pressed", texture_stylebox("ui/button_primary.png", _primary_style(Color("e08c1e"), ACCENT_DIM), Color(0.82, 0.82, 0.82)))
	item.add_theme_stylebox_override("focus", _primary_focus())
	var disabled := _primary_style(Color("5a4322"), Color("3a2c16"))
	disabled.border_color = Color("3a2c16")
	item.add_theme_stylebox_override("disabled", texture_stylebox("ui/button_primary.png", disabled, Color(1, 1, 1, 0.5)))
	item.add_theme_color_override("font_color", Color("1a1206"))
	item.add_theme_color_override("font_hover_color", Color("140d03"))
	item.add_theme_color_override("font_pressed_color", Color("1a1206"))
	item.add_theme_color_override("font_disabled_color", Color("8a7a58"))
	item.add_theme_color_override("font_focus_color", Color("1a1206"))
	if on_pressed.is_valid():
		item.pressed.connect(on_pressed)
	item.pressed.connect(_click.bind("primary"))
	return item


static func _primary_style(bg: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = edge
	style.set_border_width_all(1)
	style.border_width_bottom = 3
	style.set_corner_radius_all(0)
	style.set_content_margin_all(10)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style


static func _primary_focus() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = TEXT
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	return style


# Flat square tile button used by maps and grids (EVA navigation, consoles).
static func tile(text: String, bg: Color, on_pressed: Callable = Callable()) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size = Vector2(52, 44)
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(0)
	style.set_border_width_all(1)
	style.border_color = PANEL_EDGE
	style.set_content_margin_all(6)
	item.add_theme_stylebox_override("normal", style)
	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = bg.lightened(0.18)
	hover_style.border_color = ACCENT_2
	item.add_theme_stylebox_override("hover", hover_style)
	item.add_theme_stylebox_override("pressed", style)
	item.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	item.add_theme_font_override("font", FONT_BODY)
	item.add_theme_font_size_override("font_size", 19)
	item.add_theme_color_override("font_color", TEXT)
	item.add_theme_color_override("font_hover_color", TEXT)
	item.add_theme_color_override("font_pressed_color", TEXT)
	item.add_theme_color_override("font_disabled_color", DIM)
	if on_pressed.is_valid():
		item.pressed.connect(on_pressed)
	return item


# Standard progress bar without a percentage readout.
static func progress_bar(value: float, max_value: float, color: Color = ACCENT) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = maxf(max_value, 0.001)
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(0)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


static func back_row(screen_root: Control, target: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(button("Back", func() -> void: GameManager.request(target)))
	screen_root.add_child(row)
	return row


static func panel() -> PanelContainer:
	return PanelContainer.new()


# Board frame for the cross games: the shared panel look but with the
# game's own accent color as the border, so each game reads colorful.
static func game_panel(color: Color) -> PanelContainer:
	var item := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = color
	style.set_border_width_all(1)
	style.border_width_left = 4
	style.set_corner_radius_all(0)
	style.set_content_margin_all(16)
	item.add_theme_stylebox_override("panel", style)
	return item


# Reliable centering: PRESET_CENTER on a PanelContainer whose size is not yet
# computed puts its top-left at the screen center (panel drifts off bottom-
# right). A full-rect CenterContainer always centers the child correctly.
static func centered_panel(parent: Control, min_size: Vector2) -> PanelContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = min_size
	center.add_child(frame)
	return frame


# A centered popup frame containing a scrollable VBox. Returns the VBox.
static func popup_box(parent: Control, min_size: Vector2) -> VBoxContainer:
	var frame := centered_panel(parent, min_size)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = min_size - Vector2(28, 28)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	return box


# Header row with a title on the left and a square X button on the right.
static func header_with_close(title_text: String, on_close: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(heading(title_text.to_upper(), 14, ACCENT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var close_button := button("X", on_close)
	close_button.custom_minimum_size = Vector2(44, 40)
	row.add_child(close_button)
	return row


static func info_rows(items: Array) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	for item in items:
		box.add_child(wrapped(str(item), 18, DIM))
	return box


static func banner(text: String, color: Color) -> PanelContainer:
	var panel_box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.68)
	style.border_color = color
	style.set_border_width_all(1)
	style.border_width_left = 5
	style.set_corner_radius_all(0)
	style.set_content_margin_all(10)
	panel_box.add_theme_stylebox_override("panel", style)
	panel_box.add_child(label(text, 20, color))
	return panel_box


# Small rectangular chip label used for statuses and data tags.
static func tag(text: String, color: Color = ACCENT_2) -> PanelContainer:
	var item := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.76)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	item.add_theme_stylebox_override("panel", style)
	item.add_child(label(text, 17, color))
	return item


# Small square indicator lamp.
static func lamp(color: Color) -> PanelContainer:
	var item := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(0)
	item.custom_minimum_size = Vector2(12, 12)
	item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item.add_theme_stylebox_override("panel", style)
	return item


# Key / value row with the value pushed to the right edge.
static func kv_row(key_text: String, value_text: String, value_color: Color = TEXT) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(label(key_text, 18, DIM))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(label(value_text, 18, value_color))
	return row


# Dim briefing panel shown at the top of every task.
static func hint_box(text: String) -> PanelContainer:
	var item := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = BG_SOFT
	style.border_color = PANEL_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(10)
	item.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	item.add_child(box)
	box.add_child(heading("BRIEFING", 10, ACCENT_2))
	box.add_child(wrapped(text, 18, DIM))
	return item


# Styled status line used by task feedback.
static func status(text: String = "") -> Label:
	var item := label(text, 19, WARN)
	item.custom_minimum_size = Vector2(0, 24)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item


static func divider() -> HSeparator:
	return HSeparator.new()


# Instant gauge: header with value + OK / OUT OF RANGE chip and a drawn bar
# showing the safe zone and the current reading. Safe zone reads cyan.
static func gauge(title_text: String, value: float, lo: float, hi: float, unit: String, ok: bool) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.add_child(label(title_text, 18, TEXT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(label("%s %s" % [_fmt_value(value), unit], 18, SUCCESS if ok else DANGER))
	header.add_child(tag("OK" if ok else "OUT OF RANGE", SUCCESS if ok else DANGER))
	box.add_child(header)
	var span_lo := minf(lo, value) - maxf(2.0, absf(value) * 0.15)
	var span_hi := maxf(hi, value) + maxf(2.0, absf(value) * 0.15)
	if span_lo >= span_hi:
		span_lo = lo - 1.0
		span_hi = hi + 1.0
	var bar := GaugeBar.new()
	bar.setup(span_lo, span_hi, lo, hi, value, ok)
	bar.custom_minimum_size = Vector2(0, 30)
	box.add_child(bar)
	return box


static func _fmt_value(value: float) -> String:
	if absf(value - roundf(value)) < 0.005:
		return "%d" % int(roundf(value))
	return "%.1f" % value


static func timing_track(zone_lo: float, zone_hi: float, speed: float) -> TimingTrack:
	return TimingTrack.new(zone_lo, zone_hi, speed)


static func signal_scope() -> SignalScope:
	return SignalScope.new()


static func starfield() -> Starfield:
	return Starfield.new()


static func city_backdrop() -> CityBackdrop:
	return CityBackdrop.new()


static func pulse_trace(abnormal: bool) -> PulseTrace:
	return PulseTrace.new(abnormal)


static func scroll_box(min_height := 0.0) -> Array:
	var holder := ScrollContainer.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if min_height > 0.0:
		holder.custom_minimum_size = Vector2(0, min_height)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	holder.add_child(box)
	return [holder, box]


static func clear(node: Control) -> void:
	for child in node.get_children():
		child.queue_free()


# ---------------------------------------------------------------- instruments

class GaugeBar extends Control:
	# Horizontal bar with a cyan safe zone and a marker at the current value.
	const ZONE_FILL := Color(0.3, 0.91, 1.0, 0.22)
	const TRACK := Color("091228")
	var scale_min := 0.0
	var scale_max := 1.0
	var zone_lo := 0.0
	var zone_hi := 1.0
	var value := 0.0
	var ok := true

	func setup(min_v: float, max_v: float, lo: float, hi: float, current: float, is_ok: bool) -> void:
		scale_min = min_v
		scale_max = max_v
		zone_lo = lo
		zone_hi = hi
		value = current
		ok = is_ok

	func update_gauge(current: float, is_ok: bool) -> void:
		value = current
		ok = is_ok
		queue_redraw()

	func _draw() -> void:
		var span := scale_max - scale_min
		if span <= 0.0 or size.x <= 2.0:
			return
		var track_h := 14.0
		var y := (size.y - track_h) * 0.5
		var w := size.x
		draw_rect(Rect2(0, y, w, track_h), TRACK)
		var zone_x := w * (zone_lo - scale_min) / span
		var zone_w := w * (zone_hi - zone_lo) / span
		var zone := Rect2(zone_x, y, zone_w, track_h)
		draw_rect(zone, ZONE_FILL)
		for i in range(1, 4):
			var tx := w * float(i) / 4.0
			draw_line(Vector2(tx, y), Vector2(tx, y + track_h), Color(1, 1, 1, 0.06), 1.0)
		var marker_color := Color("4de8ff") if ok else Color("ff6a4d")
		var mx := clampf(w * (value - scale_min) / span, 2.0, w - 2.0)
		draw_rect(Rect2(mx - 2.0, y - 3.0, 4.0, track_h + 6.0), marker_color)
		draw_rect(Rect2(0, y, w, track_h), Color("2b4677"), false, 1.0)
		draw_rect(zone, Color(0.3, 0.91, 1.0, 0.75), false, 1.0)


class TimingTrack extends Control:
	# Animated timing instrument: a marker sweeps back and forth; the player
	# stops it inside the cyan window. Used for burns and measurements.
	signal locked_track(value: float, in_zone: bool)
	const TRACK := Color("091228")
	const ZONE_FILL := Color(0.3, 0.91, 1.0, 0.22)
	var zone_lo := 0.45
	var zone_hi := 0.55
	var speed := 0.8
	var marker := 0.0
	var direction := 1.0
	var is_locked := false
	var in_zone := false

	func _init(track_zone_lo: float, track_zone_hi: float, track_speed: float) -> void:
		zone_lo = track_zone_lo
		zone_hi = track_zone_hi
		speed = track_speed
		custom_minimum_size = Vector2(0, 54)

	func stop() -> void:
		if is_locked:
			return
		is_locked = true
		in_zone = marker >= zone_lo and marker <= zone_hi
		queue_redraw()
		locked_track.emit(marker, in_zone)

	func reset() -> void:
		is_locked = false
		in_zone = false
		marker = 0.0
		direction = 1.0
		queue_redraw()

	func _process(delta: float) -> void:
		if is_locked:
			return
		marker += direction * speed * delta
		if marker >= 1.0:
			marker = 1.0
			direction = -1.0
		elif marker <= 0.0:
			marker = 0.0
			direction = 1.0
		queue_redraw()

	func _draw() -> void:
		if size.x <= 2.0:
			return
		var track_h := 22.0
		var y := (size.y - track_h) * 0.5
		var w := size.x
		draw_rect(Rect2(0, y, w, track_h), TRACK)
		var zone := Rect2(w * zone_lo, y, w * (zone_hi - zone_lo), track_h)
		draw_rect(zone, ZONE_FILL)
		for i in range(1, 5):
			var tx := w * float(i) / 5.0
			draw_line(Vector2(tx, y), Vector2(tx, y + track_h), Color(1, 1, 1, 0.05), 1.0)
		var marker_color := ACCENT
		if is_locked:
			marker_color = Color("4de8ff") if in_zone else Color("ff6a4d")
		var mx := clampf(w * marker, 3.0, w - 3.0)
		draw_rect(Rect2(mx - 2.5, y - 5.0, 5.0, track_h + 10.0), marker_color)
		draw_circle(Vector2(mx, y - 5.0), 5.0, marker_color)
		draw_rect(Rect2(0, y, w, track_h), Color("2b4677"), false, 1.0)
		draw_rect(zone, Color(0.3, 0.91, 1.0, 0.75), false, 1.0)


class SignalScope extends Control:
	# Animated oscilloscope-style waveform. interference 0..1: 0 is a clean
	# carrier wave, 1 is heavy static. Used in the comms radio room.
	const GRID := Color(1, 1, 1, 0.05)
	var interference := 1.0
	var t := 0.0
	var wave_color := Color("38c8ff")
	var offsets := PackedFloat32Array()

	func _init() -> void:
		custom_minimum_size = Vector2(0, 112)
		var rng := RandomNumberGenerator.new()
		rng.seed = 20260
		for i in 512:
			offsets.append(rng.randf_range(-1.0, 1.0))

	func set_interference(v: float) -> void:
		interference = clampf(v, 0.0, 1.0)

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 4.0 or h <= 4.0:
			return
		var mid := h * 0.5
		for i in range(1, 4):
			draw_line(Vector2(w * float(i) / 4.0, 0), Vector2(w * float(i) / 4.0, h), GRID, 1.0)
		for i in range(1, 3):
			draw_line(Vector2(0, h * float(i) / 3.0), Vector2(w, h * float(i) / 3.0), GRID, 1.0)
		draw_line(Vector2(0, mid), Vector2(w, mid), Color(1, 1, 1, 0.12), 1.0)
		var points := PackedVector2Array()
		var step := 4.0
		var x := 0.0
		var index := 0
		while x <= w:
			var envelope := sin(PI * x / maxf(1.0, w))
			var clean := sin(x * 0.045 + t * 6.0) * (h * 0.30) * (1.0 - interference * 0.62)
			var jitter: float = offsets[index % 512] * interference * h * 0.30
			points.append(Vector2(x, mid + clean * envelope + jitter))
			x += step
			index += 1
		draw_polyline(points, wave_color, 2.0)


class PulseTrace extends Control:
	# Live heart-rate trace for the sickbay monitors. A synthetic ECG beat
	# (P wave, QRS spike, T wave) scrolls across the strip. abnormal=true adds
	# irregular intervals and stray spikes so a healthy read and a worried one
	# are obvious at a glance. inactive=true draws a dim flat "no signal" line.
	const GRID := Color(1, 1, 1, 0.04)
	const BPM := 68.0
	var abnormal := false
	var active := false
	var t := 0.0
	var phase := 0.0
	var seed_off := 0.0

	func _init(is_abnormal: bool) -> void:
		abnormal = is_abnormal
		seed_off = randf() * 10.0
		custom_minimum_size = Vector2(0, 64)

	func set_active(on: bool) -> void:
		active = on
		queue_redraw()

	func _process(delta: float) -> void:
		if not active:
			return
		t += delta
		var interval := 60.0 / BPM
		if abnormal:
			interval += 0.35 * sin(t * 0.9 + seed_off)
		phase += delta / maxf(0.2, interval)
		queue_redraw()

	func _beat(value: float) -> float:
		# One normalized ECG beat on 0..1. Returns -1..1-ish amplitude.
		var p := clampf(value, 0.0, 1.0)
		var amp := -0.12 * exp(-pow((p - 0.16) / 0.05, 2.0))          # P wave dip
		amp += -1.0 * exp(-pow((p - 0.30) / 0.016, 2.0))              # Q dip
		amp += 1.0 * exp(-pow((p - 0.34) / 0.018, 2.0))               # R spike
		amp += -0.35 * exp(-pow((p - 0.38) / 0.02, 2.0))              # S dip
		amp += 0.32 * exp(-pow((p - 0.58) / 0.06, 2.0))               # T wave
		if abnormal:
			amp += 0.22 * exp(-pow((p - 0.72) / 0.03, 2.0)) * sin(seed_off * 7.0)   # stray ectopic bump
			amp += 0.18 * sin(p * 41.0 + seed_off) * 0.25                            # noisy baseline
		return amp

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 4.0 or h <= 4.0:
			return
		var mid := h * 0.5
		for i in range(1, 4):
			draw_line(Vector2(w * float(i) / 4.0, 0), Vector2(w * float(i) / 4.0, h), GRID, 1.0)
		draw_line(Vector2(0, mid), Vector2(w, mid), Color(1, 1, 1, 0.10), 1.0)
		if not active:
			draw_line(Vector2(0, mid), Vector2(w, mid), Color("8aa3cf"), 1.0)
			draw_string(FONT_BODY, Vector2(6, h - 6), "NO SIGNAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("51648c"))
			return
		var points := PackedVector2Array()
		var step := 3.0
		var x := 0.0
		while x <= w:
			var u := x / maxf(1.0, w)
			var beat_pos := fmod(u + phase, 1.0)
			var amp := _beat(beat_pos)
			points.append(Vector2(x, mid - amp * h * 0.36))
			x += step
		var wave := Color("4de8ff") if not abnormal else Color("ffa632")
		draw_polyline(points, wave, 2.0)
		var bpm := int(BPM) + (14 if abnormal else 0)
		draw_string(FONT_BODY, Vector2(6, 16), "%d BPM" % bpm, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, wave)


class CityBackdrop extends Control:
	# Cinematic nighttime city backdrop: dark navy-blue skyline in three soft
	# layers, glowing warm-orange windows on the left, electric-blue and cyan
	# windows toward the center, faint stars and slowly floating light
	# particles. Everything is deterministic (seeded) and drawn with plain
	# rects - no textures, no 3D, stays sharp at any window size.
	const SKY_TOP := Color("060b18")
	const SKY_LOW := Color("14274e")
	const LAYER_BACK := Color(0.05, 0.10, 0.21, 0.85)
	const LAYER_MID := Color(0.06, 0.12, 0.24, 0.95)
	const LAYER_FRONT := Color(0.075, 0.14, 0.28, 1.0)
	const WARM_A := Color("ffa632")
	const WARM_B := Color("ff8a4d")
	const COOL_A := Color("2f8bff")
	const COOL_B := Color("4de8ff")
	var t := 0.0
	var layers: Array = []      # [{x, w, h, layer, warm, seed}]
	var stars: Array = []
	var particles: Array = []

	func _init() -> void:
		_generate()

	func _generate() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261114
		layers.clear()
		# Three skyline layers, back to front. Each building: start-x,
		# width, height (all as fractions) plus a window "temperature".
		var configs := [
			{"count": 13, "h0": 0.16, "h1": 0.34, "layer": 0},
			{"count": 9, "h0": 0.22, "h1": 0.44, "layer": 1},
			{"count": 8, "h0": 0.26, "h1": 0.54, "layer": 2},
		]
		for config in configs:
			var x := -0.04
			while x < 1.04:
				var fw := rng.randf_range(0.06, 0.13)
				var fh := rng.randf_range(float(config["h0"]), float(config["h1"]))
				var warm := x < 0.34 or (x < 0.5 and rng.randf() < 0.35)
				layers.append({
					"x": x, "w": fw, "h": fh,
					"layer": int(config["layer"]),
					"warm": warm,
					"seed": rng.randi(),
				})
				x += fw * rng.randf_range(0.82, 1.05)
		for i in 90:
			stars.append({
				"x": rng.randf(),
				"y": rng.randf() * 0.55,
				"s": rng.randf_range(0.6, 1.8),
				"tw": rng.randf_range(0.5, 2.2),
				"ph": rng.randf() * TAU,
			})
		for i in 42:
			var palette := [COOL_B, COOL_A, WARM_A, Color(0.9, 0.95, 1.0)]
			particles.append({
				"x": rng.randf(),
				"y": rng.randf(),
				"speed": rng.randf_range(0.018, 0.05),
				"size": rng.randf_range(1.2, 3.2),
				"sway": rng.randf_range(0.4, 1.6),
				"ph": rng.randf() * TAU,
				"color": palette[rng.randi() % palette.size()],
			})

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 4.0 or h <= 4.0:
			return
		# Night sky: hand-banded vertical fade from deep navy to horizon blue.
		var bands := 26
		for i in bands:
			var f := float(i) / float(bands)
			var strip := SKY_TOP.lerp(SKY_LOW, pow(f, 1.6))
			draw_rect(Rect2(0, f * h, w, h / float(bands) + 1.0), strip)
		# Faint stars in the upper half.
		for star in stars:
			var alpha := 0.12 + 0.4 * (0.5 + 0.5 * sin(t * float(star["tw"]) + float(star["ph"])))
			draw_circle(Vector2(float(star["x"]) * w, float(star["y"]) * h), float(star["s"]), Color(1, 1, 1, alpha))
		# Skyline, back to front, with lit windows.
		for building in layers:
			_draw_building(building, w, h)
		# Street-level haze so the skyline sits down instead of floating.
		draw_rect(Rect2(0, h - h * 0.03, w, h * 0.03), Color(0.11, 0.2, 0.4, 0.55))
		# Floating light particles drifting slowly upward.
		for particle in particles:
			var py := fmod(float(particle["y"]) - t * float(particle["speed"]), 1.15)
			if py < 0.0:
				py += 1.15
			var px := float(particle["x"]) + 0.02 * sin(t * float(particle["sway"]) + float(particle["ph"]))
			var glow := 0.18 + 0.26 * (0.5 + 0.5 * sin(t * 1.7 + float(particle["ph"]) * 2.0))
			var pos := Vector2(px * w, py * h)
			var color: Color = particle["color"]
			draw_circle(pos, float(particle["size"]) + 2.5, Color(color.r, color.g, color.b, glow * 0.35))
			draw_circle(pos, float(particle["size"]), Color(color.r, color.g, color.b, glow))

	func _draw_building(b: Dictionary, w: float, h: float) -> void:
		var layer := int(b["layer"])
		var bw := float(b["w"]) * w
		var bh := float(b["h"]) * h
		var bx := float(b["x"]) * w
		var top := h - bh
		var body := LAYER_BACK
		if layer == 1:
			body = LAYER_MID
		elif layer == 2:
			body = LAYER_FRONT
		draw_rect(Rect2(bx, top, bw + 1.0, bh + 2.0), body)
		if layer == 0:
			return
		# Window grid: small glowing rects. Warm on the left of town,
		# electric blue / cyan toward the centre - per the direction brief.
		var cols := maxi(1, int(bw / 22.0))
		var rows := maxi(1, int(bh / 30.0))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(b["seed"])
		var margin_x := 6.0
		var margin_y := 10.0
		var cell_w := (bw - margin_x * 2.0) / float(cols)
		var cell_h := (bh - margin_y * 2.0) / float(rows)
		for cy in rows:
			for cx in cols:
				if rng.randf() > 0.34:
					continue
				var wx := bx + margin_x + cell_w * (float(cx) + 0.24)
				var wy := top + margin_y + cell_h * (float(cy) + 0.22)
				var ww := maxf(3.0, cell_w * 0.5)
				var wh := maxf(3.0, cell_h * 0.42)
				var pick := rng.randf()
				var color := WARM_A if bool(b["warm"]) else (COOL_A if pick < 0.55 else COOL_B)
				if bool(b["warm"]) and pick > 0.7:
					color = WARM_B
				var flicker := 0.75 + 0.25 * sin(t * rng.randf_range(0.6, 2.0) + fmod(float(b["seed"]), 10.0) + float(cx) * float(cy))
				draw_rect(Rect2(wx - 1.5, wy - 1.5, ww + 3.0, wh + 3.0), Color(color.r, color.g, color.b, 0.10 * flicker))
				draw_rect(Rect2(wx, wy, ww, wh), Color(color.r, color.g, color.b, 0.82 * flicker))


class OperatorPortrait extends Control:
	# Squad-slot artwork. Uses an uploaded pixel portrait when one is handed
	# in (nearest-neighbour scaled so pixel art stays crisp); otherwise draws
	# a clean suited-operator silhouette with a profession-colored visor.
	var accent := Color("4de8ff")
	var dimmed := false
	var bob := 0.0
	var animate := false
	var texture: Texture2D = null

	func _init(color: Color, is_dimmed: bool = false, uploaded: Texture2D = null) -> void:
		accent = color
		dimmed = is_dimmed
		texture = uploaded
		if texture != null:
			texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(delta: float) -> void:
		if animate:
			bob += delta
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 4.0 or h <= 4.0:
			return
		var alpha := 0.32 if dimmed else 1.0
		if texture != null:
			var tex_w := float(texture.get_width())
			var tex_h := float(texture.get_height())
			if tex_w > 1.0 and tex_h > 1.0:
				var fit := minf(w / tex_w, h / tex_h)
				var rect := Rect2((w - tex_w * fit) * 0.5, (h - tex_h * fit) * 0.5, tex_w * fit, tex_h * fit)
				draw_texture_rect(texture, rect, false, Color(1, 1, 1, alpha))
			return
		var suit := Color(Color("1b3059").r, Color("1b3059").g, Color("1b3059").b, alpha)
		var suit_dark := Color(Color("132445").r, Color("132445").g, Color("132445").b, alpha)
		var edge := Color(Color("2b4677").r, Color("2b4677").g, Color("2b4677").b, alpha)
		var glow := Color(accent.r, accent.g, accent.b, alpha)
		var cx := w * 0.5
		var base := h * 0.98
		var lift := 2.0 * sin(bob * 2.0) if animate else 0.0
		# Shoulder block: wide torso with darker side panels.
		var torso := Rect2(cx - w * 0.34, h * 0.56 + lift, w * 0.68, base - h * 0.56 - lift)
		draw_rect(torso, suit)
		draw_rect(Rect2(torso.position, Vector2(w * 0.14, torso.size.y)), suit_dark)
		draw_rect(Rect2(Vector2(torso.position.x + torso.size.x - w * 0.14, torso.position.y), Vector2(w * 0.14, torso.size.y)), suit_dark)
		# Chest console with two tiny status lamps.
		var panel := Rect2(cx - w * 0.13, h * 0.66 + lift, w * 0.26, h * 0.13)
		draw_rect(panel, suit_dark)
		draw_rect(Rect2(panel.position, Vector2(panel.size.x, 2.0)), edge)
		draw_rect(Rect2(panel.position + Vector2(4, 4), Vector2(5, 5)), Color(Color("ffa632").r, Color("ffa632").g, Color("ffa632").b, alpha))
		draw_rect(Rect2(panel.position + Vector2(13, 4), Vector2(5, 5)), Color(Color("4de8ff").r, Color("4de8ff").g, Color("4de8ff").b, alpha))
		# Helmet: ring, shell, and a slim profession-colored visor.
		var hr := w * 0.20
		var hcenter := Vector2(cx, h * 0.34 + lift)
		draw_arc(hcenter, hr + 1.5, 0.0, TAU, 24, edge, 2.0)
		draw_circle(hcenter, hr, suit)
		var visor := Rect2(hcenter.x - hr * 0.82, hcenter.y - hr * 0.28, hr * 1.64, hr * 0.52)
		draw_rect(Rect2(visor.position - Vector2(2, 2), visor.size + Vector2(4, 4)), Color(accent.r, accent.g, accent.b, 0.14 * alpha))
		draw_rect(visor, glow)
		draw_rect(Rect2(visor.position + Vector2(3, 2), Vector2(visor.size.x * 0.22, 2.0)), Color(1, 1, 1, 0.4 * alpha))
		# Neck ring.
		draw_rect(Rect2(cx - hr * 0.55, hcenter.y + hr - 1.0, hr * 1.1, 4.0), edge)
		# Outline the torso.
		draw_rect(torso, edge, false, 1.0)


class Starfield extends Control:
	# Slowly drifting, twinkling star background. Add as the first child of a
	# screen so every other control draws on top of it.
	const STAR := Color(0.85, 0.9, 1.0)
	var stars: Array = []
	var t := 0.0

	func _init() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 150:
			stars.append({
				"x": rng.randf(),
				"y": rng.randf(),
				"s": rng.randf_range(0.8, 2.4),
				"tw": rng.randf_range(0.4, 2.4),
				"ph": rng.randf() * TAU,
				"drift": rng.randf_range(0.004, 0.012),
			})

	func _process(delta: float) -> void:
		t += delta
		for star in stars:
			var nx := float(star["x"]) - float(star["drift"]) * delta
			star["x"] = 1.02 if nx < -0.02 else nx
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 0.0 or h <= 0.0:
			return
		for star in stars:
			var alpha := 0.18 + 0.5 * (0.5 + 0.5 * sin(t * float(star["tw"]) + float(star["ph"])))
			draw_circle(Vector2(float(star["x"]) * w, float(star["y"]) * h), float(star["s"]), Color(STAR.r, STAR.g, STAR.b, alpha))

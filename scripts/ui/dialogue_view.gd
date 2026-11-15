extends Control

const UIKit = preload("res://scripts/ui/ui_kit.gd")

const PORTRAIT_COLORS := {
	"player": "ffa632",
	"mira_vale": "f2f2f2",
}

var panel: Control = null
var portrait: ColorRect = null
var portrait_art: TextureRect = null
var initials: Label = null
var name_label: Label = null
var role_label: Label = null
var text_label: RichTextLabel = null
var choices_box: VBoxContainer = null
var continue_hint: Label = null

var _full_text := ""
var _shown := 0.0
var _typing := false
var _last_choices: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -210
	panel.offset_bottom = -10
	panel.offset_left = 10
	panel.offset_right = -10
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = UIKit.PANEL
	panel_style.border_color = UIKit.PANEL_EDGE
	panel_style.set_border_width_all(1)
	panel_style.border_width_top = 3
	panel_style.set_corner_radius_all(0)
	panel_style.set_content_margin_all(14)
	panel_style.shadow_color = Color(0, 0, 0, 0.4)
	panel_style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", UIKit.texture_stylebox("ui/panel_edge.png", panel_style))
	add_child(panel)
	# Uploaded cockpit view sits behind the conversation panel, dimmed so
	# the chat text stays readable on top of it.
	var view_art := UIKit.art("ui/spaceship view.png")
	if view_art != null:
		var view_rect := TextureRect.new()
		view_rect.texture = view_art
		view_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		view_rect.modulate = Color(1, 1, 1, 0.45)
		view_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(view_rect)
		move_child(view_rect, 0)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	panel.add_child(columns)

	var portrait_box := VBoxContainer.new()
	portrait = ColorRect.new()
	portrait.custom_minimum_size = Vector2(96, 96)
	portrait_box.add_child(portrait)
	initials = UIKit.label("", 24, UIKit.BG)
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.add_child(initials)
	portrait_art = TextureRect.new()
	portrait_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_art.visible = false
	portrait.add_child(portrait_art)
	name_label = UIKit.label("", 16)
	name_label.custom_minimum_size = Vector2(96, 0)
	portrait_box.add_child(name_label)
	columns.add_child(portrait_box)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 6)
	columns.add_child(text_box)

	role_label = UIKit.label("", 14, UIKit.DIM)
	text_box.add_child(role_label)
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = false
	text_label.fit_content = true
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_child(text_label)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 6)
	text_box.add_child(choices_box)
	continue_hint = UIKit.label("Click or press E to continue", 14, UIKit.DIM)
	text_box.add_child(continue_hint)

	DialogueManager.line_shown.connect(_on_line)
	DialogueManager.conversation_ended.connect(_on_ended)


func _exit_tree() -> void:
	DialogueManager.line_shown.disconnect(_on_line)
	DialogueManager.conversation_ended.disconnect(_on_ended)


func _process(delta: float) -> void:
	if not _typing:
		return
	var speed := float(SaveManager.settings.get("text_speed", 48))
	if bool(SaveManager.settings.get("instant_text", false)):
		speed = 9999.0
	_shown += speed * delta
	text_label.visible_characters = int(_shown)
	if text_label.visible_characters >= text_label.get_total_character_count():
		text_label.visible_characters = -1
		_typing = false


func _gui_input(event: InputEvent) -> void:
	pass


func _input(event: InputEvent) -> void:
	if not DialogueManager.active or not visible:
		return
	var pressed_advance := event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if not pressed_advance:
		return
	if _typing:
		_typing = false
		text_label.visible_characters = -1
		return
	if _last_choices.is_empty():
		get_viewport().set_input_as_handled()
		DialogueManager.advance()


func _on_line(speaker_id: String, speaker_name: String, profession_name: String, text: String, choices: Array) -> void:
	visible = true
	_last_choices = choices
	var color := _speaker_color(speaker_id, profession_name)
	# Portrait chain: portraits/<speaker id>, then the speaker's profession
	# portrait (crew NPCs like mira_vale use the director art, the player
	# uses the chosen profession), then the icons folder, then initials.
	var uploaded := UIKit.art("portraits/%s.png" % speaker_id)
	if uploaded == null and speaker_id != "player":
		var member := ProfessionManager.member(speaker_id)
		if not member.is_empty():
			uploaded = UIKit.art("portraits/%s.png" % str(member.get("profession", "")))
	if uploaded == null and speaker_id == "player":
		uploaded = UIKit.art("portraits/%s.png" % str(SaveManager.state.get("profession", "")))
	if uploaded == null:
		uploaded = UIKit.art("icons/%s.png" % speaker_id)
	if uploaded != null:
		portrait.color = UIKit.PANEL
		portrait_art.texture = uploaded
		portrait_art.visible = true
		initials.visible = false
	else:
		portrait.color = color
		portrait_art.visible = false
		initials.visible = true
	initials.text = _initials_of(speaker_name)
	name_label.text = speaker_name
	role_label.text = profession_name

	UIKit.clear(choices_box)
	if text == "" and not choices.is_empty():
		text_label.text = "Your call:"
		text_label.visible_characters = -1
		_typing = false
		continue_hint.text = ""
		for i in choices.size():
			var index := i
			choices_box.add_child(UIKit.button(str(choices[i]), func() -> void:
				DialogueManager.choose(index)
			))
		return
	continue_hint.text = "Click or press E to continue"
	_full_text = text
	text_label.text = text
	_shown = 0.0
	text_label.visible_characters = 0
	_typing = true


func _on_ended() -> void:
	visible = false
	_last_choices = []
	_typing = false


func _speaker_color(speaker_id: String, profession_name: String) -> Color:
	if PORTRAIT_COLORS.has(speaker_id):
		return Color.html(PORTRAIT_COLORS[speaker_id])
	if speaker_id == "player":
		return ProfessionManager.color_of(str(SaveManager.state.get("profession", "")))
	var color := ProfessionManager.color_of(profession_name.to_lower().replace(" ", "_"))
	if color == Color("38c8ff") and profession_name != "":
		return UIKit.PANEL_LIGHT
	return color


func _initials_of(name: String) -> String:
	var parts := name.strip_edges().split(" ", false)
	var out := ""
	for part in parts:
		if part.length() > 0:
			out += part[0].to_upper()
		if out.length() >= 2:
			break
	return out if out != "" else "?"

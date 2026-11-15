extends Control

const UIKit = preload("res://scripts/ui/ui_kit.gd")

var _speed: HSlider
var _instant: CheckBox
var _fullscreen: CheckBox
var _volume: HSlider


func _ready() -> void:
	var root := UIKit.screen("Settings", "Applies immediately and is saved separately from the campaign.")
	add_child(root)

	var form := UIKit.panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	form.add_child(box)
	root.add_child(form)

	box.add_child(UIKit.label("Dialogue text speed (%d)" % int(SaveManager.settings.get("text_speed", 48)), 20))
	_speed = HSlider.new()
	_speed.min_value = 16
	_speed.max_value = 120
	_speed.step = 4
	_speed.value = float(SaveManager.settings.get("text_speed", 48))
	_speed.custom_minimum_size = Vector2(360, 44)
	box.add_child(_speed)

	_instant = CheckBox.new()
	_instant.text = "Show dialogue text instantly"
	_instant.button_pressed = bool(SaveManager.settings.get("instant_text", false))
	box.add_child(_instant)

	_fullscreen = CheckBox.new()
	_fullscreen.text = "Fullscreen"
	_fullscreen.button_pressed = bool(SaveManager.settings.get("fullscreen", false))
	box.add_child(_fullscreen)

	box.add_child(UIKit.label("Volume", 20))
	_volume = HSlider.new()
	_volume.min_value = 0.0
	_volume.max_value = 1.0
	_volume.step = 0.05
	_volume.value = float(SaveManager.settings.get("volume", 1.0))
	_volume.custom_minimum_size = Vector2(360, 44)
	box.add_child(_volume)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UIKit.button("Save and back", _save))
	row.add_child(UIKit.button("Back without saving", func() -> void: GameManager.request("main_menu")))
	root.add_child(row)


func _save() -> void:
	SaveManager.settings["text_speed"] = int(_speed.value)
	SaveManager.settings["instant_text"] = _instant.button_pressed
	SaveManager.settings["fullscreen"] = _fullscreen.button_pressed
	SaveManager.settings["volume"] = _volume.value
	SaveManager.save_settings()
	GameManager.request("main_menu")

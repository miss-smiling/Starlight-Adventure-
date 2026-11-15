extends Node

const UIKit = preload("res://scripts/ui/ui_kit.gd")

var theme: Theme

func _ready() -> void:
	theme = UIKit.build_theme()


func apply_theme(node: Control) -> void:
	if theme == null:
		theme = UIKit.build_theme()
	node.theme = theme


func make_screen(id: String) -> Control:
	match id:
		"main_menu":
			return preload("res://scripts/ui/main_menu.gd").new()
		"new_game":
			return preload("res://scripts/ui/new_game_screen.gd").new()
		"profession":
			return preload("res://scripts/ui/profession_select.gd").new()
		"mission_select":
			return preload("res://scripts/ui/mission_select.gd").new()
		"settings":
			return preload("res://scripts/ui/settings_screen.gd").new()
		"achievements":
			return preload("res://scripts/ui/progress_screen.gd").new()
		"leaderboard":
			return preload("res://scripts/ui/leaderboard_screen.gd").new()
		"archive":
			return preload("res://scripts/ui/archive_screen.gd").new()
		"gameplay":
			return preload("res://scripts/ui/gameplay_screen.gd").new()
		"debrief":
			return preload("res://scripts/ui/debrief_screen.gd").new()
		_:
			return preload("res://scripts/ui/main_menu.gd").new()

extends Control

const UIKit = preload("res://scripts/ui/ui_kit.gd")


func _ready() -> void:
	var history: Array = SaveManager.state.get("mission_history", [])
	var root := UIKit.screen("Mission Archive", "Replay any completed mission. Replays never touch your real campaign record - skill achievements and professions played still count.")
	add_child(root)

	if history.is_empty():
		root.add_child(UIKit.wrapped("Complete your first mission to unlock the archive.", 18, UIKit.DIM))
	else:
		var holder := UIKit.scroll_box(0.0)
		root.add_child(holder[0])
		var list: VBoxContainer = holder[1]
		for entry in history:
			var panel := UIKit.panel()
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			panel.add_child(row)
			var text := "%s (%d) - %s, %d points, grade %s" % [
				str(entry.get("title", "")), int(entry.get("year", 0)),
				ProfessionManager.display_name(str(entry.get("profession", ""))),
				int(entry.get("points", 0)), str(entry.get("grade", "")),
			]
			row.add_child(UIKit.label(text, 18))
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(spacer)
			row.add_child(UIKit.button("Replay", func() -> void:
				GameManager.open_mission(str(entry.get("id", "")), true, false)
			))
			list.add_child(panel)

	UIKit.back_row(root, "mission_select")

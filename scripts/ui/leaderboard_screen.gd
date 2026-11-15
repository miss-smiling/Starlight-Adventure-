extends Control

const UIKit = preload("res://scripts/ui/ui_kit.gd")


func _ready() -> void:
	var root := UIKit.screen("Leaderboard", "Top mission scores stored on this computer. Works fully offline.")
	add_child(root)

	if SaveManager.leaderboard.is_empty():
		root.add_child(UIKit.wrapped("No scores yet. Finish a mission to post the first one.", 18, UIKit.DIM))
	else:
		var holder := UIKit.scroll_box(0.0)
		root.add_child(holder[0])
		var list: VBoxContainer = holder[1]
		var header := HBoxContainer.new()
		for column in ["#", "Callsign", "Mission", "Profession", "Year", "Points", "Grade"]:
			var item := UIKit.label(column, 18, UIKit.ACCENT)
			item.custom_minimum_size = Vector2(0, 0)
			item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			header.add_child(item)
		list.add_child(header)
		for i in SaveManager.leaderboard.size():
			var entry: Dictionary = SaveManager.leaderboard[i]
			var row := HBoxContainer.new()
			for value in [str(i + 1), str(entry.get("callsign", "")), str(entry.get("mission", "")), ProfessionManager.display_name(str(entry.get("profession", ""))), str(entry.get("year", "")), str(entry.get("points", 0)), str(entry.get("grade", ""))]:
				var item := UIKit.label(value, 16)
				item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(item)
			list.add_child(row)

	UIKit.back_row(root, "main_menu")

extends Control

const UIKit = preload("res://scripts/ui/ui_kit.gd")


func _ready() -> void:
	var root := UIKit.screen("Achievements", "Milestones earned across every campaign on this computer.")
	add_child(root)

	var holder := UIKit.scroll_box(0.0)
	root.add_child(holder[0])
	var list: VBoxContainer = holder[1]

	var earned: Array = SaveManager.state.get("achievements", [])
	for item in CampaignManager.achievements:
		var id := str(item.get("id", ""))
		var unlocked := earned.has(id)
		var panel := UIKit.panel()
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		panel.add_child(box)
		var title := "%s%s" % [str(item.get("title", id)), " - unlocked" if unlocked else " - locked"]
		box.add_child(UIKit.label(title, 20, UIKit.SUCCESS if unlocked else UIKit.DIM))
		box.add_child(UIKit.wrapped(str(item.get("text", "")), 16))
		box.add_child(UIKit.wrapped("How to earn it: %s" % str(item.get("hint", "")), 14, UIKit.DIM))
		list.add_child(panel)

	UIKit.back_row(root, "main_menu")

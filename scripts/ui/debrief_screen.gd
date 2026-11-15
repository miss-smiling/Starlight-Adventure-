extends Control

const UIKit = preload("res://scripts/ui/ui_kit.gd")


func _ready() -> void:
	var report: Dictionary = GameManager.last_report
	var fresh: Array = GameManager.last_achievements
	var replay := bool(SaveManager.state.get("replay", false))
	var grade := str(report.get("grade", ""))
	var grade_color := UIKit.SUCCESS if grade == "A" or grade == "B" else (UIKit.TEXT if grade == "C" else UIKit.DANGER)

	var title := "%s - %s" % [str(report.get("title", "Mission Debrief")), str(report.get("year_title", ""))]
	if replay:
		title += " (replay)"
	var root := UIKit.screen("Mission Debrief: " + title, "")
	add_child(root)

	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 24)
	root.add_child(summary)
	summary.add_child(UIKit.label(grade, 44, grade_color))
	summary.add_child(UIKit.tag("SHIFT GRADE", UIKit.DIM))
	summary.add_child(UIKit.label("Points: %d" % int(report.get("points", 0)), 32, UIKit.ACCENT))
	summary.add_child(UIKit.tag(str(ProfessionManager.display_name(str(report.get("profession", "")))), UIKit.ACCENT_2))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	root.add_child(columns)

	columns.add_child(_column("Completed objectives", report.get("completed", []), UIKit.SUCCESS))
	columns.add_child(_column("Missed required objectives", report.get("missed", []), UIKit.DANGER))
	columns.add_child(_column("Optional objectives", report.get("optional", []), UIKit.ACCENT))
	columns.add_child(_column("Mistakes", report.get("mistakes", []), UIKit.DANGER))

	var detail := HBoxContainer.new()
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 16)
	root.add_child(detail)
	detail.add_child(_decisions_column(report))
	detail.add_child(_notes_column(report))

	var status_text := ""
	if bool(report.get("recovered", false)):
		status_text += "You recovered from an emergency on your own. "
	if bool(report.get("costly", false)):
		status_text += "A successful call still cost schedule time. "
	if bool(report.get("assisted", false)):
		status_text += "A teammate had to step in and finish a task. "
	if status_text == "":
		status_text = "A clean shift with no outside help."
	root.add_child(UIKit.wrapped("Status: " + status_text, 16, UIKit.DIM))

	if not fresh.is_empty():
		var names: Array = []
		for id in fresh:
			names.append(_achievement_title(str(id)))
		root.add_child(UIKit.banner("New achievement: " + ", ".join(PackedStringArray(names)), UIKit.SUCCESS))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var continue_text := "Continue"
	if replay:
		continue_text = "Back to archive"
	row.add_child(UIKit.button(continue_text, func() -> void:
		if replay:
			GameManager.request("mission_select")
		else:
			GameManager.request("mission_select")
	))
	root.add_child(row)


func _column(title: String, entries, color: Color) -> PanelContainer:
	var panel := UIKit.panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var holder := UIKit.scroll_box(0.0)
	panel.add_child(holder[0])
	var box: VBoxContainer = holder[1]
	box.add_child(UIKit.label(title.to_upper(), 16, color))
	box.add_child(HSeparator.new())
	if entries.is_empty():
		box.add_child(UIKit.wrapped("Nothing recorded.", 16, UIKit.DIM))
	for entry in entries:
		box.add_child(UIKit.wrapped("- " + str(entry), 16))
	return panel


func _decisions_column(report: Dictionary) -> PanelContainer:
	var panel := UIKit.panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var holder := UIKit.scroll_box(0.0)
	panel.add_child(holder[0])
	var box: VBoxContainer = holder[1]
	box.add_child(UIKit.label("DECISIONS AND CONSEQUENCES", 16, UIKit.ACCENT))
	box.add_child(HSeparator.new())
	var decisions: Array = report.get("decisions", [])
	if decisions.is_empty():
		box.add_child(UIKit.wrapped("No decisions recorded this shift.", 16, UIKit.DIM))
	for decision in decisions:
		box.add_child(UIKit.wrapped("- %s -> %s" % [str(decision.get("text", "")), str(decision.get("consequence", ""))], 16))
	return panel


func _notes_column(report: Dictionary) -> PanelContainer:
	var panel := UIKit.panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var holder := UIKit.scroll_box(0.0)
	panel.add_child(holder[0])
	var box: VBoxContainer = holder[1]
	box.add_child(UIKit.label("CREW NOTES", 16, UIKit.ACCENT))
	box.add_child(HSeparator.new())
	var team: Array = report.get("team", [])
	for member in team:
		var name: String = str(ProfessionManager.member(str(member.get("id", ""))).get("name", "Crew"))
		box.add_child(UIKit.wrapped("%s: \"%s\"" % [name, str(member.get("note", ""))], 16))
	var learned: Array = report.get("learned", [])
	if not learned.is_empty():
		box.add_child(UIKit.label("SKILLS LEARNED", 16, UIKit.ACCENT))
		for item in learned:
			box.add_child(UIKit.wrapped("- " + str(item), 16))
	return panel


func _achievement_title(id: String) -> String:
	for item in CampaignManager.achievements:
		if str(item.get("id", "")) == id:
			return str(item.get("title", id))
	return id

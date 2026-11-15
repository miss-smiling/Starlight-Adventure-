extends Control

const UIKit = preload("res://scripts/ui/ui_kit.gd")

var _mission_list: VBoxContainer


func _ready() -> void:
	var root := UIKit.screen("Mission Select", "Missions for the current season.")
	add_child(root)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	root.add_child(columns)

	# Left rail: the campaign timeline as year cards.
	var year_panel := UIKit.panel()
	year_panel.custom_minimum_size = Vector2(300, 0)
	var year_holder := ScrollContainer.new()
	year_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	year_holder.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	year_panel.add_child(year_holder)
	var year_box := VBoxContainer.new()
	year_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	year_box.add_theme_constant_override("separation", 8)
	year_holder.add_child(year_box)
	columns.add_child(year_panel)
	year_box.add_child(UIKit.heading("CAMPAIGN TIMELINE", 10, UIKit.ACCENT))

	var completed: Array = SaveManager.state.get("completed_missions", [])
	var current_year := int(SaveManager.state.get("current_year", 2026))
	for year_data in CampaignManager.years:
		var year := int(year_data.year)
		var unlocked := CampaignManager.year_unlocked(year, completed)
		var is_now := year == current_year and unlocked
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = UIKit.BG_SOFT if unlocked else UIKit.BG
		style.border_color = UIKit.ACCENT if is_now else UIKit.PANEL_EDGE
		style.set_border_width_all(1)
		style.border_width_left = 4 if is_now else 1
		style.set_corner_radius_all(0)
		style.set_content_margin_all(10)
		card.add_theme_stylebox_override("panel", style)
		year_box.add_child(card)
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 2)
		card.add_child(card_box)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		card_box.add_child(head)
		head.add_child(UIKit.heading(str(year), 12, UIKit.ACCENT if unlocked else UIKit.DIM))
		var title_label := UIKit.label(str(year_data.get("title", "")), 18, UIKit.TEXT if unlocked else UIKit.DIM)
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.clip_text = true
		head.add_child(title_label)
		if not unlocked:
			head.add_child(UIKit.heading("COMING SOON", 8, UIKit.DIM))
		var tech: Dictionary = year_data.get("tech", {})
		card_box.add_child(UIKit.wrapped(str(tech.get("title", "")), 17, UIKit.DIM))

	# Right: the season's missions as cards.
	var mission_panel := UIKit.panel()
	mission_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(mission_panel)
	var mission_box := VBoxContainer.new()
	mission_box.add_theme_constant_override("separation", 10)
	mission_panel.add_child(mission_box)
	mission_box.add_child(UIKit.heading("MISSIONS %d" % current_year, 10, UIKit.ACCENT))
	var holder := ScrollContainer.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_box.add_child(holder)
	_mission_list = VBoxContainer.new()
	_mission_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_list.add_theme_constant_override("separation", 10)
	holder.add_child(_mission_list)

	_populate_missions(completed, current_year)


func _populate_missions(completed: Array, current_year: int) -> void:
	UIKit.clear(_mission_list)
	var next_id := CampaignManager.next_mission_id(completed)
	var runtime: Dictionary = SaveManager.state.get("runtime", {})
	var resumable := bool(runtime.get("active", false)) and str(runtime.get("mission_id", "")) == next_id
	var shown := 0

	for mission_id in CampaignManager.order:
		var mission := CampaignManager.mission(str(mission_id))
		if int(mission.get("year", 2026)) != current_year:
			continue
		shown += 1
		var is_next := str(mission_id) == next_id
		var is_done: bool = completed.has(str(mission_id))
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = UIKit.BG_SOFT
		style.border_color = UIKit.ACCENT if is_next else UIKit.SUCCESS if is_done else UIKit.PANEL_EDGE
		style.set_border_width_all(1)
		style.border_width_left = 4 if is_next or is_done else 1
		style.set_corner_radius_all(0)
		style.set_content_margin_all(12)
		card.add_theme_stylebox_override("panel", style)
		_mission_list.add_child(card)
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 4)
		card.add_child(card_box)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card_box.add_child(row)
		row.add_child(UIKit.lamp(UIKit.ACCENT if is_next else UIKit.SUCCESS if is_done else UIKit.DIM))
		var title_label := UIKit.label(str(mission.get("title", "")), 23, UIKit.ACCENT if is_next else UIKit.SUCCESS if is_done else UIKit.DIM)
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title_label)
		if is_next:
			row.add_child(UIKit.primary_button("Resume" if resumable else "Start", func() -> void:
				GameManager.open_mission(str(mission_id), false, resumable)
			))
		elif is_done:
			row.add_child(UIKit.heading("DONE", 10, UIKit.SUCCESS))
		else:
			row.add_child(UIKit.heading("LOCKED", 10, UIKit.DIM))

	if shown == 0:
		_mission_list.add_child(UIKit.wrapped("New seasons are in development - the developer will add them soon, right after refilling their caffeine. Thanks for your patience!", 20, UIKit.DIM))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	_mission_list.add_child(footer)
	var year_locked: bool = SaveManager.state.get("professions_by_year", {}).has(str(current_year))
	if not year_locked and CampaignManager.next_mission_id(completed) != "":
		footer.add_child(UIKit.button("Change profession", func() -> void: GameManager.request("profession")))
	footer.add_child(UIKit.button("Mission archive", func() -> void: GameManager.request("archive")))
	footer.add_child(UIKit.button("Back to menu", func() -> void: GameManager.request("main_menu")))

	var profession := str(SaveManager.state.get("profession", ""))
	var tips := "Every task has HINT and SKIP."
	if profession != "":
		tips = "Playing as %s. Every task has HINT and SKIP." % ProfessionManager.display_name(profession)
	footer.add_child(UIKit.wrapped(tips, 18, UIKit.DIM))

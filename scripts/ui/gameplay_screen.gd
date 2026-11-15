extends Control

const UIKit = preload("res://scripts/ui/ui_kit.gd")
const DialogueView = preload("res://scripts/ui/dialogue_view.gd")
const DesignTask = preload("res://scripts/ui/tasks/design_task.gd")

# Linear shift runner. No free walking: the shift is a checklist of phases -
# task -> team meeting -> task -> team meeting -> final task -> close shift.
# After every phase the checklist shows a tick and offers Next or Main menu.

var mission: Dictionary = {}
var phases: Array = []
var phase_index := 0
var _running := false

var content: Control = null
var checklist_box: VBoxContainer = null
var emergency_banner: PanelContainer = null
var _emergency_label: Label = null
var _emergency_text := ""
var dialogue_view: Control = null
var journal_layer: Control = null
var pause_layer: Control = null
var toast: Label = null
var active_task: Control = null
var task_host: Control = null


func _ready() -> void:
	mission = CampaignManager.mission(GameManager.pending_mission)
	if mission.is_empty():
		GameManager.request("main_menu")
		return
	_build_phases()

	# Uploaded control-room art sits behind every panel; panels stay opaque
	# so text remains readable on top of it.
	var room_art := UIKit.art("scenes/control_room.png")
	if room_art != null:
		var room_rect := TextureRect.new()
		room_rect.texture = room_art
		room_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		room_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		room_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(room_rect)

	_build_top_bar()
	_build_layout()

	dialogue_view = DialogueView.new()
	dialogue_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dialogue_view)

	journal_layer = Control.new()
	journal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	journal_layer.visible = false
	add_child(journal_layer)
	_build_journal()
	_build_pause()

	toast = UIKit.label("", 18, UIKit.SUCCESS)
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.offset_top = -70
	toast.offset_bottom = -40
	toast.visible = false
	add_child(toast)

	MissionManager.changed.connect(_refresh_checklist)
	EventManager.emergency_started.connect(_on_emergency)
	MissionManager.start(GameManager.pending_mission, GameManager.pending_resume)
	phase_index = int(MissionManager.local_flags.get("phase_index", 0))
	if phase_index > 0 and phase_index <= phases.size():
		_running = false
		_refresh_checklist()
		_show_interstitial(phases[phase_index - 1], str(MissionManager.local_flags.get("last_rating", "")), false)
	else:
		phase_index = 0
		_start_phase(0)


func _exit_tree() -> void:
	MissionManager.changed.disconnect(_refresh_checklist)
	EventManager.emergency_started.disconnect(_on_emergency)


# ------------------------------------------------------------ phase setup

func _build_phases() -> void:
	var profession := str(SaveManager.state.get("profession", ""))
	var config: Dictionary = mission.get("tasks", {}).get(profession, {})
	var duty_title := str(config.get("title", "Station duty"))
	phases = [
		{"id": "quiz", "type": "quiz", "title": "Station quiz", "objective": "design", "stage": "design"},
		{"id": "briefing", "type": "meeting", "title": "Team briefing", "dialogues": [{"id": str(mission.get("intro", ""))}], "objective": "briefing"},
		{"id": "game", "type": "task", "title": "Cross-check - " + duty_title, "stage": "cross", "config": config},
		{"id": "meeting", "type": "meeting", "title": "Team meeting", "dialogues": _meeting_talks(2), "fact": str(mission.get("optional", {}).get("fact", ""))},
		{"id": "arcade", "type": "arcade", "title": "Final sign-off", "stage": "recovery", "stage_title": "FINAL SIGN-OFF - clear the debris field.", "config": config},
		{"id": "close", "type": "close", "title": "Close the shift"},
	]


func _meeting_talks(count: int) -> Array:
	var out: Array = []
	var talks: Dictionary = mission.get("talks", {})
	for member in mission.get("team", []):
		var id := str(member.get("id", ""))
		if talks.has(id):
			out.append({"id": str(talks[id]), "npc": id})
		if out.size() >= count:
			return out
	for key in talks.keys():
		if out.size() >= count:
			break
		var taken := false
		for item in out:
			if str(item.npc) == str(key):
				taken = true
		if not taken:
			out.append({"id": str(talks[key]), "npc": str(key)})
	return out


# ------------------------------------------------------------ UI skeleton

func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 56
	add_child(bar)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	bar.add_child(columns)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 2)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	title_row.add_child(UIKit.label(str(mission.get("title", "")), 20, UIKit.ACCENT))
	title_row.add_child(UIKit.tag(str(str(mission.get("room", {}).get("name", ""))).to_upper(), UIKit.DIM))
	left.add_child(title_row)
	var profession := str(SaveManager.state.get("profession", ""))
	left.add_child(UIKit.label("%s: %s" % [ProfessionManager.display_name(profession), str(SaveManager.state.get("callsign", "Explorer"))], 15, UIKit.DIM))
	columns.add_child(left)

	emergency_banner = UIKit.banner("", UIKit.DANGER)
	emergency_banner.visible = false
	columns.add_child(emergency_banner)
	_emergency_label = emergency_banner.get_child(0)

	var journal_button := UIKit.button("Journal", _open_journal)
	journal_button.custom_minimum_size = Vector2(110, 40)
	columns.add_child(journal_button)
	var menu_button := UIKit.button("Menu", func() -> void: pause_layer.visible = true)
	menu_button.custom_minimum_size = Vector2(90, 40)
	columns.add_child(menu_button)


func _build_layout() -> void:
	var body := HBoxContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 64
	body.offset_left = 16
	body.offset_right = -16
	body.offset_bottom = -16
	body.add_theme_constant_override("separation", 16)
	add_child(body)

	var side := UIKit.panel()
	side.custom_minimum_size = Vector2(300, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# The "corner fold" upload dresses the shift checklist side panel.
	if UIKit.art("ui/panel corner fold.png") != null:
		side.add_theme_stylebox_override("panel", UIKit.texture_stylebox("ui/panel corner fold.png", StyleBoxFlat.new()))
	body.add_child(side)
	var side_box := VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 8)
	side.add_child(side_box)
	var side_head := HBoxContainer.new()
	side_head.add_theme_constant_override("separation", 8)
	side_head.add_child(UIKit.heading("SHIFT CHECKLIST", 11, UIKit.ACCENT))
	var side_spacer := Control.new()
	side_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_head.add_child(side_spacer)
	side_head.add_child(UIKit.tag("%d / %d" % [_done_count(), phases.size()], UIKit.DIM))
	side_box.add_child(side_head)
	side_box.add_child(HSeparator.new())
	var holder := ScrollContainer.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_box.add_child(holder)
	checklist_box = VBoxContainer.new()
	checklist_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	checklist_box.add_theme_constant_override("separation", 6)
	holder.add_child(checklist_box)
	_emergency_text = ""

	content = Control.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(content)


func _done_count() -> int:
	return phase_index


func _refresh_checklist() -> void:
	if checklist_box == null:
		return
	UIKit.clear(checklist_box)
	for i in phases.size():
		var phase: Dictionary = phases[i]
		var text := ""
		var color := UIKit.DIM
		if i < phase_index:
			text = "DONE  " + str(phase.title)
			color = UIKit.SUCCESS
		elif i == phase_index:
			if _running:
				text = "ACTIVE  " + str(phase.title)
				color = UIKit.ACCENT
			else:
				text = "READY  " + str(phase.title)
				color = UIKit.TEXT
		else:
			text = "QUEUED  " + str(phase.title)
		var row := UIKit.label(text, 15, color)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		checklist_box.add_child(row)
	if MissionManager.recovery_open and emergency_banner != null:
		_refresh_banner()


func _on_emergency(payload: Dictionary) -> void:
	_emergency_text = "EMERGENCY: " + str(payload.get("text", ""))
	_refresh_banner()


# The top banner tracks two states: a live emergency event and the recovery
# loop. It must also hide again once both clear - previously it stayed on
# screen forever after the first recovery.
func _refresh_banner() -> void:
	if emergency_banner == null or _emergency_label == null:
		return
	if _emergency_text != "":
		_emergency_label.text = _emergency_text
		emergency_banner.visible = true
	elif MissionManager.recovery_open:
		_emergency_label.text = "RECOVERY OPEN - clear the failed stage to close the shift."
		emergency_banner.visible = true
	else:
		emergency_banner.visible = false


# ------------------------------------------------------------ phase engine

func _start_phase(index: int) -> void:
	if index < 0 or index >= phases.size():
		return
	phase_index = index
	_running = true
	_refresh_checklist()
	var phase: Dictionary = phases[index]
	UIKit.clear(content)
	active_task = null
	match str(phase.type):
		"quiz":
			AudioManager.music("shift")
			_open_game("quiz", {}, phase)
		"task":
			AudioManager.music("puzzle")
			_open_task(phase)
		"arcade":
			AudioManager.music("rock")
			_open_game("arcade", {}, phase)
		"meeting":
			AudioManager.music("chat")
			var center := CenterContainer.new()
			center.set_anchors_preset(Control.PRESET_FULL_RECT)
			content.add_child(center)
			center.add_child(UIKit.label("Team meeting in progress - click the dialogue to continue.", 18, UIKit.DIM))
			_run_meeting(phase)
		"close":
			_show_close_panel()


func _open_design(phase: Dictionary) -> void:
	var task := DesignTask.new()
	_host_task(task)
	task.setup({}, false, "")
	task.resolved.connect(_on_task_result.bind(phase))
	active_task = task


func _open_task(phase: Dictionary) -> void:
	var profession := str(SaveManager.state.get("profession", ""))
	var config: Dictionary = phase.get("config", {})
	if profession == "" or config.is_empty():
		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.add_child(center)
		center.add_child(UIKit.wrapped("No duty is configured for this station yet.", 18, UIKit.DANGER))
		_running = false
		return
	# The profession puzzle game from data/puzzles.json; missing data falls
	# back to the classic profession task module.
	var game_cfg := TaskManager.puzzle_config(profession, "cross")
	var game: Control = null
	if game_cfg.has("type"):
		game = TaskManager.make_game(str(game_cfg.type))
	if game == null:
		game = TaskManager.make(profession)
	else:
		var merged: Dictionary = config.duplicate(true)
		merged["puzzle"] = game_cfg
		config = merged
	_host_task(game)
	game.setup(config, MissionManager.recovery_open, str(phase.get("stage_title", "")))
	game.resolved.connect(_on_task_result.bind(phase))
	active_task = game


# Shared opener for the quiz and the arcade finale.
func _open_game(type: String, game_cfg: Dictionary, phase: Dictionary) -> void:
	var game := TaskManager.make_game(type)
	if game == null:
		_running = false
		return
	_host_task(game)
	game.setup({"puzzle": game_cfg}, false, str(phase.get("stage_title", "")))
	game.resolved.connect(_on_task_result.bind(phase))
	active_task = game


# Tasks run inline with a small header bar so the player can always close
# the panel with the X button.
func _host_task(task: Control) -> void:
	UIKit.clear(content)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 4)
	content.add_child(column)
	var header := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close_button := UIKit.button("X", _cancel_task)
	close_button.custom_minimum_size = Vector2(44, 36)
	header.add_child(close_button)
	column.add_child(header)
	var host := Control.new()
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(host)
	host.add_child(task)


func _cancel_task() -> void:
	# Closing a duty is a pause, not a failure. The stage stays open and can
	# be reopened from the pause card without any penalty.
	if active_task != null:
		active_task.queue_free()
		active_task = null
	_running = false
	_refresh_checklist()
	var phase: Dictionary = phases[phase_index] if phase_index < phases.size() else {}
	_show_paused_card(phase)


func _show_paused_card(phase: Dictionary) -> void:
	UIKit.clear(content)
	var box := UIKit.popup_box(content, Vector2(620, 360))
	box.add_child(UIKit.tag("DUTY PAUSED", UIKit.ACCENT_2))
	box.add_child(UIKit.wrapped("The task is closed for now. Nothing is marked wrong - reopen it whenever you are ready.", 18, UIKit.DIM))
	box.add_child(UIKit.divider())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UIKit.primary_button("Reopen duty", func() -> void: _start_phase(phase_index)))
	row.add_child(UIKit.button("Main menu", _quit_to_menu))
	box.add_child(row)


func _on_task_result(result: Dictionary, phase: Dictionary) -> void:
	_running = false
	if active_task != null:
		active_task.queue_free()
		active_task = null
	var rating := _stage_rating(result)
	var outcome := ""
	if str(phase.get("stage", "first")) == "first":
		outcome = MissionManager.apply_task_result(result)
	else:
		outcome = _apply_stage_result(result, phase)
	match outcome:
		"success":
			_complete_phase(phase, rating)
		"assisted":
			if bool(result.get("skipped", false)):
				_complete_phase(phase, "Duty handed to another operator - no task points")
			else:
				_complete_phase(phase, rating + "  (finished with crew support)")
		"recovery":
			_fail_phase(phase, str(result.get("warning", "Recovery required.")))


func _apply_stage_result(result: Dictionary, phase: Dictionary) -> String:
	var known: Array = MissionManager.mistakes
	for mistake_text in result.get("mistakes", []):
		if not known.has(mistake_text):
			MissionManager.add_mistake(str(mistake_text))
	for decision in result.get("decisions", []):
		MissionManager.note_decision(str(decision.get("text", "")), str(decision.get("consequence", "")))
	var flags: Dictionary = result.get("flags", {})
	var lasting: Array = result.get("lasting", [])
	for flag_name in flags.keys():
		EventManager.set_flag(str(flag_name), flags[flag_name], lasting.has(flag_name))
	var science := str(result.get("science", ""))
	if science != "" and not MissionManager.learned.has(science):
		MissionManager.learned.append(science)
	if bool(result.get("skipped", false)):
		# A skip is a clean hand-over, never a recovery loop.
		MissionManager.assisted = true
		EventManager.set_flag("assisted_once", true, true)
		MissionManager.complete_objective(str(phase.get("objective", "duty")))
		return "assisted"
	if bool(result.get("success", false)):
		MissionManager.complete_objective(str(phase.get("objective", "duty")))
		return "success"
	var fails := int(MissionManager.local_flags.get("fails_" + str(phase.id), 0)) + 1
	MissionManager.set_runtime_flag("fails_" + str(phase.id), fails)
	if fails >= 2:
		MissionManager.assisted = true
		EventManager.set_flag("assisted_once", true, true)
		MissionManager.complete_objective("duty")
		return "assisted"
	RecoveryManager.begin(result)
	return "recovery"


func _stage_rating(result: Dictionary) -> String:
	var count: int = result.get("mistakes", []).size()
	var points: int = max(0, 100 - 15 * int(count))
	var grade := "A" if count == 0 else ("B" if int(count) <= 2 else "C")
	return "Rating: %s - %d task points (%d mistakes)" % [grade, points, int(count)]


func _complete_phase(phase: Dictionary, result_text: String) -> void:
	phase_index += 1
	_running = false
	MissionManager.set_runtime_flag("phase_index", phase_index)
	MissionManager.set_runtime_flag("last_rating", result_text)
	_refresh_checklist()
	_show_interstitial(phase, result_text, false)


func _fail_phase(phase: Dictionary, result_text: String) -> void:
	_running = false
	_refresh_checklist()
	_show_interstitial(phase, result_text, true)


func _show_interstitial(phase: Dictionary, result_text: String, retry: bool) -> void:
	UIKit.clear(content)
	var box := UIKit.popup_box(content, Vector2(680, 580))

	var stage_tag := "STAGE FAILED - RETRY" if retry else "STAGE COMPLETE"
	box.add_child(UIKit.tag(stage_tag, UIKit.DANGER if retry else UIKit.SUCCESS))
	if retry:
		box.add_child(UIKit.banner(str(result_text), UIKit.DANGER))
		box.add_child(UIKit.wrapped("Recovery is open. The shift can only close after this stage is cleared.", 16, UIKit.DIM))
	else:
		box.add_child(UIKit.banner("Done: " + str(phase.title), UIKit.SUCCESS))
		if result_text != "":
			box.add_child(UIKit.label(result_text, 18, UIKit.ACCENT))

	box.add_child(UIKit.divider())
	box.add_child(UIKit.heading("SHIFT CHECKLIST", 10, UIKit.ACCENT))
	for i in phases.size():
		var item: Dictionary = phases[i]
		var mark := "DONE" if i < phase_index else "QUEUED"
		var color := UIKit.SUCCESS if i < phase_index else UIKit.DIM
		box.add_child(UIKit.label("%s  %s" % [mark, str(item.title)], 15, color))

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	if retry:
		buttons.add_child(UIKit.button("Retry this stage", func() -> void: _start_phase(phase_index)))
	elif phase_index >= phases.size():
		buttons.add_child(UIKit.button("Finish mission", _try_finish))
	else:
		buttons.add_child(UIKit.button("Next", func() -> void: _start_phase(phase_index)))
	buttons.add_child(UIKit.button("Main menu", _quit_to_menu))
	box.add_child(buttons)


func _run_meeting(phase: Dictionary) -> void:
	var queue: Array = phase.get("dialogues", [])
	_play_queue(queue, func() -> void:
		if str(phase.get("objective", "")) != "":
			MissionManager.complete_objective(str(phase.objective))
		var fact := str(phase.get("fact", ""))
		if fact != "":
			DialogueManager.play({"lines": [{"speaker": "player", "text": fact}]}, func() -> void:
				MissionManager.complete_objective("optional")
				_complete_phase(phase, "Meeting complete")
			)
		else:
			_complete_phase(phase, "Meeting complete")
	)


func _play_queue(items: Array, on_done: Callable) -> void:
	if items.is_empty():
		on_done.call()
		return
	var rest := items.slice(1, items.size())
	var item: Dictionary = items[0]
	var npc := str(item.get("npc", ""))
	DialogueManager.play_id(str(item.get("id", "")), func() -> void:
		if npc != "":
			MissionManager.register_talk(npc)
		_play_queue(rest, on_done)
	)


func _show_close_panel() -> void:
	UIKit.clear(content)
	var box := UIKit.popup_box(content, Vector2(680, 420))
	box.add_child(UIKit.banner("All stations cleared: " + str(phases[phases.size() - 1].title), UIKit.SUCCESS))
	if MissionManager.can_finish():
		box.add_child(UIKit.wrapped("Every required check is done. File the shift report to see your final rating.", 16))
		box.add_child(UIKit.button("Finish mission", _try_finish))
	else:
		var missing: Array = []
		for objective in MissionManager.objectives:
			if bool(objective.required) and not bool(objective.done):
				missing.append(str(objective.text))
		box.add_child(UIKit.wrapped("Still open: " + ", ".join(PackedStringArray(missing)), 16, UIKit.DANGER))
	box.add_child(UIKit.button("Main menu", _quit_to_menu))


func _try_finish() -> void:
	if not MissionManager.can_finish():
		return
	DialogueManager.play_id(str(mission.get("ending", "")), func() -> void:
		var report := MissionManager.build_report()
		var fresh := MissionManager.commit(report)
		GameManager.finish_to_debrief(report, fresh)
	)


func _quit_to_menu() -> void:
	SaveManager.save_game()
	GameManager.request("main_menu")


func _show_toast(text: String) -> void:
	toast.text = text
	toast.visible = true
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(toast):
			toast.visible = false
	)


# ------------------------------------------------------------ overlays

func _build_journal() -> void:
	UIKit.clear(journal_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	journal_layer.add_child(dim)

	var box := UIKit.popup_box(journal_layer, Vector2(680, 540))
	box.add_child(UIKit.header_with_close("Comms Journal (last 30 lines)", _close_journal))
	var history: Array = DialogueManager.history
	var recent: Array = history.slice(max(0, history.size() - 30), history.size())
	if recent.is_empty():
		box.add_child(UIKit.wrapped("No conversation recorded yet.", 16, UIKit.DIM))
	for entry in recent:
		box.add_child(UIKit.wrapped("%s: %s" % [str(entry.get("name", "")), str(entry.get("text", ""))], 15))


func _open_journal() -> void:
	_build_journal()
	journal_layer.visible = true


func _close_journal() -> void:
	journal_layer.visible = false


func _build_pause() -> void:
	pause_layer = Control.new()
	pause_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.visible = false
	add_child(pause_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(dim)

	var box := UIKit.popup_box(pause_layer, Vector2(460, 540))
	box.add_child(UIKit.heading("PAUSED", 20, UIKit.ACCENT))
	box.add_child(UIKit.button("Resume", func() -> void: pause_layer.visible = false))
	box.add_child(UIKit.button("Save and quit to menu", func() -> void:
		SaveManager.save_game()
		pause_layer.visible = false
		GameManager.request("main_menu")
	))

	box.add_child(UIKit.heading("QUICK SETTINGS", 11, UIKit.ACCENT))
	var volume_row := HBoxContainer.new()
	volume_row.add_child(UIKit.label("Volume", 16))
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = float(SaveManager.settings.get("volume", 1.0))
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume.value_changed.connect(func(value: float) -> void:
		SaveManager.settings["volume"] = value
		SaveManager.save_settings()
	)
	volume_row.add_child(volume)
	box.add_child(volume_row)

	var fullscreen := CheckBox.new()
	fullscreen.text = "Fullscreen"
	fullscreen.button_pressed = bool(SaveManager.settings.get("fullscreen", false))
	fullscreen.toggled.connect(func(on: bool) -> void:
		SaveManager.settings["fullscreen"] = on
		SaveManager.save_settings()
	)
	box.add_child(fullscreen)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if journal_layer.visible:
			_close_journal()
			return
		pause_layer.visible = not pause_layer.visible

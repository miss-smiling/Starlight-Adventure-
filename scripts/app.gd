extends Control

# Root application script. Swaps screens and registers the input map in code
# so the project file never needs fragile manual input entries.

const UIKit = preload("res://scripts/ui/ui_kit.gd")

var current: Control = null
var city: Control = null
var stars: Control = null


func _enter_tree() -> void:
	_register_inputs()


func _ready() -> void:
	_fit_window()
	UIManager.apply_theme(self)
	_build_background()
	GameManager.screen_changed.connect(_swap)
	if OS.get_cmdline_user_args().has("--selftest"):
		_selftest()
		return
	if OS.get_cmdline_user_args().has("--shots"):
		_shots()
		return
	_swap("main_menu")
	_boot_intro()


# ------------------------------------------------------------ boot intro

# Black title card before the menu: two lines type themselves out, then a
# green STATUS ACTIVE stamp, a short hold, and it fades into the menu.
var _boot: Control = null
var _tap: Control = null
var _boot_lines: Array = []
var _boot_stage := 0
var _boot_chars := 0.0
var _boot_hold := 0.0

func _boot_intro() -> void:
	# Web browsers refuse audio until a user gesture, so on the web the
	# boot intro waits behind an explicit tap card first.
	if OS.has_feature("web"):
		_tap = Control.new()
		_tap.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_tap)
		var veil := ColorRect.new()
		veil.color = Color("05070d")
		veil.set_anchors_preset(Control.PRESET_FULL_RECT)
		_tap.add_child(veil)
		var hold := CenterContainer.new()
		hold.set_anchors_preset(Control.PRESET_FULL_RECT)
		_tap.add_child(hold)
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 14)
		hold.add_child(card)
		card.add_child(UIKit.heading("STARLIGHT ADVENTURE", 22, UIKit.ACCENT))
		var prompt := UIKit.heading("TAP TO BEGIN", 14, UIKit.ACCENT_2)
		prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(prompt)
		return
	_boot_card()


func _input(event: InputEvent) -> void:
	# The tap gate: any press on the web start card dismisses it and lets
	# the typed intro (and audio) begin from a real user gesture.
	if _tap != null and (event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch):
		var gate := _tap
		_tap = null
		gate.queue_free()
		_boot_card()
		AudioManager.unlock()


func _boot_card() -> void:
	_boot = Control.new()
	_boot.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_boot)
	var black := ColorRect.new()
	black.color = Color("05070d")
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boot.add_child(black)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boot.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)
	_boot_lines = [
		UIKit.heading("WELCOME TO YEAR 2026", 14, UIKit.TEXT),
		UIKit.heading("PROJECT STARLIGHT ADVENTURE", 22, UIKit.ACCENT),
		UIKit.heading("STATUS ACTIVE", 13, UIKit.SUCCESS),
	]
	for line in _boot_lines:
		line.visible_characters = 0
		# Centered in a full-width row so the text never shifts while typing.
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(line)


func _process(delta: float) -> void:
	if _boot == null:
		return
	var line: Label = _boot_lines[_boot_stage]
	_boot_chars += delta * 16.0
	line.visible_characters = int(_boot_chars)
	if line.visible_characters >= line.text.length():
		if _boot_stage < _boot_lines.size() - 1:
			_boot_stage += 1
			_boot_chars = 0.0
		else:
			_boot_hold += delta
			if _boot_hold > 1.2:
				var fade := create_tween()
				fade.tween_property(_boot, "modulate:a", 0.0, 0.5)
				fade.tween_callback(_boot.queue_free)
				_boot = null


# Dev helper: renders each screen and saves a PNG under res://screenshots/.
# Run with: godot --path . -- --shots
func _shots() -> void:
	# Ignore all GUI input (mouse hover/wheel etc.) so the captures are
	# deterministic even while the machine is being used.
	get_window().gui_disable_input = true
	GameManager.pending_mission = "genesis"
	SaveManager.state["profession"] = "astronaut"
	GameManager.last_report = {"title": "Test", "grade": "A", "points": 900}
	await get_tree().process_frame
	var dir := DirAccess.open("res://")
	if not DirAccess.dir_exists_absolute("res://screenshots"):
		dir.make_dir("screenshots")
	for screen_id in ["main_menu", "profession", "mission_select", "new_game", "settings", "achievements", "leaderboard", "archive", "gameplay", "debrief"]:
		_swap(screen_id)
		await get_tree().create_timer(0.8).timeout
		var image := get_viewport().get_texture().get_image()
		image.save_png("res://screenshots/%s.png" % screen_id)
		print("shot: " + screen_id)
	# Extra task boards: render each profession task directly, like the
	# selftest does, to isolate task rendering from phase hosting.
	current.queue_free()
	current = null
	city.visible = false
	await get_tree().process_frame
	for profession_id in ["medical", "comms", "astronaut"]:
		SaveManager.state["profession"] = profession_id
		var task := TaskManager.make(profession_id)
		add_child(task)
		task.setup(CampaignManager.mission("genesis").get("tasks", {}).get(profession_id, {}), false)
		await get_tree().create_timer(0.8).timeout
		var image2 := get_viewport().get_texture().get_image()
		image2.save_png("res://screenshots/task_%s.png" % profession_id)
		print("shot: task_" + profession_id)
		task.queue_free()
		await get_tree().process_frame
	# Puzzle games: one shot per module type with real profession configs.
	for spec in [["quiz", {}, "astronaut"], ["arcade", {}, "astronaut"], ["tango", TaskManager.puzzle_config("engineer", "cross"), "engineer"], ["pinpoint", TaskManager.puzzle_config("medical", "cross"), "medical"], ["crossclimb", TaskManager.puzzle_config("comms", "cross"), "comms"], ["sudoku", TaskManager.puzzle_config("mathematician", "cross"), "mathematician"], ["matiks", {}, "physicist"]]:
		SaveManager.state["profession"] = spec[2]
		var game := TaskManager.make_game(spec[0])
		add_child(game)
		game.setup({"puzzle": spec[1]}, false)
		await get_tree().create_timer(0.8).timeout
		var image3 := get_viewport().get_texture().get_image()
		image3.save_png("res://screenshots/game_%s.png" % spec[0])
		print("shot: game_" + spec[0])
		game.queue_free()
		await get_tree().process_frame
	get_tree().quit()


# Integration check: instantiate every screen and every task module with the
# real autoloads running. Save/settings files are backed up and restored so a
# test run can never touch real campaign progress.
func _selftest() -> void:
	var failures: Array = []
	var backup := _backup_user_files()

	GameManager.pending_mission = "genesis"
	SaveManager.state["profession"] = "astronaut"
	for screen_id in ["main_menu", "new_game", "profession", "mission_select", "settings", "achievements", "leaderboard", "archive", "gameplay", "debrief"]:
		var screen := UIManager.make_screen(screen_id)
		add_child(screen)
		if screen_id == "gameplay" and screen.phases.size() != 6:
			failures.append("gameplay screen did not build the phase checklist")
		screen.queue_free()
		print("screen ok: " + screen_id)

	GameManager.last_report = {"title": "Test", "grade": "A", "points": 900}
	var genesis: Dictionary = CampaignManager.mission("genesis")
	for profession in ProfessionManager.ids():
		var task := TaskManager.make(profession)
		add_child(task)
		task.setup(genesis.get("tasks", {}).get(profession, {}), false)
		task.queue_free()
		print("task ok: " + profession)

	# Puzzle games: every profession's cross/final config must build.
	var puzzles = JSON.parse_string(FileAccess.get_file_as_string("res://data/puzzles.json"))
	if typeof(puzzles) == TYPE_DICTIONARY:
		for prof in puzzles:
			if str(prof).begins_with("_"):
				continue
			for stage_key in ["cross", "final"]:
				var game_cfg: Dictionary = puzzles[prof].get(stage_key, {})
				var game := TaskManager.make_game(str(game_cfg.get("type", "")))
				if game == null:
					failures.append("no game module for %s / %s" % [prof, str(game_cfg.get("type", ""))])
					continue
				add_child(game)
				game.setup({"puzzle": game_cfg}, false)
				game.queue_free()
				print("game ok: %s %s" % [prof, str(game_cfg.get("type", ""))])

	_restore_user_files(backup)
	if failures.is_empty():
		print("SELFTEST PASSED")
		get_tree().quit(0)
	else:
		for failure in failures:
			print("SELFTEST FAIL: " + failure)
		get_tree().quit(1)


func _backup_user_files() -> Dictionary:
	var backup := {}
	for path in [SaveManager.save_path, SaveManager.settings_path, SaveManager.board_path]:
		if FileAccess.file_exists(path):
			backup[path] = FileAccess.get_file_as_string(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return backup


func _restore_user_files(backup: Dictionary) -> void:
	for path in [SaveManager.save_path, SaveManager.settings_path, SaveManager.board_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if backup.has(path):
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_string(backup[path])


# Shared backdrops: the deep-space starfield for every screen, plus the
# cinematic night-city skyline that belongs to the main menu only.
func _build_background() -> void:
	var background := ColorRect.new()
	background.color = UIKit.BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	# Uploaded space photo replaces the flat navy; the animated glowing
	# starfield dots always render on top of it.
	var space_art := UIKit.art("scenes/space.png")
	if space_art != null:
		var space_rect := TextureRect.new()
		space_rect.texture = space_art
		space_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		space_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		space_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(space_rect)
	city = UIKit.city_backdrop()
	city.set_anchors_preset(Control.PRESET_FULL_RECT)
	city.visible = false
	add_child(city)
	stars = UIKit.starfield()
	stars.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(stars)


func _swap(screen_id: String) -> void:
	if city != null:
		city.visible = screen_id == "main_menu"
	if current != null:
		current.queue_free()
	current = UIManager.make_screen(screen_id)
	current.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(current)
	current.theme = UIManager.theme
	# Music mood per screen family: menu loop everywhere outside the shift,
	# the calm track during missions, and the game-over theme on the debrief.
	var mood := "menu"
	if screen_id == "gameplay":
		mood = "shift"
	elif screen_id == "debrief":
		mood = "over"
	AudioManager.music(mood)


func _register_inputs() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("interact", [KEY_E])
	_bind("pause", [KEY_ESCAPE])


func _bind(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


# Keeps the game window fully on screen and centered. Fixes the case where
# the window opens shifted so its bottom-right third is off the display.
func _fit_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	# Never fight a fullscreen setting: resizing a fullscreen window would
	# change the desktop resolution instead of the game layout.
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	var screen := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var size := Vector2i(1280, 720)
	if size.x > screen.size.x or size.y > screen.size.y:
		var scale: float = min(float(screen.size.x) / float(size.x), float(screen.size.y) / float(size.y))
		size = Vector2i(int(float(size.x) * scale), int(float(size.y) * scale))
		DisplayServer.window_set_size(size)
	var pos := screen.position + (screen.size - size) / 2
	DisplayServer.window_set_position(pos)

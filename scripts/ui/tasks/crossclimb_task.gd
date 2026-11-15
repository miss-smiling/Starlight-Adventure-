extends "res://scripts/ui/tasks/task_base.gd"

# Crossclimb-style word ladder: each rung changes exactly one letter. The
# correct next word is offered alongside three one-letter impostors. Config:
# {"ladder": ["WIRE", "FIRE", ...], "theme": "cipher"} - missing data uses a
# built-in station ladder.

const LETTERS := "AEIOUBCDFGLMNRSTWY"

var ladder: Array = []
var rung := 0

var from_label: Label = null
var choices_box: VBoxContainer = null
var note: Label = null


func _build() -> void:
	build_frame(self)
	var cfg: Dictionary = config.get("puzzle", {})
	ladder = cfg.get("ladder", ["STAR", "STAB", "SLAB", "FLAB", "FLAG", "FLAT"])
	if ladder.size() < 3:
		ladder = ["STAR", "STAB", "SLAB", "FLAB", "FLAG", "FLAT"]
	body.add_child(UIKit.banner("GOAL: climb the ladder - every rung changes exactly one letter.", Color("ffe08a")))
	body.add_child(UIKit.wrapped("Three impostors differ from the ANSWER by two letters. Compare each option to the word shown, letter by letter.", 18, UIKit.DIM))
	var board := UIKit.game_panel(Color("ffe08a"))
	body.add_child(board)
	var panel_box := VBoxContainer.new()
	panel_box.add_theme_constant_override("separation", 8)
	board.add_child(panel_box)
	from_label = UIKit.heading("", 26, UIKit.ACCENT)
	from_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	from_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_box.add_child(from_label)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 8)
	panel_box.add_child(choices_box)
	note = UIKit.wrapped("", 18, UIKit.DIM)
	body.add_child(note)
	_show()


func _mutate(word: String) -> String:
	var pos := randi() % word.length()
	var pool := LETTERS.replace(word[pos], "")
	return word.substr(0, pos) + pool[randi() % pool.length()] + word.substr(pos + 1)


func _show() -> void:
	UIKit.clear(choices_box)
	note.text = ""
	if rung >= ladder.size() - 1:
		return _finish()
	from_label.text = str(ladder[rung])
	var correct := str(ladder[rung + 1])
	var options: Array = [correct]
	while options.size() < 4:
		var fake := _mutate(correct)
		if fake != correct and not options.has(fake):
			options.append(fake)
	options.shuffle()
	for option in options:
		var pick := UIKit.button(option, Callable(), "tap")
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.pressed.connect(_pick.bind(option, correct))
		choices_box.add_child(pick)


func _pick(option: String, correct: String) -> void:
	if option == correct:
		rung += 1
		note.text = "Rung locked."
		note.add_theme_color_override("font_color", UIKit.SUCCESS)
		_show()
	else:
		mistake("Ladder: picked %s over %s" % [option, correct])
		note.text = "That impostor is more than one letter from %s. Look again." % str(ladder[rung])
		note.add_theme_color_override("font_color", UIKit.WARN)


func _finish() -> void:
	finish(true, {
		"decisions": [{"text": "Word ladder climbed: %s to %s." % [str(ladder.front()), str(ladder.back())], "consequence": "Cipher chain verified rung by rung.", "result": "pass"}],
		"science": "Cipher ladders: one letter of change per verified step.",
	})


func tips() -> Array:
	return [
		"Compare each option to the current word letter by letter.",
		"Impostors differ from the answer, not from the current word - that is the tell.",
		"Wrong picks never lock you out; the rung stays open.",
	]

extends "res://scripts/ui/tasks/task_base.gd"

# Pinpoint-style narrowing: clues are revealed one at a time and the player
# picks the answer from four candidates. Fewer clues used = better log.
# Config: {"rounds": [{"answer": "...", "choices": ["A","B","C","D"],
# "clues": ["...", ...]}]}.

var rounds: Array = []
var round_index := 0
var clue_index := 0

var clue_label: Label = null
var clues_box: VBoxContainer = null
var choices_box: VBoxContainer = null
var note: Label = null


func _build() -> void:
	build_frame(self)
	var cfg: Dictionary = config.get("puzzle", {})
	rounds = cfg.get("rounds", [])
	if rounds.is_empty():
		rounds = [{"answer": "NEBULA", "choices": ["NEBULA", "QUASAR", "PULSAR", "MAGNETAR"], "clues": ["A stellar nursery.", "It is a cloud, not a star.", "New stars are born inside it.", "It glows by reflecting light."]}]
	body.add_child(UIKit.banner("GOAL: identify the target from the clues. A wrong pick reveals one more clue for free.", Color("7fe08c")))
	body.add_child(UIKit.wrapped("Fewer clues = a cleaner log. Read the revealed clues together - they point at one single answer.", 18, UIKit.DIM))
	var board := UIKit.game_panel(Color("7fe08c"))
	body.add_child(board)
	var panel_box := VBoxContainer.new()
	panel_box.add_theme_constant_override("separation", 6)
	board.add_child(panel_box)
	clue_label = UIKit.heading("", 13, Color("7fe08c"))
	panel_box.add_child(clue_label)
	clues_box = VBoxContainer.new()
	clues_box.add_theme_constant_override("separation", 4)
	panel_box.add_child(clues_box)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 8)
	panel_box.add_child(choices_box)
	note = UIKit.wrapped("", 18, UIKit.DIM)
	body.add_child(note)
	_show()


func _show() -> void:
	UIKit.clear(clues_box)
	UIKit.clear(choices_box)
	note.text = ""
	if round_index >= rounds.size():
		return _finish()
	var round: Dictionary = rounds[round_index]
	clue_index = 0
	clue_label.text = "TARGET %d / %d   -   CLUE 1" % [round_index + 1, rounds.size()]
	_reveal()


func _reveal() -> void:
	UIKit.clear(clues_box)
	var round: Dictionary = rounds[round_index]
	var clues: Array = round.get("clues", [])
	clue_label.text = "TARGET %d / %d   -   %d clue%s shown" % [round_index + 1, rounds.size(), clue_index, "" if clue_index == 1 else "s"]
	for i in clue_index:
		clues_box.add_child(UIKit.wrapped("- " + str(clues[i]), 19, UIKit.TEXT))
	UIKit.clear(choices_box)
	for choice in round.get("choices", []):
		var pick := UIKit.button(str(choice), Callable(), "tap")
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.pressed.connect(_guess.bind(str(choice)))
		choices_box.add_child(pick)
	if clue_index < clues.size():
		var more := UIKit.button("REVEAL NEXT CLUE")
		more.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		more.pressed.connect(_more_clue)
		choices_box.add_child(more)


func _more_clue() -> void:
	clue_index += 1
	_reveal()


func _guess(choice: String) -> void:
	var round: Dictionary = rounds[round_index]
	if choice == str(round.get("answer", "")):
		note.text = "Target identified with %d clue%s." % [clue_index, "" if clue_index == 1 else "s"]
		note.add_theme_color_override("font_color", UIKit.SUCCESS)
		round_index += 1
		var next := UIKit.primary_button("Next target" if round_index < rounds.size() else "File the deduction report")
		next.pressed.connect(_show)
		choices_box.add_child(next)
	else:
		mistake("Deduction: wrong pick after %d clues" % clue_index)
		if clue_index < round.get("clues", []).size():
			clue_index += 1
			note.text = "Not it - one more clue narrows the field."
			note.add_theme_color_override("font_color", UIKit.WARN)
			_reveal()
		else:
			note.text = "All clues are out. Reread them and pick again."
			note.add_theme_color_override("font_color", UIKit.WARN)


func _finish() -> void:
	finish(true, {
		"decisions": [{"text": "Deduction run: %d target(s) identified." % rounds.size(), "consequence": "Diagnosis confirmed from narrowing clues.", "result": "pass"}],
		"science": "Good deduction: each clue eliminates half the field.",
	})


func tips() -> Array:
	return [
		"Guessing early keeps the log clean - but a wrong guess reveals a free clue.",
		"Every wrong pick is survivable; the clues keep coming until you have them all.",
		"Read the revealed clues together - they point at one single answer.",
	]

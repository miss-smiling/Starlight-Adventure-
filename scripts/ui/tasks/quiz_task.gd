extends "res://scripts/ui/tasks/task_base.gd"

# Profession knowledge quiz. Questions live in data/quiz.json under the
# profession id: {"questions": [{"q": "...", "choices": ["..","..","..",".."],
# "answer": 0}]}. Missing or empty data falls back to the "general" section.
# Forgiving: wrong answers stay clickable until correct, each wrong try is
# one recorded mistake, and the quiz always completes with a grade.

var questions: Array = []
var index := 0
var correct := 0

var progress: Label = null
var question_label: Label = null
var choices_box: VBoxContainer = null
var note: Label = null


func _build() -> void:
	build_frame(self)
	questions = puzzle_data("quiz.json", str(SaveManager.state.get("profession", ""))).get("questions", [])
	if questions.is_empty():
		questions = puzzle_data("quiz.json", "general").get("questions", [])
	body.add_child(UIKit.wrapped("Station certification quiz - answer at your own pace. Wrong picks stay open so you can try again.", 18, UIKit.DIM))
	progress = UIKit.heading("", 13, UIKit.ACCENT_2)
	body.add_child(progress)
	question_label = UIKit.wrapped("", 21, UIKit.TEXT)
	body.add_child(question_label)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 8)
	body.add_child(choices_box)
	note = UIKit.wrapped("", 18, UIKit.DIM)
	body.add_child(note)
	_show_question()


func _show_question() -> void:
	UIKit.clear(choices_box)
	note.text = ""
	if index >= questions.size():
		return _finish()
	var item: Dictionary = questions[index]
	progress.text = "QUESTION %d / %d   -   %d correct" % [index + 1, questions.size(), correct]
	question_label.text = str(item.get("q", ""))
	var answer := int(item.get("answer", 0))
	var choices: Array = item.get("choices", [])
	for i in choices.size():
		var text := str(choices[i])
		var pick := UIKit.button(text, Callable(), "tap")
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.pressed.connect(_answer.bind(i, answer, pick))
		choices_box.add_child(pick)


func _answer(choice: int, answer: int, button: Button) -> void:
	if choice == answer:
		correct += 1
		button.add_theme_stylebox_override("normal", UIKit._primary_style(UIKit.SUCCESS, UIKit.SUCCESS.darkened(0.3)))
		note.text = "Correct. Committing that to the station log."
		note.add_theme_color_override("font_color", UIKit.SUCCESS)
		index += 1
		var next := UIKit.primary_button("Next question" if index < questions.size() else "File the quiz report")
		next.pressed.connect(_show_question)
		choices_box.add_child(next)
	else:
		mistake("Quiz: wrong answer on question %d" % (index + 1))
		button.disabled = true
		note.text = "Not it - that choice is ruled out. Try another."
		note.add_theme_color_override("font_color", UIKit.WARN)


func _finish() -> void:
	var profession := str(SaveManager.state.get("profession", ""))
	finish(true, {
		"decisions": [{
			"text": "Certification quiz: %d/%d correct" % [correct, questions.size()],
			"consequence": "Station knowledge refreshed before the shift.",
			"result": "pass",
		}],
		"science": "Quick recall of %s procedures keeps the station safe." % profession,
	})


func tips() -> Array:
	return [
		"Wrong picks are never a dead end - they just get ruled out.",
		"Read every choice before answering; the station logs mistakes either way.",
		"You can SKIP the whole quiz and keep your points untouched.",
	]

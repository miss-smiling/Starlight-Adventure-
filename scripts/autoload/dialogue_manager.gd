extends Node

const Sequence = preload("res://scripts/model/dialogue_sequence.gd")

signal line_shown(speaker_id, speaker_name, profession_name, text, choices)
signal conversation_ended

var active := false
var history: Array = []
var _sequence = null
var _on_finished: Callable = Callable()
var _pending_choices: Array = []

func play_id(id: String, on_finished: Callable = Callable()) -> void:
	play(CampaignManager.dialogue(id), on_finished)


func play(data: Dictionary, on_finished: Callable = Callable()) -> void:
	if data.is_empty() or data.get("lines", []).is_empty():
		active = false
		if on_finished.is_valid():
			on_finished.call()
		conversation_ended.emit()
		return
	_sequence = Sequence.new()
	_sequence.setup(data)
	_on_finished = on_finished
	active = true
	_present()


func advance() -> void:
	if _sequence == null:
		return
	var outcome := str(_sequence.advance())
	if outcome == "goto":
		play_id(_sequence.next_id, _on_finished)
		return
	if outcome == "end":
		_finish()
		return
	_present()


func choose(index: int) -> void:
	if index < 0 or index >= _pending_choices.size():
		return
	var choice: Dictionary = _pending_choices[index]
	var spoken := str(choice.get("text", ""))
	_remember("player", spoken)
	if choice.has("flag"):
		var lasting := bool(choice.get("lasting", false))
		EventManager.set_flag(str(choice.flag), choice.get("value", true), lasting)
	var goto_id := str(choice.get("goto", ""))
	if goto_id == "":
		_finish()
		return
	play_id(goto_id, _on_finished)


func _present() -> void:
	var line: Dictionary = _sequence.current()
	if line.is_empty():
		_finish()
		return
	if line.has("choices"):
		_pending_choices = line.get("choices", [])
		var speaker := _speaker("mira_vale")
		line_shown.emit(speaker.id, speaker.name, speaker.profession, "", _choice_labels())
		return
	_pending_choices = []
	var resolved := _speaker(str(line.get("speaker", "mira_vale")))
	var text := _fill(str(line.get("text", "")))
	_remember(resolved.id, text)
	line_shown.emit(resolved.id, resolved.name, resolved.profession, text, [])


func _choice_labels() -> Array:
	var labels: Array = []
	for choice in _pending_choices:
		labels.append(_fill(str(choice.get("text", ""))))
	return labels


func _finish() -> void:
	active = false
	_sequence = null
	_pending_choices = []
	var callback := _on_finished
	_on_finished = Callable()
	conversation_ended.emit()
	if callback.is_valid():
		callback.call()


func _remember(speaker_id: String, text: String) -> void:
	if text == "":
		return
	var person := _speaker(speaker_id)
	history.append({"id": speaker_id, "name": person.name, "text": text})
	if history.size() > 40:
		history = history.slice(history.size() - 40, history.size())


func _speaker(id: String) -> Dictionary:
	var resolved := ProfessionManager.resolve_speaker(id)
	if resolved == "player":
		var profession := str(SaveManager.state.get("profession", ""))
		return {
			"id": "player",
			"name": str(SaveManager.state.get("callsign", "Explorer")),
			"profession": ProfessionManager.display_name(profession),
			"color": ProfessionManager.color_of(profession),
		}
	var member := ProfessionManager.member(resolved)
	if member.is_empty():
		return {"id": resolved, "name": resolved, "profession": "", "color": Color("7ec8ff")}
	return {
		"id": resolved,
		"name": str(member.name),
		"profession": ProfessionManager.display_name(str(member.profession)),
		"color": Color.html(str(member.get("color", "#7ec8ff"))),
	}


func _fill(text: String) -> String:
	var profession := str(SaveManager.state.get("profession", ""))
	return text.replace("{callsign}", str(SaveManager.state.get("callsign", "Explorer"))).replace("{profession_name}", ProfessionManager.display_name(profession)).replace("{year}", str(SaveManager.state.get("current_year", 2026)))

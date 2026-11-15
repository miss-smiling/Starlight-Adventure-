extends Node

const ScoreModel = preload("res://scripts/model/score_model.gd")
const AchievementRules = preload("res://scripts/model/achievement_rules.gd")

signal changed

var mission_id := ""
var objectives: Array = []
var mistakes: Array = []
var decisions: Array = []
var lasting := {}
var local_flags := {}
var talks: Array = []
var recovered := false
var assisted := false
var recovery_open := false
var recovery_used := false
var costly := false
var learned: Array = []

func start(id: String, resume: bool) -> void:
	var mission := CampaignManager.mission(id)
	mission_id = id
	var runtime: Dictionary = SaveManager.state.get("runtime", {})
	if resume and str(runtime.get("mission_id", "")) == id and bool(runtime.get("active", false)):
		_load_runtime(runtime)
	else:
		_fresh(mission)
		DialogueManager.history.clear()
	var year := int(mission.get("year", 2026))
	SaveManager.state["current_year"] = year
	var key := str(year)
	if not bool(SaveManager.state.get("replay", false)):
		if not SaveManager.state.professions_by_year.has(key):
			SaveManager.state.professions_by_year[key] = SaveManager.state.profession
		else:
			SaveManager.state.profession = str(SaveManager.state.professions_by_year[key])
	_store()
	changed.emit()


func _fresh(mission: Dictionary) -> void:
	objectives = [
		{"id": "briefing", "text": "Hear the briefing", "required": true, "done": false},
		{"id": "design", "text": "Design the mission: budget, mass, power and science", "required": true, "done": false},
		{"id": "duty", "text": str(mission.get("duty_text", "Complete your station duty")), "required": true, "done": false},
		{"id": "crew", "text": "Check in with two teammates", "required": true, "done": false},
	]
	if mission.has("optional"):
		objectives.append({
			"id": "optional",
			"text": str(mission.optional.get("text", "Optional note")),
			"required": false,
			"done": false,
		})
	mistakes = []
	decisions = []
	lasting = {}
	local_flags = {}
	talks = []
	recovered = false
	assisted = false
	recovery_open = false
	recovery_used = false
	costly = false
	learned = mission.get("learn", []).duplicate()


func _load_runtime(runtime: Dictionary) -> void:
	objectives = runtime.get("objectives", []).duplicate(true)
	mistakes = runtime.get("mistakes", []).duplicate()
	decisions = runtime.get("decisions", []).duplicate(true)
	lasting = runtime.get("lasting", {}).duplicate(true)
	local_flags = runtime.get("local_flags", {}).duplicate(true)
	talks = runtime.get("talks", []).duplicate()
	recovered = bool(runtime.get("recovered", false))
	assisted = bool(runtime.get("assisted", false))
	recovery_open = bool(runtime.get("recovery_open", false))
	recovery_used = bool(runtime.get("recovery_used", false))
	costly = bool(runtime.get("costly", false))
	learned = runtime.get("learned", []).duplicate()
	DialogueManager.history = runtime.get("history", []).duplicate(true)


func set_runtime_flag(key: String, value) -> void:
	local_flags[key] = value
	_store()
	changed.emit()


func complete_objective(id: String) -> void:
	for objective in objectives:
		if str(objective.id) == id:
			objective.done = true
	if id == "duty":
		recovery_open = false
	_store()
	changed.emit()


func objective_done(id: String) -> bool:
	for objective in objectives:
		if str(objective.id) == id:
			return bool(objective.done)
	return false


func add_mistake(text: String) -> void:
	if text != "":
		mistakes.append(text)
	_store()
	changed.emit()


func note_decision(text: String, consequence: String) -> void:
	var entry := {"text": text, "consequence": consequence, "mission": mission_id}
	decisions.append(entry)
	if not bool(SaveManager.state.get("replay", false)):
		SaveManager.state.decisions.append(entry)
	_store()
	changed.emit()


func register_talk(npc_id: String) -> void:
	if talks.has(npc_id):
		return
	talks.append(npc_id)
	if talks.size() >= 2:
		complete_objective("crew")
	else:
		_store()
		changed.emit()


func apply_task_result(result: Dictionary) -> String:
	for text in result.get("mistakes", []):
		if not mistakes.has(text):
			mistakes.append(text)
	for decision in result.get("decisions", []):
		note_decision(str(decision.get("text", "")), str(decision.get("consequence", "")))
		if str(decision.get("result", "")) == "success_cost":
			costly = true
	var flags: Dictionary = result.get("flags", {})
	for flag_name in result.get("lasting", []):
		if flags.has(flag_name):
			EventManager.set_flag(str(flag_name), flags[flag_name], true)
	for flag_name in flags.keys():
		if not result.get("lasting", []).has(flag_name):
			local_flags[flag_name] = flags[flag_name]
	var science := str(result.get("science", ""))
	if science != "" and not learned.has(science):
		learned.append(science)
	if bool(result.get("recovery_needed", false)) and not recovery_used:
		recovery_used = true
		RecoveryManager.begin(result)
		_store()
		changed.emit()
		return "recovery"
	if bool(result.get("assisted", false)):
		assisted = true
		EventManager.set_flag("assisted_once", true, true)
		complete_objective("duty")
		return "assisted"
	if bool(result.get("success", false)):
		complete_objective("duty")
		return "success"
	assisted = true
	EventManager.set_flag("assisted_once", true, true)
	complete_objective("duty")
	return "assisted"


func can_finish() -> bool:
	if recovery_open:
		return false
	for objective in objectives:
		if bool(objective.required) and not bool(objective.done):
			return false
	return mission_id != ""


func build_report() -> Dictionary:
	var mission := CampaignManager.mission(mission_id)
	var completed: Array = []
	var missed: Array = []
	var optional: Array = []
	var required_done := 0
	var required_total := 0
	for objective in objectives:
		if bool(objective.required):
			required_total += 1
			if bool(objective.done):
				required_done += 1
				completed.append(str(objective.text))
			else:
				missed.append(str(objective.text))
		elif bool(objective.done):
			optional.append(str(objective.text))
	var report := {
		"mission_id": mission_id,
		"title": str(mission.get("title", "")),
		"year": int(mission.get("year", 2026)),
		"profession": str(SaveManager.state.get("profession", "")),
		"profession_name": ProfessionManager.display_name(str(SaveManager.state.get("profession", ""))),
		"completed": completed,
		"missed": missed,
		"optional": optional,
		"mistakes": mistakes.duplicate(),
		"decisions": decisions.duplicate(true),
		"team": mission.get("team", []),
		"learned": learned.duplicate(),
		"recovered": recovered,
		"assisted": assisted,
		"costly": costly,
		"required_done": required_done,
		"required_total": required_total,
		"optional_done": optional.size(),
		"mistake_count": mistakes.size(),
	}
	var score: Dictionary = ScoreModel.calculate(report)
	report["points"] = score.points
	report["grade"] = score.grade
	report["clean"] = score.clean
	return report


func commit(report: Dictionary) -> Array:
	var fresh: Array = []
	if bool(SaveManager.state.get("replay", false)):
		var profession := str(report.get("profession", ""))
		if profession != "" and not SaveManager.state.professions_played.has(profession):
			SaveManager.state.professions_played.append(profession)
		fresh = AchievementRules.evaluate(SaveManager.state, report)
		for id in fresh:
			SaveManager.state.achievements.append(id)
		SaveManager.add_score(report)
		SaveManager.finish_replay()
		return fresh
	if report.mission_id == "new_beginnings":
		EventManager.set_flag("signal_classified", true, true)
	if not SaveManager.state.completed_missions.has(report.mission_id):
		SaveManager.state.completed_missions.append(report.mission_id)
	var profession := str(report.get("profession", ""))
	if profession != "" and not SaveManager.state.professions_played.has(profession):
		SaveManager.state.professions_played.append(profession)
	SaveManager.state.mission_history.append({
		"id": report.mission_id,
		"title": report.title,
		"year": report.year,
		"profession": profession,
		"points": report.points,
		"grade": report.grade,
		"mistakes": report.mistakes,
		"decisions": report.decisions,
	})
	fresh = AchievementRules.evaluate(SaveManager.state, report)
	for id in fresh:
		SaveManager.state.achievements.append(id)
	SaveManager.state.current_year = CampaignManager.current_year_for(SaveManager.state.completed_missions)
	SaveManager.state.runtime = {}
	TechnologyManager.sync()
	SaveManager.add_score(report)
	SaveManager.save_game()
	return fresh


func _store() -> void:
	var snapshot := {
		"active": true,
		"mission_id": mission_id,
		"objectives": objectives.duplicate(true),
		"mistakes": mistakes.duplicate(),
		"decisions": decisions.duplicate(true),
		"lasting": lasting.duplicate(true),
		"local_flags": local_flags.duplicate(true),
		"talks": talks.duplicate(),
		"recovered": recovered,
		"assisted": assisted,
		"recovery_open": recovery_open,
		"recovery_used": recovery_used,
		"costly": costly,
		"learned": learned.duplicate(),
		"history": DialogueManager.history.duplicate(true),
		"pos": SaveManager.state.get("runtime", {}).get("pos", [140, 360]),
	}
	SaveManager.state["runtime"] = snapshot
	SaveManager.save_game()

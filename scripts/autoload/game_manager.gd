extends Node

signal screen_changed(screen_id)

var pending_mission := ""
var pending_replay := false
var pending_resume := false
var last_report: Dictionary = {}
var last_achievements: Array = []
var notice := ""

func request(screen_id: String) -> void:
	screen_changed.emit(screen_id)


func start_new(callsign: String, gender := "") -> void:
	SaveManager.new_game(callsign, gender)
	request("profession")


func continue_campaign() -> void:
	var result := SaveManager.load_game()
	if not result.ok:
		notice = str(result.error)
		request("main_menu")
		return
	if str(SaveManager.state.get("profession", "")) == "":
		request("profession")
	else:
		request("mission_select")


func choose_profession(profession_id: String) -> void:
	var year := int(SaveManager.state.get("current_year", 2026))
	var locked: Dictionary = SaveManager.state.get("professions_by_year", {})
	if locked.has(str(year)):
		SaveManager.state.profession = str(locked[str(year)])
	else:
		SaveManager.state.profession = profession_id
	SaveManager.save_game()
	request("mission_select")


func open_mission(mission_id: String, replay: bool, resume: bool) -> void:
	pending_mission = mission_id
	pending_replay = replay
	pending_resume = resume
	if replay:
		SaveManager.begin_replay()
	request("gameplay")


func finish_to_debrief(report: Dictionary, achievements: Array) -> void:
	last_report = report
	last_achievements = achievements
	request("debrief")

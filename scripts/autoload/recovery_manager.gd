extends Node

func begin(result: Dictionary) -> void:
	MissionManager.recovery_open = true
	MissionManager.recovered = true
	var warning := str(result.get("warning", "A check needs to be done again."))
	var record := {
		"mission": MissionManager.mission_id,
		"id": str(result.get("emergency_id", "recovery")),
		"text": warning,
	}
	if not bool(SaveManager.state.get("replay", false)):
		SaveManager.state.recovery_events.append(record)
	var fail_flag := str(result.get("fail_flag", ""))
	if fail_flag != "":
		EventManager.set_flag(fail_flag, true, true)
	for flag_name in result.get("lasting", []):
		if result.get("flags", {}).has(flag_name):
			EventManager.set_flag(str(flag_name), result.flags[flag_name], true)
	EventManager.raise_emergency(record)
	var mission := CampaignManager.mission(MissionManager.mission_id)
	var lines: Array = mission.get("emergency_script", [])
	var prepared: Array = []
	for line in lines:
		var copy: Dictionary = line.duplicate(true)
		copy["text"] = str(copy.get("text", "")).replace("{warning}", warning)
		prepared.append(copy)
	if prepared.is_empty():
		prepared = [
			{"speaker": "mira_vale", "text": warning},
			{"speaker": "mira_vale", "text": "Recovery is open. Do the critical step again. The shift is not over."},
		]
	DialogueManager.play({"lines": prepared})

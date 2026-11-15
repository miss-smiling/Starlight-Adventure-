extends Node

signal flags_changed
signal emergency_started(payload)

func set_flag(flag_name: String, value, lasting: bool) -> void:
	var runtime: Dictionary = MissionManager.local_flags
	runtime[flag_name] = value
	MissionManager.local_flags = runtime
	if lasting:
		MissionManager.lasting[flag_name] = value
		if not bool(SaveManager.state.get("replay", false)):
			SaveManager.state.story_flags[flag_name] = value
	flags_changed.emit()


func raise_emergency(payload: Dictionary) -> void:
	emergency_started.emit(payload)

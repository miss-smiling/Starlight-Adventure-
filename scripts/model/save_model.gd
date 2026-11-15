extends RefCounted

const VERSION := 1

static func clean_callsign(raw: String) -> String:
	var out := ""
	var source := raw.strip_edges()
	for i in source.length():
		var ch := source.substr(i, 1)
		var ok := (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == " "
		if ok:
			out += ch
	out = out.strip_edges()
	if out.length() > 16:
		out = out.substr(0, 16).strip_edges()
	if out == "":
		return "Explorer"
	return out


static func default_state(callsign: String) -> Dictionary:
	return {
		"version": VERSION,
		"callsign": clean_callsign(callsign),
		"profession": "",
		"current_year": 2026,
		"completed_missions": [],
		"unlocked_tech": ["manual_diagnostics_2026"],
		"story_flags": {},
		"mission_history": [],
		"recovery_events": [],
		"achievements": [],
		"decisions": [],
		"runtime": {},
		"professions_by_year": {},
		"professions_played": [],
		"replay": false,
		"gender": "",
	}


static func validate(data, mission_ids: Array, profession_ids: Array) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "The save file is not a campaign record."}
	if int(data.get("version", 0)) != VERSION:
		return {"ok": false, "error": "This save is from a different game version."}
	var profession := str(data.get("profession", ""))
	if profession != "" and not profession_ids.has(profession):
		return {"ok": false, "error": "The saved profession is not in this build."}
	if typeof(data.get("completed_missions", [])) != TYPE_ARRAY:
		return {"ok": false, "error": "The mission list in the save is damaged."}
	for mission_id in data.get("completed_missions", []):
		if not mission_ids.has(str(mission_id)):
			return {"ok": false, "error": "The save names a mission this build does not have."}
	if typeof(data.get("story_flags", {})) != TYPE_DICTIONARY:
		return {"ok": false, "error": "The story record in the save is damaged."}
	var state: Dictionary = default_state(str(data.get("callsign", "Explorer")))
	state["callsign"] = clean_callsign(str(data.get("callsign", "Explorer")))
	state["profession"] = profession
	state["current_year"] = int(data.get("current_year", 2026))
	state["completed_missions"] = _string_array(data.get("completed_missions", []))
	state["unlocked_tech"] = _string_array(data.get("unlocked_tech", []))
	state["story_flags"] = data.get("story_flags", {}).duplicate(true)
	state["mission_history"] = data.get("mission_history", []).duplicate(true)
	state["recovery_events"] = data.get("recovery_events", []).duplicate(true)
	state["achievements"] = _string_array(data.get("achievements", []))
	state["decisions"] = data.get("decisions", []).duplicate(true)
	state["runtime"] = data.get("runtime", {}).duplicate(true)
	state["professions_by_year"] = data.get("professions_by_year", {}).duplicate(true)
	state["professions_played"] = _string_array(data.get("professions_played", []))
	state["replay"] = false
	state["gender"] = str(data.get("gender", ""))
	return {"ok": true, "error": "", "state": state}


static func _string_array(value) -> Array:
	var out: Array = []
	if typeof(value) != TYPE_ARRAY:
		return out
	for item in value:
		out.append(str(item))
	return out

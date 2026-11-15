extends RefCounted

const PROFESSION_IDS := [
	"astronaut", "engineer", "physicist", "mathematician",
	"biologist", "medical", "comms", "director",
]

static func check(years: Array, dialogues: Dictionary, achievements: Array) -> Array:
	var errors: Array = []
	var seen := {}
	var ach_ids := {}
	for item in achievements:
		ach_ids[str(item.get("id", ""))] = true
	var rules = preload("res://scripts/model/achievement_rules.gd")
	for id in rules.IDS:
		if not ach_ids.has(id):
			errors.append("Missing achievement text for %s." % id)
	for year_data in years:
		if not year_data.has("tech"):
			errors.append("Year %s has no technology." % str(year_data.get("year", "?")))
		for mission in year_data.get("missions", []):
			var mid := str(mission.get("id", ""))
			if mid == "" or seen.has(mid):
				errors.append("Duplicate or blank mission id %s." % mid)
			seen[mid] = true
			mission["year"] = int(year_data.year)
			if not dialogues.has(str(mission.get("intro", ""))):
				errors.append("%s is missing its intro dialogue." % mid)
			if not dialogues.has(str(mission.get("ending", ""))):
				errors.append("%s is missing its ending dialogue." % mid)
			var tasks: Dictionary = mission.get("tasks", {})
			for profession in PROFESSION_IDS:
				if not tasks.has(profession):
					errors.append("%s has no %s duty." % [mid, profession])
					continue
				errors.append_array(_task_errors(mid, profession, tasks[profession]))
			var blob := JSON.stringify(mission).to_lower()
			if int(year_data.year) < 2030 and blob.find("first contact") >= 0:
				errors.append("%s mentions first contact before 2030." % mid)
			if int(year_data.year) <= 2026 and blob.find("we found aliens") >= 0:
				errors.append("%s claims an alien encounter." % mid)
	if dialogues.has("new_beginnings_end"):
		var ending := JSON.stringify(dialogues["new_beginnings_end"])
		if ending.find("ORIGIN UNCONFIRMED") < 0:
			errors.append("The 2026 ending does not classify the signal.")
	return errors


static func _task_errors(mission_id: String, profession: String, task: Dictionary) -> Array:
	var errors: Array = []
	var prefix := "%s/%s" % [mission_id, profession]
	for field in ["pattern", "title", "science", "hint", "emergency"]:
		if not task.has(field):
			errors.append("%s is missing %s." % [prefix, field])
	var pattern := str(task.get("pattern", ""))
	match pattern:
		"route":
			for field in ["cols", "rows", "start", "goal", "hazards"]:
				if not task.has(field):
					errors.append("%s route is missing %s." % [prefix, field])
		"switches":
			if not task.has("steps") or not task.has("order"):
				errors.append("%s switches need steps and order." % prefix)
		"burn":
			if not task.has("parts") or not task.has("timing"):
				errors.append("%s burn needs a heading and a timing window." % prefix)
		"build":
			if not task.has("parts") or not task.has("order") or not task.has("gauges"):
				errors.append("%s build needs parts, order, and gauges." % prefix)
		"inspect":
			if not task.has("steps"):
				errors.append("%s inspect needs steps." % prefix)
		"repair":
			if not task.has("symptom") or not task.has("rows"):
				errors.append("%s repair needs a symptom and a manual." % prefix)
		"measure":
			if not task.has("parts"):
				errors.append("%s measure needs parts." % prefix)
		"figure":
			if not task.has("parts"):
				errors.append("%s figure needs parts." % prefix)
		"procedure":
			for field in ["steps", "question", "samples", "answer", "conclusions"]:
				if not task.has(field):
					errors.append("%s procedure is missing %s." % [prefix, field])
		"triage":
			if not task.has("patients") or not task.has("actions"):
				errors.append("%s triage needs patients and actions." % prefix)
		"tune":
			if not task.has("frequency"):
				errors.append("%s tune needs a frequency." % prefix)
		"channels":
			if not task.has("channels"):
				errors.append("%s channels need a channel list." % prefix)
		"link":
			if not task.has("parts") or not task.has("messages"):
				errors.append("%s link needs a calculation and a message choice." % prefix)
		"priority":
			if not task.has("events"):
				errors.append("%s priority needs events." % prefix)
		"decision":
			if not task.has("prompt") or not task.has("choices"):
				errors.append("%s decision needs a prompt and choices." % prefix)
		_:
			errors.append("%s uses unknown pattern %s." % [prefix, pattern])
	return errors

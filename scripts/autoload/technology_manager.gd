extends Node

func sync() -> void:
	var completed: Array = SaveManager.state.get("completed_missions", [])
	var unlocked: Array = SaveManager.state.get("unlocked_tech", [])
	for year_data in CampaignManager.years:
		if not CampaignManager.year_unlocked(int(year_data.year), completed):
			continue
		var tech_id := str(year_data.get("tech", {}).get("id", ""))
		if tech_id != "" and not unlocked.has(tech_id):
			unlocked.append(tech_id)
	SaveManager.state["unlocked_tech"] = unlocked


func current_note(year: int) -> String:
	var tech: Dictionary = CampaignManager.year_data(year).get("tech", {})
	return str(tech.get("effect", ""))

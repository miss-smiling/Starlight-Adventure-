extends RefCounted

const IDS := [
	"first_shift",
	"clean_sheet",
	"steady_hands",
	"classified",
	"frontier",
	"verified",
	"first_contact",
	"long_listen",
	"cross_train",
]

static func evaluate(state: Dictionary, report: Dictionary) -> Array:
	var have: Array = state.get("achievements", [])
	var earned: Array = []
	var flags: Dictionary = state.get("story_flags", {})
	var completed: Array = state.get("completed_missions", [])
	_grant(earned, have, "first_shift")
	if int(report.get("mistake_count", 0)) == 0 and not bool(report.get("assisted", false)) and not bool(report.get("recovered", false)):
		_grant(earned, have, "clean_sheet")
	if bool(report.get("recovered", false)) and not bool(report.get("assisted", false)):
		_grant(earned, have, "steady_hands")
	if completed.has("new_beginnings") and not bool(flags.get("jumped_to_aliens", false)):
		_grant(earned, have, "classified")
	if _has_all(completed, ["genesis", "countdown", "transit", "red_horizon", "new_beginnings"]):
		_grant(earned, have, "frontier")
	if bool(flags.get("ai_rejected", false)):
		_grant(earned, have, "verified")
	if completed.has("first_light") and not bool(flags.get("premature_hail", false)):
		_grant(earned, have, "first_contact")
	if completed.has("long_listen"):
		_grant(earned, have, "long_listen")
	if state.get("professions_played", []).size() >= 3:
		_grant(earned, have, "cross_train")
	return earned


static func _has_all(completed: Array, needed: Array) -> bool:
	for id in needed:
		if not completed.has(id):
			return false
	return true


static func _grant(earned: Array, have: Array, id: String) -> void:
	if not have.has(id) and not earned.has(id):
		earned.append(id)

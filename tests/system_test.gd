extends SceneTree

# Headless system test. Run with:
#   godot --headless -s res://tests/system_test.gd
# Autoloads are not available with -s, so only RefCounted logic and raw data
# files are tested here, exactly as designed.

const SaveModel = preload("res://scripts/model/save_model.gd")
const NumberGrader = preload("res://scripts/model/number_grader.gd")
const RouteGrader = preload("res://scripts/model/route_grader.gd")
const CommsGrader = preload("res://scripts/model/comms_grader.gd")
const DirectorGrader = preload("res://scripts/model/director_grader.gd")
const TwistGrader = preload("res://scripts/model/twist_grader.gd")
const ScoreModel = preload("res://scripts/model/score_model.gd")
const AchievementRules = preload("res://scripts/model/achievement_rules.gd")
const Validator = preload("res://scripts/model/content_validator.gd")
const DesignModel = preload("res://scripts/model/design_model.gd")

var failures: Array = []
var checks := 0


func _init() -> void:
	_test_save_model()
	_test_number_grader()
	_test_route_grader()
	_test_comms_grader()
	_test_director_grader()
	_test_twist_grader()
	_test_dialogue_sequence()
	_test_score_model()
	_test_achievements()
	_test_campaign_data()
	_test_design_model()
	_test_save_roundtrip()

	if failures.is_empty():
		print("ALL TESTS PASSED (%d checks)" % checks)
		quit(0)
	else:
		for failure in failures:
			print("FAIL: " + failure)
		print("%d of %d checks FAILED" % [failures.size(), checks])
		quit(1)


func expect(condition: bool, name: String) -> void:
	checks += 1
	if not condition:
		failures.append(name)


func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


# ---------------------------------------------------------------- save model

func _test_save_model() -> void:
	expect(SaveModel.clean_callsign("  Ne@@ha!! ") == "Neha", "callsign strips bad characters")
	expect(SaveModel.clean_callsign("") == "Explorer", "empty callsign defaults")
	expect(SaveModel.clean_callsign("0123456789012345678") == "0123456789012345", "callsign capped at 16")

	var state := SaveModel.default_state("Tester")
	expect(state.get("version", 0) == 1, "save schema version")
	for key in ["callsign", "profession", "current_year", "completed_missions", "story_flags", "mission_history", "achievements", "runtime", "professions_by_year"]:
		expect(state.has(key), "save schema has " + key)

	expect(SaveModel.validate("nope", [], []).ok == false, "validate rejects non-dictionary")
	expect(SaveModel.validate({"version": 99}, [], []).ok == false, "validate rejects wrong version")
	expect(SaveModel.validate({"version": 1, "profession": "wizard"}, [], ["astronaut"]).ok == false, "validate rejects unknown profession")
	expect(SaveModel.validate({"version": 1, "completed_missions": "no"}, [], []).ok == false, "validate rejects damaged mission list")


# ---------------------------------------------------------------- math grader

func _test_number_grader() -> void:
	expect(NumberGrader.parse("1,234.5").value == 1234.5, "parse handles commas")
	expect(NumberGrader.parse("abc").ok == false, "parse rejects text")
	expect(NumberGrader.near(8000.0, 8000.0, 160.0), "near accepts tolerance")
	expect(not NumberGrader.near(7800.0, 8000.0, 160.0), "near rejects outside tolerance")

	var parts := [{"prompt": "x", "answer": 108.0, "tolerance": 1.0}]
	expect(NumberGrader.grade_parts(["108"], parts).ok, "grade_parts accepts correct answer")
	expect(not NumberGrader.grade_parts(["200"], parts).ok, "grade_parts rejects wrong answer")
	expect(not NumberGrader.grade_parts(["108"], []).ok, "grade_parts counts entries")
	expect(NumberGrader.grade_parts(["109.5"], parts, 2.0).ok, "grade_parts scales tolerance in recovery")


# ---------------------------------------------------------------- route grader

func _test_route_grader() -> void:
	var start := [0, 5]
	var goal := [7, 0]
	var hazards := [[2, 4], [2, 5], [3, 1], [4, 3]]
	var good := [[0, 5], [1, 5], [1, 4], [1, 3], [1, 2], [1, 1], [2, 1], [3, 1]]
	expect(RouteGrader.valid(good, start, goal, hazards, 8, 6) == false, "route through hazard rejected")
	var detour := [[0, 5], [1, 5], [1, 4], [1, 3], [1, 2], [1, 1], [2, 1], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0], [7, 0]]
	expect(RouteGrader.valid(detour, start, goal, hazards, 8, 6), "valid detour accepted")
	expect(not RouteGrader.valid([[0, 5], [0, 4]], start, goal, hazards, 8, 6), "route must reach the goal")
	expect(not RouteGrader.valid([[1, 5], [0, 5], [1, 5]], start, goal, hazards, 8, 6), "route cannot revisit tiles")
	expect(not RouteGrader.valid([[0, 5], [2, 5]], start, goal, hazards, 8, 6), "route must be contiguous")
	expect(RouteGrader.adjacent([1, 1], [2, 1]), "adjacent detects neighbors")
	expect(not RouteGrader.adjacent([1, 1], [2, 2]), "adjacent rejects diagonals")


# ---------------------------------------------------------------- comms grader

func _test_comms_grader() -> void:
	expect(CommsGrader.decode_shift("SFBEZ", 1) == "READY", "caesar decodes SFBEZ to READY")
	expect(CommsGrader.cipher_ok("ready", "SFBEZ", 1), "cipher check is case-insensitive")
	expect(CommsGrader.frequency_ok(437.5, 437.5, 0.5), "frequency in tolerance")
	expect(not CommsGrader.frequency_ok(441.0, 437.5, 0.5), "frequency out of tolerance")
	expect(CommsGrader.frequency_ok(441.0, 437.5, 0.5) == false, "backup band is not the primary")
	expect(CommsGrader.code_ok("go go", "GOGO"), "code check ignores spaces")


# ---------------------------------------------------------------- director grader

func _test_director_grader() -> void:
	var events := [
		{"id": "fuel", "rank": 1},
		{"id": "camera", "rank": 2},
		{"id": "sensor", "rank": 3},
	]
	expect(DirectorGrader.click(events, [], "camera") == "wrong", "life safety must be answered first")
	expect(DirectorGrader.click(events, [], "fuel") == "ok", "rank one click accepted")
	expect(DirectorGrader.click(events, ["fuel"], "camera") == "ok", "second click follows rank")
	expect(DirectorGrader.next_id(events, ["fuel", "camera", "sensor"]) == "", "all events handled")
	expect(DirectorGrader.expired(events, [], {"fuel": 0.0}), "expired life-safety alert detected")
	expect(not DirectorGrader.expired(events, [], {"fuel": 10.0}), "live alert not expired")


# ---------------------------------------------------------------- twist grader

func _test_twist_grader() -> void:
	expect(TwistGrader.bad_ai("reject"), "rejecting the AI is the verified path")
	expect(not TwistGrader.bad_ai("accept"), "accepting the AI is not verification")
	expect(TwistGrader.choice_ok("Go", "Go"), "verdict match")
	expect(TwistGrader.order_ok(["a", "b"], ["a", "b"]), "order match")
	expect(not TwistGrader.order_ok(["b", "a"], ["a", "b"]), "order mismatch")


# ---------------------------------------------------------------- dialogue model

func _test_dialogue_sequence() -> void:
	var Sequence = load("res://scripts/model/dialogue_sequence.gd")
	var model = Sequence.new()
	model.setup({"lines": [
		{"speaker": "mira_vale", "text": "Line one."},
		{"speaker": "player", "text": "Reply.", "choices": [{"text": "Yes", "goto": "other"}]},
	]})
	expect(model.current().get("text", "") == "Line one.", "dialogue starts at line one")
	expect(model.advance() == "line", "advance within node returns line")
	expect(model.current().get("speaker", "") == "player", "second line is the player")
	expect(model.advance() == "end", "node without next ends")

	var chained = Sequence.new()
	chained.setup({"lines": [{"speaker": "x", "text": "go"}], "next": "other"})
	expect(chained.advance() == "goto", "chained node reports goto")


# ---------------------------------------------------------------- scoring

func _test_score_model() -> void:
	var perfect := {
		"required_done": 3, "required_total": 3, "optional_done": 1,
		"mistake_count": 0, "recovered": false, "assisted": false, "costly": false,
	}
	var clean := ScoreModel.calculate(perfect)
	expect(clean.grade == "A", "perfect shift earns grade A")
	expect(clean.points == 1000, "perfect shift earns 1000 points")
	expect(clean.clean, "perfect shift is clean")

	var sloppy := perfect.duplicate()
	sloppy["mistake_count"] = 3
	sloppy["recovered"] = true
	var graded := ScoreModel.calculate(sloppy)
	expect(graded.points < clean.points, "mistakes reduce the score")
	expect(graded.grade != "A", "sloppy shift loses grade A")

	var zero := ScoreModel.calculate({"required_done": 0, "required_total": 3, "optional_done": 0, "mistake_count": 0, "recovered": false, "assisted": true, "costly": true})
	expect(zero.points >= 0, "score never goes below zero")


# ---------------------------------------------------------------- achievements

func _test_achievements() -> void:
	var state := SaveModel.default_state("Tester")
	var report := {"mistake_count": 0, "assisted": false, "recovered": false}
	var fresh := AchievementRules.evaluate(state, report)
	expect(fresh.has("first_shift"), "first shift granted immediately")

	var classified_state := state.duplicate(true)
	classified_state["completed_missions"] = ["new_beginnings"]
	expect(AchievementRules.evaluate(classified_state, report).has("classified"), "classified needs the signal mission without aliens")
	var jumped := classified_state.duplicate(true)
	jumped["story_flags"] = {"jumped_to_aliens": true}
	expect(not AchievementRules.evaluate(jumped, report).has("classified"), "jumping to aliens blocks classified")

	var all_five := state.duplicate(true)
	all_five["completed_missions"] = ["genesis", "countdown", "transit", "red_horizon", "new_beginnings"]
	expect(AchievementRules.evaluate(all_five, report).has("frontier"), "frontier needs all five 2026 missions")

	var cross := state.duplicate(true)
	cross["professions_played"] = ["comms", "engineer", "biologist"]
	expect(AchievementRules.evaluate(cross, report).has("cross_train"), "cross train needs three professions")

	expect(not AchievementRules.evaluate(state.duplicate(true), report).has("verified"), "verified needs the AI flag")
	var ai_state := state.duplicate(true)
	ai_state["story_flags"] = {"ai_rejected": true}
	expect(AchievementRules.evaluate(ai_state, report).has("verified"), "verified from ai_rejected flag")


# ---------------------------------------------------------------- campaign data

func _test_campaign_data() -> void:
	var years: Array = []
	for path in ["res://data/year_2026.json", "res://data/year_2027.json", "res://data/year_2028.json", "res://data/year_2029.json", "res://data/year_2030.json", "res://data/year_2031.json"]:
		var parsed = _read_json(path)
		expect(parsed != null, "readable " + path)
		if parsed != null:
			years.append(parsed)
	var dialogues = _read_json("res://data/dialogues.json")
	var achievements = _read_json("res://data/achievements.json")
	expect(dialogues != null and dialogues.size() > 40, "dialogues present")
	expect(achievements != null and achievements.size() >= 9, "achievements present")

	var errors: Array = Validator.check(years, dialogues, achievements)
	expect(errors.is_empty(), "campaign data validates: " + " | ".join(PackedStringArray(errors.slice(0, 3))))

	var mission_count := 0
	for year_data in years:
		mission_count += year_data.get("missions", []).size()
	expect(mission_count == 10, "ten missions total (5 in 2026 + 5 later)")
	for year_data in years:
		for mission in year_data.get("missions", []):
			var tasks: Dictionary = mission.get("tasks", {})
			expect(tasks.size() == 8, "%s has eight profession tasks" % str(mission.get("id", "")))


# ---------------------------------------------------------------- design model

func _test_design_model() -> void:
	var catalog = _read_json("res://data/design_catalog.json")
	expect(catalog != null, "design catalog readable")
	var rules: Dictionary = catalog.get("rules", {})

	var good := {"vehicle": "skyrider", "propulsion": "liquid", "power": "solar_l", "comms": "high"}
	var best_instruments := ["camera", "spectrometer", "dust"]
	var summary := DesignModel.summarize(good, best_instruments, catalog, rules)
	var problems := DesignModel.violations(summary)
	expect(problems.is_empty(), "science-max design passes all constraints: " + " | ".join(PackedStringArray(problems.slice(0, 2))))
	expect(int(summary.science) == 8, "instrument science values sum to 8")
	expect(float(summary.cost) <= float(rules.get("budget", 0)), "best design fits the budget")

	var heavy := DesignModel.summarize({"vehicle": "atlas", "propulsion": "liquid", "power": "solar_s", "comms": "low"}, best_instruments, catalog, rules)
	expect(not DesignModel.violations(heavy).is_empty(), "heavy launcher design cannot meet the science target")

	var solid_only := DesignModel.summarize({"vehicle": "skyrider", "propulsion": "solid", "power": "solar_l", "comms": "high"}, best_instruments, catalog, rules)
	expect(DesignModel.violations(solid_only).any(func(v: String): return v.find("Propulsion") >= 0), "solid kick stage fails the delta-v requirement")

	var empty := DesignModel.summarize({}, [], catalog, rules)
	expect(DesignModel.violations(empty).size() >= 3, "empty design flagged")

	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 7
	var run_a := DesignModel.simulate(summary, rng_a)
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 7
	var run_b := DesignModel.simulate(summary, rng_b)
	expect(str(run_a.lines) == str(run_b.lines), "simulation deterministic for a fixed seed")
	expect(int(run_a.science_returned) == 8, "full power and high-gain design returns all science")
	expect(run_a.grade == "A", "clean design simulation grades A")

	var bottleneck := DesignModel.summarize({"vehicle": "skyrider", "propulsion": "liquid", "power": "solar_s", "comms": "low"}, best_instruments, catalog, rules)
	expect(float(bottleneck.power_draw) <= float(bottleneck.power_supply), "low-power design still within supply")
	expect(int(DesignModel.simulate(bottleneck, rng_a).science_returned) < 8, "low-gain antenna loses science in the sim")


# ---------------------------------------------------------------- save roundtrip

func _test_save_roundtrip() -> void:
	var state := SaveModel.default_state("Round Trip")
	state["profession"] = "comms"
	state["current_year"] = 2027
	state["completed_missions"] = ["genesis", "countdown", "transit", "red_horizon", "new_beginnings"]
	state["story_flags"] = {"signal_classified": true, "launch_delay": true}
	state["mission_history"] = [{"id": "genesis", "points": 900, "grade": "A"}]

	var text := JSON.stringify(state)
	var parsed = JSON.parse_string(text)
	var mission_ids: Array = ["genesis", "countdown", "transit", "red_horizon", "new_beginnings", "shackleton_relay", "ember_drive", "living_sensors", "first_light", "long_listen"]
	var result := SaveModel.validate(parsed, mission_ids, ["comms"])
	expect(result.ok, "roundtrip validates")
	if result.ok:
		var loaded: Dictionary = result.state
		expect(loaded["callsign"] == "Round Trip", "roundtrip keeps callsign")
		expect(loaded["profession"] == "comms", "roundtrip keeps profession")
		expect(loaded["completed_missions"].size() == 5, "roundtrip keeps mission list")
		expect(bool(loaded["story_flags"].get("signal_classified", false)), "roundtrip keeps story flags")
		expect(bool(loaded.get("replay", true)) == false, "roundtrip never restores replay mode")

extends "res://scripts/ui/tasks/task_base.gd"

# Mission design board. The player assembles a spacecraft inside a budget,
# a launch-mass limit and a power supply, chasing a science target - then
# simulates the mission and sees exactly how each choice shaped the result.

const DesignModel = preload("res://scripts/model/design_model.gd")

const CATEGORY_TITLES := {
	"vehicle": "Launch vehicle",
	"propulsion": "Propulsion (kick stage)",
	"power": "Power system",
	"comms": "Communications",
}

var catalog: Dictionary = {}
var rules: Dictionary = {}
var picks := {"vehicle": "", "propulsion": "", "power": "", "comms": ""}
var instruments: Array = []
var board: VBoxContainer = null
var status_labels := {}
var option_buttons := {}
var sim_status: Label = null
var sims := 0
var sim_result: Dictionary = {}


func _build() -> void:
	build_frame(self)
	if FileAccess.file_exists("res://data/design_catalog.json"):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/design_catalog.json"))
		if typeof(parsed) == TYPE_DICTIONARY:
			catalog = parsed
	rules = catalog.get("rules", {})
	board = VBoxContainer.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.add_theme_constant_override("separation", 8)
	body.add_child(board)
	_build_board()


func _build_board() -> void:
	UIKit.clear(board)
	status_labels = {}
	option_buttons = {}
	sims = 0
	sim_result = {}

	var status := UIKit.panel()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 10)
	status.add_child(grid)
	board.add_child(status)
	var budget_span := maxf(1.0, float(rules.get("budget", 240))) * 1.15
	status_labels["budget"] = _add_gauge(grid, "Budget", 0.0, budget_span, 0.0, budget_span)
	var capacity_span := 1.0
	status_labels["mass"] = _add_gauge(grid, "Payload mass", 0.0, capacity_span, 0.0, capacity_span)
	status_labels["power"] = _add_gauge(grid, "Power draw", 0.0, capacity_span, 0.0, capacity_span)
	var max_science: int = DesignModel.max_science(catalog)
	status_labels["science"] = _add_gauge(grid, "Science value", 0.0, maxf(1.0, float(max_science)), float(rules.get("required_science", 8)), float(max_science))
	status_labels["dv"] = _add_gauge(grid, "Delta-v", 0.0, maxf(1.0, float(rules.get("dv_needed", 1500))) * 1.2, float(rules.get("dv_needed", 1500)), maxf(1.0, float(rules.get("dv_needed", 1500))) * 1.2)

	for category in ["vehicle", "propulsion", "power", "comms"]:
		board.add_child(UIKit.label(str(CATEGORY_TITLES[category]), 16, UIKit.ACCENT))
		var row := GridContainer.new()
		row.columns = 2
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("h_separation", 8)
		row.add_theme_constant_override("v_separation", 8)
		var refs: Array = []
		for option in catalog.get(category, []):
			var id := str(option.get("id", ""))
			var text := _option_text(option)
			var item_button := UIKit.button(text)
			item_button.pressed.connect(_pick.bind(category, id))
			row.add_child(item_button)
			refs.append({"button": item_button, "id": id, "text": text})
		option_buttons[category] = refs
		board.add_child(row)

	board.add_child(UIKit.label("Science instruments (pick several)", 16, UIKit.ACCENT))
	var instrument_grid := GridContainer.new()
	instrument_grid.columns = 2
	instrument_grid.add_theme_constant_override("h_separation", 10)
	for option in catalog.get("instruments", []):
		var toggle := Button.new()
		toggle.toggle_mode = true
		toggle.custom_minimum_size = Vector2(300, 44)
		toggle.text = _option_text(option)
		toggle.add_theme_font_override("font", UIKit.FONT_BODY)
		toggle.add_theme_font_size_override("font_size", 19)
		toggle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle.toggled.connect(_toggle_instrument.bind(str(option.get("id", ""))))
		instrument_grid.add_child(toggle)
	board.add_child(instrument_grid)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UIKit.button("Run launch simulation", _run_sim))
	board.add_child(row)
	sim_status = UIKit.wrapped("", 16, UIKit.DANGER)
	board.add_child(sim_status)
	_update_status()


func _add_gauge(parent: Control, title_text: String, min_v: float, max_v: float, zone_lo: float, zone_hi: float) -> Dictionary:
	var gauge := UIKit.gauge(title_text, 0.0, zone_lo, zone_hi, "", true)
	gauge.custom_minimum_size = Vector2(300, 0)
	parent.add_child(gauge)
	var bar = gauge.get_child(1)
	var readout: Label = (gauge.get_child(0) as HBoxContainer).get_child(2)
	bar.setup(min_v, max_v, zone_lo, zone_hi, 0.0, true)
	return {"bar": bar, "readout": readout}


func _set_gauge(key: String, value: float, ok: bool, readout_text: String) -> void:
	var parts: Dictionary = status_labels[key]
	var bar = parts["bar"]
	bar.update_gauge(value, ok)
	var readout: Label = parts["readout"]
	readout.text = readout_text
	readout.add_theme_color_override("font_color", UIKit.SUCCESS if ok else UIKit.DANGER)


func _option_text(option: Dictionary) -> String:
	var stats: Array = []
	for key in ["cost", "mass", "power", "capacity", "dv", "science", "band"]:
		if option.has(key):
			stats.append("%s %d" % [key, int(option[key])])
	if option.has("reliability"):
		stats.append("rel %d%%" % int(float(option.reliability) * 100.0))
	var note := str(option.get("note", ""))
	var text := "%s\n%s" % [str(option.get("name", "Part")), " | ".join(PackedStringArray(stats))]
	if note != "":
		text += "\n" + note
	return text


func _pick(category: String, id: String) -> void:
	picks[category] = id
	_update_status()


func _toggle_instrument(on: bool, id: String) -> void:
	if on and not instruments.has(id):
		instruments.append(id)
	elif not on and instruments.has(id):
		instruments.erase(id)
	_update_status()


func _update_status() -> void:
	if status_labels.is_empty():
		return
	var summary := DesignModel.summarize(picks, instruments, catalog, rules)
	var budget_ok: bool = float(summary.cost) <= float(summary.budget)
	_set_gauge("budget", float(summary.cost), budget_ok, "%d / %d M used" % [int(summary.cost), int(summary.budget)])
	var mass_ok: bool = float(summary.mass) <= float(summary.capacity)
	_set_gauge("mass", float(summary.mass), mass_ok, "%d / %d kg" % [int(summary.mass), int(summary.capacity)])
	var power_ok: bool = float(summary.power_draw) <= float(summary.power_supply)
	_set_gauge("power", float(summary.power_draw), power_ok, "%d / %d W draw" % [int(summary.power_draw), int(summary.power_supply)])
	var science_ok: bool = int(summary.science) >= int(summary.required_science)
	_set_gauge("science", float(summary.science), science_ok, "%d / %d target (max %d)" % [int(summary.science), int(summary.required_science), int(summary.max_science)])
	var dv_ok: bool = float(summary.dv) >= float(summary.dv_needed)
	_set_gauge("dv", float(summary.dv), dv_ok, "%d / %d m/s needed" % [int(summary.dv), int(summary.dv_needed)])

	for category in option_buttons.keys():
		for reference in option_buttons[category]:
			var button: Button = reference.button
			var chosen: bool = str(picks[category]) == str(reference.id)
			button.text = str(reference.text) + ("   << selected" if chosen else "")

	if sim_status != null:
		var problems := DesignModel.violations(summary)
		# One problem per line: a single long joined line would force the
		# whole board wider than the window and push the header off-screen.
		sim_status.text = "" if problems.is_empty() else "\n".join(PackedStringArray(problems))
		sim_status.add_theme_color_override("font_color", UIKit.DANGER)


func _run_sim() -> void:
	var summary := DesignModel.summarize(picks, instruments, catalog, rules)
	var problems := DesignModel.violations(summary)
	if problems.has("Design incomplete: pick a vehicle, engine, power and comms system."):
		sim_status.text = "Pick one part in every category before simulating."
		return
	for violation in problems:
		mistake(str(violation))
	sims += 1
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	sim_result = DesignModel.simulate(summary, rng)
	_show_outcome(summary)


func _show_outcome(summary: Dictionary) -> void:
	UIKit.clear(board)
	var verdict_color := UIKit.SUCCESS if bool(sim_result.launch_ok) else UIKit.DANGER
	board.add_child(UIKit.banner("Simulation %d of %d - grade %s" % [sims, int(rules.get("max_sims", 3)), str(sim_result.grade)], verdict_color))
	for line in sim_result.lines:
		board.add_child(UIKit.wrapped("- " + str(line), 16))
	board.add_child(UIKit.wrapped("Each choice moved a number: budget bought instruments, mass had to fit the rocket, power had to feed them, and the antenna decided how much science came home.", 15, UIKit.DIM))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UIKit.button("File the design report", _file_report))
	var again := UIKit.button("Back to the board", _back_to_board)
	again.disabled = sims >= int(rules.get("max_sims", 3))
	row.add_child(again)
	board.add_child(row)
	if again.disabled:
		board.add_child(UIKit.wrapped("No simulations left. File the report with what you have.", 15, UIKit.DANGER))


func _back_to_board() -> void:
	_build_board()


func _file_report() -> void:
	var vehicle := DesignModel.item(catalog, "vehicle", str(picks.get("vehicle", "")))
	var decision := {
		"text": "Mission design: %s, %d instruments, %s power" % [str(vehicle.get("name", "?")), instruments.size(), str(DesignModel.item(catalog, "power", str(picks.get("power", ""))).get("name", "?"))],
		"consequence": "Simulated: launch %s, grade %s, science %d of %d, %d M left" % ["nominal" if bool(sim_result.get("launch_ok", false)) else "anomaly", str(sim_result.get("grade", "?")), int(sim_result.get("science_returned", 0)), int(rules.get("required_science", 0)), int(max(0.0, float(rules.get("budget", 0)) - float(DesignModel.summarize(picks, instruments, catalog, rules).cost)))],
	}
	finish(true, {
		"decisions": [decision],
		"science": "Mission design trades budget, mass and power against science return.",
		"flags": {"design_grade": str(sim_result.get("grade", "C"))},
	})


func tips() -> Array:
	return [
		"Run the simulation early and often - every run is free feedback.",
		"Budget first: an instrument you cannot afford never leaves the ground.",
		"Watch all three gauges: cost, payload mass and power must all fit.",
		"Pick the instruments the mission goal actually asks for, not the shiniest set.",
	]

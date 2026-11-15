extends RefCounted

# Pure mission-design math: budget, mass, power, science and launch
# simulation. Deterministic when given a seeded RandomNumberGenerator, so the
# headless test suite can verify every trade-off rule.

static func item(catalog: Dictionary, category: String, id: String) -> Dictionary:
	for option in catalog.get(category, []):
		if str(option.get("id", "")) == id:
			return option
	return {}


static func max_science(catalog: Dictionary) -> int:
	var total := 0
	for option in catalog.get("instruments", []):
		total += int(option.get("science", 0))
	return total


static func summarize(picks: Dictionary, instruments: Array, catalog: Dictionary, rules: Dictionary) -> Dictionary:
	var vehicle := item(catalog, "vehicle", str(picks.get("vehicle", "")))
	var engine := item(catalog, "propulsion", str(picks.get("propulsion", "")))
	var power := item(catalog, "power", str(picks.get("power", "")))
	var comms := item(catalog, "comms", str(picks.get("comms", "")))

	var cost := float(vehicle.get("cost", 0)) + float(engine.get("cost", 0)) + float(power.get("cost", 0)) + float(comms.get("cost", 0))
	var payload_mass := float(engine.get("mass", 0)) + float(power.get("mass", 0)) + float(comms.get("mass", 0))
	var power_draw := float(comms.get("power", 0))
	var science := 0
	for id in instruments:
		var instrument := item(catalog, "instruments", str(id))
		cost += float(instrument.get("cost", 0))
		payload_mass += float(instrument.get("mass", 0))
		power_draw += float(instrument.get("power", 0))
		science += int(instrument.get("science", 0))

	return {
		"vehicle": vehicle,
		"engine": engine,
		"power": power,
		"comms": comms,
		"cost": cost,
		"mass": payload_mass,
		"capacity": float(vehicle.get("capacity", 0)),
		"power_draw": power_draw,
		"power_supply": float(power.get("power", 0)),
		"science": science,
		"max_science": max_science(catalog),
		"dv": float(engine.get("dv", 0)),
		"dv_needed": float(rules.get("dv_needed", 0)),
		"required_science": int(rules.get("required_science", 0)),
		"budget": float(rules.get("budget", 0)),
		"complete": vehicle.size() > 0 and engine.size() > 0 and power.size() > 0 and comms.size() > 0,
	}


static func violations(summary: Dictionary) -> Array:
	var out: Array = []
	if not bool(summary.complete):
		out.append("Design incomplete: pick a vehicle, engine, power and comms system.")
	if float(summary.cost) > float(summary.budget):
		out.append("Over budget: used %d of %d M." % [int(summary.cost), int(summary.budget)])
	if float(summary.mass) > float(summary.capacity):
		out.append("Over the mass limit: %d of %d kg." % [int(summary.mass), int(summary.capacity)])
	if int(summary.science) < int(summary.required_science):
		out.append("Not enough science value: %d of %d." % [int(summary.science), int(summary.required_science)])
	if float(summary.dv) < float(summary.dv_needed):
		out.append("Propulsion too weak: %d of %d m/s of delta-v." % [int(summary.dv), int(summary.dv_needed)])
	if float(summary.power_draw) > float(summary.power_supply):
		out.append("Power draw exceeds the supply: %d of %d W." % [int(summary.power_draw), int(summary.power_supply)])
	return out


static func reliability(summary: Dictionary) -> float:
	var p := float(summary.vehicle.get("reliability", 0.9))
	var capacity := float(summary.capacity)
	if capacity > 0 and float(summary.mass) / capacity <= 0.75:
		p += 0.03
	var draw := float(summary.power_draw)
	if draw > 0 and float(summary.power_supply) / draw >= 1.3:
		p += 0.03
	if float(summary.budget) - float(summary.cost) >= float(summary.budget) * 0.08:
		p += 0.02
	if int(summary.comms.get("band", 1)) >= 3:
		p += 0.02
	return clampf(p, 0.05, 0.99)


static func simulate(summary: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var lines: Array = []
	var factor := 1.0
	var p := reliability(summary)
	var roll := rng.randf()
	var launch_ok := roll < p
	if launch_ok:
		lines.append("Launch: nominal. Reliability %d%%, roll %.2f." % [int(p * 100.0), roll])
	else:
		factor *= 0.6
		lines.append("Launch anomaly: the vehicle safed itself. Backup windows saved most of the science. (roll %.2f vs %d%%)" % [roll, int(p * 100.0)])
	if float(summary.power_draw) > float(summary.power_supply):
		factor *= 0.5
		lines.append("Power shortfall: the instruments share one supply, so science time was cut in half.")
	else:
		lines.append("Power: every instrument gets its full share.")
	if int(summary.comms.get("band", 1)) < 2:
		factor *= 0.6
		lines.append("Comms bottleneck: the low-gain antenna drops most of the data.")
	else:
		lines.append("Comms: the high-gain dish returns the full data set.")
	var returned := int(round(float(summary.science) * factor))
	lines.append("Science returned: %d of %d target." % [returned, int(summary.required_science)])
	lines.append("Money left: %d M." % int(max(0.0, float(summary.budget) - float(summary.cost))))
	var grade := "C"
	if returned >= int(summary.required_science):
		grade = "A" if launch_ok else "B"
	elif returned >= int(round(float(summary.required_science) * 0.75)):
		grade = "B" if launch_ok else "C"
	return {
		"lines": lines,
		"science_returned": returned,
		"launch_ok": launch_ok,
		"grade": grade,
		"reliability": p,
		"roll": roll,
	}

extends RefCounted

static func parse(text: String) -> Dictionary:
	var cleaned := text.strip_edges().replace(",", "").replace(" ", "")
	if cleaned == "" or not cleaned.is_valid_float():
		return {"ok": false, "value": 0.0}
	return {"ok": true, "value": float(cleaned)}


static func near(value: float, answer: float, tolerance: float) -> bool:
	return abs(value - answer) <= abs(tolerance) + 0.0001


static func grade_parts(entries: Array, parts: Array, scale: float = 1.0) -> Dictionary:
	if entries.size() != parts.size():
		return {"ok": false, "reason": "Enter every value."}
	for i in parts.size():
		var parsed: Dictionary = parse(str(entries[i]))
		if not parsed.ok:
			return {"ok": false, "reason": "Use a number for each blank."}
		var tol := float(parts[i].get("tolerance", 0.0)) * scale
		if not near(float(parsed.value), float(parts[i].answer), tol):
			return {"ok": false, "reason": "Check the figure for: %s" % str(parts[i].get("prompt", "value"))}
	return {"ok": true, "reason": ""}

extends RefCounted

static func calculate(report: Dictionary) -> Dictionary:
	var points := 400
	points += int(report.get("required_done", 0)) * 150
	points += int(report.get("optional_done", 0)) * 50
	points -= int(report.get("mistake_count", 0)) * 40
	if bool(report.get("recovered", false)):
		points -= 30
	if bool(report.get("assisted", false)):
		points -= 80
	var clean := int(report.get("mistake_count", 0)) == 0 and not bool(report.get("assisted", false)) and not bool(report.get("recovered", false)) and not bool(report.get("costly", false))
	if clean:
		points += 100
	points = max(points, 0)
	var grade := "D"
	if points >= 950:
		grade = "A"
	elif points >= 800:
		grade = "B"
	elif points >= 600:
		grade = "C"
	return {"points": points, "grade": grade, "clean": clean}

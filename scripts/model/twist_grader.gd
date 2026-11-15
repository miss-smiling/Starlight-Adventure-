extends RefCounted

static func bad_ai(choice: String) -> bool:
	return choice == "reject"


static func heat(value: float, answer: float, tolerance: float, max_temp: float) -> bool:
	return value <= max_temp and abs(value - answer) <= abs(tolerance) + 0.0001


static func choice_ok(choice: String, answer: String) -> bool:
	return choice == answer


static func order_ok(path: Array, expected: Array) -> bool:
	if path.size() != expected.size():
		return false
	for i in path.size():
		if str(path[i]) != str(expected[i]):
			return false
	return true

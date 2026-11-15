extends RefCounted

static func key_of(cell) -> String:
	return "%d,%d" % [int(cell[0]), int(cell[1])]


static func same(a, b) -> bool:
	return int(a[0]) == int(b[0]) and int(a[1]) == int(b[1])


static func adjacent(a, b) -> bool:
	return abs(int(a[0]) - int(b[0])) + abs(int(a[1]) - int(b[1])) == 1


static func valid(path: Array, start, goal, hazards: Array, cols: int, rows: int) -> bool:
	if path.is_empty():
		return false
	if not same(path[0], start) or not same(path[path.size() - 1], goal):
		return false
	var blocked := {}
	for hazard in hazards:
		blocked[key_of(hazard)] = true
	var seen := {}
	for i in path.size():
		var cell = path[i]
		var x := int(cell[0])
		var y := int(cell[1])
		if x < 0 or y < 0 or x >= cols or y >= rows:
			return false
		var key := key_of(cell)
		if blocked.has(key) or seen.has(key):
			return false
		seen[key] = true
		if i > 0 and not adjacent(path[i - 1], cell):
			return false
	return true

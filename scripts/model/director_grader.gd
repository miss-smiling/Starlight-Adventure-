extends RefCounted

static func next_id(events: Array, done: Array) -> String:
	var next_rank := 9999
	var found := ""
	for event in events:
		var id := str(event.id)
		if done.has(id):
			continue
		var rank := int(event.rank)
		if rank < next_rank:
			next_rank = rank
			found = id
	return found


static func click(events: Array, done: Array, id: String) -> String:
	var expected := next_id(events, done)
	if expected == "":
		return "done"
	if id == expected:
		return "ok"
	return "wrong"


static func expired(events: Array, done: Array, remaining: Dictionary) -> bool:
	var expected := next_id(events, done)
	if expected == "" or not remaining.has(expected):
		return false
	return float(remaining[expected]) <= 0.0

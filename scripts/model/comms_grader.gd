extends RefCounted

static func frequency_ok(value: float, target: float, tolerance: float) -> bool:
	return abs(value - target) <= abs(tolerance) + 0.0001


static func decode_shift(text: String, shift: int) -> String:
	var out := ""
	for i in text.length():
		var code := text.unicode_at(i)
		var upper := text.substr(i, 1).to_upper()
		var letter := upper.unicode_at(0)
		if letter >= 65 and letter <= 90:
			var n := (letter - 65 - shift) % 26
			if n < 0:
				n += 26
			out += char(n + 65)
		else:
			out += char(code)
	return out


static func cipher_ok(guess: String, cipher: String, shift: int) -> bool:
	return guess.strip_edges().to_upper() == decode_shift(cipher, shift)


static func code_ok(guess: String, answer: String) -> bool:
	var left := guess.strip_edges().to_upper().replace(" ", "")
	var right := answer.strip_edges().to_upper().replace(" ", "")
	return left == right

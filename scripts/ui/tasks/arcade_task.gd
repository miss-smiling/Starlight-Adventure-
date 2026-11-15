extends "res://scripts/ui/tasks/task_base.gd"

# Debris-field finale - the same arcade run for every profession. The ship
# slides up and down (mouse or W/S/arrows) and fires automatically; blast 10
# asteroids before the timer ends. Forgiving: 3 hull plates, and running out
# just patches the hull and keeps going - the run always completes.

const TARGET := 10
const HULL := 3

var field: Control = null
var ship_y := 0.5
var asteroids: Array = []
var bullets: Array = []
var score := 0
var hull := HULL
var time_left := 60.0
var fire_cd := 0.0
var spawn_cd := 0.6
var over := false

var readout: Label = null
var art_bg: Texture2D = null
var art_ship: Texture2D = null
var art_rocks: Array = []


func _build() -> void:
	build_frame(self)
	art_bg = UIKit.art("game/shooting game backgraund.png")
	art_ship = UIKit.art("game/shooting game spaceship.png")
	for path in ["game/asteroid.png", "game/fireball blue.png", "game/fireball red.png"]:
		var sprite := UIKit.art(path)
		if sprite != null:
			art_rocks.append(sprite)
	body.add_child(UIKit.banner("GOAL: blast %d asteroids. Move with the MOUSE or W/S - the laser fires by itself." % TARGET, UIKit.ACCENT_2))
	readout = UIKit.heading("", 14, UIKit.ACCENT)
	body.add_child(readout)
	field = DebrisField.new(self)
	field.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	field.custom_minimum_size = Vector2(0, 400)
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(field)
	for i in 3:
		asteroids.append(_new_asteroid(1.2 + i * 0.7))


func _new_asteroid(delay: float) -> Dictionary:
	return {"y": randf_range(0.1, 0.9), "x": 1.05 + delay, "v": randf_range(0.10, 0.20), "r": randf_range(16.0, 30.0), "hp": 1 if randf() < 0.7 else 2, "kind": randi() % 3, "seed": randf() * TAU}


func _process(delta: float) -> void:
	if over or field == null:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		return _finish()
	var up := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var down := Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	if up:
		ship_y = clampf(ship_y - delta * 0.8, 0.06, 0.94)
	if down:
		ship_y = clampf(ship_y + delta * 0.8, 0.06, 0.94)
	var mouse_y := field.get_local_mouse_position().y
	if mouse_y > 0.0 and not (up or down):
		ship_y = clampf(mouse_y / maxf(1.0, field.size.y), 0.06, 0.94)
	fire_cd -= delta
	if fire_cd <= 0.0:
		fire_cd = 0.35
		bullets.append({"x": 0.08, "y": ship_y})
	spawn_cd -= delta
	if spawn_cd <= 0.0 and asteroids.size() < 6:
		spawn_cd = randf_range(1.0, 2.0)
		asteroids.append(_new_asteroid(0.0))
	var dead: Array = []
	for rock in asteroids:
		rock.x -= rock.v * delta
		if rock.x < -0.05:
			dead.append(rock)
			hull -= 1
			mistake("Arcade: asteroid slipped past the ship")
			if hull <= 0:
				hull = HULL
				readout.add_theme_color_override("font_color", UIKit.WARN)
		for i in range(bullets.size() - 1, -1, -1):
			var b: Dictionary = bullets[i]
			b.x += delta * 0.9
			if b.x > 1.05:
				bullets.remove_at(i)
				continue
			var dy: float = abs(float(b.y) - float(rock.y))
			if dy * field.size.y < float(rock.r) and abs(float(b.x) - float(rock.x)) * field.size.x < float(rock.r):
				bullets.remove_at(i)
				rock.hp -= 1
				if rock.hp <= 0:
					dead.append(rock)
					score += 1
	for rock in dead:
		asteroids.erase(rock)
	if score >= TARGET:
		return _finish()
	readout.text = "BLASTED %d / %d    HULL %d    TIME %ds" % [score, TARGET, hull, int(ceil(time_left))]
	readout.add_theme_color_override("font_color", UIKit.SUCCESS if hull == HULL else UIKit.ACCENT)
	field.queue_redraw()


func _finish() -> void:
	over = true
	finish(true, {
		"decisions": [{"text": "Debris run: %d asteroids blasted." % score, "consequence": "The approach corridor is clear.", "result": "pass"}],
		"science": "Reflex drills keep the crew sharp for real debris.",
	})


class DebrisField extends Control:
	var game = null

	func _init(parent) -> void:
		game = parent

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w < 10.0 or game == null:
			return
		if game.art_bg != null:
			draw_texture_rect(game.art_bg, Rect2(Vector2.ZERO, size), false)
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color("081020"))
		for i in 14:
			var sx := fposmod(float(i * 137), w)
			var sy := fposmod(float(i * 251), h)
			draw_rect(Rect2(sx, sy, 2, 2), Color("1d2f52"))
		# Asteroids and fireballs use uploaded sprites when available.
		for rock in game.asteroids:
			var pos := Vector2(float(rock.x) * w, float(rock.y) * h)
			var r: float = float(rock.r)
			if not game.art_rocks.is_empty():
				var sprite: Texture2D = game.art_rocks[int(rock.kind) % game.art_rocks.size()]
				draw_texture_rect(sprite, Rect2(pos - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false)
			else:
				var body := Color("2b4677") if int(rock.hp) > 1 else Color("1b3059")
				draw_circle(pos, r, body)
				draw_circle(pos + Vector2(r * 0.3, -r * 0.2), r * 0.25, Color("132244"))
			if float(rock.x) < 0.35:
				draw_arc(pos, r, 0, TAU, 20, game.UIKit.ACCENT, 2.0)
		# Bullets: cyan tracer bolts flying right.
		for b in game.bullets:
			var pos := Vector2(float(b.x) * w, float(b.y) * h)
			draw_rect(Rect2(pos - Vector2(6, 2), Vector2(14, 4)), game.UIKit.ACCENT_2)
			draw_rect(Rect2(pos - Vector2(2, 1), Vector2(10, 2)), Color.WHITE)
		# Ship: uploaded spacecraft sprite rotated to face right (the art is
		# drawn nose-up), or the drawn rocket fallback.
		var ship := Vector2(0.08 * w, game.ship_y * h)
		var flame := 8.0 + 4.0 * sin(Time.get_ticks_msec() / 90.0)
		draw_rect(Rect2(ship + Vector2(-14 - flame, -3), Vector2(flame, 6)), game.UIKit.ACCENT_2)
		if game.art_ship != null:
			draw_set_transform(ship, PI / 2.0, Vector2.ONE)
			draw_texture_rect(game.art_ship, Rect2(Vector2(-28, -28), Vector2(56, 56)), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var points := PackedVector2Array([ship + Vector2(18, 0), ship + Vector2(-14, -12), ship + Vector2(-8, 0), ship + Vector2(-14, 12)])
			draw_colored_polygon(points, Color.WHITE)
			draw_circle(ship + Vector2(14, 0), 5.0, game.UIKit.ACCENT)
		# Hull plates across the top.
		for i in game.HULL:
			draw_rect(Rect2(w - 24 - i * 20, 8, 14, 8), game.UIKit.SUCCESS if i < game.hull else Color("132244"))


func tips() -> Array:
	return [
		"Move the mouse over the field, or hold W/S - the ship follows either.",
		"The laser fires on its own; your job is lining up the shot.",
		"Losing all 3 hull plates is safe - the hull patches itself and the run continues.",
		"Big two-hit rocks flash a thicker rim; keep shooting.",
	]

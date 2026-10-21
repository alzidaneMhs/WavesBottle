class_name Matriarch
extends Enemy

const OFFSETS := [-30.0, -15.0, 0.0, 15.0, 30.0]

var state := "approach"
var state_time := 4.0
var phase := 1
var cycle := -1
var fire_side := 1.0
var volleys := 0
var both_sides := false
var reposition_target := Vector2.ZERO
var current_ref: Dictionary = {}


func _on_setup() -> void:
	boss = true
	side_gunned = true


func phase_marks() -> Array:
	return [0.66, 0.33]


func boss_title() -> String:
	return "THE STORM MATRIARCH"


func boss_status() -> String:
	if exposed:
		return "BECALMED  x1.5 DAMAGE"
	match state:
		"run":
			return "RUNNING WITH THE WIND"
		"call_lanes", "channel":
			return "CALLING LIGHTNING"
	if phase == 3:
		return "RIDING THE CURRENT"
	return "SAILING THE STORM"


func _go(s: String, t: float) -> void:
	state = s
	state_time = t


func _side_toward(p: Vector2) -> float:
	var right := forward().rotated(PI / 2.0)
	return 1.0 if right.dot(p - position) > 0.0 else -1.0


func _wind_speed(base: float) -> float:
	var d: float = forward().dot(run.wind.dir())
	return base * (1.0 + 0.45 * maxf(0.0, d) * float(run.wind.strength))


func _think(dt: float) -> void:
	state_time -= dt
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	if phase == 1 and hull <= max_hull * 0.66:
		phase = 2
		exposed = false
		run.on_boss_phase(self)
		run.hazards.add_storm(position + forward() * 200.0)
		_go("call_lanes", 0.6)
		return
	if phase == 2 and hull <= max_hull * 0.33:
		phase = 3
		exposed = false
		run.on_boss_phase(self)
		current_ref = run.hazards.add_moving_current(run.arena.size * 0.5, run.wind.dir())
		_go("call_lanes", 0.8)
		return
	match state:
		"approach":
			steer_to_point(run.arena.size * 0.5, _wind_speed(speed), dt)
			if state_time <= 0.0 or position.distance_to(run.arena.size * 0.5) < 420.0:
				_next()
		"aim":
			fire_side = _side_toward(tp)
			var radial := clampf((dist - 360.0) / 200.0, -1.0, 1.0)
			var ang := to.angle() - fire_side * PI / 2.0 + fire_side * radial * 0.55
			steer_to_angle(ang, _wind_speed(speed), dt)
			var side_vec := forward().rotated(PI / 2.0) * fire_side
			if (dist > 1.0 and side_vec.dot(to / dist) > 0.88 and dist < float(data["range"])) or state_time <= 0.0:
				_go("windup", 0.75 if phase < 3 else 0.9)
				Sound.play("warning", position, -4.0, 1.1)
		"windup":
			steer_to_angle(rotation, speed * 0.4, dt)
			if state_time <= 0.0:
				_volley(fire_side)
				if both_sides:
					_volley(-fire_side)
				volleys += 1
				if phase == 3:
					exposed = true
					_go("recover", 3.0)
				else:
					_go("recover", 0.9)
		"run":
			steer_to_angle(run.wind.dir().angle(), _wind_speed(speed * 1.6), dt)
			if state_time <= 0.0:
				_next()
		"call_lanes":
			steer_to_angle(rotation, speed * 0.3, dt)
			if state_time <= 0.0:
				_lanes(tp)
				_go("channel", 2.2)
		"channel":
			steer_to_angle(rotation, speed * 0.2, dt)
			if state_time <= 0.0:
				exposed = true
				_go("recover", 3.2 if phase == 3 else 2.2)
		"recover":
			steer_to_angle(rotation, speed * 0.2, dt)
			if state_time <= 0.0:
				exposed = false
				_next()
		"reposition":
			steer_to_point(reposition_target, _wind_speed(speed * 1.2), dt)
			if state_time <= 0.0 or position.distance_to(reposition_target) < 90.0:
				_next()


func _next() -> void:
	cycle += 1
	var pattern: Array
	match phase:
		1:
			pattern = ["aim", "aim", "gust", "aim", "reposition"]
		2:
			pattern = ["lanes", "aim", "aim", "gust", "lanes", "reposition"]
		_:
			pattern = ["lanes", "barrage", "reposition", "lanes", "aim"]
	var s: String = pattern[cycle % pattern.size()]
	both_sides = false
	match s:
		"aim":
			_go("aim", 3.5)
		"barrage":
			both_sides = true
			_go("aim", 3.5)
		"gust":
			run.wind.force_shift()
			run.banner("THE MATRIARCH CALLS THE WIND", "The wind is turning - she will run with it", Color(0.75, 0.85, 1.0))
			Sound.play("wind", position, 0.0, 0.8)
			_go("run", 4.0)
		"lanes":
			_go("call_lanes", 1.0)
			Sound.play("boss", position, -6.0, 1.5)
		"reposition":
			reposition_target = _pick_point()
			_go("reposition", 3.5)


func _lanes(tp: Vector2) -> void:
	var dir: Vector2 = run.wind.dir().rotated(PI / 2.0) if run.rng.randf() < 0.5 else run.wind.dir()
	run.hazards.lane_strike(tp, dir, float(data["strike_damage"]), true, 1.7 if phase < 3 else 1.5)
	if phase == 3:
		run.hazards.lane_strike(tp, dir.rotated(PI / 2.0), float(data["strike_damage"]), true, 3.6)


func _pick_point() -> Vector2:
	var size: Vector2 = run.arena.size
	for i in 20:
		var pt := Vector2(run.rng.randf_range(size.x * 0.2, size.x * 0.8), run.rng.randf_range(size.y * 0.2, size.y * 0.8))
		if run.arena.is_clear(pt, radius + 40.0) and pt.distance_to(position) > 320.0:
			return pt
	return size * 0.5


func _volley(side: float) -> void:
	var fwd := forward()
	var side_vec := fwd.rotated(PI / 2.0) * side
	var n := OFFSETS.size()
	for i in n:
		var x: float = OFFSETS[i]
		var origin := position + fwd * x + side_vec * radius * 0.7
		var ang := lerpf(0.1, -0.1, float(i) / float(n - 1)) * side
		fire_shot(origin, side_vec.rotated(ang), 470.0, float(data["damage"]), float(data["range"]) + 60.0, 6.0)
		run.fx_over.burst(origin, 3, 90.0, Color(0.8, 0.9, 1.0), 0.3, 3.0, side_vec, 0.6)
	Sound.play("enemy_cannon", position, 0.0, 0.9)
	run.add_shake(5.0)


func on_contact(f, rel: float) -> void:
	if f == run.player:
		var p: PlayerShip = run.player
		p.ram(self, maxf(rel, 120.0), float(data["contact"]))
	else:
		f.take_damage(float(data["contact"]) * 0.1, "Ramming", position)


func _draw_ship() -> void:
	if state == "windup":
		var total := 0.75 if phase < 3 else 0.9
		var prog := 1.0 - clampf(state_time / total, 0.0, 1.0)
		draw_side_lanes(fire_side, OFFSETS, float(data["range"]), prog, 0.1)
		if both_sides:
			draw_side_lanes(-fire_side, OFFSETS, float(data["range"]), prog, 0.1)
	var outline := Color(0.7, 0.8, 1.0)
	if exposed:
		var pulse := 0.5 + 0.5 * sin(age * 10.0)
		outline = Color(0.4, 1.0, 0.95).lerp(Color.WHITE, pulse * 0.4)
		draw_circle(Vector2.ZERO, radius + 18.0, Color(0.3, 0.95, 1.0, 0.07 + 0.05 * pulse))
	if state == "call_lanes" or state == "channel":
		var cp := 0.5 + 0.5 * sin(age * 18.0)
		draw_circle(Vector2.ZERO, radius + 26.0, Color(0.85, 0.9, 1.0, 0.06 + 0.08 * cp))
		for k in 6:
			var a0 := TAU * float(k) / 6.0 + age * 3.0
			var p0 := Vector2.RIGHT.rotated(a0) * (radius + 8.0)
			var p1 := Vector2.RIGHT.rotated(a0 + 0.2) * (radius + 26.0)
			draw_line(p0, p1, Color(1.0, 1.0, 0.8, 0.7), 2.0)
	draw_hull(104.0, 34.0, Color(0.08, 0.10, 0.16), outline)
	draw_colored_polygon(hull_points(78.0, 22.0), Color(0.12, 0.15, 0.24))
	for side in [-1.0, 1.0]:
		for x in OFFSETS:
			var lit: bool = state == "windup" and (side == fire_side or both_sides)
			draw_rect(Rect2(Vector2(float(x) - 2.5, side * 15.0 - 2.0), Vector2(5, 4)), Color(1.0, 0.4, 0.3) if lit else Color(0.6, 0.65, 0.8))
	for mx in [28.0, 0.0, -26.0]:
		var sail := 1.0 + 0.3 * float(run.wind.strength)
		var wd: Vector2 = run.wind.dir().rotated(-rotation)
		draw_line(Vector2(mx, -22.0 * sail), Vector2(mx, 22.0 * sail), Color(0.75, 0.85, 1.0, 0.75), 3.0)
		draw_arc(Vector2(mx, 0) + wd * 4.0, 20.0 * sail, wd.angle() - 1.1, wd.angle() + 1.1, 10, Color(0.8, 0.9, 1.0, 0.5), 2.0)
		draw_circle(Vector2(mx, 0), 5.0, Color(0.85, 0.9, 1.0))


func _draw_overlay() -> void:
	if exposed:
		draw_string_outline(font, Vector2(-90, -radius - 30.0), "BECALMED", HORIZONTAL_ALIGNMENT_CENTER, 180.0, 20, 5, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(-90, -radius - 30.0), "BECALMED", HORIZONTAL_ALIGNMENT_CENTER, 180.0, 20, Color(0.4, 1.0, 0.95))

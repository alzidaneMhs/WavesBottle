class_name Sovereign
extends Enemy

const OFFSETS := [-48.0, -32.0, -16.0, 0.0, 16.0, 32.0, 48.0]

var state := "approach"
var state_time := 5.0
var phase := 1
var cycle := -1
var fire_side := 1.0
var both := false
var aim := Vector2.RIGHT
var anchors: Array = []
var reposition_target := Vector2.ZERO


func _on_setup() -> void:
	boss = true
	side_gunned = true


func phase_marks() -> Array:
	return [0.7, 0.4, 0.15]


func boss_title() -> String:
	return "THE RESONANT SOVEREIGN"


func boss_status() -> String:
	if exposed:
		return "OPEN  x1.5" + ("  WAKE x%.1f" % _wake_mult() if phase == 4 else "")
	match phase:
		2:
			return "DISTORTION: 2x WAKE, +30% DAMAGE"
		3:
			var n := _count(anchors)
			if n > 0:
				return "ANCHORED - DESTROY %d ANCHOR%s" % [n, "" if n == 1 else "S"]
			return "ANCHORS BROKEN"
		4:
			return "THE DUEL - WAKE x%.1f DAMAGE" % _wake_mult()
	return "THE SEA REMEMBERS"


func _wake_mult() -> float:
	return 1.0 + 0.1 * float(run.wake.tier)


func _count(list: Array) -> int:
	var n := 0
	for e in list:
		if is_instance_valid(e) and e.alive:
			n += 1
	return n


func _go(s: String, t: float) -> void:
	state = s
	state_time = t


func _side_toward(p: Vector2) -> float:
	var right := forward().rotated(PI / 2.0)
	return 1.0 if right.dot(p - position) > 0.0 else -1.0


func _think(dt: float) -> void:
	state_time -= dt
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	if phase == 1 and hull <= max_hull * 0.7:
		phase = 2
		exposed = false
		run.on_boss_phase(self)
		run.hazards.add_rift(position + Vector2(380, 0))
		run.hazards.add_rift(position - Vector2(380, 0))
		_go("recover", 1.0)
		return
	if phase == 2 and hull <= max_hull * 0.4:
		phase = 3
		exposed = false
		run.distortion = {}
		run.on_boss_phase(self)
		_spawn_anchors()
		_go("focus", 2.0)
		return
	if phase == 3 and hull <= max_hull * 0.15:
		phase = 4
		exposed = false
		for a in anchors:
			if is_instance_valid(a) and a.alive:
				a.die()
		run.on_boss_phase(self)
		_go("reposition", 3.0)
		reposition_target = run.arena.size * 0.5
		return
	if phase == 2:
		run.distortion = {"pos": position, "radius": 520.0}
	match state:
		"approach":
			steer_to_point(run.arena.size * 0.5, speed, dt)
			if state_time <= 0.0 or position.distance_to(run.arena.size * 0.5) < 400.0:
				_next()
		"aim":
			fire_side = _side_toward(tp)
			var radial := clampf((dist - 400.0) / 220.0, -1.0, 1.0)
			steer_to_angle(to.angle() - fire_side * PI / 2.0 + fire_side * radial * 0.5, speed, dt)
			var side_vec := forward().rotated(PI / 2.0) * fire_side
			if (dist > 1.0 and side_vec.dot(to / dist) > 0.9 and dist < float(data["range"])) or state_time <= 0.0:
				_go("windup", 0.9 if phase == 4 else 1.1)
				Sound.play("warning", position, -2.0, 0.6)
		"windup":
			steer_to_angle(rotation, speed * 0.3, dt)
			if state_time <= 0.0:
				_broadside(fire_side)
				if both or phase == 4:
					_broadside(-fire_side)
				if phase == 4:
					exposed = true
					_go("recover", 2.5)
				else:
					_go("recover", 1.3)
		"bow_aim":
			steer_to_angle(to.angle(), speed * 0.5, dt)
			if absf(wrapf(to.angle() - rotation, -PI, PI)) < 0.1 or state_time <= 0.0:
				_go("bow_windup", 1.3)
				Sound.play("boss", position, -4.0, 1.2)
		"bow_windup":
			steer_to_angle(rotation, 0.0, dt)
			if state_time <= 0.0:
				var fwd := forward()
				for k in [-1.0, 0.0, 1.0]:
					fire_shot(position + fwd * (radius + 6.0), fwd.rotated(float(k) * 0.07), 470.0, float(data["bow_damage"]), float(data["range"]) + 120.0, 8.0)
				Sound.play("cannon", position, 2.0, 0.55)
				run.add_shake(8.0)
				_go("recover", 1.2)
		"channel":
			steer_to_angle(rotation, speed * 0.2, dt)
			if state_time <= 0.0:
				exposed = true
				_go("recover", 2.0)
		"focus":
			steer_to_angle(to.angle(), speed * 0.3, dt)
			if state_time > 0.4:
				aim = (aim_point(t, 900.0) - position).normalized()
			if state_time <= 0.0:
				for k in [-1.0, 0.0, 1.0]:
					fire_shot(position + aim * radius, aim.rotated(float(k) * 0.12), 900.0, 12.0, 1000.0, 5.0)
				Sound.play("cannon", position, -2.0, 1.6)
				_go("recover", 0.9)
		"recover":
			steer_to_angle(rotation, speed * 0.25, dt)
			if state_time <= 0.0:
				exposed = false
				_next()
		"reposition":
			steer_to_point(reposition_target, speed * 1.3, dt)
			if state_time <= 0.0 or position.distance_to(reposition_target) < 90.0:
				_next()


func _next() -> void:
	cycle += 1
	var pattern: Array
	match phase:
		1:
			pattern = ["aim", "bow", "lanes", "aim", "vents", "mortars", "reposition"]
		2:
			pattern = ["lanes", "aim", "mortars", "bow", "vents", "both", "reposition"]
		3:
			pattern = ["focus", "focus", "aim", "focus", "lanes", "focus", "reposition"]
		_:
			pattern = ["aim", "aim", "focus"]
	var s: String = pattern[cycle % pattern.size()]
	both = false
	var t = target()
	var tp: Vector2 = t.position
	match s:
		"aim":
			_go("aim", 3.5)
		"both":
			both = true
			_go("aim", 3.5)
		"bow":
			_go("bow_aim", 2.5)
		"lanes":
			run.hazards.lane_strike(tp, Vector2.RIGHT.rotated(run.rng.randf() * TAU), 14.0, true, 1.7)
			_go("channel", 1.9)
		"vents":
			var dir := (tp - position).normalized()
			for i in 6:
				run.hazards.add_vent_burst(position + dir * (radius + 90.0 + float(i) * 115.0), 1.4 + float(i) * 0.2)
			_go("channel", 1.6)
		"mortars":
			var tv: Vector2 = t.velocity
			run.shots.add_mortar(tp + tv * 0.9, 1.6, 70.0, 15.0, "Sovereign shell")
			for i in 5:
				run.shots.add_mortar(tp + Vector2.RIGHT.rotated(run.rng.randf() * TAU) * run.rng.randf_range(100.0, 300.0), 1.6 + float(i) * 0.08, 70.0, 15.0, "Sovereign shell")
			Sound.play("boss", position, -6.0, 1.4)
			_go("recover", 1.6)
		"focus":
			aim = (tp - position).normalized()
			_go("focus", 1.6)
			Sound.play("warning", position, -6.0, 1.6)
		"reposition":
			reposition_target = _pick_point()
			_go("reposition", 3.5)


func _spawn_anchors() -> void:
	anchors.clear()
	var size: Vector2 = run.arena.size
	var spots := [Vector2(0.2, 0.25), Vector2(0.8, 0.25), Vector2(0.5, 0.82)]
	for sp in spots:
		var p := Vector2(size.x * float(sp.x), size.y * float(sp.y))
		for i in 8:
			if run.arena.is_clear(p, 60.0):
				break
			p += Vector2(run.rng.randf_range(-120, 120), run.rng.randf_range(-120, 120))
		run.fx_over.spawn_cue(p, true)
		var a = run.spawn_enemy("resonance_anchor", p, [])
		if a != null:
			a.summon = false
			a.shielding = self
			anchors.append(a)


func _pick_point() -> Vector2:
	var size: Vector2 = run.arena.size
	for i in 20:
		var pt := Vector2(run.rng.randf_range(size.x * 0.25, size.x * 0.75), run.rng.randf_range(size.y * 0.25, size.y * 0.75))
		if run.arena.is_clear(pt, radius + 40.0) and pt.distance_to(position) > 300.0:
			return pt
	return size * 0.5


func damage_factor(_origin: Vector2) -> float:
	if phase == 3 and _count(anchors) > 0:
		run.fx_over.text(position + Vector2(0, -radius - 20.0), "ANCHORED", Color(1.0, 0.6, 0.9), 13, 0.4)
		return 0.1
	if phase == 4:
		return _wake_mult()
	return 1.0


func _broadside(side: float) -> void:
	var fwd := forward()
	var side_vec := fwd.rotated(PI / 2.0) * side
	var n := OFFSETS.size()
	for i in n:
		var x: float = OFFSETS[i]
		var origin := position + fwd * x + side_vec * radius * 0.8
		var ang := lerpf(0.1, -0.1, float(i) / float(n - 1)) * side
		fire_shot(origin, side_vec.rotated(ang), 430.0, float(data["damage"]), float(data["range"]) + 60.0, 7.0)
		run.fx_over.burst(origin, 3, 90.0, Color(1.0, 0.6, 0.9), 0.35, 4.0, side_vec, 0.6)
	Sound.play("enemy_cannon", position, 2.0, 0.6)
	run.add_shake(7.0)


func on_contact(f, rel: float) -> void:
	if f == run.player:
		var p: PlayerShip = run.player
		p.ram(self, maxf(rel, 130.0), float(data["contact"]))
	else:
		f.take_damage(float(data["contact"]) * 0.1, "Ramming", position)


func die() -> void:
	run.distortion = {}
	super.die()


func _draw_ship() -> void:
	if state == "windup":
		var prog := 1.0 - clampf(state_time / (0.9 if phase == 4 else 1.1), 0.0, 1.0)
		draw_side_lanes(fire_side, OFFSETS, float(data["range"]), prog, 0.1)
		if both or phase == 4:
			draw_side_lanes(-fire_side, OFFSETS, float(data["range"]), prog, 0.1)
	if state == "bow_aim" or state == "bow_windup":
		var bp := 0.0 if state == "bow_aim" else 1.0 - clampf(state_time / 1.3, 0.0, 1.0)
		draw_forward_lane(float(data["range"]) + 120.0, 40.0, bp)
	if state == "focus":
		var la := aim.rotated(-rotation)
		var locked := state_time <= 0.4
		for k in [-1.0, 0.0, 1.0]:
			var d := la.rotated(float(k) * 0.12)
			draw_line(d * radius, d * 1000.0, Color(GameData.COL_WARN, 0.85 if locked else 0.3), 3.0 if locked else 1.2)
	if phase == 2:
		var rp := fposmod(age * 0.5, 1.0)
		draw_arc(Vector2.ZERO, 520.0 * rp, 0.0, TAU, 64, Color(1.0, 0.5, 0.85, 0.25 * (1.0 - rp)), 2.0, true)
		draw_arc(Vector2.ZERO, 520.0, 0.0, TAU, 64, Color(1.0, 0.5, 0.85, 0.3), 2.0, true)
	var outline := Color(1.0, 0.55, 0.85)
	if exposed:
		var pulse := 0.5 + 0.5 * sin(age * 10.0)
		outline = Color(0.4, 1.0, 0.95).lerp(Color.WHITE, pulse * 0.4)
		draw_circle(Vector2.ZERO, radius + 20.0, Color(0.3, 0.95, 1.0, 0.07 + 0.05 * pulse))
	draw_hull(150.0, 56.0, Color(0.10, 0.05, 0.12), outline)
	draw_colored_polygon(hull_points(112.0, 36.0), Color(0.16, 0.07, 0.18))
	for side in [-1.0, 1.0]:
		for x in OFFSETS:
			var lit: bool = state == "windup" and (side == fire_side or both or phase == 4)
			draw_rect(Rect2(Vector2(float(x) - 3.0, side * 25.0 - 2.5), Vector2(6, 5)), Color(1.0, 0.4, 0.4) if lit else Color(0.75, 0.5, 0.75))
	var g := 0.5 + 0.5 * sin(age * 2.5)
	for k in 3:
		var cx := -40.0 + float(k) * 40.0
		draw_arc(Vector2(cx, 0), 10.0, age + float(k), age + float(k) + 4.5, 14, Color(1.0, 0.6, 0.9, 0.5 + 0.4 * g), 2.5)
		draw_circle(Vector2(cx, 0), 4.0, Color(1.0, 0.8, 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(68, -12), Vector2(86, 0), Vector2(68, 12)]), Color(1.0, 0.7, 0.9, 0.8))


func _draw_overlay() -> void:
	if exposed:
		draw_string_outline(font, Vector2(-90, -radius - 34.0), "OPEN", HORIZONTAL_ALIGNMENT_CENTER, 180.0, 22, 5, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(-90, -radius - 34.0), "OPEN", HORIZONTAL_ALIGNMENT_CENTER, 180.0, 22, Color(0.4, 1.0, 0.95))

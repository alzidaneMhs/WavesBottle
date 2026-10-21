class_name Ironwake
extends Enemy

const OFFSETS := [-36.0, -24.0, -12.0, 0.0, 12.0, 24.0, 36.0]

var state := "approach"
var state_time := 5.0
var phase := 1
var cycle := -1
var fire_side := 1.0
var plate_side := 0.0
var plate_timer := 0.0
var plate_shift := 0.0
var ram_dir := Vector2.RIGHT
var ram_hits: Array = []
var reposition_target := Vector2.ZERO


func _on_setup() -> void:
	boss = true
	side_gunned = true


func boss_title() -> String:
	return "THE IRONWAKE"


func boss_status() -> String:
	if exposed:
		return "EXPOSED  x1.5 DAMAGE"
	if phase == 2:
		return "PLATES SHIFTING" if plate_shift > 0.0 else "PLATED SIDE: %s" % ("STARBOARD" if plate_side > 0.0 else "PORT")
	if phase == 3:
		return "RAMMING SPEED"
	return ""


func phase_marks() -> Array:
	return [0.66, 0.33]


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
	var center: Vector2 = run.arena.size * 0.5
	if phase == 1 and hull <= max_hull * 0.66:
		phase = 2
		exposed = false
		plate_side = _side_toward(tp)
		plate_timer = 7.0
		run.on_boss_phase(self)
		_go("aim", 4.0)
		return
	if phase == 2 and hull <= max_hull * 0.33:
		phase = 3
		exposed = false
		plate_side = 0.0
		run.on_boss_phase(self)
		_go("ram_aim", 2.0)
		return
	if phase == 2:
		if plate_shift > 0.0:
			plate_shift -= dt
			if plate_shift <= 0.0:
				plate_side = _side_toward(tp)
				Sound.play("impact", position, 0.0, 0.5)
		else:
			plate_timer -= dt
			if plate_timer <= 0.0:
				plate_shift = 1.4
				plate_timer = 7.0
				Sound.play("warning", position, -6.0, 0.6)
	match state:
		"approach":
			steer_to_point(center, speed, dt)
			if state_time <= 0.0 or position.distance_to(center) < 350.0:
				_next()
		"aim":
			if phase == 2 and plate_side != 0.0 and plate_shift <= 0.0:
				fire_side = plate_side
			else:
				fire_side = _side_toward(tp)
			var radial := clampf((dist - 400.0) / 220.0, -1.0, 1.0)
			var ang := to.angle() - fire_side * PI / 2.0 + fire_side * radial * 0.5
			steer_to_angle(ang, speed, dt)
			var side_vec := forward().rotated(PI / 2.0) * fire_side
			if (dist > 1.0 and side_vec.dot(to / dist) > 0.93 and dist < float(data["range"])) or state_time <= 0.0:
				_go("windup", 1.3 if phase == 1 else 1.1)
				Sound.play("warning", position, -2.0, 0.7)
		"windup":
			steer_to_angle(rotation, speed * 0.3, dt)
			if state_time <= 0.0:
				_broadside()
				exposed = true
				_go("recover", 2.0)
		"recover":
			steer_to_angle(rotation, speed * 0.2, dt)
			if state_time <= 0.0:
				exposed = false
				_next()
		"ram_aim":
			steer_to_angle(to.angle(), speed * 0.6, dt)
			if absf(wrapf(to.angle() - rotation, -PI, PI)) < 0.08 or state_time <= 0.0:
				ram_dir = forward()
				_go("ram_windup", 1.4)
				Sound.play("boss", position, -2.0, 1.2)
		"ram_windup":
			steer_to_angle(rotation, 0.0, dt)
			if state_time <= 0.0:
				ram_hits.clear()
				_go("ram", 1.9)
		"ram":
			velocity = ram_dir * float(data["ram_speed"]) * slow_factor()
			position += velocity * dt
			run.fx_under.burst(position - ram_dir * radius, 2, 60.0, Color(0.8, 0.85, 1.0, 0.7), 0.5, 4.0)
			for f in run.friendlies:
				if not f.alive or not f.physical or ram_hits.has(f):
					continue
				if position.distance_to(f.position) <= radius + float(f.radius) + 8.0:
					ram_hits.append(f)
					f.take_damage(float(data["ram_damage"]), "Ironwake ram", position)
					if f == run.player:
						run.player.velocity += ram_dir * 320.0
					run.add_shake(14.0)
			var ahead := position + ram_dir * (radius + 30.0)
			if state_time <= 0.0 or run.arena.point_blocked(ahead) or not run.arena.rect.grow(-40.0).has_point(ahead):
				exposed = true
				run.add_shake(10.0)
				_go("ram_recover", 3.2)
		"ram_recover":
			velocity *= exp(-2.5 * dt)
			position += velocity * dt
			if state_time <= 0.0:
				exposed = false
				_next()
		"reposition":
			steer_to_point(reposition_target, speed * 1.4, dt)
			if state_time <= 0.0 or position.distance_to(reposition_target) < 80.0:
				_next()


func _next() -> void:
	cycle += 1
	var pattern: Array
	match phase:
		1:
			pattern = ["aim", "aim", "reposition"]
		2:
			pattern = ["aim", "aim", "reposition"]
		_:
			pattern = ["ram_aim", "aim", "ram_aim", "reposition"]
	var s: String = pattern[cycle % pattern.size()]
	match s:
		"aim":
			_go("aim", 4.5)
		"ram_aim":
			_go("ram_aim", 2.5)
		"reposition":
			reposition_target = _pick_point()
			_go("reposition", 3.5)


func _pick_point() -> Vector2:
	var size: Vector2 = run.arena.size
	for i in 20:
		var pt := Vector2(run.rng.randf_range(size.x * 0.25, size.x * 0.75), run.rng.randf_range(size.y * 0.25, size.y * 0.75))
		if run.arena.is_clear(pt, radius + 40.0) and pt.distance_to(position) > 300.0:
			return pt
	return size * 0.5


func damage_factor(origin: Vector2) -> float:
	if phase == 2 and plate_side != 0.0 and plate_shift <= 0.0:
		if _side_toward(origin) == plate_side:
			run.fx_over.text(position + Vector2(0, -radius - 20.0), "PLATED", Color(0.75, 0.8, 0.85), 13, 0.4)
			return 0.15
	return 1.0


func _broadside() -> void:
	var fwd := forward()
	var side_vec := fwd.rotated(PI / 2.0) * fire_side
	var n := OFFSETS.size()
	for i in n:
		var x: float = OFFSETS[i]
		var origin := position + fwd * x + side_vec * radius * 0.8
		var ang := lerpf(0.1, -0.1, float(i) / float(n - 1)) * fire_side
		fire_shot(origin, side_vec.rotated(ang), 400.0, float(data["damage"]), float(data["range"]) + 60.0, 7.0)
		run.fx_over.burst(origin, 3, 90.0, Color(1.0, 0.7, 0.4), 0.35, 4.0, side_vec, 0.6)
	Sound.play("enemy_cannon", position, 2.0, 0.7)
	Sound.play("cannon", position, -2.0, 0.8)
	run.add_shake(8.0)


func on_contact(f, rel: float) -> void:
	if state == "ram":
		return
	if f == run.player:
		var p: PlayerShip = run.player
		p.ram(self, maxf(rel, 120.0), float(data["contact"]))
	else:
		f.take_damage(float(data["contact"]) * 0.1, "Ramming", position)


func _draw_ship() -> void:
	if state == "windup":
		var prog := 1.0 - clampf(state_time / (1.3 if phase == 1 else 1.1), 0.0, 1.0)
		draw_side_lanes(fire_side, OFFSETS, float(data["range"]), prog, 0.1)
	if state == "ram_windup" or state == "ram_aim":
		var rprog := 0.0 if state == "ram_aim" else 1.0 - clampf(state_time / 1.4, 0.0, 1.0)
		draw_forward_lane(float(data["ram_speed"]) * 1.9, radius * 0.95, rprog)
	var outline := Color(0.6, 0.75, 0.9)
	if exposed:
		var pulse := 0.5 + 0.5 * sin(age * 10.0)
		outline = Color(0.4, 1.0, 0.95).lerp(Color.WHITE, pulse * 0.4)
		draw_circle(Vector2.ZERO, radius + 18.0, Color(0.3, 0.95, 1.0, 0.07 + 0.05 * pulse))
	draw_hull(116.0, 44.0, Color(0.11, 0.12, 0.15), outline)
	draw_colored_polygon(hull_points(88.0, 28.0), Color(0.17, 0.18, 0.22))
	draw_colored_polygon(PackedVector2Array([Vector2(56, -10), Vector2(76, 0), Vector2(56, 10)]), Color(0.75, 0.8, 0.85))
	for side in [-1.0, 1.0]:
		for x in OFFSETS:
			var lit: bool = state == "windup" and side == fire_side
			draw_rect(Rect2(Vector2(float(x) - 3.0, side * 20.0 - 2.5), Vector2(6, 5)), Color(1.0, 0.35, 0.25) if lit else Color(0.6, 0.55, 0.5))
	if phase == 2:
		var sides: Array = [plate_side] if plate_shift <= 0.0 else [-1.0, 1.0]
		for ps in sides:
			if float(ps) == 0.0:
				continue
			var a := 1.0 if plate_shift <= 0.0 else 0.4 + 0.4 * sin(age * 16.0)
			draw_line(Vector2(-46, float(ps) * 27.0), Vector2(30, float(ps) * 27.0), Color(0.8, 0.85, 0.95, a), 7.0)
	for mx in [26.0, 0.0, -26.0]:
		draw_circle(Vector2(mx, 0), 6.0, Color(0.8, 0.85, 0.9))
		draw_line(Vector2(mx, -18), Vector2(mx, 18), Color(0.7, 0.75, 0.85, 0.6), 3.0)


func _draw_overlay() -> void:
	if exposed:
		var txt := "EXPOSED"
		draw_string_outline(font, Vector2(-80, -radius - 30.0), txt, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 20, 5, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(-80, -radius - 30.0), txt, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 20, Color(0.4, 1.0, 0.95))

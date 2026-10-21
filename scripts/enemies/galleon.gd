class_name Galleon
extends Enemy

const OFFSETS_1 := [-42.0, -28.0, -14.0, 0.0, 14.0, 28.0, 42.0]
const OFFSETS_2 := [-44.0, -33.0, -22.0, -11.0, 0.0, 11.0, 22.0, 33.0, 44.0]

var state := "approach"
var state_time := 4.0
var phase := 1
var cycle_index := -1
var fire_side := 1.0
var volleys := 0
var reposition_target := Vector2.ZERO


func _on_setup() -> void:
	boss = true
	side_gunned = true
	_set_state("approach", 5.0)


func _set_state(s: String, t: float) -> void:
	state = s
	state_time = t


func offsets() -> Array:
	return OFFSETS_1 if phase == 1 else OFFSETS_2


func _think(dt: float) -> void:
	state_time -= dt
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	var center: Vector2 = run.arena.size * 0.5
	if phase == 1 and hull <= max_hull * 0.5:
		phase = 2
		exposed = false
		run.on_boss_phase(self)
		reposition_target = _pick_point()
		_set_state("reposition", 2.5)
		return
	match state:
		"approach":
			steer_to_point(center, speed, dt)
			if state_time <= 0.0 or position.distance_to(center) < 350.0:
				_next_attack()
		"aim":
			var right := forward().rotated(PI / 2.0)
			fire_side = 1.0 if right.dot(to) > 0.0 else -1.0
			var radial := clampf((dist - 380.0) / 220.0, -1.0, 1.0)
			var ang := to.angle() - fire_side * PI / 2.0 + fire_side * radial * 0.5
			steer_to_angle(ang, speed, dt)
			var side_vec := right * fire_side
			var aligned := dist > 1.0 and side_vec.dot(to / dist) > 0.93 and dist < float(data["range"])
			if aligned or state_time <= 0.0:
				_set_state("windup", 1.2 if phase == 1 else 1.0)
				Sound.play("warning", position, -2.0, 0.8)
		"windup":
			steer_to_angle(rotation, speed * 0.3, dt)
			if state_time <= 0.0:
				_broadside()
				volleys += 1
				if phase == 2 and volleys < 2:
					_set_state("windup", 0.7)
				else:
					exposed = true
					_set_state("recover", 2.2)
		"mortar":
			steer_to_angle(rotation, speed * 0.4, dt)
			if state_time <= 0.0:
				exposed = true
				_set_state("recover", 1.6)
		"recover":
			steer_to_angle(rotation, speed * 0.2, dt)
			if state_time <= 0.0:
				exposed = false
				_next_attack()
		"reposition":
			steer_to_point(reposition_target, speed * 1.4, dt)
			if state_time <= 0.0 or position.distance_to(reposition_target) < 80.0:
				_next_attack()


func _next_attack() -> void:
	cycle_index += 1
	var pattern := ["aim", "mortar", "reposition"] if phase == 1 else ["aim", "mortar", "aim", "reposition"]
	var s: String = pattern[cycle_index % pattern.size()]
	match s:
		"aim":
			volleys = 0
			_set_state("aim", 4.5)
		"mortar":
			_launch_mortars()
			_set_state("mortar", 1.9)
		"reposition":
			reposition_target = _pick_point()
			_set_state("reposition", 3.5)


func _pick_point() -> Vector2:
	var size: Vector2 = run.arena.size
	for i in 20:
		var pt := Vector2(run.rng.randf_range(size.x * 0.2, size.x * 0.8), run.rng.randf_range(size.y * 0.2, size.y * 0.8))
		if run.arena.is_clear(pt, radius + 40.0) and pt.distance_to(position) > 300.0:
			return pt
	return size * 0.5


func _launch_mortars() -> void:
	var t = target()
	var tp: Vector2 = t.position
	var tv: Vector2 = t.velocity
	var count := 5 if phase == 1 else 8
	run.shots.add_mortar(tp + tv * 0.9, 1.5, 70.0, 16.0)
	for i in range(1, count):
		var off: Vector2 = Vector2.RIGHT.rotated(run.rng.randf() * TAU) * run.rng.randf_range(90.0, 280.0)
		run.shots.add_mortar(tp + off, 1.5 + float(i) * 0.08, 70.0, 16.0)
	Sound.play("boss", position, -6.0, 1.4)
	run.fx_over.burst(position, 10, 90.0, Color(1.0, 0.7, 0.4), 0.5, 4.0, Vector2.UP, 1.0)


func _broadside() -> void:
	var fwd := forward()
	var side_vec := fwd.rotated(PI / 2.0) * fire_side
	var offs := offsets()
	var fan := 0.12 if phase == 1 else 0.18
	var n := offs.size()
	for i in n:
		var x: float = offs[i]
		var origin := position + fwd * x + side_vec * radius * 0.8
		var ang := lerpf(fan, -fan, float(i) / float(n - 1)) * fire_side
		if volleys == 1:
			ang += 0.05 * fire_side
		var dir := side_vec.rotated(ang)
		fire_shot(origin, dir, 400.0, float(data["damage"]), float(data["range"]) + 60.0, 7.0)
		run.fx_over.burst(origin, 3, 90.0, Color(1.0, 0.7, 0.4), 0.35, 4.0, side_vec, 0.6)
	Sound.play("enemy_cannon", position, 2.0, 0.7)
	Sound.play("cannon", position, -2.0, 0.8)
	run.add_shake(8.0)


func on_contact(f, rel: float) -> void:
	if f == run.player:
		var p: PlayerShip = run.player
		p.ram(self, maxf(rel, 120.0), float(data["contact"]))
	else:
		f.take_damage(float(data["contact"]) * 0.1, "Ramming", position)


func _draw_ship() -> void:
	if state == "windup":
		var total := 1.2 if phase == 1 else 1.0
		if volleys > 0:
			total = 0.7
		var prog := 1.0 - clampf(state_time / total, 0.0, 1.0)
		var fan := 0.12 if phase == 1 else 0.18
		draw_side_lanes(fire_side, offsets(), float(data["range"]), prog, fan)
	var outline := Color(1.0, 0.62, 0.3)
	if exposed:
		var pulse := 0.5 + 0.5 * sin(age * 10.0)
		outline = Color(0.4, 1.0, 0.95).lerp(Color.WHITE, pulse * 0.4)
		draw_circle(Vector2.ZERO, radius + 18.0, Color(0.3, 0.95, 1.0, 0.07 + 0.05 * pulse))
	draw_hull(124.0, 46.0, Color(0.14, 0.06, 0.06), outline)
	var pts := hull_points(96.0, 30.0)
	draw_colored_polygon(pts, Color(0.22, 0.10, 0.08))
	for side in [-1.0, 1.0]:
		for x in offsets():
			var lit: bool = state == "windup" and side == fire_side
			var c := Color(1.0, 0.35, 0.25) if lit else Color(0.7, 0.45, 0.3)
			draw_rect(Rect2(Vector2(float(x) - 3.0, side * 21.0 - 2.5), Vector2(6, 5)), c)
	for mx in [30.0, 0.0, -30.0]:
		draw_circle(Vector2(mx, 0), 6.0, Color(0.95, 0.8, 0.6))
		draw_line(Vector2(mx, -20), Vector2(mx, 20), Color(0.95, 0.75, 0.55, 0.6), 3.0)
	if phase == 2:
		draw_circle(Vector2(-44, 0), 5.0, Color(1.0, 0.4, 0.2, 0.6 + 0.3 * sin(age * 8.0)))


func _draw_overlay() -> void:
	if exposed:
		var txt := "EXPOSED"
		draw_string_outline(font, Vector2(-80, -radius - 30.0), txt, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 20, 5, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(-80, -radius - 30.0), txt, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 20, Color(0.4, 1.0, 0.95))

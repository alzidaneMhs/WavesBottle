class_name Kharon
extends Enemy

const OFFSETS := [-42.0, -28.0, -14.0, 0.0, 14.0, 28.0, 42.0]

var state := "approach"
var state_time := 5.0
var phase := 1
var cycle := -1
var fire_side := 1.0
var screen_spawned := false
var supports: Array = []
var platforms: Array = []
var sealed := false
var open_timer := 0.0
var reseal_timer := 0.0
var deploy_points: Array = []
var reposition_target := Vector2.ZERO


func _on_setup() -> void:
	boss = true
	side_gunned = true


func phase_marks() -> Array:
	return [0.66, 0.33]


func boss_title() -> String:
	return "DREADNOUGHT KHARON"


func boss_status() -> String:
	if phase == 3:
		if sealed:
			var n := _count(supports)
			if n > 0:
				return "SEALED - SINK %d SUPPORT BARGE%s" % [n, "" if n == 1 else "S"]
			return "SEALED - SUPPORT INBOUND"
		return "PLATES OPEN  x1.5  %ds" % int(ceil(open_timer))
	if shield_mult < 1.0:
		return "SCREENED BY SHIELD TENDERS"
	if exposed:
		return "EXPOSED  x1.5 DAMAGE"
	return "BOW ARMOR - STRIKE THE SIDES"


func _go(s: String, t: float) -> void:
	state = s
	state_time = t


func _count(list: Array) -> int:
	var n := 0
	for e in list:
		if is_instance_valid(e) and e.alive:
			n += 1
	return n


func _side_toward(p: Vector2) -> float:
	var right := forward().rotated(PI / 2.0)
	return 1.0 if right.dot(p - position) > 0.0 else -1.0


func _spawn_near(what: String, dist: float, ang: float) -> Enemy:
	var p := position + forward().rotated(ang) * dist
	var size: Vector2 = run.arena.size
	for i in 12:
		p.x = clampf(p.x, 140.0, size.x - 140.0)
		p.y = clampf(p.y, 140.0, size.y - 140.0)
		if run.arena.is_clear(p, 50.0):
			break
		p = position + forward().rotated(ang + run.rng.randf_range(-1.2, 1.2)) * dist
	run.fx_over.spawn_cue(p)
	return run.spawn_enemy(what, p, [])


func _spawn_supports() -> void:
	supports.clear()
	for a in [PI * 0.75, -PI * 0.75]:
		var e := _spawn_near("repair_barge", 260.0, a)
		if e != null:
			supports.append(e)
	if not supports.is_empty():
		run.banner("SUPPORT BARGES INBOUND", "Sink both barges to open Kharon's plates", GameData.COL_WARN)


func _think(dt: float) -> void:
	state_time -= dt
	if not screen_spawned:
		screen_spawned = true
		for a in [PI * 0.8, -PI * 0.8]:
			_spawn_near("shield_tender", 150.0, a)
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	if phase == 1 and hull <= max_hull * 0.66:
		phase = 2
		exposed = false
		run.on_boss_phase(self)
		_go("deploy_start", 0.5)
		return
	if phase == 2 and hull <= max_hull * 0.33:
		phase = 3
		exposed = false
		sealed = true
		run.on_boss_phase(self)
		_spawn_supports()
		_go("bow_aim", 2.5)
		return
	if phase == 3:
		if sealed:
			if reseal_timer > 0.0:
				reseal_timer -= dt
				if reseal_timer <= 0.0:
					_spawn_supports()
			elif _count(supports) == 0:
				sealed = false
				exposed = true
				open_timer = 9.0
				run.banner("KHARON: PLATES OPEN", "Hit it with everything for 9 seconds", Color(0.4, 1.0, 0.95))
				Sound.play("impact", position, 2.0, 0.5)
				run.add_shake(8.0)
		else:
			open_timer -= dt
			if open_timer <= 0.0:
				sealed = true
				exposed = false
				reseal_timer = 4.0
				Sound.play("warning", position, -2.0, 0.6)
	match state:
		"approach":
			steer_to_point(run.arena.size * 0.5, speed, dt)
			if state_time <= 0.0 or position.distance_to(run.arena.size * 0.5) < 380.0:
				_next()
		"aim":
			fire_side = _side_toward(tp)
			var radial := clampf((dist - 420.0) / 220.0, -1.0, 1.0)
			var ang := to.angle() - fire_side * PI / 2.0 + fire_side * radial * 0.5
			steer_to_angle(ang, speed, dt)
			var side_vec := forward().rotated(PI / 2.0) * fire_side
			if (dist > 1.0 and side_vec.dot(to / dist) > 0.92 and dist < float(data["range"])) or state_time <= 0.0:
				_go("windup", 1.3 if phase == 1 else 1.1)
				Sound.play("warning", position, -2.0, 0.65)
		"windup":
			steer_to_angle(rotation, speed * 0.3, dt)
			if state_time <= 0.0:
				_broadside()
				_go("recover", 1.6)
		"bow_aim":
			steer_to_angle(to.angle(), speed * 0.5, dt)
			if absf(wrapf(to.angle() - rotation, -PI, PI)) < 0.1 or state_time <= 0.0:
				_go("bow_windup", 1.4)
				Sound.play("boss", position, -4.0, 1.3)
		"bow_windup":
			steer_to_angle(rotation, 0.0, dt)
			if state_time <= 0.0:
				_bow_salvo()
				_go("recover", 1.4)
		"mortar":
			steer_to_angle(rotation, speed * 0.4, dt)
			if state_time <= 0.0:
				_go("recover", 1.0)
		"deploy_start":
			steer_to_angle(rotation, speed * 0.2, dt)
			if state_time <= 0.0:
				_begin_deploy()
		"deploy":
			steer_to_angle(rotation, 0.0, dt)
			if state_time <= 0.0:
				for p in deploy_points:
					var e = run.spawn_enemy("siege_platform", p, [])
					if e != null:
						platforms.append(e)
				deploy_points.clear()
				Sound.play("impact", position, -2.0, 0.6)
				_go("recover", 1.2)
		"recover":
			steer_to_angle(rotation, speed * 0.25, dt)
			if state_time <= 0.0:
				_next()
		"reposition":
			steer_to_point(reposition_target, speed * 1.4, dt)
			if state_time <= 0.0 or position.distance_to(reposition_target) < 90.0:
				_next()


func _next() -> void:
	cycle += 1
	var pattern: Array
	match phase:
		1:
			pattern = ["aim", "bow", "aim", "reposition"]
		2:
			pattern = ["aim", "mortar", "bow", "deploy", "reposition"]
		_:
			pattern = ["bow", "mortar", "aim", "deploy", "reposition"]
	var s: String = pattern[cycle % pattern.size()]
	match s:
		"aim":
			_go("aim", 4.5)
		"bow":
			_go("bow_aim", 2.5)
		"mortar":
			_launch_mortars()
			_go("mortar", 1.8)
		"deploy":
			_begin_deploy()
		"reposition":
			reposition_target = _pick_point()
			_go("reposition", 4.0)


func _begin_deploy() -> void:
	deploy_points.clear()
	var free := 2 - _count(platforms)
	if free <= 0:
		_go("aim", 4.5)
		return
	var right := forward().rotated(PI / 2.0)
	for side in [1.0, -1.0]:
		if deploy_points.size() >= free:
			break
		var p: Vector2 = position + right * float(side) * (radius + 80.0) - forward() * 30.0
		if run.arena.is_clear(p, 40.0):
			deploy_points.append(p)
	if deploy_points.is_empty():
		_go("aim", 4.5)
		return
	_go("deploy", 1.8)
	Sound.play("warning", position, -4.0, 0.55)


func _pick_point() -> Vector2:
	var size: Vector2 = run.arena.size
	for i in 20:
		var pt := Vector2(run.rng.randf_range(size.x * 0.25, size.x * 0.75), run.rng.randf_range(size.y * 0.25, size.y * 0.75))
		if run.arena.is_clear(pt, radius + 40.0) and pt.distance_to(position) > 300.0:
			return pt
	return size * 0.5


func damage_factor(origin: Vector2) -> float:
	if phase == 3 and sealed:
		run.fx_over.text(position + Vector2(0, -radius - 20.0), "SEALED", Color(0.75, 0.8, 0.85), 13, 0.4)
		return 0.12
	if exposed:
		return 1.0
	var to := origin - position
	if to.length() > 1.0 and forward().dot(to.normalized()) > 0.55:
		run.fx_over.text(position + forward() * radius + Vector2(0, -20.0), "BOW ARMOR", Color(0.75, 0.8, 0.85), 13, 0.4)
		return 0.3
	return 1.0


func _broadside() -> void:
	var fwd := forward()
	var side_vec := fwd.rotated(PI / 2.0) * fire_side
	var n := OFFSETS.size()
	for i in n:
		var x: float = OFFSETS[i]
		var origin := position + fwd * x + side_vec * radius * 0.8
		var ang := lerpf(0.12, -0.12, float(i) / float(n - 1)) * fire_side
		fire_shot(origin, side_vec.rotated(ang), 410.0, float(data["damage"]), float(data["range"]) + 60.0, 7.0)
		run.fx_over.burst(origin, 3, 90.0, Color(1.0, 0.7, 0.4), 0.35, 4.0, side_vec, 0.6)
	Sound.play("enemy_cannon", position, 2.0, 0.65)
	Sound.play("cannon", position, -2.0, 0.75)
	run.add_shake(8.0)


func _bow_salvo() -> void:
	var fwd := forward()
	for k in [-1.0, 0.0, 1.0]:
		var origin := position + fwd * (radius + 6.0) + fwd.rotated(PI / 2.0) * float(k) * 14.0
		fire_shot(origin, fwd.rotated(float(k) * 0.07), 470.0, float(data["bow_damage"]), float(data["range"]) + 120.0, 8.0)
	run.fx_over.burst(position + fwd * (radius + 10.0), 10, 160.0, Color(1.0, 0.75, 0.45), 0.4, 5.0, fwd, 0.5)
	Sound.play("cannon", position, 2.0, 0.55)
	run.add_shake(10.0)


func _launch_mortars() -> void:
	var t = target()
	var tp: Vector2 = t.position
	var tv: Vector2 = t.velocity
	var count := 6 if phase == 2 else 8
	run.shots.add_mortar(tp + tv * 1.0, 1.6, 70.0, 16.0, "Kharon mortar")
	for i in range(1, count):
		var off: Vector2 = Vector2.RIGHT.rotated(run.rng.randf() * TAU) * run.rng.randf_range(90.0, 300.0)
		run.shots.add_mortar(tp + tv * 0.6 + off, 1.6 + float(i) * 0.08, 70.0, 16.0, "Kharon mortar")
	Sound.play("boss", position, -6.0, 1.4)
	run.fx_over.burst(position, 12, 90.0, Color(1.0, 0.7, 0.4), 0.5, 4.0, Vector2.UP, 1.0)


func on_contact(f, rel: float) -> void:
	if f == run.player:
		var p: PlayerShip = run.player
		p.ram(self, maxf(rel, 120.0), float(data["contact"]))
	else:
		f.take_damage(float(data["contact"]) * 0.1, "Ramming", position)


func _draw_ship() -> void:
	if state == "windup":
		var prog := 1.0 - clampf(state_time / (1.3 if phase == 1 else 1.1), 0.0, 1.0)
		draw_side_lanes(fire_side, OFFSETS, float(data["range"]), prog, 0.12)
	if state == "bow_windup" or state == "bow_aim":
		var bprog := 0.0 if state == "bow_aim" else 1.0 - clampf(state_time / 1.4, 0.0, 1.0)
		draw_forward_lane(float(data["range"]) + 120.0, 46.0, bprog)
	if state == "deploy":
		var dprog := 1.0 - clampf(state_time / 1.8, 0.0, 1.0)
		for dp in deploy_points:
			var lp := to_local(dp as Vector2)
			draw_arc(lp, 30.0, 0.0, TAU, 24, Color(GameData.COL_WARN, 0.4 + 0.4 * dprog), 2.5, true)
			draw_arc(lp, 30.0 * dprog, 0.0, TAU, 24, Color(1.0, 0.6, 0.4, 0.6), 1.5, true)
	var outline := Color(0.85, 0.6, 0.45)
	if exposed:
		var pulse := 0.5 + 0.5 * sin(age * 10.0)
		outline = Color(0.4, 1.0, 0.95).lerp(Color.WHITE, pulse * 0.4)
		draw_circle(Vector2.ZERO, radius + 20.0, Color(0.3, 0.95, 1.0, 0.07 + 0.05 * pulse))
	draw_hull(132.0, 52.0, Color(0.12, 0.10, 0.09), outline)
	draw_colored_polygon(hull_points(100.0, 34.0), Color(0.19, 0.15, 0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(48, -24), Vector2(70, -14), Vector2(78, 0), Vector2(70, 14), Vector2(48, 24)]), Color(0.55, 0.5, 0.48) if not exposed else Color(0.3, 0.5, 0.55))
	for side in [-1.0, 1.0]:
		for x in OFFSETS:
			var lit: bool = state == "windup" and side == fire_side
			draw_rect(Rect2(Vector2(float(x) - 3.0, side * 23.0 - 2.5), Vector2(6, 5)), Color(1.0, 0.35, 0.25) if lit else Color(0.65, 0.5, 0.42))
	for mx in [30.0, -2.0, -34.0]:
		draw_circle(Vector2(mx, 0), 8.0, Color(0.32, 0.27, 0.24))
		draw_line(Vector2(mx, 0), Vector2(mx + 16.0, 0), Color(0.7, 0.6, 0.5), 4.0)
	if phase == 3 and sealed:
		var a := 0.6 + 0.3 * sin(age * 6.0)
		for x in [-40.0, -12.0, 16.0, 40.0]:
			draw_line(Vector2(x, -26), Vector2(x, 26), Color(0.8, 0.82, 0.9, a), 4.0)
	if state == "bow_windup":
		draw_circle(Vector2(radius + 2.0, 0), 6.0, Color(1.0, 0.5, 0.3, 0.6 + 0.4 * sin(age * 20.0)))


func _draw_overlay() -> void:
	var txt := ""
	var col := Color(0.4, 1.0, 0.95)
	if exposed:
		txt = "PLATES OPEN" if phase == 3 else "EXPOSED"
	elif phase == 3 and sealed:
		txt = "SEALED"
		col = Color(0.8, 0.85, 0.95)
	if txt != "":
		draw_string_outline(font, Vector2(-90, -radius - 32.0), txt, HORIZONTAL_ALIGNMENT_CENTER, 180.0, 20, 5, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(-90, -radius - 32.0), txt, HORIZONTAL_ALIGNMENT_CENTER, 180.0, 20, col)

class_name Leviathan
extends Enemy

const POD_SLOTS := [[Vector2(58, -78), "gun"], [Vector2(58, 78), "gun"], [Vector2(-52, -80), "launcher"], [Vector2(-52, 80), "launcher"]]
const CONDUIT_SLOTS := [Vector2(0, -100), Vector2(-100, 0), Vector2(0, 100)]

var phase := 1
var started := false
var pods: Array = []
var conduits: Array = []
var open_timer := 0.0
var rebuild_timer := 0.0
var seq := 0
var seq_timer := 4.0
var surge_timer := 26.0
var vent_timer := 6.0
var heat_timer := 12.0
var skater_timer := 15.0


func _on_setup() -> void:
	boss = true
	side_gunned = false


func phase_marks() -> Array:
	return [0.66, 0.33]


func boss_title() -> String:
	return "THE LEVIATHAN ENGINE"


func boss_status() -> String:
	if open_timer > 0.0:
		return "CORE OPEN  x1.5  %ds" % int(ceil(open_timer))
	match phase:
		1:
			if rebuild_timer > 0.0:
				return "REBUILDING PODS"
			return "CORE SEALED - DESTROY PODS (%d)" % _count(pods)
		2:
			return "BREAK THE LIT CONDUIT (%d)  SURGE %ds" % [_count(conduits), int(ceil(surge_timer))]
	return "CRAWLING - CORE VENTS IN %ds" % int(ceil(heat_timer))


func _count(list: Array) -> int:
	var n := 0
	for e in list:
		if is_instance_valid(e) and e.alive:
			n += 1
	return n


func _alive(list: Array) -> Array:
	var out: Array = []
	for e in list:
		if is_instance_valid(e) and e.alive:
			out.append(e)
	return out


func _add_pod(off: Vector2, role: String) -> Enemy:
	var p := position + off.rotated(rotation)
	var e: Enemy = run.spawn_enemy("leviathan_pod", p, [])
	if e != null:
		(e as LeviathanPod).attach(self, off, role)
	return e


func _open(t: float) -> void:
	open_timer = t
	exposed = true
	run.banner("CORE OPEN", "Hit the Leviathan's core now", Color(0.4, 1.0, 0.95))
	Sound.play("impact", position, 2.0, 0.45)
	run.add_shake(8.0)


func _think(dt: float) -> void:
	if not started:
		started = true
		for s in POD_SLOTS:
			var pe := _add_pod(s[0], str(s[1]))
			if pe != null:
				pods.append(pe)
	if open_timer > 0.0:
		open_timer -= dt
		if open_timer <= 0.0:
			exposed = false
			if phase == 1:
				rebuild_timer = 3.0
				run.banner("REBUILDING PODS", "New weapon pods are bolting on", GameData.COL_WARN)
			elif phase == 2:
				_light_conduits()
	if phase == 1 and hull <= max_hull * 0.66:
		phase = 2
		open_timer = 0.0
		exposed = false
		run.on_boss_phase(self)
		_light_conduits()
	elif phase == 2 and hull <= max_hull * 0.33:
		phase = 3
		open_timer = 0.0
		exposed = false
		for c in _alive(conduits):
			c.die()
		conduits.clear()
		run.on_boss_phase(self)
	match phase:
		1:
			_phase_one(dt)
		2:
			_phase_two(dt)
		_:
			_phase_three(dt)


func _phase_one(dt: float) -> void:
	var t = target()
	steer_to_point(run.arena.size * 0.5, speed * 0.5, dt)
	if position.distance_to(run.arena.size * 0.5) < 60.0:
		steer_to_angle(((t.position as Vector2) - position).angle(), 0.0, dt)
	if rebuild_timer > 0.0:
		rebuild_timer -= dt
		if rebuild_timer <= 0.0:
			var picks := [POD_SLOTS[0], POD_SLOTS[3]] if run.rng.randf() < 0.5 else [POD_SLOTS[1], POD_SLOTS[2]]
			for s in picks:
				var pe := _add_pod(s[0], str(s[1]))
				if pe != null:
					pods.append(pe)
		return
	if open_timer <= 0.0 and _count(pods) == 0:
		_open(10.0)


func _light_conduits() -> void:
	conduits = _alive(conduits)
	for s in CONDUIT_SLOTS:
		if conduits.size() >= 3:
			break
		var ce := _add_pod(s, "conduit")
		if ce != null:
			conduits.append(ce)
	for c in conduits:
		c.hull = c.max_hull
	seq = 0
	seq_timer = 4.0
	surge_timer = 26.0
	_update_lit()


func _update_lit() -> void:
	var live := _alive(conduits)
	for i in live.size():
		live[i].lit = i == seq % maxi(1, live.size())


func _phase_two(dt: float) -> void:
	var t = target()
	steer_to_angle(((t.position as Vector2) - position).angle(), speed * 0.3, dt)
	if open_timer > 0.0:
		return
	var live := _alive(conduits)
	if live.is_empty():
		_open(10.0)
		return
	seq_timer -= dt
	if seq_timer <= 0.0:
		seq_timer = 4.0
		seq += 1
		Sound.play("ready", position, -6.0, 0.7)
	_update_lit()
	surge_timer -= dt
	if surge_timer <= 0.0:
		_surge()
		_light_conduits()


func _surge() -> void:
	run.banner("PRESSURE SURGE", "Vents are erupting around the Engine - get clear of the rings", GameData.COL_WARN)
	Sound.play("boss", position, 0.0, 0.6)
	for i in 10:
		var p: Vector2 = position + Vector2.RIGHT.rotated(TAU * float(i) / 10.0 + run.rng.randf() * 0.3) * run.rng.randf_range(220.0, 480.0)
		run.hazards.add_vent_burst(p, 1.8 + float(i) * 0.05)
	var t = target()
	run.hazards.add_vent_burst(t.position, 2.0)


func _phase_three(dt: float) -> void:
	var t = target()
	var tp: Vector2 = t.position
	steer_to_point(tp, speed, dt)
	heat_timer -= dt
	if heat_timer <= 0.0 and open_timer <= 0.0:
		heat_timer = 13.0
		_open(5.0)
	vent_timer -= dt
	if vent_timer <= 0.0:
		vent_timer = 7.0
		var dir := (tp - position).normalized()
		for i in 6:
			run.hazards.add_vent_burst(position + dir * (radius + 90.0 + float(i) * 115.0), 1.5 + float(i) * 0.22)
	skater_timer -= dt
	if skater_timer <= 0.0:
		skater_timer = 16.0
		for k in 2:
			var sp: Vector2 = run.director.pick_spawn(false)
			run.fx_over.spawn_cue(sp)
			run.spawn_enemy("swarm_skater", sp, [])


func damage_factor(_origin: Vector2) -> float:
	if open_timer > 0.0:
		return 1.0
	if phase == 3:
		return 0.35
	run.fx_over.text(position + Vector2(0, -radius - 20.0), "CORE SEALED", Color(0.75, 0.8, 0.85), 13, 0.4)
	return 0.06


func on_contact(f, rel: float) -> void:
	if f == run.player:
		var p: PlayerShip = run.player
		p.ram(self, maxf(rel, 140.0), float(data["contact"]))
	else:
		f.take_damage(float(data["contact"]) * 0.1, "Ramming", position)


func _draw_ship() -> void:
	var body := Color(0.05, 0.08, 0.10)
	if hit_flash > 0.0 and not SaveData.reduce_flash():
		body = body.lerp(Color(0.6, 0.7, 0.7), 0.4)
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		var r := radius * (1.0 + 0.12 * sin(a * 3.0)) * Vector2(1.35, 1.0).length() / 1.2
		pts.append(Vector2(cos(a) * r * 1.2, sin(a) * r * 0.95))
	draw_colored_polygon(pts, body)
	var closed := pts.duplicate()
	closed.append(pts[0])
	var open := open_timer > 0.0
	var pulse := 0.5 + 0.5 * sin(age * (8.0 if open else 2.0))
	draw_polyline(closed, Color(0.3, 0.9, 0.8, 0.6 + 0.3 * pulse) if not open else Color(0.6, 1.0, 1.0), 3.0, true)
	for c in _alive(pods) + _alive(conduits):
		var lp := to_local(c.position)
		draw_line(Vector2.ZERO, lp, Color(0.3, 0.8, 0.75, 0.35) if not bool(c.get("lit")) else Color(1.0, 0.95, 0.5, 0.8), 4.0)
	draw_circle(Vector2.ZERO, 34.0, Color(0.02, 0.05, 0.06))
	if open:
		draw_circle(Vector2.ZERO, 30.0, Color(0.4, 1.0, 0.95, 0.5 + 0.4 * pulse))
		draw_circle(Vector2.ZERO, 14.0, Color(0.9, 1.0, 1.0))
	else:
		draw_circle(Vector2.ZERO, 22.0, Color(0.2, 0.6, 0.55, 0.25 + 0.2 * pulse))
		for k in 4:
			var a := PI / 2.0 * float(k) + PI / 4.0
			draw_line(Vector2.RIGHT.rotated(a) * 10.0, Vector2.RIGHT.rotated(a) * 34.0, Color(0.6, 0.7, 0.75), 6.0)
	for k in 5:
		var vx := -60.0 + float(k) * 30.0
		draw_circle(Vector2(vx, 0), 4.0, Color(0.3, 0.9, 0.8, 0.3 + 0.5 * fposmod(age * 0.7 + float(k) * 0.2, 1.0)))


func _draw_overlay() -> void:
	if open_timer > 0.0:
		draw_string_outline(font, Vector2(-90, -radius - 34.0), "CORE OPEN", HORIZONTAL_ALIGNMENT_CENTER, 180.0, 22, 5, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(-90, -radius - 34.0), "CORE OPEN", HORIZONTAL_ALIGNMENT_CENTER, 180.0, 22, Color(0.4, 1.0, 0.95))

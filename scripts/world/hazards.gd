class_name Hazards
extends Node2D

var run
var mines: Array = []
var fields: Array = []
var currents: Array = []
var whirlpools: Array = []
var storms: Array = []
var wrecks: Array = []
var time := 0.0
var whirl_timer := 0.0
var storm_timer := 0.0
var timed_events := false
var wave := 0
var last_mine_hit := -10.0
var pickups: Array = []
var checkpoints: Array = []
var cp_index := 0
var wreck_value := -1
var debris_fields: Array = []
var lightning_fields: Array = []
var wards: Array = []
var lane_sets: Array = []
var vents: Array = []
var rifts: Array = []
var shift_interval := 0.0
var shift_timer := 0.0
var shift_warned := false
var blooms: Array = []
var buoys: Array = []
var lanes_interval := 0.0
var lanes_timer := 0.0
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font


func cfg(kind: String) -> Dictionary:
	return GameData.HAZARDS[kind]


func prepare_wave(n: int) -> void:
	wave = n
	mines.clear()
	fields.clear()
	var boss := n >= GameData.MAX_WAVE
	timed_events = not boss and n >= 6
	if boss:
		whirlpools.clear()
		storms.clear()
	var want_currents := 0
	if n >= 3:
		want_currents = 1
	if n >= 7:
		want_currents = 2
	while currents.size() < want_currents:
		if not add_current():
			break
	if n >= 4 and not boss:
		var count := 1 + int(float(n - 4) / 3.0)
		for i in count:
			add_minefield()
	var i := wrecks.size() - 1
	while i >= 0:
		if bool(wrecks[i]["looted"]):
			wrecks.remove_at(i)
		i -= 1
	var want_wrecks := 1 if n < 5 else 2
	var guard := 0
	while wrecks.size() < want_wrecks and guard < 4:
		guard += 1
		add_wreck()
	whirl_timer = run.rng.randf_range(12.0, 20.0)
	storm_timer = run.rng.randf_range(18.0, 28.0) if n >= 7 else 9999.0
	queue_redraw()


func setup_mission(mcfg: Dictionary, stage: int) -> void:
	wave = stage
	var hz: Dictionary = mcfg.get("hazards", {})
	for i in int(hz.get("currents", 0)):
		add_current()
	for i in int(hz.get("minefields", 0)):
		add_minefield()
	for i in int(hz.get("wreck_fields", 0)):
		add_wreck_field()
	for i in int(hz.get("wrecks", 0)):
		add_wreck()
	for i in int(hz.get("lightning_fields", 0)):
		add_lightning_field()
	for i in int(hz.get("storms", 0)):
		add_storm(null, true)
	for i in int(hz.get("whirlpools", 0)):
		add_whirlpool(null, true)
	for i in int(hz.get("vents", 0)):
		add_vent()
	for i in int(hz.get("rifts", 0)):
		add_rift()
	shift_interval = float(hz.get("shift_currents", 0.0))
	shift_timer = shift_interval
	for i in int(hz.get("blooms", 0)):
		add_bloom()
	for i in int(hz.get("moving_currents", 0)):
		var mc := _find_spot(300.0, 0.0)
		if mc != Vector2.INF:
			add_moving_current(mc, Vector2.RIGHT.rotated(run.rng.randf() * TAU))
	lanes_interval = float(hz.get("storm_lanes", 0.0))
	lanes_timer = 6.0
	timed_events = bool(hz.get("whirlpool", false)) or bool(hz.get("storm", false))
	whirl_timer = run.rng.randf_range(12.0, 20.0) if bool(hz.get("whirlpool", false)) else 99999.0
	storm_timer = run.rng.randf_range(18.0, 28.0) if bool(hz.get("storm", false)) else 99999.0


func add_player_mine(pos: Vector2, damage: float, max_count: int) -> void:
	var own: Array = []
	for m in mines:
		if int(m.get("team", 1)) == 0:
			own.append(m)
	while own.size() >= max_count:
		mines.erase(own[0])
		own.remove_at(0)
	mines.append({"pos": pos, "armed": false, "fuse": 0.0, "tick": 0.0, "phase": 0.0, "team": 0, "damage": damage, "age": 0.0})


func add_layer_mine(pos: Vector2, layer_id: int, max_count: int) -> void:
	var own: Array = []
	for m in mines:
		if int(m.get("owner", 0)) == layer_id:
			own.append(m)
	while own.size() >= max_count:
		mines.erase(own[0])
		own.remove_at(0)
	mines.append({"pos": pos, "armed": false, "fuse": 0.0, "tick": 0.0, "phase": run.rng.randf() * TAU, "owner": layer_id, "layer": true, "age": 0.0})
	run.hazard_intro("mines")


func add_lightning_field(near: Variant = null) -> bool:
	var lf := cfg("lightning_field")
	var r: float = lf["radius"]
	var c: Vector2
	if near is Vector2:
		c = near
	else:
		c = _find_spot(r + 20.0, 520.0)
	if c == Vector2.INF:
		return false
	lightning_fields.append({"pos": c, "radius": r, "timer": run.rng.randf_range(2.0, 4.5)})
	run.hazard_intro("lightning_field")
	queue_redraw()
	return true


func add_moving_current(center: Vector2, dir: Vector2) -> Dictionary:
	var c := {"pos": center, "dir": dir.normalized(), "length": 1150.0, "width": 240.0, "speed": 140.0, "vel": dir.normalized().rotated(PI / 2.0) * 45.0, "spin": 0.12}
	currents.append(c)
	run.banner("THE SEA IS MOVING", "A great current is dragging the battle with it", Color(0.6, 0.9, 1.0))
	return c


func lane_strike(center: Vector2, dir: Vector2, damage: float, spare: bool, delay: float) -> void:
	var lc := cfg("lane")
	var w: float = lc["width"]
	var span: float = lc["span"]
	var count := int(span / w)
	var half := int(float(count) / 2.0)
	var open_idx: int = clampi(run.rng.randi_range(-1, 1), -half, half)
	lane_sets.append({"center": center, "dir": dir.normalized(), "w": w, "span": span, "half": half, "open": open_idx, "time": delay, "max": delay, "damage": damage, "spare": spare})
	Sound.play("warning", center, -4.0, 0.5)


func _lane_index(ls: Dictionary, p: Vector2) -> int:
	var d: Vector2 = ls["dir"]
	var local: Vector2 = p - (ls["center"] as Vector2)
	if absf(local.dot(d)) > float(ls["span"]) * 0.5:
		return 9999
	var idx := int(round(local.dot(d.rotated(PI / 2.0)) / float(ls["w"])))
	if absi(idx) > int(ls["half"]):
		return 9999
	return idx


func _update_trench(dt: float) -> void:
	var vc := cfg("vent")
	var i := vents.size() - 1
	while i >= 0:
		var v: Dictionary = vents[i]
		v["timer"] = float(v["timer"]) - dt
		if float(v["timer"]) <= 0.0:
			if v["state"] == "idle":
				v["state"] = "warn"
				v["timer"] = float(vc["warn"])
				v["max"] = float(vc["warn"])
				Sound.play("warning", v["pos"], -8.0, 0.5)
			else:
				_erupt(v["pos"])
				if bool(v["once"]):
					vents.remove_at(i)
				else:
					v["state"] = "idle"
					v["timer"] = run.rng.randf_range(float(vc["idle_min"]), float(vc["idle_max"]))
		i -= 1
	var bc := cfg("bloom")
	var rect: Rect2 = run.arena.rect
	for b in blooms:
		var bp: Vector2 = b["pos"]
		var bv: Vector2 = b["vel"]
		bp += bv * dt
		if bp.x < 250.0 or bp.x > rect.size.x - 250.0:
			bv.x = -bv.x
		if bp.y < 250.0 or bp.y > rect.size.y - 250.0:
			bv.y = -bv.y
		b["pos"] = bp
		b["vel"] = bv.limit_length(float(bc["drift"]))
	var bcfg := cfg("buoy")
	var player: PlayerShip = run.player
	for b in buoys:
		if bool(b["done"]):
			continue
		var inside := player.alive and player.position.distance_to(b["pos"]) <= float(bcfg["radius"])
		if inside:
			b["progress"] = float(b["progress"]) + dt / float(bcfg["time"])
		else:
			b["progress"] = maxf(0.0, float(b["progress"]) - dt * 0.25)
		if float(b["progress"]) >= 1.0:
			b["done"] = true
			b["progress"] = 1.0
			run.fx_over.ring(b["pos"], 160.0, 0.8, Color(0.5, 1.0, 0.9, 0.9), 3.0)
			Sound.play("confirm", b["pos"], -2.0, 0.8)
			run.on_style_event("BUOY ANSWERED", 10.0, 200, b["pos"])


func _update_expanse(dt: float) -> void:
	var rc := cfg("rift")
	for r in rifts:
		r["timer"] = float(r["timer"]) - dt
		if not bool(r["warn"]) and float(r["timer"]) <= float(rc["warn"]):
			r["warn"] = true
			Sound.play("warning", r["pos"], -8.0, 0.4)
		if float(r["timer"]) <= 0.0:
			r["timer"] = float(rc["cycle"])
			r["warn"] = false
			_rift_pulse(r)
	if shift_interval > 0.0 and run.state == "combat":
		shift_timer -= dt
		if not shift_warned and shift_timer <= 3.0:
			shift_warned = true
			run.hazard_intro("shift")
			run.banner("CURRENTS SHIFTING", "New directions in 3 seconds", Color(0.6, 0.9, 1.0))
		if shift_timer <= 0.0:
			shift_timer = shift_interval
			shift_warned = false
			for c in currents:
				var turn := PI / 2.0 * (1.0 if run.rng.randf() < 0.5 else -1.0)
				if run.rng.randf() < 0.3:
					turn = PI
				c["dir"] = (c["dir"] as Vector2).rotated(turn)
			Sound.play("wind", null, -2.0, 0.6)


func _rift_pulse(r: Dictionary) -> void:
	var rc := cfg("rift")
	var c: Vector2 = r["pos"]
	var rad: float = rc["radius"]
	run.fx_over.ring(c, rad, 0.5, Color(1.0, 0.5, 0.9, 0.9), 5.0)
	run.fx_over.burst(c, 26, 240.0, Color(1.0, 0.6, 0.95), 0.6, 3.5)
	Sound.play("impact", c, -2.0, 0.4)
	for f in run.friendlies:
		if not f.alive:
			continue
		var d: float = (f.position as Vector2).distance_to(c)
		if d <= rad + float(f.radius) * 0.5:
			f.take_damage(float(rc["damage"]), "Resonance rift", c)
			if f == run.player:
				run.wake.lose(float(rc["drain"]), "RIFT PULSE")
		elif f == run.player and d <= rad + 60.0:
			run.on_close_dodge(run.player.position)
	for e in run.enemies.duplicate():
		if is_instance_valid(e) and e.alive and not e.boss and c.distance_to(e.position) <= rad + float(e.radius):
			e.take_damage(float(rc["damage"]) * 0.5)


func _draw_expanse() -> void:
	var rc := cfg("rift")
	var rad: float = rc["radius"]
	var half: float = float(rc["length"]) * 0.5
	for r in rifts:
		var c: Vector2 = r["pos"]
		var d := Vector2.RIGHT.rotated(float(r["angle"]))
		var n := d.rotated(PI / 2.0)
		var warn := bool(r["warn"])
		var prog := 1.0 - clampf(float(r["timer"]) / float(rc["warn"]), 0.0, 1.0) if warn else 0.0
		var seed_v: float = r["seed"]
		var pts := PackedVector2Array()
		for k in 11:
			var t := lerpf(-half, half, float(k) / 10.0)
			var jitter := sin(float(k) * 2.7 + seed_v + time * (6.0 if warn else 1.5)) * (10.0 + 10.0 * prog)
			pts.append(c + d * t + n * jitter)
		draw_polyline(pts, Color(1.0, 0.5, 0.85, 0.35 + 0.5 * prog), 6.0 + 4.0 * prog)
		draw_polyline(pts, Color(1.0, 0.85, 0.95, 0.8), 2.0)
		if warn:
			draw_circle(c, rad * prog, Color(1.0, 0.5, 0.85, 0.12))
			draw_arc(c, rad, 0.0, TAU, 40, Color(1.0, 0.55, 0.9, 0.5 + 0.4 * prog), 2.5, true)
			_label(c + Vector2(0, -rad - 8.0), "RIFT PULSE", Color(1.0, 0.65, 0.92, 0.95))
		else:
			draw_arc(c, rad, 0.0, TAU, 40, Color(1.0, 0.55, 0.9, 0.1), 1.0, true)


func _erupt(p: Vector2) -> void:
	var vc := cfg("vent")
	var r: float = vc["radius"]
	run.fx_over.explosion(p, r)
	run.fx_over.burst(p, 24, 260.0, Color(0.6, 1.0, 0.9), 0.7, 4.0)
	Sound.play("explosion", p, -2.0, 0.6)
	run.add_shake(4.0)
	for f in run.friendlies:
		if not f.alive:
			continue
		var d: Vector2 = (f.position as Vector2) - p
		if d.length() <= r + float(f.radius) * 0.5:
			f.take_damage(float(vc["damage"]), "Pressure vent", p)
			if f == run.player:
				run.player.velocity += d.normalized() * float(vc["push"])
		elif f == run.player and d.length() <= r + 60.0:
			run.on_close_dodge(run.player.position)
	for e in run.enemies.duplicate():
		if is_instance_valid(e) and e.alive and not e.anchored and p.distance_to(e.position) <= r + float(e.radius):
			e.take_damage(float(vc["damage"]) * (0.4 if e.boss else 1.0))
			if is_instance_valid(e) and e.alive and not e.boss:
				e.velocity += ((e.position as Vector2) - p).normalized() * float(vc["push"])


func _draw_trench() -> void:
	for b in blooms:
		var c: Vector2 = b["pos"]
		var r: float = b["radius"]
		draw_circle(c, r, Color(0.3, 1.0, 0.8, 0.05))
		draw_circle(c, r * 0.6, Color(0.3, 1.0, 0.8, 0.04))
		var seed_v: float = b["seed"]
		for k in 18:
			var fx := fposmod(sin(float(k) * 12.99 + seed_v) * 437.5, 1.0)
			var fy := fposmod(sin(float(k) * 78.23 + seed_v) * 123.4, 1.0)
			var sp := c + Vector2(fx - 0.5, fy - 0.5) * r * 1.6
			if sp.distance_to(c) > r:
				continue
			draw_circle(sp, 2.0, Color(0.5, 1.0, 0.9, 0.3 + 0.4 * (0.5 + 0.5 * sin(time * 2.0 + float(k)))))
	var vc := cfg("vent")
	var vr: float = vc["radius"]
	for v in vents:
		var c: Vector2 = v["pos"]
		if v["state"] == "idle":
			draw_circle(c, 14.0, Color(0.1, 0.2, 0.2, 0.8))
			draw_arc(c, 14.0, 0.0, TAU, 16, Color(0.4, 0.9, 0.8, 0.6), 2.0, true)
			for k in 3:
				var bb := fposmod(time * 0.8 + float(k) * 0.33, 1.0)
				draw_circle(c + Vector2(sin(float(k) * 2.1) * 6.0, -bb * 14.0), 2.0 + bb * 2.0, Color(0.6, 1.0, 0.9, 0.5 * (1.0 - bb)))
			if not bool(v["once"]):
				draw_arc(c, vr, 0.0, TAU, 32, Color(0.4, 0.9, 0.8, 0.12), 1.0, true)
		else:
			var prog := 1.0 - clampf(float(v["timer"]) / maxf(0.01, float(v.get("max", 2.0))), 0.0, 1.0)
			draw_circle(c, vr * prog, Color(0.5, 1.0, 0.85, 0.18))
			draw_arc(c, vr, 0.0, TAU, 32, Color(0.6, 1.0, 0.9, 0.5 + 0.4 * prog), 2.5, true)
			_label(c + Vector2(0, -vr - 8.0), "VENT", Color(0.6, 1.0, 0.9, 0.9))
	var bcfg := cfg("buoy")
	for b in buoys:
		var c: Vector2 = b["pos"]
		var done := bool(b["done"])
		var col := Color(0.5, 1.0, 0.9) if done else Color(0.6, 0.85, 1.0)
		draw_circle(c, 12.0, Color(0.05, 0.12, 0.16))
		draw_arc(c, 12.0, 0.0, TAU, 16, col, 2.5, true)
		draw_line(c, c + Vector2(0, -26), col, 2.0)
		draw_circle(c + Vector2(0, -26), 4.0, col if done or int(time * 2.0) % 2 == 0 else Color(col, 0.3))
		if not done:
			draw_arc(c, float(bcfg["radius"]), 0.0, TAU, 40, Color(col, 0.3), 1.5, true)
			if float(b["progress"]) > 0.0:
				draw_arc(c, float(bcfg["radius"]) - 8.0, -PI / 2.0, -PI / 2.0 + TAU * float(b["progress"]), 40, Color(0.6, 1.0, 0.9, 0.95), 5.0, true)
			_label(c + Vector2(0, -float(bcfg["radius"]) - 8.0), "ECHO BUOY", col)


func _update_lanes(dt: float) -> void:
	var i := lane_sets.size() - 1
	while i >= 0:
		var ls: Dictionary = lane_sets[i]
		ls["time"] = float(ls["time"]) - dt
		if float(ls["time"]) > 0.0:
			i -= 1
			continue
		lane_sets.remove_at(i)
		i -= 1
		_resolve_lanes(ls)


func _resolve_lanes(ls: Dictionary) -> void:
	var d: Vector2 = ls["dir"]
	var n := d.rotated(PI / 2.0)
	var w: float = ls["w"]
	var span: float = ls["span"]
	var c: Vector2 = ls["center"]
	for k in range(-int(ls["half"]), int(ls["half"]) + 1):
		if k == int(ls["open"]):
			continue
		var mid := c + n * float(k) * w
		for j in 3:
			var t: float = lerpf(-0.45, 0.45, float(j) / 2.0) + run.rng.randf_range(-0.05, 0.05)
			run.fx_over.bolt(mid + d * span * (t - 0.12), mid + d * span * (t + 0.12), Color(1.0, 1.0, 0.75, 0.9))
	if not SaveData.reduce_flash():
		run.fx_over.flashes.append({"pos": c, "radius": span * 0.6, "life": 0.12, "max": 0.12})
	Sound.play("impact", c, 0.0, 0.55)
	Sound.play("explosion", c, -6.0, 1.8)
	run.add_shake(5.0)
	var open_i: int = int(ls["open"])
	for f in run.friendlies:
		if not f.alive:
			continue
		var idx := _lane_index(ls, f.position)
		if idx == 9999:
			continue
		if idx != open_i:
			f.take_damage(float(ls["damage"]), "Lightning", f.position)
		elif f == run.player:
			run.on_close_dodge(run.player.position)
	if not bool(ls["spare"]):
		for e in run.enemies.duplicate():
			if is_instance_valid(e) and e.alive:
				var ei := _lane_index(ls, e.position)
				if ei != 9999 and ei != open_i:
					e.take_damage(float(ls["damage"]))


func _draw_lanes() -> void:
	for ls in lane_sets:
		var d: Vector2 = ls["dir"]
		var n := d.rotated(PI / 2.0)
		var w: float = ls["w"]
		var span: float = ls["span"]
		var c: Vector2 = ls["center"]
		var prog := 1.0 - clampf(float(ls["time"]) / float(ls["max"]), 0.0, 1.0)
		var flick := 0.5 + 0.5 * sin(time * 24.0)
		for k in range(-int(ls["half"]), int(ls["half"]) + 1):
			var mid := c + n * float(k) * w
			var a0 := mid - d * span * 0.5
			var a1 := mid + d * span * 0.5
			var e0 := n * w * 0.5
			if k == int(ls["open"]):
				draw_line(a0 - e0 * 0.92, a1 - e0 * 0.92, Color(0.5, 1.0, 0.7, 0.75), 3.0)
				draw_line(a0 + e0 * 0.92, a1 + e0 * 0.92, Color(0.5, 1.0, 0.7, 0.75), 3.0)
				var lp := c + n * float(k) * w
				_label(lp + Vector2(0, 5), "OPEN LANE", Color(0.55, 1.0, 0.75, 0.95))
				continue
			var inner := e0 * 0.86
			var poly := PackedVector2Array([a0 - inner, a1 - inner, a1 + inner, a0 + inner])
			draw_colored_polygon(poly, Color(1.0, 0.95, 0.45, 0.05 + 0.18 * prog))
			var fill := e0 * 0.86 * prog
			draw_colored_polygon(PackedVector2Array([a0 - fill, a1 - fill, a1 + fill, a0 + fill]), Color(1.0, 1.0, 0.7, 0.08 + 0.1 * prog * flick))
			draw_line(a0 - inner, a1 - inner, Color(1.0, 0.95, 0.5, 0.35 + 0.45 * prog), 1.5)
			draw_line(a0 + inner, a1 + inner, Color(1.0, 0.95, 0.5, 0.35 + 0.45 * prog), 1.5)


func add_rift(near: Variant = null) -> bool:
	var rc := cfg("rift")
	var c: Vector2
	if near is Vector2:
		c = near
		var rect: Rect2 = run.arena.rect.grow(-150.0)
		c.x = clampf(c.x, rect.position.x, rect.end.x)
		c.y = clampf(c.y, rect.position.y, rect.end.y)
	else:
		c = _find_spot(float(rc["radius"]) + 20.0, 480.0)
	if c == Vector2.INF:
		return false
	rifts.append({"pos": c, "angle": run.rng.randf() * PI, "timer": run.rng.randf_range(2.0, float(rc["cycle"])), "warn": false, "seed": run.rng.randf() * 40.0})
	run.hazard_intro("rift")
	return true


func in_rift(p: Vector2) -> bool:
	var rc := cfg("rift")
	for r in rifts:
		if bool(r["warn"]) and p.distance_to(r["pos"]) <= float(rc["radius"]):
			return true
	return false


func add_vent(near: Variant = null) -> bool:
	var vc := cfg("vent")
	var c: Vector2
	if near is Vector2:
		c = near
	else:
		c = _find_spot(float(vc["radius"]) + 20.0, 420.0)
	if c == Vector2.INF:
		return false
	vents.append({"pos": c, "state": "idle", "timer": run.rng.randf_range(2.0, float(vc["idle_max"])), "once": false})
	run.hazard_intro("vent")
	return true


func add_vent_burst(pos: Vector2, delay: float) -> void:
	var rect: Rect2 = run.arena.rect.grow(-30.0)
	if not rect.has_point(pos):
		return
	vents.append({"pos": pos, "state": "warn", "timer": delay, "max": delay, "once": true})


func add_bloom(near: Variant = null) -> bool:
	var bc := cfg("bloom")
	var c: Vector2
	if near is Vector2:
		c = near
	else:
		c = _find_spot(80.0, 200.0)
	if c == Vector2.INF:
		return false
	blooms.append({"pos": c, "radius": float(bc["radius"]), "vel": Vector2.RIGHT.rotated(run.rng.randf() * TAU) * float(bc["drift"]), "seed": run.rng.randf() * 50.0})
	run.hazard_intro("bloom")
	return true


func in_bloom(p: Vector2) -> bool:
	for b in blooms:
		if p.distance_to(b["pos"]) <= float(b["radius"]):
			return true
	return false


func set_buoys(n: int) -> void:
	buoys.clear()
	var spots: Array = []
	var guard := 0
	while spots.size() < n and guard < 200:
		guard += 1
		var c := _find_spot(110.0, 420.0)
		if c == Vector2.INF:
			continue
		var ok := true
		for q in spots:
			if c.distance_to(q) < 650.0:
				ok = false
		if ok:
			spots.append(c)
	for c in spots:
		buoys.append({"pos": c, "progress": 0.0, "done": false})


func buoys_done() -> int:
	var n := 0
	for b in buoys:
		if bool(b["done"]):
			n += 1
	return n


func add_ward(pos: Vector2, radius: float, duration: float) -> void:
	wards.append({"pos": pos, "radius": radius, "life": duration, "max": duration, "cap": 14})
	Sound.play("ready", pos, -4.0, 0.7)


func add_wreck_field(near: Variant = null) -> bool:
	var wf := cfg("wreck_field")
	var r: float = wf["radius"]
	var c: Vector2
	if near is Vector2:
		c = near
	else:
		c = _find_spot(r + 30.0, 520.0)
	if c == Vector2.INF:
		return false
	var placed: int = run.arena.add_debris_field(run.rng, c, r, int(wf["pieces"]), run.player.position)
	if placed <= 0:
		return false
	debris_fields.append({"pos": c, "radius": r})
	run.hazard_intro("wreck_field")
	if run.arena.is_clear(c, 60.0):
		var before := wrecks.size()
		add_wreck(c)
		if wrecks.size() > before:
			wrecks[wrecks.size() - 1]["value"] = int(wrecks[wrecks.size() - 1]["value"]) + 6
	queue_redraw()
	return true


func add_pickup(pos: Vector2, kind: String) -> void:
	pickups.append({"pos": pos, "kind": kind, "life": 20.0})


func set_checkpoints(points: Array) -> void:
	checkpoints = points.duplicate()
	cp_index = 0


func clear_all() -> void:
	pickups.clear()
	mines.clear()
	fields.clear()
	currents.clear()
	whirlpools.clear()
	storms.clear()
	wrecks.clear()
	lightning_fields.clear()
	wards.clear()
	lane_sets.clear()
	vents.clear()
	rifts.clear()
	shift_interval = 0.0
	blooms.clear()
	buoys.clear()
	lanes_interval = 0.0
	for f in debris_fields:
		run.arena.clear_debris_near(f["pos"], float(f["radius"]) + 40.0)
	debris_fields.clear()
	queue_redraw()


func _find_spot(clearance: float, min_player: float) -> Vector2:
	var size: Vector2 = run.arena.size
	var p: Vector2 = run.player.position
	for i in 40:
		var c := Vector2(run.rng.randf_range(clearance, size.x - clearance), run.rng.randf_range(clearance, size.y - clearance))
		if c.distance_to(p) < min_player:
			continue
		if not run.arena.is_clear(c, clearance):
			continue
		var ok := true
		for f in fields:
			if c.distance_to(f["pos"]) < float(f["radius"]) + clearance:
				ok = false
		for w in wrecks:
			if c.distance_to(w["pos"]) < 160.0 + clearance:
				ok = false
		for wp in whirlpools:
			if c.distance_to(wp["pos"]) < float(wp["radius"]) + clearance:
				ok = false
		for df in debris_fields:
			if c.distance_to(df["pos"]) < float(df["radius"]) + clearance:
				ok = false
		for lfd in lightning_fields:
			if c.distance_to(lfd["pos"]) < float(lfd["radius"]) + clearance:
				ok = false
		if ok:
			return c
	return Vector2.INF


func add_minefield(near: Variant = null) -> bool:
	var m := cfg("mine")
	var fr: float = m["field"]
	var c: Vector2
	if near is Vector2:
		c = near
	else:
		c = _find_spot(fr + 20.0, 480.0)
	if c == Vector2.INF:
		return false
	fields.append({"pos": c, "radius": fr})
	var count: int = run.rng.randi_range(4, 6)
	var placed: Array = []
	var tries := 0
	while placed.size() < count and tries < 60:
		tries += 1
		var p: Vector2 = c + Vector2.RIGHT.rotated(run.rng.randf() * TAU) * run.rng.randf_range(0.0, fr - 20.0)
		var ok: bool = run.arena.is_clear(p, 30.0)
		for q in placed:
			if p.distance_to(q) < 60.0:
				ok = false
		if ok:
			placed.append(p)
	for p in placed:
		mines.append({"pos": p, "armed": false, "fuse": 0.0, "tick": 0.0, "phase": run.rng.randf() * TAU})
	run.fx_over.ring(c, fr, 0.9, Color(1.0, 0.4, 0.3, 0.8), 2.5)
	run.hazard_intro("mines")
	queue_redraw()
	return true


func add_current(near: Variant = null) -> bool:
	var cc := cfg("current")
	var length: float = cc["length"]
	var width: float = cc["width"]
	for i in 30:
		var c: Vector2
		if near is Vector2:
			c = near
		else:
			c = _find_spot(60.0, 0.0)
		if c == Vector2.INF:
			continue
		var dir := Vector2.RIGHT.rotated(run.rng.randf() * TAU)
		if not (near is Vector2):
			var p: Vector2 = run.player.position
			var cp := Geometry2D.get_closest_point_to_segment(p, c - dir * length * 0.5, c + dir * length * 0.5)
			if cp.distance_to(p) < width * 0.5 + 300.0:
				continue
		currents.append({"pos": c, "dir": dir, "length": length, "width": width, "speed": float(cc["speed"])})
		run.hazard_intro("current")
		queue_redraw()
		return true
	return false


func add_whirlpool(near: Variant = null, persistent: bool = false) -> bool:
	var wc := cfg("whirlpool")
	var r: float = wc["radius"]
	var c: Vector2
	if near is Vector2:
		c = near
	else:
		c = _find_spot(r + 40.0, 450.0)
	if c == Vector2.INF:
		return false
	whirlpools.append({"pos": c, "radius": r, "age": 0.0, "form": float(wc["form"]), "life": 99999.0 if persistent else float(wc["life"]), "fade": float(wc["fade"])})
	run.fx_over.spawn_cue(c, true)
	run.hazard_intro("whirlpool")
	Sound.play("wind", c, -2.0, 0.7)
	return true


func add_storm(near: Variant = null, persistent: bool = false) -> bool:
	var sc := cfg("storm")
	var r: float = sc["radius"]
	var c: Vector2
	if near is Vector2:
		c = near
	else:
		c = _find_spot(80.0, 520.0)
	if c == Vector2.INF:
		return false
	var drift: Vector2 = run.wind.dir() * float(sc["drift"])
	storms.append({"pos": c, "radius": r, "vel": drift, "age": 0.0, "form": float(sc["form"]), "life": 99999.0 if persistent else float(sc["life"]), "fade": float(sc["fade"]), "strike": 2.5, "seed": run.rng.randf() * 100.0, "persistent": persistent})
	run.hazard_intro("storm")
	Sound.play("wind", null, 0.0, 0.6)
	return true


func add_wreck(near: Variant = null) -> bool:
	var c: Vector2
	if near is Vector2:
		c = near
	else:
		c = _find_spot(90.0, 420.0)
	if c == Vector2.INF:
		return false
	var value := 8 + 2 * maxi(wave, 1)
	if wreck_value > 0:
		value = wreck_value
	wrecks.append({"pos": c, "progress": 0.0, "looted": false, "value": value, "fade": 1.0, "angle": run.rng.randf() * TAU, "hint": ""})
	run.hazard_intro("wreck")
	queue_redraw()
	return true


func _strength(h: Dictionary) -> float:
	var age: float = h["age"]
	var form: float = h["form"]
	var life: float = h["life"]
	var fade: float = h["fade"]
	if age < form:
		return 0.0
	if age > form + life:
		return clampf(1.0 - (age - form - life) / fade, 0.0, 1.0)
	return clampf((age - form) / 1.0, 0.0, 1.0)


func flow_at(pos: Vector2, ignore_storm: bool = false) -> Vector2:
	var v := Vector2.ZERO
	for c in currents:
		var dir: Vector2 = c["dir"]
		var local: Vector2 = pos - (c["pos"] as Vector2)
		var along := local.dot(dir)
		var across := local.dot(dir.rotated(PI / 2.0))
		var hl: float = float(c["length"]) * 0.5
		var hw: float = float(c["width"]) * 0.5
		if absf(along) < hl and absf(across) < hw:
			var side := 1.0 - pow(absf(across) / hw, 2.0)
			var ends := clampf((hl - absf(along)) / 120.0, 0.0, 1.0)
			v += dir * float(c["speed"]) * side * ends
	for w in whirlpools:
		var st := _strength(w)
		if st <= 0.0:
			continue
		var d: Vector2 = pos - (w["pos"] as Vector2)
		var dist := d.length()
		var r: float = w["radius"]
		if dist < r and dist > 8.0:
			var t := 1.0 - dist / r
			var inward := -d / dist
			var wc := cfg("whirlpool")
			v += (inward * float(wc["pull"]) * t + inward.rotated(PI / 2.0) * float(wc["swirl"]) * t) * st
	var sc := cfg("storm")
	if ignore_storm:
		return v
	for s in storms:
		var k := storm_factor(s, pos)
		if k <= 0.0:
			continue
		var seed_v: float = s["seed"]
		var gust := Vector2(sin(time * 1.7 + seed_v), cos(time * 1.3 + seed_v * 0.7)) * float(sc["gust"])
		v += (run.wind.dir() * float(sc["push"]) + gust) * k
	return v


func storm_factor(s: Dictionary, pos: Vector2) -> float:
	var st := _strength(s)
	if st <= 0.0:
		return 0.0
	var dist := pos.distance_to(s["pos"])
	var r: float = s["radius"]
	if dist >= r:
		return 0.0
	return st * (1.0 - pow(dist / r, 2.0) * 0.5)


func in_storm(pos: Vector2) -> bool:
	for s in storms:
		if storm_factor(s, pos) > 0.0:
			return true
	return false


func shot_hits_mine(a: Vector2, b: Vector2, r: float) -> bool:
	var mr: float = cfg("mine")["radius"]
	for m in mines:
		if int(m.get("team", 1)) == 0:
			continue
		var p: Vector2 = m["pos"]
		var cp := Geometry2D.get_closest_point_to_segment(p, a, b)
		if cp.distance_to(p) <= mr + r:
			m["armed"] = true
			m["fuse"] = 0.05
			return true
	return false


func _physics_process(delta: float) -> void:
	if run == null or run.state == "ended":
		return
	var dt := minf(delta, 0.05)
	time += dt
	_update_mines(dt)
	_update_temporary(dt)
	_update_weather(dt)
	_update_lanes(dt)
	_update_trench(dt)
	_update_expanse(dt)
	_update_wrecks(dt)
	_update_pickups(dt)
	_update_checkpoints()
	if timed_events and run.state == "combat" and run.mode != "practice":
		whirl_timer -= dt
		if whirl_timer <= 0.0:
			whirl_timer = run.rng.randf_range(30.0, 45.0)
			if whirlpools.is_empty():
				add_whirlpool()
		storm_timer -= dt
		if storm_timer <= 0.0:
			storm_timer = run.rng.randf_range(50.0, 70.0)
			if storms.is_empty():
				add_storm()
	queue_redraw()


func _update_mines(dt: float) -> void:
	var m_cfg := cfg("mine")
	var trigger: float = m_cfg["trigger"]
	var player: PlayerShip = run.player
	var due: Array = []
	for item in mines:
		var m: Dictionary = item
		var p: Vector2 = m["pos"]
		if int(m.get("team", 1)) == 0:
			m["age"] = float(m["age"]) + dt
			if float(m["age"]) < 0.8:
				continue
			for e in run.enemies:
				if e.alive and p.distance_to(e.position) < 60.0 + float(e.radius):
					due.append(m)
					break
			continue
		if bool(m.get("layer", false)):
			m["age"] = float(m["age"]) + dt
			if float(m["age"]) < 0.7:
				continue
		if bool(m["armed"]):
			m["fuse"] = float(m["fuse"]) - dt
			m["tick"] = float(m["tick"]) - dt
			if float(m["tick"]) <= 0.0:
				m["tick"] = 0.18
				Sound.play("fuse", p, -6.0, 1.3)
			if float(m["fuse"]) <= 0.0:
				due.append(m)
			continue
		var near := player.alive and player.position.distance_to(p) < trigger + player.radius
		if not near and not bool(m.get("layer", false)):
			for e in run.enemies:
				if e.alive and p.distance_to(e.position) < trigger + float(e.radius) * 0.5:
					near = true
					break
		if near:
			m["armed"] = true
			m["fuse"] = float(m_cfg["fuse"])
			m["tick"] = 0.0
			Sound.play("warning", p, -6.0, 1.4)
	for m in due:
		if mines.has(m):
			_explode_mine(m)


func _explode_mine(m: Dictionary) -> void:
	mines.erase(m)
	var m_cfg := cfg("mine")
	var p: Vector2 = m["pos"]
	if int(m.get("team", 1)) == 0:
		run.fx_over.explosion(p, 90.0)
		Sound.play("explosion", p, -2.0, 1.2)
		for e in run.enemies.duplicate():
			if is_instance_valid(e) and e.alive and p.distance_to(e.position) <= 90.0 + float(e.radius):
				e.receive_hit(float(m["damage"]), p, false, "mine")
		return
	var blast: float = m_cfg["blast"]
	var dmg: float = m_cfg["damage"]
	run.fx_over.explosion(p, blast)
	Sound.play("explosion", p, -1.0, 1.1)
	run.add_shake(8.0)
	var player: PlayerShip = run.player
	if player.alive:
		var d := player.position.distance_to(p)
		if d <= blast + player.radius * 0.5:
			if time - last_mine_hit > 0.5:
				last_mine_hit = time
				player.take_damage(dmg, "Mine")
		elif d <= blast + 60.0:
			run.on_close_dodge(player.position)
	run.mine_credit = true
	for e in run.enemies.duplicate():
		if is_instance_valid(e) and e.alive and p.distance_to(e.position) <= blast + float(e.radius):
			e.take_damage(dmg * (0.5 if e.boss else 1.0))
	run.mine_credit = false
	for other in mines:
		if not bool(other["armed"]) and p.distance_to(other["pos"]) <= blast * 0.9:
			other["armed"] = true
			other["fuse"] = 0.2
			other["tick"] = 0.0
	var i := fields.size() - 1
	while i >= 0:
		var f: Dictionary = fields[i]
		var any := false
		for other in mines:
			if (other["pos"] as Vector2).distance_to(f["pos"]) <= float(f["radius"]):
				any = true
				break
		if not any:
			fields.remove_at(i)
		i -= 1


func _update_weather(dt: float) -> void:
	var lf := cfg("lightning_field")
	for f in lightning_fields:
		f["timer"] = float(f["timer"]) - dt
		if float(f["timer"]) <= 0.0:
			f["timer"] = float(lf["cycle"])
			var r: float = f["radius"]
			for i in int(lf["strikes"]):
				var p: Vector2 = (f["pos"] as Vector2) + Vector2.RIGHT.rotated(run.rng.randf() * TAU) * sqrt(run.rng.randf()) * (r - 30.0)
				run.shots.add_mortar(p, float(lf["delay"]) + float(i) * 0.12, float(lf["strike_radius"]), float(lf["damage"]), "Lightning", true)
	var rect: Rect2 = run.arena.rect
	for c in currents:
		if not c.has("vel"):
			continue
		var cp: Vector2 = c["pos"]
		var v: Vector2 = c["vel"]
		cp += v * dt
		if cp.x < 400.0 or cp.x > rect.size.x - 400.0:
			v.x = -v.x
		if cp.y < 400.0 or cp.y > rect.size.y - 400.0:
			v.y = -v.y
		c["pos"] = cp
		c["vel"] = v
		c["dir"] = (c["dir"] as Vector2).rotated(float(c["spin"]) * dt)
	for s in storms:
		if not bool(s.get("persistent", false)):
			continue
		var sp: Vector2 = s["pos"]
		var sv: Vector2 = s["vel"]
		if sp.x < 300.0 or sp.x > rect.size.x - 300.0:
			sv.x = -sv.x
		if sp.y < 300.0 or sp.y > rect.size.y - 300.0:
			sv.y = -sv.y
		s["vel"] = sv
	var i := wards.size() - 1
	while i >= 0:
		var w: Dictionary = wards[i]
		w["life"] = float(w["life"]) - dt
		if int(w["cap"]) > 0:
			var n: int = run.shots.clear_enemy_near(w["pos"], float(w["radius"]), int(w["cap"]))
			if n > 0:
				w["cap"] = int(w["cap"]) - n
				run.fx_over.bolt(w["pos"], (w["pos"] as Vector2) + Vector2.RIGHT.rotated(run.rng.randf() * TAU) * float(w["radius"]) * 0.7, Color(0.6, 1.0, 0.85, 0.8))
				run.on_style_event("INTERCEPTED x%d" % n, 3.0 * n, 15 * n, w["pos"])
		if float(w["life"]) <= 0.0 or int(w["cap"]) <= 0:
			wards.remove_at(i)
		i -= 1
	if lanes_interval > 0.0 and run.state == "combat":
		lanes_timer -= dt
		if lanes_timer <= 0.0:
			lanes_timer = lanes_interval
			run.hazard_intro("storm_lanes")
			var p: PlayerShip = run.player
			lane_strike(p.position, Vector2.RIGHT.rotated(run.rng.randf() * TAU), float(cfg("lane")["damage"]), false, 1.9)


func _update_temporary(dt: float) -> void:
	var sc := cfg("storm")
	var player: PlayerShip = run.player
	for list in [whirlpools, storms]:
		var i: int = list.size() - 1
		while i >= 0:
			var h: Dictionary = list[i]
			h["age"] = float(h["age"]) + dt
			if float(h["age"]) > float(h["form"]) + float(h["life"]) + float(h["fade"]):
				list.remove_at(i)
			i -= 1
	for s in storms:
		var pos: Vector2 = s["pos"]
		s["pos"] = pos + (s["vel"] as Vector2) * dt
		if _strength(s) < 0.5:
			continue
		s["strike"] = float(s["strike"]) - dt
		if float(s["strike"]) > 0.0:
			continue
		var r: float = s["radius"]
		var target: Vector2
		if player.alive and player.position.distance_to(s["pos"]) < r:
			target = player.position + player.velocity * 0.6 + Vector2.RIGHT.rotated(run.rng.randf() * TAU) * run.rng.randf_range(0.0, 80.0)
			s["strike"] = run.rng.randf_range(2.2, 3.5)
		else:
			target = (s["pos"] as Vector2) + Vector2.RIGHT.rotated(run.rng.randf() * TAU) * run.rng.randf_range(0.0, r * 0.85)
			s["strike"] = run.rng.randf_range(1.6, 2.6)
		run.shots.add_mortar(target, float(sc["strike_delay"]), float(sc["strike_radius"]), float(sc["strike_damage"]), "Lightning", true)


func _update_wrecks(dt: float) -> void:
	var wc := cfg("wreck")
	var player: PlayerShip = run.player
	var wreck_time: float = float(wc["time"]) * player.stats.get_value("wreck_time_mult")
	var i := wrecks.size() - 1
	while i >= 0:
		var w: Dictionary = wrecks[i]
		if bool(w["looted"]):
			w["fade"] = float(w["fade"]) - dt * 0.5
			if float(w["fade"]) <= 0.0:
				wrecks.remove_at(i)
			i -= 1
			continue
		var p: Vector2 = w["pos"]
		w["hint"] = ""
		var in_range := player.alive and player.position.distance_to(p) < float(wc["radius"])
		if in_range and player.velocity.length() <= float(wc["max_speed"]):
			w["progress"] = float(w["progress"]) + dt / wreck_time
			w["hint"] = "SALVAGING"
		else:
			w["progress"] = maxf(0.0, float(w["progress"]) - dt * 0.5)
			if in_range:
				w["hint"] = "SLOW DOWN"
		if float(w["progress"]) >= 1.0:
			w["looted"] = true
			w["progress"] = 1.0
			var value := int(w["value"])
			run.award_salvage(value, p + Vector2(0, -50), "WRECK")
			run.add_score(100)
			run.on_style_event("SALVAGED", 8.0, 0, p, "salvage")
			run.on_wreck_salvaged(p)
			run.fx_over.burst(p, 18, 140.0, GameData.COL_SALVAGE, 0.8, 3.0)
			Sound.play("confirm", p, -4.0)
		i -= 1


func _update_pickups(dt: float) -> void:
	var player: PlayerShip = run.player
	var reach: float = player.radius + 40.0 * player.stats.get_value("pickup_mult")
	var i := pickups.size() - 1
	while i >= 0:
		var pk: Dictionary = pickups[i]
		pk["life"] = float(pk["life"]) - dt
		var p: Vector2 = pk["pos"]
		if player.alive and player.position.distance_to(p) <= reach:
			if pk["kind"] == "repair":
				player.heal(20.0)
				run.fx_over.text(p + Vector2(0, -20), "+20 HULL", GameData.COL_ALLY, 15, 1.0)
				Sound.play("salvage", p, -4.0, 0.8)
			else:
				run.award_salvage(8, p + Vector2(0, -20), "")
			pickups.remove_at(i)
		elif float(pk["life"]) <= 0.0:
			pickups.remove_at(i)
		i -= 1


func _update_checkpoints() -> void:
	if cp_index >= checkpoints.size():
		return
	var player: PlayerShip = run.player
	var p: Vector2 = checkpoints[cp_index]
	if player.alive and player.position.distance_to(p) <= 75.0:
		cp_index += 1
		run.fx_over.ring(p, 110.0, 0.5, Color(0.5, 1.0, 0.9, 0.9), 3.0)
		Sound.play("confirm", p, -4.0)
		run.on_checkpoint(cp_index)


func _draw() -> void:
	_draw_debris_fields()
	_draw_lightning_fields()
	_draw_lanes()
	_draw_trench()
	_draw_expanse()
	_draw_wards()
	_draw_checkpoints()
	_draw_pickups()
	_draw_currents()
	_draw_storms()
	_draw_whirlpools()
	_draw_wrecks()
	_draw_mines()


func _draw_currents() -> void:
	for c in currents:
		var dir: Vector2 = c["dir"]
		var perp := dir.rotated(PI / 2.0)
		var center: Vector2 = c["pos"]
		var hl: float = float(c["length"]) * 0.5
		var hw: float = float(c["width"]) * 0.5
		var corners := PackedVector2Array([center - dir * hl - perp * hw, center + dir * hl - perp * hw, center + dir * hl + perp * hw, center - dir * hl + perp * hw])
		draw_colored_polygon(corners, Color(0.25, 0.65, 0.95, 0.06))
		draw_line(corners[0], corners[1], Color(0.4, 0.8, 1.0, 0.22), 2.0)
		draw_line(corners[3], corners[2], Color(0.4, 0.8, 1.0, 0.22), 2.0)
		var spacing := 90.0
		var offset := fmod(time * float(c["speed"]) * 0.6, spacing)
		for row in [-0.5, 0.0, 0.5]:
			var a := -hl + offset
			while a < hl:
				var fade := clampf((hl - absf(a)) / 120.0, 0.0, 1.0)
				var p := center + dir * a + perp * hw * float(row)
				var col := Color(0.55, 0.9, 1.0, 0.35 * fade)
				draw_line(p - dir * 10.0 - perp * 9.0, p, col, 2.5)
				draw_line(p - dir * 10.0 + perp * 9.0, p, col, 2.5)
				a += spacing


func _draw_whirlpools() -> void:
	for w in whirlpools:
		var c: Vector2 = w["pos"]
		var r: float = w["radius"]
		var st := _strength(w)
		var age: float = w["age"]
		if age < float(w["form"]):
			var pulse := 0.5 + 0.5 * sin(time * 8.0)
			var segs := 24
			for i in segs:
				if i % 2 == 0:
					var a0 := TAU * float(i) / float(segs) + time
					draw_arc(c, r, a0, a0 + TAU / float(segs), 6, Color(0.5, 0.9, 1.0, 0.3 + 0.4 * pulse), 2.0)
			_label(c + Vector2(0, -r - 12.0), "WHIRLPOOL FORMING", Color(0.6, 0.95, 1.0, 0.8))
			continue
		draw_circle(c, r, Color(0.05, 0.25, 0.4, 0.12 * st))
		draw_arc(c, r, 0.0, TAU, 48, Color(0.5, 0.9, 1.0, 0.35 * st), 2.0, true)
		for arm in 4:
			var pts := PackedVector2Array()
			var base := TAU * float(arm) / 4.0 - time * 1.6
			for k in 14:
				var t := float(k) / 13.0
				var rr := lerpf(r, 10.0, t)
				pts.append(c + Vector2.RIGHT.rotated(base + t * 3.2) * rr)
			draw_polyline(pts, Color(0.55, 0.95, 1.0, 0.45 * st), 2.0, true)
		draw_circle(c, 10.0, Color(0.02, 0.06, 0.1, 0.8 * st))


func _draw_storms() -> void:
	for s in storms:
		var c: Vector2 = s["pos"]
		var r: float = s["radius"]
		var st := _strength(s)
		var age: float = s["age"]
		var dir: Vector2 = run.wind.dir()
		if age < float(s["form"]):
			var pulse := 0.5 + 0.5 * sin(time * 6.0)
			draw_arc(c, r, 0.0, TAU, 64, Color(0.75, 0.8, 1.0, 0.25 + 0.35 * pulse), 2.5, true)
			_label(c + Vector2(0, -r - 12.0), "STORM FRONT INCOMING", Color(0.85, 0.9, 1.0, 0.85))
			continue
		draw_circle(c, r, Color(0.02, 0.03, 0.07, 0.38 * st))
		draw_arc(c, r, 0.0, TAU, 64, Color(0.75, 0.82, 1.0, 0.4 * st), 2.5, true)
		for k in 5:
			var a0 := time * 0.35 + TAU * float(k) / 5.0
			draw_arc(c, r * (0.45 + 0.1 * float(k)), a0, a0 + 1.4, 16, Color(0.6, 0.65, 0.8, 0.15 * st), 6.0)
		var seed_v: float = s["seed"]
		for k in 46:
			var fx := fposmod(sin(float(k) * 12.9898 + seed_v) * 43758.5, 1.0)
			var fy := fposmod(sin(float(k) * 78.233 + seed_v) * 12345.6, 1.0)
			var travel := fposmod(fy + time * 0.6, 1.0)
			var p := c + Vector2((fx - 0.5) * 2.0 * r, (travel - 0.5) * 2.0 * r)
			if p.distance_to(c) > r * 0.95:
				continue
			draw_line(p, p + (Vector2(0.25, 1.0) + dir * 0.5).normalized() * 14.0, Color(0.7, 0.8, 1.0, 0.35 * st), 1.2)


func _draw_wrecks() -> void:
	var wc := cfg("wreck")
	var rr: float = wc["radius"]
	for w in wrecks:
		var c: Vector2 = w["pos"]
		var alpha: float = w["fade"]
		var ang: float = w["angle"]
		var looted := bool(w["looted"])
		var body := Color(0.22, 0.17, 0.13, alpha)
		var edge := Color(0.6, 0.5, 0.35, alpha)
		var piece1 := PackedVector2Array([Vector2(-26, -9), Vector2(8, -11), Vector2(14, -2), Vector2(4, 9), Vector2(-24, 8)])
		var piece2 := PackedVector2Array([Vector2(18, -6), Vector2(34, -2), Vector2(30, 8), Vector2(16, 6)])
		for piece in [piece1, piece2]:
			var pts := PackedVector2Array()
			for v in piece:
				pts.append(c + (v as Vector2).rotated(ang))
			draw_colored_polygon(pts, body)
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, edge, 1.5, true)
		draw_line(c + Vector2(-6, -16).rotated(ang), c + Vector2(4, 12).rotated(ang), Color(0.5, 0.4, 0.3, alpha), 2.0)
		if looted:
			continue
		var glint := 0.5 + 0.5 * sin(time * 4.0 + ang * 3.0)
		draw_circle(c + Vector2(-8, 0).rotated(ang), 3.0 + glint * 1.5, Color(1.0, 0.85, 0.4, 0.5 + 0.5 * glint))
		var segs := 20
		for i in segs:
			if i % 2 == 0:
				var a0 := TAU * float(i) / float(segs) + time * 0.3
				draw_arc(c, rr, a0, a0 + TAU / float(segs), 4, Color(1.0, 0.85, 0.4, 0.4), 1.5)
		var prog: float = w["progress"]
		if prog > 0.0:
			draw_arc(c, rr - 8.0, -PI / 2.0, -PI / 2.0 + TAU * prog, 40, Color(1.0, 0.85, 0.4, 0.95), 5.0, true)
		var hint: String = w["hint"]
		if hint != "":
			var hc := GameData.COL_SALVAGE if hint == "SALVAGING" else Color(1.0, 0.6, 0.4)
			_label(c + Vector2(0, -rr - 10.0), hint, hc)


func _draw_debris_fields() -> void:
	for f in debris_fields:
		var c: Vector2 = f["pos"]
		var r: float = f["radius"]
		draw_circle(c, r, Color(0.35, 0.22, 0.12, 0.05))
		var segs := 40
		for i in segs:
			if i % 2 == 0:
				var a0 := TAU * float(i) / float(segs)
				draw_arc(c, r, a0, a0 + TAU / float(segs), 4, Color(0.85, 0.55, 0.3, 0.28), 2.0)
		_label(c + Vector2(0, -r - 10.0), "WRECK FIELD", Color(0.95, 0.65, 0.4, 0.85))


func _draw_lightning_fields() -> void:
	for f in lightning_fields:
		var c: Vector2 = f["pos"]
		var r: float = f["radius"]
		var charge := 1.0 - clampf(float(f["timer"]) / 1.5, 0.0, 1.0)
		var flick := 0.5 + 0.5 * sin(time * 20.0)
		draw_circle(c, r, Color(0.9, 0.9, 0.5, 0.04 + 0.08 * charge))
		var segs := 36
		for i in segs:
			if i % 2 == 0:
				var a0 := TAU * float(i) / float(segs) - time * 0.2
				draw_arc(c, r, a0, a0 + TAU / float(segs), 4, Color(1.0, 0.95, 0.5, 0.3 + 0.5 * charge * flick), 2.0)
		_label(c + Vector2(0, -r - 10.0), "LIGHTNING FIELD" if charge <= 0.0 else "CHARGING", Color(1.0, 0.95, 0.55, 0.9))


func _draw_wards() -> void:
	for w in wards:
		var c: Vector2 = w["pos"]
		var r: float = w["radius"]
		var fade := clampf(float(w["life"]) / 1.0, 0.0, 1.0)
		draw_circle(c, r, Color(0.5, 1.0, 0.85, 0.05 * fade))
		draw_arc(c, r, 0.0, TAU, 40, Color(0.5, 1.0, 0.85, 0.5 * fade), 2.0, true)
		draw_circle(c, 9.0, Color(0.05, 0.2, 0.18))
		draw_arc(c, 9.0, 0.0, TAU, 16, Color(0.6, 1.0, 0.9), 2.0, true)
		draw_arc(c, 13.0, -PI / 2.0, -PI / 2.0 + TAU * float(w["life"]) / float(w["max"]), 20, Color(0.6, 1.0, 0.9, 0.8), 2.0, true)


func _draw_mines() -> void:
	var m_cfg := cfg("mine")
	var mr: float = m_cfg["radius"]
	var trigger: float = m_cfg["trigger"]
	var blast: float = m_cfg["blast"]
	for f in fields:
		var c: Vector2 = f["pos"]
		var fr: float = f["radius"]
		var segs := 28
		for i in segs:
			if i % 2 == 0:
				var a0 := TAU * float(i) / float(segs)
				draw_arc(c, fr, a0, a0 + TAU / float(segs), 4, Color(1.0, 0.45, 0.3, 0.35), 2.0)
		_label(c + Vector2(0, -fr - 10.0), "MINES", Color(1.0, 0.55, 0.4, 0.9))
	for m in mines:
		var p: Vector2 = m["pos"]
		if int(m.get("team", 1)) == 0:
			var ready_m := float(m["age"]) >= 0.8
			draw_circle(p, 10.0, Color(0.05, 0.2, 0.25))
			draw_arc(p, 10.0, 0.0, TAU, 16, Color(0.45, 0.95, 1.0), 2.0, true)
			draw_circle(p, 3.0, Color(0.6, 1.0, 1.0) if ready_m and int(time * 4.0) % 2 == 0 else Color(0.2, 0.5, 0.6))
			continue
		var armed := bool(m["armed"])
		var bob := sin(time * 2.0 + float(m["phase"])) * 1.5
		var mp := p + Vector2(0, bob)
		if armed:
			var fuse_max: float = m_cfg["fuse"]
			var prog := 1.0 - clampf(float(m["fuse"]) / fuse_max, 0.0, 1.0)
			draw_circle(p, blast * prog, Color(1.0, 0.3, 0.15, 0.15))
			draw_arc(p, blast, 0.0, TAU, 40, Color(1.0, 0.3, 0.2, 0.8), 2.5, true)
		else:
			draw_arc(p, trigger, 0.0, TAU, 32, Color(1.0, 0.45, 0.3, 0.14), 1.0, true)
		for k in 8:
			var d := Vector2.RIGHT.rotated(TAU * float(k) / 8.0 + float(m["phase"]))
			draw_line(mp + d * (mr - 2.0), mp + d * (mr + 6.0), Color(0.75, 0.35, 0.25), 2.0)
		var flash := armed and int(time * 12.0) % 2 == 0
		draw_circle(mp, mr, Color(0.6, 0.15, 0.1) if flash else Color(0.22, 0.07, 0.06))
		draw_arc(mp, mr, 0.0, TAU, 20, Color(1.0, 0.45, 0.3), 2.0, true)
		draw_circle(mp, 3.5, Color(1.0, 0.9, 0.6) if armed else Color(1.0, 0.5, 0.35))


func _draw_pickups() -> void:
	for pk in pickups:
		var p: Vector2 = pk["pos"]
		var blink := float(pk["life"]) > 4.0 or int(time * 8.0) % 2 == 0
		if not blink:
			continue
		var bob := sin(time * 3.0 + p.x) * 2.0
		var c := GameData.COL_ALLY if pk["kind"] == "repair" else GameData.COL_SALVAGE
		draw_rect(Rect2(p + Vector2(-8, -8 + bob), Vector2(16, 16)), Color(0.05, 0.1, 0.1))
		draw_rect(Rect2(p + Vector2(-8, -8 + bob), Vector2(16, 16)), c, false, 2.0)
		if pk["kind"] == "repair":
			draw_rect(Rect2(p + Vector2(-2, -6 + bob), Vector2(4, 12)), c)
			draw_rect(Rect2(p + Vector2(-6, -2 + bob), Vector2(12, 4)), c)
		else:
			draw_circle(p + Vector2(0, bob), 4.0, c)


func _draw_checkpoints() -> void:
	for i in range(cp_index, checkpoints.size()):
		var p: Vector2 = checkpoints[i]
		var current := i == cp_index
		var col := Color(0.5, 1.0, 0.9, 0.9 if current else 0.25)
		var r := 75.0 + (sin(time * 5.0) * 6.0 if current else 0.0)
		draw_arc(p, r, 0.0, TAU, 40, col, 3.0 if current else 1.5, true)
		_label(p + Vector2(0, -r - 8.0), str(i + 1), col)
		if i + 1 < checkpoints.size() and i < cp_index + 2:
			var q: Vector2 = checkpoints[i + 1]
			draw_line(p.move_toward(q, r), q.move_toward(p, 75.0), Color(0.5, 1.0, 0.9, 0.15), 2.0)


func _label(pos: Vector2, txt: String, col: Color) -> void:
	var p := pos - Vector2(150, 0)
	draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 15, 4, Color(0, 0.02, 0.05, 0.85))
	draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 15, col)

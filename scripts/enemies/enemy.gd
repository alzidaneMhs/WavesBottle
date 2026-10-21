class_name Enemy
extends Node2D

var run
var kind := ""
var data: Dictionary = {}
var hull := 10.0
var max_hull := 10.0
var radius := 14.0
var speed := 100.0
var accel := 100.0
var turn := 1.0
var velocity := Vector2.ZERO
var alive := true
var variants: Array = []
var elite := false
var veteran := false
var armored := false
var commander := false
var boss := false
var name_tag := ""
var named_id := ""
var side_gunned := false
var exposed := false
var slow_amount := 0.0
var slow_timer := 0.0
var harpoon_timer := 0.0
var hit_flash := 0.0
var smoke_timer := 0.0
var age := 0.0
var orbit_sign := 1.0
var cooldown := 0.0
var winding := false
var windup_damage := 0.0
var aura := false
var sunder_timer := 0.0
var grapple_timer := 0.0
var shield_mult := 1.0
var supply := false
var stormbound := false
var weather_boost := false
var marked := 0.0
var cloaked := false
var anchored := false
var resonant := false
var font: Font


func setup(p_run, p_kind: String, p_variants: Array, hull_mult: float) -> void:
	run = p_run
	kind = p_kind
	data = GameData.ENEMIES[kind]
	variants = p_variants.duplicate()
	elite = variants.has("elite")
	veteran = variants.has("veteran")
	armored = variants.has("armored")
	commander = variants.has("commander")
	stormbound = variants.has("stormbound")
	resonant = variants.has("resonant")
	var mult := hull_mult
	if elite:
		mult *= 1.6
	if commander:
		mult *= 1.3
	max_hull = float(data["hull"]) * mult
	hull = max_hull
	radius = float(data["radius"])
	speed = float(data["speed"]) * (1.08 if elite else 1.0) * (1.06 if veteran else 1.0)
	accel = float(data["accel"])
	turn = float(data["turn"])
	orbit_sign = 1.0 if run.rng.randf() < 0.5 else -1.0
	cooldown = run.rng.randf_range(1.2, 2.6)
	font = ThemeDB.fallback_font
	_on_setup()


func _on_setup() -> void:
	pass


func _think(_dt: float) -> void:
	pass


func _draw_ship() -> void:
	pass


func boss_title() -> String:
	return GameData.enemy_name(kind).to_upper()


func boss_status() -> String:
	return "EXPOSED  x1.5 DAMAGE" if exposed else ""


func phase_marks() -> Array:
	return [0.5]


func hidden() -> bool:
	return cloaked and not run.reveals(self)


func heavy() -> bool:
	return boss or radius >= 26.0


func forward() -> Vector2:
	return Vector2.RIGHT.rotated(rotation)


func slow_factor() -> float:
	var f := 1.0
	if slow_timer > 0.0:
		f *= 1.0 - slow_amount
	if harpoon_timer > 0.0:
		f *= 0.5
	return f


func target():
	return run.target_for(self)


func aim_point(t, shot_speed: float) -> Vector2:
	var tp: Vector2 = t.position
	if not veteran:
		return tp
	var tv: Vector2 = t.velocity
	var time := position.distance_to(tp) / maxf(1.0, shot_speed)
	return tp + tv * minf(time, 1.2)


func _physics_process(delta: float) -> void:
	if not alive or run == null:
		return
	if run.state == "ended":
		return
	var dt := minf(delta, 0.05)
	age += dt
	slow_timer = maxf(0.0, slow_timer - dt)
	harpoon_timer = maxf(0.0, harpoon_timer - dt)
	sunder_timer = maxf(0.0, sunder_timer - dt)
	grapple_timer = maxf(0.0, grapple_timer - dt)
	marked = maxf(0.0, marked - dt)
	hit_flash = maxf(0.0, hit_flash - dt)
	aura = run.commander_aura(self)
	shield_mult = run.shield_factor(self)
	var flow: Vector2 = run.hazards.flow_at(position)
	weather_boost = stormbound and (flow.length() > 30.0 or run.hazards.in_storm(position) or float(run.wind.strength) > 0.75)
	var rate: float = run.enemy_cd_rate * (1.33 if veteran else 1.0) * (1.3 if aura else 1.0) * (1.25 if weather_boost else 1.0) * (1.0 + 0.08 * float(run.wake.tier) if resonant else 1.0)
	cooldown -= dt * rate
	if not winding:
		windup_damage = 0.0
	_think(dt)
	if not alive:
		return
	if not stormbound and not anchored:
		position += flow * dt
	if grapple_timer > 0.0 and run.player != null and run.player.alive:
		var pull: Vector2 = (run.player.position as Vector2) - position
		if heavy():
			if pull.length() > radius + 60.0:
				run.player.velocity -= pull.normalized() * 260.0 * dt
		elif pull.length() > 110.0:
			position += pull.normalized() * 120.0 * dt
	if not anchored:
		_separate()
		run.arena.resolve_circle(self, 0.3)
	_contact_friendlies()
	if hull < max_hull * 0.5:
		smoke_timer -= dt
		if smoke_timer <= 0.0:
			smoke_timer = 0.12
			run.fx_over.burst(position + Vector2(randf_range(-6, 6), randf_range(-6, 6)), 1, 20.0, Color(0.35, 0.36, 0.4, 0.6), 1.2, 7.0)
	queue_redraw()


func steer_to_angle(target_angle: float, desired_speed: float, dt: float) -> void:
	var diff := wrapf(target_angle - rotation, -PI, PI)
	var turn_rate := turn * slow_factor()
	rotation = wrapf(rotation + clampf(diff, -turn_rate * dt, turn_rate * dt), -PI, PI)
	var fwd := forward()
	var right := fwd.rotated(PI / 2.0)
	var fs := velocity.dot(fwd)
	var ls := velocity.dot(right)
	var want := desired_speed * slow_factor() * (1.15 if aura else 1.0) * (1.2 if weather_boost else 1.0) * (1.0 + 0.04 * float(run.wake.tier) if resonant else 1.0)
	fs = move_toward(fs, want, accel * dt)
	ls *= exp(-3.0 * dt)
	velocity = fwd * fs + right * ls
	position += velocity * dt


func steer_to_point(p: Vector2, desired_speed: float, dt: float) -> void:
	steer_to_angle((p - position).angle(), desired_speed, dt)


func _separate() -> void:
	for o in run.enemies:
		if o == self or not o.alive or o.anchored:
			continue
		var d: Vector2 = position - o.position
		var min_d: float = radius + float(o.radius) + 6.0
		var l := d.length()
		if l < min_d and l > 0.01:
			var w := 0.15 if boss else (0.85 if o.boss else 0.5)
			position += d / l * (min_d - l) * w


func _contact_friendlies() -> void:
	for f in run.friendlies:
		if not f.alive or not f.physical:
			continue
		var d: Vector2 = position - (f.position as Vector2)
		var min_d: float = radius + float(f.radius)
		var l := d.length()
		if l >= min_d or l < 0.01:
			continue
		var n := d / l
		var overlap := min_d - l
		var fv: Vector2 = f.velocity
		var rel := (fv - velocity).length()
		var ratio := 0.85 if boss else 0.5
		if f != run.player:
			ratio = 0.2
		position += n * overlap * (1.0 - ratio)
		f.position -= n * overlap * ratio
		if f == run.player:
			var p: PlayerShip = run.player
			var into := p.velocity.dot(n)
			if into > 0.0:
				p.velocity -= n * into * (1.0 + 0.5 * p.stats.get_value("collision_mult"))
		on_contact(f, rel)


func on_contact(f, rel: float) -> void:
	if f == run.player:
		var p: PlayerShip = run.player
		p.ram(self, rel, float(data["contact"]))
	elif rel > 60.0 or float(data["contact"]) > 0.0:
		f.take_damage(float(data["contact"]) * 0.05, "Ramming", position)
	if rel > 90.0 and not boss:
		take_damage(5.0 * clampf(rel / 200.0, 0.6, 1.5))


func apply_slow(amount: float, duration: float) -> void:
	if boss:
		amount *= 0.5
		duration *= 0.5
	elif elite:
		duration *= 0.7
	var current := slow_amount if slow_timer > 0.0 else 0.0
	slow_amount = maxf(current, amount)
	slow_timer = minf(maxf(slow_timer, duration), 3.0)


func apply_harpoon(duration: float) -> void:
	if boss:
		duration *= 0.4
	harpoon_timer = minf(maxf(harpoon_timer, duration), 6.0)


func is_crossing(origin: Vector2) -> bool:
	var to := origin - position
	if to.length() > 900.0 or to.length() < 1.0:
		return false
	var d := forward().dot(to.normalized())
	if side_gunned:
		return absf(d) > 0.82
	return d < -0.82


func damage_factor(_origin: Vector2) -> float:
	return 1.0


func receive_shot(s) -> void:
	if not alive:
		return
	if s.status == "slow":
		apply_slow(s.status_a, s.status_t)
	elif s.status == "harpoon":
		apply_harpoon(s.status_t)
		run.fx_over.text(position + Vector2(0, -radius - 20.0), "HARPOONED", Color(0.6, 1.0, 0.8), 14, 0.8)
	elif s.status == "sunder":
		sunder_timer = maxf(sunder_timer, s.status_t)
		run.fx_over.text(position + Vector2(0, -radius - 20.0), "SUNDERED", Color(1.0, 0.75, 0.4), 14, 0.8)
	elif s.status == "grapple":
		grapple_timer = maxf(grapple_timer, s.status_t * (0.5 if boss else 1.0))
		run.fx_over.text(position + Vector2(0, -radius - 20.0), "GRAPPLED", Color(0.6, 1.0, 0.8), 14, 0.8)
	receive_hit(s.damage, s.origin, s.armor_pierce, s.weapon, s.pos)


func receive_hit(dmg: float, origin: Vector2, armor_pierce: bool, weapon: String = "", at: Vector2 = Vector2.INF) -> void:
	if not alive:
		return
	if at == Vector2.INF:
		at = position
	var crossed := is_crossing(origin)
	if crossed:
		dmg *= 1.25
	if run.stats.ability == "side_slip" and weapon not in ["mine", "test"]:
		if marked > 0.0:
			marked = 0.0
			dmg *= 1.4 + run.stats.get_value("mark_bonus")
			run.fx_over.text(at + Vector2(0, -44), "MARK BROKEN", Color(0.55, 0.75, 1.0), 15, 0.8)
		elif crossed:
			marked = 4.0
			run.fx_over.text(at + Vector2(0, -44), "MARKED", Color(0.55, 0.75, 1.0), 15, 0.8)
	if exposed:
		dmg *= 1.5
	var weak := false
	if sunder_timer > 0.0:
		dmg *= 1.25
	if armored and not exposed:
		if armor_pierce or sunder_timer > 0.0:
			weak = true
		else:
			dmg *= 0.6
	if shield_mult < 1.0:
		dmg *= shield_mult
		run.fx_over.ring(at, 18.0, 0.25, Color(0.5, 0.8, 1.0, 0.8), 2.0)
	if run.scanner_timer > 0.0:
		dmg *= 1.0 + run.scanner_bonus
		weak = true
	dmg *= damage_factor(origin)
	run.fx_over.burst(at, 6, 110.0, Color(1.0, 0.8, 0.5), 0.35, 2.5)
	Sound.play("impact", at, -7.0, randf_range(0.9, 1.15))
	run.on_enemy_hit(self, dmg, crossed, at, weak and armor_pierce)
	if winding:
		windup_damage += dmg * (2.0 if weapon == "overload" else 1.0)
		if windup_damage >= float(data.get("interrupt", 9999.0)):
			winding = false
			windup_damage = 0.0
			interrupt()
			run.on_interrupt(self)
	take_damage(dmg)


func interrupt() -> void:
	pass


func take_damage(dmg: float) -> void:
	if not alive:
		return
	hull -= dmg
	hit_flash = 0.12
	if hull <= 0.0:
		die()


func die() -> void:
	if not alive:
		return
	alive = false
	if stormbound:
		run.shots.add_mortar(position, 1.2, 70.0, 12.0, "Lightning", true)
	run.fx_over.explosion(position, radius * 2.2)
	Sound.play("explosion", position, 2.0 if boss else -3.0, 0.8 if boss else 1.0)
	run.add_shake(6.0 if not boss else 18.0)
	run.on_enemy_killed(self)
	queue_free()


func fire_shot(from: Vector2, dir: Vector2, shot_speed: float, damage: float, reach: float, shot_radius: float = 5.0) -> void:
	run.shots.spawn(1, from, dir * shot_speed + velocity * 0.3, reach / shot_speed, damage, "enemy", from, shot_radius, GameData.COL_ENEMY_SHOT, GameData.enemy_name(kind))


func hull_points(length: float, width: float) -> PackedVector2Array:
	var l := length * 0.5
	var w := width * 0.5
	return PackedVector2Array([Vector2(l, 0), Vector2(l * 0.45, -w), Vector2(-l * 0.8, -w), Vector2(-l, -w * 0.6), Vector2(-l, w * 0.6), Vector2(-l * 0.8, w), Vector2(l * 0.45, w)])


func draw_hull(length: float, width: float, body: Color, outline: Color) -> void:
	var pts := hull_points(length, width)
	if hit_flash > 0.0 and not SaveData.reduce_flash():
		body = body.lerp(Color(1.0, 0.9, 0.8), 0.6)
	draw_colored_polygon(pts, body)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, outline, 2.0, true)
	if armored:
		var l := length * 0.5
		var w := width * 0.5
		draw_line(Vector2(-l * 0.7, -w - 2.0), Vector2(l * 0.4, -w - 2.0), Color(0.75, 0.8, 0.85), 3.0)
		draw_line(Vector2(-l * 0.7, w + 2.0), Vector2(l * 0.4, w + 2.0), Color(0.75, 0.8, 0.85), 3.0)


func draw_side_lanes(side: float, offsets: Array, reach: float, progress: float, fan: float = 0.0) -> void:
	var col := Color(GameData.COL_WARN, 0.18 + 0.5 * progress)
	var n := offsets.size()
	for i in n:
		var x: float = offsets[i]
		var ang := 0.0
		if fan > 0.0 and n > 1:
			ang = lerpf(fan, -fan, float(i) / float(n - 1)) * side
		var start := Vector2(x, side * radius)
		var dir := Vector2(0, side).rotated(ang)
		draw_line(start, start + dir * reach * (0.3 + 0.7 * progress), col, 2.0)
	var a := Vector2(float(offsets[0]), side * radius)
	var b := Vector2(float(offsets[n - 1]), side * radius)
	var poly := PackedVector2Array([a, b, b + Vector2(0, side * reach).rotated(-fan * side), a + Vector2(0, side * reach).rotated(fan * side)])
	draw_colored_polygon(poly, Color(GameData.COL_WARN, 0.06 + 0.1 * progress))


func draw_forward_lane(length: float, width: float, progress: float) -> void:
	var col := Color(GameData.COL_WARN, 0.12 + 0.18 * progress)
	var poly := PackedVector2Array([Vector2(radius, -width), Vector2(radius + length, -width), Vector2(radius + length, width), Vector2(radius, width)])
	draw_colored_polygon(poly, col)
	draw_line(Vector2(radius, -width), Vector2(radius + length * (0.3 + 0.7 * progress), -width), Color(GameData.COL_WARN, 0.7), 2.0)
	draw_line(Vector2(radius, width), Vector2(radius + length * (0.3 + 0.7 * progress), width), Color(GameData.COL_WARN, 0.7), 2.0)


func _draw() -> void:
	if not alive:
		return
	if hidden():
		var hp := fposmod(age * 0.66, 1.0)
		draw_arc(Vector2.ZERO, radius + 4.0 + hp * 10.0, 0.0, TAU, 20, Color(0.5, 0.9, 1.0, 0.12 * (1.0 - hp)), 1.5, true)
		return
	if (harpoon_timer > 0.0 or grapple_timer > 0.0) and run.player != null and run.player.alive:
		draw_line(Vector2.ZERO, to_local(run.player.position), Color(0.6, 1.0, 0.8, 0.45 if grapple_timer <= 0.0 else 0.8), 1.5 if grapple_timer <= 0.0 else 2.5)
	_draw_ship()
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	if commander:
		var segs := 24
		for i in segs:
			if i % 2 == 0:
				var a0 := TAU * float(i) / float(segs) + age * 0.3
				draw_arc(Vector2.ZERO, 280.0, a0, a0 + TAU / float(segs), 6, Color(1.0, 0.6, 0.3, 0.22), 1.5)
		draw_line(Vector2(0, -radius - 4.0), Vector2(0, -radius - 26.0), Color(1.0, 0.6, 0.3), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -radius - 26.0), Vector2(12, -radius - 21.0), Vector2(0, -radius - 16.0)]), Color(1.0, 0.6, 0.3))
	if elite:
		draw_arc(Vector2.ZERO, radius + 9.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.3, 0.7), 1.5, true)
		var dpos := Vector2(0, -radius - 22.0)
		draw_colored_polygon(PackedVector2Array([dpos + Vector2(0, -5), dpos + Vector2(5, 0), dpos + Vector2(0, 5), dpos + Vector2(-5, 0)]), Color(1.0, 0.85, 0.3))
	if veteran:
		var vp := Vector2(-radius - 12.0, -radius - 10.0)
		draw_polyline(PackedVector2Array([vp + Vector2(-5, -3), vp, vp + Vector2(5, -3)]), Color(0.9, 0.6, 1.0), 2.0)
		draw_polyline(PackedVector2Array([vp + Vector2(-5, 1), vp + Vector2(0, 4), vp + Vector2(5, 1)]), Color(0.9, 0.6, 1.0), 2.0)
	if run.scanner_timer > 0.0:
		var rr := radius + 6.0
		var c := Color(0.6, 1.0, 0.9, 0.8)
		for k in 4:
			var a := PI / 2.0 * float(k) + age
			draw_arc(Vector2.ZERO, rr, a - 0.3, a + 0.3, 6, c, 2.0)
	if slow_timer > 0.0:
		draw_arc(Vector2.ZERO, radius + 5.0, -PI / 2.0, -PI / 2.0 + TAU * (slow_timer / 3.0), 28, Color(1.0, 0.78, 0.3, 0.9), 2.5, true)
	if shield_mult < 1.0:
		var sp := 0.5 + 0.5 * sin(age * 4.0)
		draw_arc(Vector2.ZERO, radius + 12.0, 0.0, TAU, 36, Color(0.5, 0.8, 1.0, 0.35 + 0.25 * sp), 2.5, true)
		draw_circle(Vector2.ZERO, radius + 12.0, Color(0.4, 0.7, 1.0, 0.05 + 0.04 * sp))
	if resonant:
		var rpl := fposmod(age * (0.6 + 0.15 * float(run.wake.tier)), 1.0)
		draw_arc(Vector2.ZERO, radius + 6.0 + rpl * 14.0, 0.0, TAU, 24, Color(1.0, 0.5, 0.85, 0.5 * (1.0 - rpl)), 2.0, true)
	if stormbound:
		var sp2 := 0.5 + 0.5 * sin(age * 9.0)
		for k in 4:
			var a1 := TAU * float(k) / 4.0 + age * 1.5
			var p0 := Vector2.RIGHT.rotated(a1) * (radius + 5.0)
			var p1 := Vector2.RIGHT.rotated(a1 + 0.25) * (radius + 12.0)
			draw_line(p0, p1, Color(0.6, 0.8, 1.0, 0.4 + 0.5 * sp2 if weather_boost else 0.35), 2.0)
	if marked > 0.0:
		draw_arc(Vector2.ZERO, radius + 16.0, 0.0, TAU, 4, Color(0.55, 0.75, 1.0, 0.9), 2.0)
	if sunder_timer > 0.0:
		for k in 3:
			var a0 := -PI / 2.0 + TAU * float(k) / 3.0 + age * 2.0
			draw_line(Vector2.RIGHT.rotated(a0) * (radius + 3.0), Vector2.RIGHT.rotated(a0) * (radius + 11.0), Color(1.0, 0.7, 0.35, 0.9), 2.5)
	if not boss and hull < max_hull:
		var w := radius * 2.4
		var top := Vector2(-w * 0.5, -radius - 14.0)
		draw_rect(Rect2(top, Vector2(w, 4)), Color(0.0, 0.0, 0.0, 0.6))
		draw_rect(Rect2(top, Vector2(w * clampf(hull / max_hull, 0.0, 1.0), 4)), Color(1.0, 0.4, 0.3))
	if name_tag != "":
		var tp := Vector2(-120, radius + 26.0)
		draw_string_outline(font, tp, name_tag, HORIZONTAL_ALIGNMENT_CENTER, 240.0, 15, 4, Color(0, 0, 0, 0.8))
		draw_string(font, tp, name_tag, HORIZONTAL_ALIGNMENT_CENTER, 240.0, 15, Color(1.0, 0.85, 0.4))
	_draw_overlay()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_overlay() -> void:
	pass

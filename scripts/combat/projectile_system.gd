class_name ProjectileSystem
extends Node2D

const MAX_SHOTS := 700


class Shot:
	var team := 0
	var pos := Vector2.ZERO
	var prev := Vector2.ZERO
	var vel := Vector2.ZERO
	var life := 0.0
	var max_life := 1.0
	var damage := 0.0
	var kind := "round"
	var origin := Vector2.ZERO
	var radius := 4.0
	var color := Color.WHITE
	var min_dist := 99999.0
	var source := ""
	var spin := 0.0
	var armor_pierce := false
	var weapon := ""
	var status := ""
	var status_a := 0.0
	var status_t := 0.0
	var blast := 0.0
	var pierce := 0
	var homing := 0.0
	var hit_list: Array = []
	var owner_ref = null
	var spark := false


var run
var active: Array = []
var pool: Array = []
var markers: Array = []
var updating := false
var clear_requested := false


func spawn(team: int, pos: Vector2, vel: Vector2, life: float, damage: float, kind: String, origin: Vector2, radius: float, color: Color, source: String = "") -> Shot:
	if active.size() >= MAX_SHOTS:
		return null
	var s: Shot
	if pool.is_empty():
		s = Shot.new()
	else:
		s = pool.pop_back()
	s.team = team
	s.pos = pos
	s.prev = pos
	s.vel = vel
	s.life = life
	s.max_life = life
	s.damage = damage
	s.kind = kind
	s.origin = origin
	s.radius = radius
	s.color = color
	s.min_dist = 99999.0
	s.source = source
	s.spin = randf() * TAU
	s.armor_pierce = false
	s.weapon = ""
	s.status = ""
	s.status_a = 0.0
	s.status_t = 0.0
	s.blast = 0.0
	s.pierce = 0
	s.homing = 0.0
	s.hit_list = []
	s.owner_ref = null
	s.spark = false
	active.append(s)
	return s


func add_mortar(pos: Vector2, delay: float, blast: float, damage: float, source: String = "Mortar", lightning: bool = false, team: int = 1, spare: bool = false) -> void:
	markers.append({"pos": pos, "time": delay, "max": delay, "radius": blast, "damage": damage, "source": source, "lightning": lightning, "team": team, "spare": spare})


func clear_enemy_fire() -> void:
	var kept: Array = []
	for m in markers:
		if int(m.get("team", 1)) == 0:
			kept.append(m)
	markers = kept
	if updating:
		clear_requested = true
		return
	_remove_enemy_shots()


func clear_enemy_near(pos: Vector2, r: float, cap: int = 9999) -> int:
	var n := 0
	for s in active:
		if n >= cap:
			break
		var sh: Shot = s
		if sh.team == 1 and sh.life > 0.0 and sh.pos.distance_to(pos) <= r:
			sh.life = -100.0
			run.fx_over.burst(sh.pos, 3, 60.0, Color(1.0, 0.85, 0.5), 0.25, 2.0)
			n += 1
	return n


func _remove_enemy_shots() -> void:
	var kept: Array = []
	for s in active:
		var sh: Shot = s
		if sh.team == 1:
			pool.append(sh)
		else:
			kept.append(sh)
	active = kept


func _physics_process(delta: float) -> void:
	if run == null:
		return
	if run.state == "ended":
		queue_redraw()
		return
	var dt := minf(delta, 0.05)
	var player: PlayerShip = run.player
	updating = true
	var current: Array = active
	active = []
	for item in current:
		var s: Shot = item
		if (clear_requested and s.team == 1) or s.life <= -50.0:
			pool.append(s)
			continue
		s.prev = s.pos
		if s.homing > 0.0 and s.team == 0:
			_steer(s, dt)
		s.pos += s.vel * dt
		s.life -= dt
		s.spin += dt * 14.0
		var done := false
		if s.team == 0:
			for e in run.enemies:
				if not e.alive or s.hit_list.has(e) or e.hidden():
					continue
				var cp := Geometry2D.get_closest_point_to_segment(e.position, s.prev, s.pos)
				if cp.distance_to(e.position) <= float(e.radius) + s.radius:
					e.receive_shot(s)
					run.on_shot_result(true)
					if s.blast > 0.0:
						_splash(s, e)
					if s.spark:
						_spark(s, e)
					if s.pierce > 0:
						s.pierce -= 1
						s.hit_list.append(e)
						s.damage *= 0.8
						run.fx_over.burst(cp, 6, 140.0, Color(0.7, 0.9, 1.0), 0.3, 2.5, s.vel.normalized(), 0.5)
						continue
					s.pos = cp
					done = true
					break
			if not done and run.hazards.shot_hits_mine(s.prev, s.pos, s.radius):
				run.on_shot_result(true)
				done = true
		else:
			for f in run.friendlies:
				if not f.alive:
					continue
				var cp2 := Geometry2D.get_closest_point_to_segment(f.position, s.prev, s.pos)
				var dist := cp2.distance_to(f.position)
				if f == player:
					s.min_dist = minf(s.min_dist, dist)
				if dist <= float(f.radius) + s.radius:
					f.take_damage(s.damage, s.source, s.pos - s.vel.normalized() * 30.0)
					if s.status == "tether" and f == player and is_instance_valid(s.owner_ref):
						player.apply_tether(s.owner_ref, s.status_t)
					done = true
					break
		if not done and run.arena.point_blocked(s.pos):
			run.fx_under.burst(s.pos, 5, 60.0, Color(0.6, 0.8, 0.9), 0.4, 2.5)
			Sound.play("impact", s.pos, -12.0, 1.3)
			if s.team == 0:
				run.on_shot_result(false)
			done = true
		if not done and (s.life <= 0.0 or not run.arena.rect.has_point(s.pos)):
			run.fx_under.burst(s.pos, 4, 50.0, Color(0.55, 0.75, 0.9, 0.8), 0.45, 2.5)
			run.fx_under.ring(s.pos, 14.0, 0.5, Color(0.6, 0.85, 1.0, 0.5), 1.5)
			if s.team == 0:
				run.on_shot_result(false)
			elif player.alive and s.min_dist < player.radius + 34.0:
				run.on_close_dodge(s.pos)
			done = true
		if done:
			pool.append(s)
		else:
			active.append(s)
	updating = false
	if clear_requested:
		clear_requested = false
		_remove_enemy_shots()
	_update_markers(dt, player)
	queue_redraw()


func _spark(s: Shot, hit) -> void:
	var best = null
	var bd := 170.0
	for e in run.enemies:
		if e == hit or not e.alive or e.hidden():
			continue
		var d: float = (e.position as Vector2).distance_to(s.pos)
		if d < bd:
			bd = d
			best = e
	if best == null:
		return
	run.fx_over.bolt(s.pos, best.position, Color(1.0, 0.6, 0.9))
	best.receive_hit(6.0, s.origin, false, "spark")


func _steer(s: Shot, dt: float) -> void:
	var best = null
	var bd := 620.0
	var dir := s.vel.normalized()
	for e in run.enemies:
		if not e.alive:
			continue
		var to: Vector2 = (e.position as Vector2) - s.pos
		var d := to.length()
		if d < bd and d > 1.0 and dir.dot(to / d) > 0.2:
			bd = d
			best = e
	if best == null:
		return
	var want: float = ((best.position as Vector2) - s.pos).angle()
	var cur := s.vel.angle()
	var diff := wrapf(want - cur, -PI, PI)
	var turn := clampf(diff, -s.homing * dt, s.homing * dt)
	s.vel = s.vel.rotated(turn)


func _splash(s: Shot, direct) -> void:
	run.fx_over.explosion(s.pos, s.blast)
	Sound.play("explosion", s.pos, -4.0, 1.1)
	for e in run.enemies.duplicate():
		if e == direct or not is_instance_valid(e) or not e.alive:
			continue
		if (e.position as Vector2).distance_to(s.pos) <= s.blast + float(e.radius):
			e.receive_hit(s.damage * 0.6, s.origin, true, s.weapon)


func _update_markers(dt: float, player: PlayerShip) -> void:
	var due: Array = []
	var waiting: Array = []
	for item in markers:
		var m: Dictionary = item
		m["time"] = float(m["time"]) - dt
		if float(m["time"]) <= 0.0:
			due.append(m)
		else:
			waiting.append(m)
	markers = waiting
	for item in due:
		var m: Dictionary = item
		var p: Vector2 = m["pos"]
		var r: float = m["radius"]
		var team: int = int(m.get("team", 1))
		var lightning := bool(m.get("lightning", false))
		if lightning:
			run.fx_over.burst(p, 16, 220.0, Color(0.85, 0.95, 1.0), 0.35, 3.0)
			run.fx_over.ring(p, r, 0.35, Color(1.0, 1.0, 0.8, 0.9), 3.0)
			if not SaveData.reduce_flash():
				run.fx_over.flashes.append({"pos": p, "radius": r * 1.2, "life": 0.15, "max": 0.15})
			Sound.play("impact", p, 0.0, 0.6)
			Sound.play("explosion", p, -8.0, 1.8)
		else:
			run.fx_over.explosion(p, r)
			Sound.play("explosion", p, -4.0, 1.2)
		run.add_shake(5.0 if team == 1 else 2.5)
		if team == 1 or lightning:
			for f in run.friendlies:
				if not f.alive:
					continue
				var d: float = (f.position as Vector2).distance_to(p)
				if d <= r + float(f.radius) * 0.5:
					f.take_damage(float(m["damage"]), str(m.get("source", "Mortar")), p)
				elif f == player and d <= r + 60.0:
					run.on_close_dodge(player.position)
		if team == 0 or (lightning and not bool(m.get("spare", false))):
			for e in run.enemies.duplicate():
				if is_instance_valid(e) and e.alive and p.distance_to(e.position) <= r + float(e.radius):
					if team == 0:
						e.receive_hit(float(m["damage"]), run.player.position, false, "mortar")
					else:
						e.take_damage(float(m["damage"]))


func _draw() -> void:
	for m in markers:
		var p: Vector2 = m["pos"]
		var r: float = m["radius"]
		var prog := 1.0 - float(m["time"]) / float(m["max"])
		var lit := bool(m.get("lightning", false))
		var mine := int(m.get("team", 1)) == 0
		var fill := Color(1.0, 0.95, 0.4, 0.16) if lit else Color(1.0, 0.25, 0.2, 0.16)
		var rim := Color(1.0, 0.95, 0.5, 0.9) if lit else Color(1.0, 0.3, 0.25, 0.85)
		var inner := Color(1.0, 1.0, 0.8, 0.6) if lit else Color(1.0, 0.6, 0.4, 0.6)
		if mine:
			fill = Color(0.4, 0.9, 1.0, 0.1)
			rim = Color(0.45, 0.95, 1.0, 0.7)
			inner = Color(0.7, 1.0, 1.0, 0.5)
		draw_circle(p, r * prog, fill)
		draw_arc(p, r, 0.0, TAU, 40, rim, 2.0, true)
		draw_arc(p, r * prog, 0.0, TAU, 40, inner, 1.5, true)
		if lit:
			var bolt := PackedVector2Array([p + Vector2(-4, -12), p + Vector2(3, -2), p + Vector2(-3, 1), p + Vector2(4, 12)])
			draw_polyline(bolt, rim, 2.5)
		else:
			draw_line(p + Vector2(-10, 0), p + Vector2(10, 0), rim, 2.0)
			draw_line(p + Vector2(0, -10), p + Vector2(0, 10), rim, 2.0)
	for s in active:
		var sh: Shot = s
		var tail := sh.vel.normalized() * (8.0 + sh.radius * 2.0)
		if sh.team == 0:
			if sh.kind == "torpedo":
				draw_line(sh.pos - tail * 3.0, sh.pos, Color(0.5, 1.0, 0.9, 0.35), 3.0)
				draw_circle(sh.pos, sh.radius, Color(0.2, 0.5, 0.5))
				draw_arc(sh.pos, sh.radius, 0.0, TAU, 12, sh.color, 2.0)
				continue
			draw_line(sh.pos - tail, sh.pos, Color(sh.color, 0.45), sh.radius * 1.2)
			if sh.status == "slow":
				var off := Vector2(5, 0).rotated(sh.spin)
				draw_line(sh.pos - off, sh.pos + off, Color(0.9, 0.8, 0.6), 1.5)
				draw_circle(sh.pos - off, 3.0, sh.color)
				draw_circle(sh.pos + off, 3.0, sh.color)
			elif sh.status == "harpoon":
				draw_line(sh.pos, sh.origin.lerp(sh.pos, 0.85), Color(0.6, 1.0, 0.8, 0.35), 1.0)
				draw_circle(sh.pos, sh.radius, sh.color)
			else:
				draw_circle(sh.pos, sh.radius, sh.color)
		elif sh.status == "tether":
			draw_line(sh.origin, sh.pos, Color(0.5, 1.0, 0.7, 0.35), 1.5)
			draw_circle(sh.pos, sh.radius + 2.0, Color(0.5, 1.0, 0.7, 0.4))
			draw_circle(sh.pos, sh.radius, Color(0.75, 1.0, 0.85))
		else:
			draw_line(sh.pos - tail * 1.4, sh.pos, Color(1.0, 0.35, 0.1, 0.4), sh.radius * 1.4)
			draw_circle(sh.pos, sh.radius + 3.0, Color(1.0, 0.3, 0.1, 0.35))
			draw_circle(sh.pos, sh.radius, GameData.COL_ENEMY_SHOT)
			draw_circle(sh.pos, sh.radius * 0.45, Color(1.0, 0.95, 0.8))

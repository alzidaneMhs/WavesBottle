class_name Fireship
extends Enemy

var armed := false
var fuse := 0.0
var tick := 0.0
var flame_timer := 0.0


func _on_setup() -> void:
	side_gunned = false


func blast_radius() -> float:
	return float(data["blast"])


func _think(dt: float) -> void:
	var t = target()
	var tp: Vector2 = t.position
	var tv: Vector2 = t.velocity
	var dist := position.distance_to(tp)
	flame_timer -= dt
	if flame_timer <= 0.0:
		flame_timer = 0.06
		run.fx_over.burst(position - forward() * radius, 1, 30.0, Color(1.0, 0.55, 0.2, 0.8), 0.5, 4.0)
	if not armed:
		steer_to_point(tp + tv * 0.4, speed, dt)
		if t.alive and dist < blast_radius() * 0.8 + float(t.radius):
			arm()
		return
	fuse -= dt
	tick -= dt
	if tick <= 0.0:
		tick = 0.22
		Sound.play("fuse", position, -6.0)
	steer_to_point(tp, speed * 0.45, dt)
	if fuse <= 0.0:
		detonate()


func arm() -> void:
	if armed:
		return
	armed = true
	fuse = float(data["fuse"])
	Sound.play("warning", position, -4.0, 1.3)


func on_contact(_f, _rel: float) -> void:
	if not armed:
		arm()
	fuse = minf(fuse, 0.3)


func die() -> void:
	if not alive:
		return
	alive = false
	_blast(false)
	run.on_enemy_killed(self)
	queue_free()


func detonate() -> void:
	if not alive:
		return
	alive = false
	_blast(true)
	run.on_enemy_expended(self)
	queue_free()


func _blast(hurt_friendly: bool) -> void:
	var r := blast_radius()
	run.fx_over.explosion(position, r)
	Sound.play("explosion", position, 0.0, 0.9)
	run.add_shake(10.0)
	if hurt_friendly:
		for f in run.friendlies:
			if not f.alive:
				continue
			var d := position.distance_to(f.position)
			if d <= r + float(f.radius) * 0.5:
				f.take_damage(float(data["damage"]), "Fireship blast", position)
			elif f == run.player and d <= r + 70.0:
				run.on_close_dodge(run.player.position)
	for e in run.enemies.duplicate():
		if e == self or not is_instance_valid(e) or not e.alive:
			continue
		if position.distance_to(e.position) <= r + float(e.radius):
			run.blast_credit = true
			e.take_damage(float(data["damage"]))
			run.blast_credit = false


func _draw_ship() -> void:
	var r := blast_radius()
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	if armed:
		var prog := 1.0 - clampf(fuse / float(data["fuse"]), 0.0, 1.0)
		var pulse := 0.5 + 0.5 * sin(age * 28.0)
		draw_circle(Vector2.ZERO, r * prog, Color(1.0, 0.3, 0.15, 0.12 + 0.1 * pulse))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 0.3, 0.2, 0.6 + 0.4 * pulse), 3.0, true)
	else:
		var segs := 16
		for i in segs:
			if i % 2 == 0:
				var a0 := TAU * float(i) / float(segs) + age * 0.6
				draw_arc(Vector2.ZERO, r, a0, a0 + TAU / float(segs), 6, Color(1.0, 0.45, 0.25, 0.22), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var body := Color(0.25, 0.08, 0.03)
	if armed and int(age * 12.0) % 2 == 0:
		body = Color(0.6, 0.2, 0.05)
	draw_hull(34.0, 16.0, body, Color(1.0, 0.6, 0.2))
	draw_circle(Vector2(0, 0), 5.0, Color(1.0, 0.6, 0.2, 0.9))
	draw_circle(Vector2(0, 0), 2.5, Color(1.0, 0.95, 0.7))

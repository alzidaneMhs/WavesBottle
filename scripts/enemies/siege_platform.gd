class_name SiegePlatform
extends Enemy

var windup := 0.0
var life := 22.0
var aim_dir := Vector2.RIGHT


func _on_setup() -> void:
	side_gunned = false
	life = float(data["life"])
	cooldown = run.rng.randf_range(1.0, 1.8)


func _think(dt: float) -> void:
	life -= dt
	velocity = Vector2.ZERO
	if life <= 0.0:
		_scuttle()
		return
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	if windup > 0.0:
		windup -= dt
		if windup <= 0.0:
			winding = false
			_fire()
			cooldown = float(data["cooldown"]) * run.rng.randf_range(0.9, 1.1)
		return
	var want := to.angle()
	var diff := wrapf(want - rotation, -PI, PI)
	rotation = wrapf(rotation + clampf(diff, -turn * slow_factor() * dt, turn * slow_factor() * dt), -PI, PI)
	if cooldown <= 0.0 and dist < float(data["range"]) and absf(diff) < 0.12 and t.alive:
		windup = float(data["windup"])
		winding = true
		aim_dir = forward()


func _fire() -> void:
	for k in [-1.0, 1.0]:
		var dir := aim_dir.rotated(0.05 * float(k))
		fire_shot(position + aim_dir * radius + aim_dir.rotated(PI / 2.0) * 5.0 * float(k), dir, 420.0, float(data["damage"]), float(data["range"]) + 40.0, 5.0)
	Sound.play("enemy_cannon", position, -6.0, 1.1)
	run.fx_over.burst(position + aim_dir * (radius + 4.0), 4, 80.0, Color(1.0, 0.7, 0.4), 0.3, 3.0, aim_dir, 0.6)


func interrupt() -> void:
	windup = 0.0
	cooldown = float(data["cooldown"]) * 0.7
	run.fx_over.text(position + Vector2(0, -30), "JAMMED", Color(0.6, 1.0, 0.9), 14, 0.8)


func _scuttle() -> void:
	if not alive:
		return
	alive = false
	run.fx_over.explosion(position, radius * 1.6)
	Sound.play("splash", position, -4.0, 0.7)
	run.on_enemy_expended(self)
	queue_free()


func _draw_ship() -> void:
	if windup > 0.0:
		var prog := 1.0 - clampf(windup / float(data["windup"]), 0.0, 1.0)
		draw_forward_lane(float(data["range"]) * 0.6, 10.0, prog)
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	var pts := PackedVector2Array()
	for i in 6:
		pts.append(Vector2.RIGHT.rotated(TAU * float(i) / 6.0) * radius)
	var body := Color(0.16, 0.12, 0.10)
	if hit_flash > 0.0 and not SaveData.reduce_flash():
		body = body.lerp(Color(1.0, 0.9, 0.8), 0.6)
	draw_colored_polygon(pts, body)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, GameData.COL_ENEMY, 2.0, true)
	var frac := clampf(life / float(data["life"]), 0.0, 1.0)
	draw_arc(Vector2.ZERO, radius + 4.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 24, Color(1.0, 0.6, 0.4, 0.5), 1.5, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 7.0, Color(0.5, 0.4, 0.33))
	draw_line(Vector2.ZERO, Vector2(radius + 6.0, 0), Color(1.0, 0.6, 0.4) if windup > 0.0 else Color(0.75, 0.6, 0.5), 4.0)

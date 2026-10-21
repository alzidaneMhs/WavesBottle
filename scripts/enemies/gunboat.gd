class_name Gunboat
extends Enemy

var windup := 0.0


func _on_setup() -> void:
	side_gunned = false


func _think(dt: float) -> void:
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	var dirn := to.normalized() if dist > 0.01 else Vector2.RIGHT
	if windup > 0.0:
		windup -= dt
		steer_to_point(tp, speed * 0.55, dt)
		if windup <= 0.0:
			winding = false
			_fire(t)
		return
	var tangent := dirn.rotated(PI / 2.0 * orbit_sign)
	var goal := tp - dirn * 250.0 + tangent * 170.0
	steer_to_point(goal, speed, dt)
	var facing := forward().dot(dirn)
	if cooldown <= 0.0 and dist < float(data["range"]) and facing > 0.85 and t.alive:
		windup = 0.4
		winding = true


func interrupt() -> void:
	windup = 0.0
	cooldown = float(data["cooldown"]) * 0.6
	run.fx_over.text(position + Vector2(0, -30), "STALLED", Color(0.6, 1.0, 0.9), 14, 0.8)


func _fire(t) -> void:
	var fwd := forward()
	var to := (aim_point(t, 380.0) - position).normalized()
	var ang := clampf(fwd.angle_to(to), -0.25, 0.25)
	var dir := fwd.rotated(ang + run.rng.randf_range(-0.05, 0.05))
	fire_shot(position + fwd * radius, dir, 380.0, float(data["damage"]), float(data["range"]) + 60.0, 4.5)
	Sound.play("enemy_cannon", position, -8.0, 1.25)
	run.fx_over.burst(position + fwd * (radius + 4.0), 3, 70.0, Color(1.0, 0.7, 0.4), 0.25, 2.5, fwd, 0.6)
	cooldown = float(data["cooldown"]) * run.rng.randf_range(0.8, 1.2)


func _draw_ship() -> void:
	if windup > 0.0:
		var a := 0.35 + 0.4 * sin(age * 30.0)
		draw_line(Vector2(radius, 0), Vector2(radius + 130.0, 0), Color(GameData.COL_WARN, a), 2.0)
	draw_hull(32.0, 14.0, Color(0.20, 0.07, 0.05), GameData.COL_ENEMY)
	draw_circle(Vector2(10, 0), 3.0, Color(1.0, 0.75, 0.45))
	draw_line(Vector2(10, 0), Vector2(17, 0), Color(1.0, 0.75, 0.45), 2.0)
	draw_circle(Vector2(-5, 0), 2.5, Color(0.9, 0.6, 0.45))

class_name Harpooner
extends Enemy

var state := "stalk"
var state_time := 0.0
var aim := Vector2.RIGHT


func _on_setup() -> void:
	side_gunned = false
	cooldown = run.rng.randf_range(2.0, 3.5)


func _go(s: String, t: float) -> void:
	state = s
	state_time = t


func _think(dt: float) -> void:
	state_time -= dt
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	var dirn := to.normalized() if dist > 0.01 else Vector2.RIGHT
	match state:
		"stalk":
			var goal := tp - dirn * 360.0 + dirn.rotated(PI / 2.0 * orbit_sign) * 160.0
			steer_to_point(goal, speed, dt)
			if cooldown <= 0.0 and dist < float(data["range"]) and t.alive and forward().dot(dirn) > 0.6:
				_go("aim", float(data["windup"]))
				winding = true
				aim = dirn
				Sound.play("warning", position, -8.0, 1.2)
		"aim":
			steer_to_angle(to.angle(), speed * 0.3, dt)
			if state_time > 0.25:
				aim = (aim_point(t, 640.0) - position).normalized()
			if state_time <= 0.0:
				winding = false
				_fire()
				cooldown = float(data["cooldown"]) * run.rng.randf_range(0.85, 1.15)
				_go("stalk", 0.0)


func _fire() -> void:
	var s = run.shots.spawn(1, position + aim * (radius + 4.0), aim * 640.0, float(data["range"]) / 640.0, float(data["damage"]), "harpoon", position, 5.0, Color(0.6, 1.0, 0.8), "Harpoon")
	if s != null:
		s.status = "tether"
		s.status_t = float(data["tether"])
		s.owner_ref = self
	Sound.play("cannon", position, -6.0, 1.5)


func interrupt() -> void:
	_go("stalk", 0.0)
	cooldown = float(data["cooldown"]) * 0.6
	run.fx_over.text(position + Vector2(0, -34), "LINE FOULED", Color(0.6, 1.0, 0.9), 14, 0.8)


func _draw_ship() -> void:
	if state == "aim":
		var la := aim.rotated(-rotation)
		var prog := 1.0 - clampf(state_time / float(data["windup"]), 0.0, 1.0)
		draw_line(la * radius, la * float(data["range"]) * (0.4 + 0.6 * prog), Color(0.5, 1.0, 0.7, 0.25 + 0.45 * prog), 2.0)
	draw_hull(40.0, 18.0, Color(0.10, 0.14, 0.12), GameData.COL_ENEMY)
	draw_line(Vector2(-4, 0), Vector2(20, 0), Color(0.6, 1.0, 0.8) if state == "aim" else Color(0.55, 0.65, 0.6), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(24, 0), Vector2(17, -4), Vector2(17, 4)]), Color(0.75, 0.9, 0.85))
	draw_circle(Vector2(-10, 0), 4.0, Color(0.35, 0.45, 0.4))

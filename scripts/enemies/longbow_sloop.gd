class_name LongbowSloop
extends Enemy

var state := "move"
var state_time := 0.0
var aim := Vector2.RIGHT
var locked := false


func _on_setup() -> void:
	side_gunned = false
	cooldown = run.rng.randf_range(2.5, 4.0)


func _go(s: String, t: float) -> void:
	state = s
	state_time = t


func aiming() -> bool:
	return state == "aim"


func _think(dt: float) -> void:
	state_time -= dt
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	var dirn := to.normalized() if dist > 0.01 else Vector2.RIGHT
	match state:
		"move":
			var goal := position
			if dist < 600.0:
				goal = position - dirn * 300.0 + dirn.rotated(PI / 2.0 * orbit_sign) * 140.0
			elif dist > 860.0:
				goal = tp - dirn * 720.0
			else:
				goal = position + dirn.rotated(PI / 2.0 * orbit_sign) * 180.0
			steer_to_point(goal, speed, dt)
			if cooldown <= 0.0 and dist < float(data["range"]) and t.alive:
				_go("aim", float(data["windup"]))
				winding = true
				locked = false
				aim = dirn
				Sound.play("warning", position, -10.0, 1.6)
		"aim":
			steer_to_angle(rotation, speed * 0.15, dt)
			if state_time > float(data["lock"]):
				aim = aim.slerp((aim_point(t, float(data["shot_speed"])) - position).normalized(), minf(1.0, 6.0 * dt))
			elif not locked:
				locked = true
				Sound.play("ready", position, -6.0, 1.8)
			if state_time <= 0.0:
				winding = false
				var reach: float = float(data["range"]) + 60.0
				fire_shot(position + aim * (radius + 4.0), aim, float(data["shot_speed"]), float(data["damage"]), reach, 5.0)
				Sound.play("cannon", position, -4.0, 1.7)
				run.fx_over.burst(position + aim * (radius + 6.0), 6, 140.0, Color(1.0, 0.6, 0.4), 0.3, 3.0, aim, 0.3)
				cooldown = float(data["cooldown"]) * run.rng.randf_range(0.85, 1.15)
				_go("move", 0.0)


func interrupt() -> void:
	_go("move", 0.0)
	cooldown = float(data["cooldown"]) * 0.6
	run.fx_over.text(position + Vector2(0, -34), "AIM SPOILED", Color(0.6, 1.0, 0.9), 14, 0.8)


func _draw_ship() -> void:
	if state == "aim":
		var la := aim.rotated(-rotation)
		var reach: float = float(data["range"])
		if locked:
			draw_line(la * radius, la * reach, Color(GameData.COL_WARN, 0.85), 3.0)
		else:
			draw_line(la * radius, la * reach, Color(GameData.COL_WARN, 0.3), 1.2)
	draw_hull(44.0, 14.0, Color(0.16, 0.08, 0.07), GameData.COL_ENEMY)
	draw_line(Vector2(-8, 0), Vector2(26, 0), Color(0.85, 0.6, 0.5), 2.5)
	draw_circle(Vector2(-6, 0), 3.0, Color(1.0, 0.4, 0.3) if state == "aim" else Color(0.7, 0.5, 0.4))

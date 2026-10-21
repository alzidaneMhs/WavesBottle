class_name GhostRunner
extends Enemy

var state := "surface"
var state_time := 1.5
var ping := 1.5
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
		"surface":
			steer_to_point(tp - dirn * 420.0, speed * 0.7, dt)
			if state_time <= 0.0:
				_dive()
		"hidden":
			ping -= dt
			if ping <= 0.0:
				ping = 1.5
				run.fx_under.ring(position, 46.0, 0.8, Color(0.5, 0.9, 1.0, 0.35), 1.5)
				Sound.play("ready", position, -20.0, 0.5)
			var tv: Vector2 = t.velocity
			var behind := -tv.normalized() if tv.length() > 40.0 else dirn.rotated(PI * 0.6 * orbit_sign)
			var goal := tp + behind * 280.0 + behind.rotated(PI / 2.0) * 120.0 * orbit_sign
			steer_to_point(goal, speed, dt)
			if cooldown <= 0.0 and dist < float(data["range"]) and t.alive:
				cloaked = false
				aim = dirn
				_go("reveal", float(data["windup"]))
				winding = true
				run.fx_over.ring(position, 60.0, 0.5, Color(0.6, 0.95, 1.0, 0.9), 3.0)
				Sound.play("warning", position, -6.0, 1.3)
		"reveal":
			steer_to_angle(to.angle(), speed * 0.3, dt)
			if state_time > 0.3:
				aim = dirn
			if state_time <= 0.0:
				winding = false
				for k in [-1.0, 0.0, 1.0]:
					fire_shot(position + aim * radius, aim.rotated(float(k) * 0.16), 520.0, float(data["damage"]), float(data["range"]) + 120.0, 5.0)
				Sound.play("enemy_cannon", position, -6.0, 1.4)
				cooldown = float(data["cooldown"]) * run.rng.randf_range(0.85, 1.15)
				_go("exposed", 3.0)
		"exposed":
			steer_to_point(position - dirn * 300.0 + dirn.rotated(PI / 2.0 * orbit_sign) * 260.0, speed, dt)
			if state_time <= 0.0:
				_dive()


func _dive() -> void:
	cloaked = true
	ping = 0.5
	_go("hidden", 0.0)
	run.fx_under.burst(position, 10, 80.0, Color(0.5, 0.9, 1.0, 0.6), 0.6, 3.0)


func interrupt() -> void:
	_go("exposed", 3.0)
	cooldown = float(data["cooldown"]) * 0.7
	run.fx_over.text(position + Vector2(0, -34), "AMBUSH BROKEN", Color(0.6, 1.0, 0.9), 14, 0.8)


func _draw_ship() -> void:
	if state == "reveal":
		var la := aim.rotated(-rotation)
		var prog := 1.0 - clampf(state_time / float(data["windup"]), 0.0, 1.0)
		for k in [-1.0, 0.0, 1.0]:
			var d := la.rotated(float(k) * 0.16)
			draw_line(d * radius, d * (radius + 260.0 * (0.4 + 0.6 * prog)), Color(GameData.COL_WARN, 0.3 + 0.5 * prog), 2.0)
	var body := Color(0.05, 0.10, 0.13)
	var edge := Color(0.5, 0.9, 1.0) if state != "exposed" else GameData.COL_ENEMY
	draw_hull(42.0, 16.0, body, edge)
	draw_line(Vector2(-14, 0), Vector2(14, 0), Color(0.5, 0.9, 1.0, 0.5), 2.0)
	draw_circle(Vector2(8, 0), 3.0, Color(0.7, 1.0, 1.0, 0.8))

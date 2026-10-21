class_name ResonantCarrier
extends Enemy

var drones: Array = []
var bay := 0.0


func _on_setup() -> void:
	side_gunned = true
	cooldown = run.rng.randf_range(2.0, 3.5)


func _alive_drones() -> int:
	var n := 0
	for d in drones:
		if is_instance_valid(d) and d.alive:
			n += 1
	return n


func _think(dt: float) -> void:
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	var dirn := to.normalized() if dist > 0.01 else Vector2.RIGHT
	var goal: Vector2
	if dist < 450.0:
		goal = position - dirn * 300.0 + dirn.rotated(PI / 2.0 * orbit_sign) * 150.0
	elif dist > 700.0:
		goal = tp - dirn * 580.0
	else:
		goal = position + dirn.rotated(PI / 2.0 * orbit_sign) * 180.0
	steer_to_point(goal, speed, dt)
	bay = maxf(0.0, bay - dt)
	if cooldown <= 1.0 and cooldown > 0.0:
		bay = 1.0
	if cooldown <= 0.0:
		cooldown = float(data["cooldown"]) * run.rng.randf_range(0.9, 1.1)
		for k in 2:
			if _alive_drones() >= int(data["max_drones"]):
				break
			var side := 1.0 if k == 0 else -1.0
			var p: Vector2 = position + forward().rotated(PI / 2.0) * side * (radius + 14.0)
			var d = run.spawn_enemy("resonant_drone", p, variants.filter(func(v): return v == "resonant"))
			if d != null:
				drones.append(d)
		Sound.play("ready", position, -8.0, 1.5)


func _draw_ship() -> void:
	draw_hull(58.0, 30.0, Color(0.14, 0.06, 0.12), Color(1.0, 0.5, 0.85))
	draw_rect(Rect2(Vector2(-18, -9), Vector2(30, 18)), Color(0.22, 0.08, 0.18))
	var glow := 0.4 + 0.6 * bay
	for k in 3:
		draw_rect(Rect2(Vector2(-14.0 + float(k) * 9.0, -4), Vector2(6, 8)), Color(1.0, 0.5, 0.85, 0.3 + 0.6 * glow))
	draw_circle(Vector2(18, 0), 4.0, Color(1.0, 0.75, 0.95))

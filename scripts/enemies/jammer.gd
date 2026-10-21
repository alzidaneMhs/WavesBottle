class_name Jammer
extends Enemy

var decoy_timer := 3.0


func _on_setup() -> void:
	side_gunned = false


func jamming() -> bool:
	if not alive or run.player == null:
		return false
	return position.distance_to(run.player.position) <= float(data["jam_range"])


func _think(dt: float) -> void:
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	var dirn := to.normalized() if dist > 0.01 else Vector2.RIGHT
	var goal: Vector2
	if dist < 480.0:
		goal = position - dirn * 300.0 + dirn.rotated(PI / 2.0 * orbit_sign) * 160.0
	elif dist > 720.0:
		goal = tp - dirn * 600.0
	else:
		goal = position + dirn.rotated(PI / 2.0 * orbit_sign) * 200.0
	steer_to_point(goal, speed, dt)
	decoy_timer -= dt
	if decoy_timer <= 0.0:
		decoy_timer = float(data["decoy_cd"]) * run.rng.randf_range(0.8, 1.2)
		if jamming():
			for i in 3:
				var p: Vector2 = run.player.position + Vector2.RIGHT.rotated(run.rng.randf() * TAU) * run.rng.randf_range(650.0, 1000.0)
				run.false_contacts.append({"pos": p, "life": 6.0})


func _draw_ship() -> void:
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	var pulse := fposmod(age * 0.6, 1.0)
	draw_arc(Vector2.ZERO, 60.0 + pulse * 200.0, 0.0, TAU, 40, Color(0.75, 0.5, 1.0, 0.35 * (1.0 - pulse)), 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_hull(40.0, 20.0, Color(0.12, 0.07, 0.16), Color(0.8, 0.55, 1.0))
	draw_line(Vector2(-4, -12), Vector2(-4, 12), Color(0.8, 0.6, 1.0, 0.8), 2.0)
	for k in 3:
		var a := -0.6 + 0.6 * float(k)
		draw_line(Vector2(-4, 0), Vector2(-4, 0) + Vector2.UP.rotated(a) * 14.0, Color(0.85, 0.65, 1.0, 0.6 + 0.4 * sin(age * 12.0 + float(k))), 1.5)
	draw_circle(Vector2(10, 0), 3.0, Color(0.9, 0.75, 1.0))

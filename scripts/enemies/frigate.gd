class_name Frigate
extends Enemy

const OFFSETS := [-14.0, 0.0, 14.0]

var state := "maneuver"
var windup := 0.0
var fire_side := 1.0


func _on_setup() -> void:
	side_gunned = true


func _think(dt: float) -> void:
	var t = target()
	var tp: Vector2 = aim_point(t, 420.0)
	var to := tp - position
	var dist := to.length()
	var dirn := to.normalized() if dist > 0.01 else Vector2.RIGHT
	var right := forward().rotated(PI / 2.0)
	if state == "windup":
		windup -= dt
		steer_to_angle(rotation, speed * 0.35, dt)
		if windup <= 0.0:
			winding = false
			_fire()
			state = "maneuver"
			cooldown = float(data["cooldown"]) * run.rng.randf_range(0.85, 1.15)
		return
	fire_side = 1.0 if right.dot(to) > 0.0 else -1.0
	var radial := clampf((dist - 330.0) / 200.0, -1.0, 1.0)
	var ang := to.angle() - fire_side * PI / 2.0 + fire_side * radial * 0.6
	steer_to_angle(ang, speed, dt)
	var side_vec := right * fire_side
	if cooldown <= 0.0 and dist < float(data["range"]) and side_vec.dot(dirn) > 0.9 and t.alive:
		state = "windup"
		windup = float(data["windup"])
		winding = true
		Sound.play("warning", position, -10.0)


func interrupt() -> void:
	state = "maneuver"
	windup = 0.0
	cooldown = float(data["cooldown"]) * 0.7
	run.fx_over.text(position + Vector2(0, -36), "BROADSIDE BROKEN", Color(0.6, 1.0, 0.9), 15, 0.9)


func _fire() -> void:
	var fwd := forward()
	var side_vec := fwd.rotated(PI / 2.0) * fire_side
	for x in OFFSETS:
		var origin := position + fwd * float(x) + side_vec * radius
		var dir := side_vec.rotated(run.rng.randf_range(-0.04, 0.04))
		fire_shot(origin, dir, 420.0, float(data["damage"]), float(data["range"]) + 40.0, 5.5)
		run.fx_over.burst(origin, 3, 80.0, Color(1.0, 0.7, 0.4), 0.3, 3.0, side_vec, 0.6)
	Sound.play("enemy_cannon", position, -4.0)


func _draw_ship() -> void:
	if state == "windup":
		var prog := 1.0 - windup / float(data["windup"])
		draw_side_lanes(fire_side, OFFSETS, float(data["range"]), prog)
	draw_hull(48.0, 20.0, Color(0.18, 0.07, 0.06), GameData.COL_ENEMY)
	for side in [-1.0, 1.0]:
		for x in OFFSETS:
			var lit: bool = state == "windup" and side == fire_side
			var c := Color(1.0, 0.35, 0.25) if lit else Color(0.7, 0.4, 0.3)
			draw_rect(Rect2(Vector2(float(x) - 2.5, side * 10.0 - 2.0), Vector2(5, 4)), c)
	draw_circle(Vector2(8, 0), 3.5, Color(0.95, 0.75, 0.6))
	draw_circle(Vector2(-8, 0), 3.5, Color(0.95, 0.75, 0.6))
	draw_line(Vector2(8, -9), Vector2(8, 9), Color(0.9, 0.6, 0.5, 0.6), 2.0)
	draw_line(Vector2(-8, -9), Vector2(-8, 9), Color(0.9, 0.6, 0.5, 0.6), 2.0)

class_name SiegeBarge
extends Enemy

var state := "move"
var state_time := 0.0
var deploy_at := Vector2.ZERO
var platforms: Array = []


func _on_setup() -> void:
	side_gunned = true
	armored = true
	cooldown = run.rng.randf_range(3.0, 5.0)


func _go(s: String, t: float) -> void:
	state = s
	state_time = t


func _alive_platforms() -> int:
	var n := 0
	for p in platforms:
		if is_instance_valid(p) and p.alive:
			n += 1
	return n


func _think(dt: float) -> void:
	state_time -= dt
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	match state:
		"move":
			var dirn := to.normalized() if dist > 0.01 else Vector2.RIGHT
			var goal := tp - dirn * 460.0 + dirn.rotated(PI / 2.0 * orbit_sign) * 120.0
			steer_to_point(goal, speed, dt)
			if cooldown <= 0.0 and dist < 900.0 and _alive_platforms() < 2:
				var right := forward().rotated(PI / 2.0)
				var side := 1.0 if right.dot(to) > 0.0 else -1.0
				deploy_at = position + right * side * (radius + 70.0) + forward() * 20.0
				if not run.arena.is_clear(deploy_at, 40.0):
					deploy_at = position - right * side * (radius + 70.0)
				_go("deploy", float(data["windup"]))
				exposed = true
				Sound.play("warning", position, -6.0, 0.6)
		"deploy":
			steer_to_angle(rotation, 0.0, dt)
			if state_time <= 0.0:
				var p = run.spawn_enemy("siege_platform", deploy_at, [])
				if p != null:
					platforms.append(p)
				Sound.play("impact", deploy_at, -2.0, 0.6)
				_go("recover", 1.5)
		"recover":
			steer_to_angle(rotation, speed * 0.3, dt)
			if state_time <= 0.0:
				exposed = false
				cooldown = float(data["cooldown"]) * run.rng.randf_range(0.85, 1.15)
				_go("move", 0.0)


func _draw_ship() -> void:
	if state == "deploy":
		var lp := to_local(deploy_at)
		var prog := 1.0 - clampf(state_time / float(data["windup"]), 0.0, 1.0)
		draw_arc(lp, 30.0, 0.0, TAU, 24, Color(GameData.COL_WARN, 0.4 + 0.4 * prog), 2.5, true)
		draw_arc(lp, 30.0 * prog, 0.0, TAU, 24, Color(1.0, 0.6, 0.4, 0.6), 1.5, true)
	var outline := GameData.COL_ENEMY
	if exposed:
		var pulse := 0.5 + 0.5 * sin(age * 10.0)
		outline = Color(0.4, 1.0, 0.95).lerp(Color.WHITE, pulse * 0.4)
	draw_hull(64.0, 34.0, Color(0.14, 0.11, 0.09), outline)
	draw_rect(Rect2(Vector2(-20, -10), Vector2(30, 20)), Color(0.22, 0.17, 0.13))
	for x in [-14.0, -2.0, 10.0]:
		draw_rect(Rect2(Vector2(x - 3.0, -4.0), Vector2(6, 8)), Color(0.55, 0.45, 0.38))
	if state == "deploy":
		draw_line(Vector2(-24, -17), Vector2(18, -17), Color(0.4, 1.0, 0.95, 0.8), 3.0)
		draw_line(Vector2(-24, 17), Vector2(18, 17), Color(0.4, 1.0, 0.95, 0.8), 3.0)


func _draw_overlay() -> void:
	if exposed:
		draw_string_outline(font, Vector2(-70, -radius - 22.0), "OPEN", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 15, 4, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(-70, -radius - 22.0), "OPEN", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 15, Color(0.4, 1.0, 0.95))

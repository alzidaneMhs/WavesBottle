class_name MortarMonitor
extends Enemy

var state := "move"
var state_time := 0.0
var aim_at := Vector2.ZERO


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
		"move":
			var goal := position
			if dist < 420.0:
				goal = position - dirn * 300.0 + dirn.rotated(PI / 2.0 * orbit_sign) * 120.0
			elif dist > 700.0:
				goal = tp - dirn * 560.0
			else:
				goal = position + dirn.rotated(PI / 2.0 * orbit_sign) * 200.0
			steer_to_point(goal, speed, dt)
			if cooldown <= 0.0 and dist < float(data["range"]) and dist > float(data["min_range"]) and t.alive:
				_go("windup", float(data["windup"]))
				winding = true
				Sound.play("warning", position, -8.0, 0.7)
		"windup":
			steer_to_angle(to.angle(), speed * 0.2, dt)
			if dist < float(data["min_range"]):
				winding = false
				_go("move", 0.0)
				cooldown = 1.2
				return
			if state_time <= 0.0:
				winding = false
				_fire(t)
				cooldown = float(data["cooldown"]) * run.rng.randf_range(0.85, 1.15)
				_go("move", 0.0)


func _fire(t) -> void:
	var tp: Vector2 = t.position
	var tv: Vector2 = t.velocity
	var lead := tp + tv * 1.4
	var side := tv.normalized().rotated(PI / 2.0) if tv.length() > 20.0 else Vector2.RIGHT.rotated(run.rng.randf() * TAU)
	var dmg: float = float(data["damage"])
	var blast: float = float(data["blast"])
	run.shots.add_mortar(lead, 1.7, blast, dmg, "Mortar Monitor")
	run.shots.add_mortar(lead + side * 85.0, 1.8, blast, dmg, "Mortar Monitor")
	run.shots.add_mortar(lead - side * 85.0, 1.9, blast, dmg, "Mortar Monitor")
	Sound.play("enemy_cannon", position, -4.0, 0.6)
	run.fx_over.burst(position, 8, 80.0, Color(1.0, 0.7, 0.4), 0.5, 4.0, Vector2.UP, 1.0)


func interrupt() -> void:
	_go("move", 0.0)
	cooldown = float(data["cooldown"]) * 0.6
	run.fx_over.text(position + Vector2(0, -40), "BARRAGE BROKEN", Color(0.6, 1.0, 0.9), 15, 0.9)


func _draw_ship() -> void:
	if state == "windup":
		var t = target()
		if t != null:
			var prog := 1.0 - clampf(state_time / float(data["windup"]), 0.0, 1.0)
			var tl := to_local(t.position)
			var a := 0.25 + 0.5 * prog
			draw_line(Vector2.ZERO, tl, Color(GameData.COL_WARN, a * 0.4), 1.0)
			var r := lerpf(90.0, 40.0, prog)
			for k in 4:
				var ang := PI / 2.0 * float(k) + PI / 4.0
				draw_arc(tl, r, ang - 0.3, ang + 0.3, 6, Color(GameData.COL_WARN, a), 2.0)
	draw_hull(46.0, 24.0, Color(0.16, 0.10, 0.07), GameData.COL_ENEMY)
	var lit := state == "windup"
	for x in [-10.0, 2.0, 14.0]:
		var c := Color(1.0, 0.55, 0.25) if lit and int(age * 10.0) % 2 == 0 else Color(0.6, 0.45, 0.35)
		draw_circle(Vector2(x, 0), 5.0, Color(0.08, 0.05, 0.04))
		draw_arc(Vector2(x, 0), 5.0, 0.0, TAU, 12, c, 2.0)
	draw_line(Vector2(-18, -8), Vector2(-18, 8), Color(0.75, 0.55, 0.4, 0.7), 2.0)

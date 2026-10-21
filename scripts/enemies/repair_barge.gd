class_name RepairBarge
extends Enemy

var state := "seek"
var state_time := 0.0
var patient = null


func _on_setup() -> void:
	side_gunned = false


func _go(s: String, t: float) -> void:
	state = s
	state_time = t


func _find_patient() -> void:
	patient = null
	var best := 0.9
	for e in run.enemies:
		if e == self or not e.alive or e.kind == "siege_platform":
			continue
		var ratio: float = float(e.hull) / maxf(1.0, float(e.max_hull))
		if ratio < best and position.distance_to(e.position) < 1200.0:
			best = ratio
			patient = e


func _think(dt: float) -> void:
	state_time -= dt
	var t = target()
	var tp: Vector2 = t.position
	match state:
		"seek":
			if patient == null or not is_instance_valid(patient) or not patient.alive or float(patient.hull) >= float(patient.max_hull) * 0.98:
				_find_patient()
			if patient == null:
				var away := (position - tp).normalized() if position.distance_to(tp) > 1.0 else Vector2.RIGHT
				var goal := tp + away * 520.0 + away.rotated(PI / 2.0 * orbit_sign) * 160.0
				steer_to_point(goal, speed, dt)
				return
			var pp: Vector2 = patient.position
			var back := (pp - tp).normalized() if pp.distance_to(tp) > 1.0 else Vector2.RIGHT
			var spot := pp + back * (float(patient.radius) + 110.0)
			steer_to_point(spot, speed, dt)
			if cooldown <= 0.0 and position.distance_to(pp) <= float(data["heal_range"]):
				_go("repair", float(data["channel"]))
				winding = true
		"repair":
			steer_to_angle(rotation, speed * 0.2, dt)
			if patient == null or not is_instance_valid(patient) or not patient.alive or position.distance_to(patient.position) > float(data["heal_range"]) + 60.0:
				winding = false
				cooldown = 0.8
				_go("seek", 0.0)
				return
			var rate: float = float(data["heal"]) * (0.45 if patient.boss else 1.0)
			patient.hull = minf(float(patient.max_hull), float(patient.hull) + rate * dt)
			if state_time <= 0.0 or float(patient.hull) >= float(patient.max_hull):
				winding = false
				cooldown = float(data["cooldown"])
				_go("seek", 0.0)


func interrupt() -> void:
	cooldown = 3.0
	_go("seek", 0.0)
	run.fx_over.text(position + Vector2(0, -40), "BEAM CUT", Color(0.6, 1.0, 0.9), 15, 0.9)


func _draw_ship() -> void:
	if state == "repair" and patient != null and is_instance_valid(patient):
		var lp := to_local(patient.position)
		var w := 3.0 + 1.5 * sin(age * 12.0)
		draw_line(Vector2.ZERO, lp, Color(0.4, 1.0, 0.6, 0.5), w)
		draw_line(Vector2.ZERO, lp, Color(0.8, 1.0, 0.85, 0.8), 1.0)
		draw_arc(lp, float(patient.radius) + 8.0, age * 3.0, age * 3.0 + 4.0, 16, Color(0.4, 1.0, 0.6, 0.7), 2.0)
	draw_hull(52.0, 28.0, Color(0.10, 0.14, 0.10), Color(0.5, 0.95, 0.6))
	draw_rect(Rect2(Vector2(-14, -8), Vector2(20, 16)), Color(0.14, 0.22, 0.15))
	draw_rect(Rect2(Vector2(-7, -2), Vector2(6, 4)), Color(0.5, 1.0, 0.6))
	draw_rect(Rect2(Vector2(-6, -5), Vector2(4, 10)), Color(0.5, 1.0, 0.6))
	draw_circle(Vector2(14, 0), 3.5, Color(0.8, 0.95, 0.8))

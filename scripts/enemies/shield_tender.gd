class_name ShieldTender
extends Enemy

var ward = null
var ward_time := 0.0


func _on_setup() -> void:
	side_gunned = false


func _pick_ward() -> void:
	ward = null
	var best := -1.0
	for e in run.enemies:
		if e == self or not e.alive or e.kind in ["shield_tender", "siege_platform"]:
			continue
		var d: float = position.distance_to(e.position)
		if d > 1100.0:
			continue
		var score: float = float(e.max_hull) / (1.0 + d * 0.004)
		if e.supply or e.kind == "courier":
			score *= 3.0
		if score > best:
			best = score
			ward = e
	ward_time = 2.0


func _think(dt: float) -> void:
	ward_time -= dt
	if ward_time <= 0.0 or ward == null or not is_instance_valid(ward) or not ward.alive:
		_pick_ward()
	var t = target()
	var tp: Vector2 = t.position
	var goal: Vector2
	if ward != null and is_instance_valid(ward):
		var wp: Vector2 = ward.position
		var back := (wp - tp).normalized() if wp.distance_to(tp) > 1.0 else Vector2.RIGHT
		goal = wp + back * (float(ward.radius) + 90.0)
	else:
		var away := (position - tp).normalized() if position.distance_to(tp) > 1.0 else Vector2.RIGHT
		goal = tp + away * 480.0
	var spd := speed
	if position.distance_to(goal) < 60.0:
		spd = speed * 0.4
	steer_to_point(goal, spd, dt)


func covers(e) -> bool:
	if e == self or not alive or e.kind == "shield_tender":
		return false
	return position.distance_to(e.position) <= float(data["shield_range"]) + float(e.radius)


func _draw_ship() -> void:
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	var r: float = float(data["shield_range"])
	var pulse := 0.5 + 0.5 * sin(age * 2.5)
	var segs := 36
	for i in segs:
		if i % 3 != 0:
			var a0 := TAU * float(i) / float(segs) - age * 0.25
			draw_arc(Vector2.ZERO, r, a0, a0 + TAU / float(segs), 4, Color(0.5, 0.8, 1.0, 0.16 + 0.1 * pulse), 1.5)
	for e in run.enemies:
		if is_instance_valid(e) and e.alive and covers(e):
			var lp: Vector2 = (e.position as Vector2) - position
			draw_line(Vector2.ZERO, lp, Color(0.5, 0.8, 1.0, 0.25 + 0.2 * pulse), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_hull(40.0, 20.0, Color(0.08, 0.10, 0.16), Color(0.55, 0.8, 1.0))
	draw_circle(Vector2(0, 0), 7.0, Color(0.1, 0.2, 0.35))
	draw_arc(Vector2(0, 0), 7.0, 0.0, TAU, 16, Color(0.6, 0.85, 1.0, 0.7 + 0.3 * pulse), 2.0)
	draw_line(Vector2(-12, -7), Vector2(-12, 7), Color(0.6, 0.8, 1.0, 0.6), 2.0)

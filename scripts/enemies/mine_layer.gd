class_name MineLayer
extends Enemy

var route := Vector2.ZERO
var route_time := 0.0
var drop_timer := 2.0


func _on_setup() -> void:
	side_gunned = false
	drop_timer = run.rng.randf_range(1.5, 2.5)


func _pick_route(t) -> void:
	var tp: Vector2 = t.position
	var tv: Vector2 = t.velocity
	var ahead := tv.normalized() if tv.length() > 30.0 else (tp - position).normalized()
	var across := ahead.rotated(PI / 2.0 * orbit_sign)
	route = tp + ahead * 320.0 + across * 420.0
	var size: Vector2 = run.arena.size
	route.x = clampf(route.x, 160.0, size.x - 160.0)
	route.y = clampf(route.y, 160.0, size.y - 160.0)
	route_time = run.rng.randf_range(3.5, 5.0)
	orbit_sign = -orbit_sign


func _think(dt: float) -> void:
	var t = target()
	var tp: Vector2 = t.position
	route_time -= dt
	if route_time <= 0.0 or position.distance_to(route) < 80.0:
		_pick_route(t)
	var goal := route
	var away := position - tp
	if away.length() < 200.0:
		goal += away.normalized() * 260.0
	steer_to_point(goal, speed, dt)
	drop_timer -= dt * (1.3 if aura else 1.0)
	if drop_timer <= 0.0:
		drop_timer = float(data["cooldown"]) * run.rng.randf_range(0.85, 1.15)
		if position.distance_to(tp) > 150.0:
			var at := position - forward() * (radius + 22.0)
			if run.arena.is_clear(at, 30.0):
				run.hazards.add_layer_mine(at, get_instance_id(), int(data["max_mines"]))
				Sound.play("splash", at, -8.0, 1.2)


func _draw_ship() -> void:
	draw_hull(40.0, 20.0, Color(0.18, 0.09, 0.05), GameData.COL_ENEMY)
	draw_rect(Rect2(Vector2(-16, -6), Vector2(14, 12)), Color(0.3, 0.12, 0.08))
	for k in 3:
		var x := -13.0 + float(k) * 5.0
		var on := int(age * 3.0) % 3 == k
		draw_circle(Vector2(x, 0), 2.5, Color(1.0, 0.5, 0.3) if on else Color(0.6, 0.35, 0.25))
	draw_circle(Vector2(10, 0), 3.0, Color(0.95, 0.7, 0.5))

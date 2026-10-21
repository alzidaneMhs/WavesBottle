class_name ResonantDrone
extends Enemy

var orbit := 0.0


func _on_setup() -> void:
	side_gunned = false
	orbit = run.rng.randf() * TAU
	cooldown = run.rng.randf_range(1.0, 2.2)


func _think(dt: float) -> void:
	var t = target()
	var tp: Vector2 = t.position
	orbit += dt * 1.6 * orbit_sign
	var goal := tp + Vector2.RIGHT.rotated(orbit) * 170.0
	steer_to_point(goal, speed, dt)
	var to := tp - position
	if cooldown <= 0.0 and to.length() < float(data["range"]) and t.alive:
		cooldown = float(data["cooldown"]) * run.rng.randf_range(0.85, 1.15)
		fire_shot(position, to.normalized().rotated(run.rng.randf_range(-0.05, 0.05)), 420.0, float(data["damage"]), float(data["range"]) + 40.0, 3.0)


func _draw_ship() -> void:
	var glow := 1.0 - clampf(cooldown / 0.4, 0.0, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(9, 0), Vector2(0, -7), Vector2(-7, 0), Vector2(0, 7)]), Color(0.25, 0.08, 0.2) if hit_flash <= 0.0 else Color(1.0, 0.85, 0.95))
	draw_polyline(PackedVector2Array([Vector2(9, 0), Vector2(0, -7), Vector2(-7, 0), Vector2(0, 7), Vector2(9, 0)]), Color(1.0, 0.5, 0.85), 1.5, true)
	draw_circle(Vector2.ZERO, 2.5 + glow * 2.0, Color(1.0, 0.6, 0.9, 0.5 + 0.5 * glow))

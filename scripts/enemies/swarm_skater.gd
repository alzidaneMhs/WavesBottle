class_name SwarmSkater
extends Enemy

var orbit := 0.0
var dart := 0.0


func _on_setup() -> void:
	side_gunned = false
	orbit = run.rng.randf() * TAU
	cooldown = run.rng.randf_range(0.8, 2.2)


func _think(dt: float) -> void:
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	var dirn := to.normalized() if dist > 0.01 else Vector2.RIGHT
	orbit += dt * 1.1 * orbit_sign
	dart -= dt
	var r := 200.0 if dart <= 0.0 else 110.0
	var goal := tp + Vector2.RIGHT.rotated(orbit) * r
	steer_to_point(goal, speed, dt)
	if dart <= -3.0 and run.rng.randf() < dt * 0.6:
		dart = 1.2
	if cooldown <= 0.0 and dist < float(data["range"]) and forward().dot(dirn) > 0.8 and t.alive:
		cooldown = float(data["cooldown"]) * run.rng.randf_range(0.8, 1.2)
		fire_shot(position + forward() * radius, forward().rotated(run.rng.randf_range(-0.06, 0.06)), 470.0, float(data["damage"]), float(data["range"]) + 60.0, 3.5)
		Sound.play("enemy_cannon", position, -14.0, 1.8)


func _draw_ship() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(12, 0), Vector2(-8, -7), Vector2(-4, 0), Vector2(-8, 7)]), Color(0.25, 0.08, 0.05) if hit_flash <= 0.0 else Color(0.9, 0.8, 0.7))
	draw_polyline(PackedVector2Array([Vector2(12, 0), Vector2(-8, -7), Vector2(-4, 0), Vector2(-8, 7), Vector2(12, 0)]), GameData.COL_ENEMY, 1.5, true)
	draw_circle(Vector2(2, 0), 2.0, Color(1.0, 0.7, 0.45))

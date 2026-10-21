class_name ResonanceAnchor
extends Enemy

var summon := true
var shielding = null


func _on_setup() -> void:
	side_gunned = false
	anchored = true
	cooldown = run.rng.randf_range(8.0, 12.0)


func _think(_dt: float) -> void:
	velocity = Vector2.ZERO
	rotation += 0.01
	if not summon:
		return
	if cooldown <= 0.0:
		cooldown = float(data["cooldown"]) * run.rng.randf_range(0.9, 1.1)
		var picks := [["gunboat", 2, ["resonant"]], ["frigate", 1, ["resonant"]], ["swarm_skater", 3, []], ["harpooner", 1, ["resonant"]]]
		var pick: Array = picks[run.rng.randi_range(0, picks.size() - 1)]
		for i in int(pick[1]):
			var p: Vector2 = position + Vector2.RIGHT.rotated(run.rng.randf() * TAU) * run.rng.randf_range(80.0, 140.0)
			run.fx_over.spawn_cue(p)
			run.spawn_enemy(str(pick[0]), p, (pick[2] as Array).duplicate())
		run.fx_over.ring(position, 160.0, 0.6, Color(1.0, 0.5, 0.85, 0.8), 3.0)
		Sound.play("boss", position, -10.0, 1.6)


func _draw_ship() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var flare := 1.0 - clampf(cooldown / 2.0, 0.0, 1.0) if summon else 0.0
	var pulse := 0.5 + 0.5 * sin(age * 3.0)
	for k in 3:
		var r := radius + 8.0 + float(k) * 10.0 - flare * 6.0
		draw_arc(Vector2.ZERO, r, age * (0.6 + 0.3 * float(k)), age * (0.6 + 0.3 * float(k)) + 4.2, 24, Color(1.0, 0.5, 0.85, 0.35 + 0.3 * pulse + 0.3 * flare), 2.0, true)
	var pts := PackedVector2Array()
	for i in 6:
		pts.append(Vector2.RIGHT.rotated(TAU * float(i) / 6.0 + age * 0.3) * radius)
	var body := Color(0.18, 0.05, 0.16)
	if hit_flash > 0.0 and not SaveData.reduce_flash():
		body = body.lerp(Color(1.0, 0.9, 0.95), 0.6)
	draw_colored_polygon(pts, body)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color(1.0, 0.5, 0.85), 2.5, true)
	draw_circle(Vector2.ZERO, 9.0 + 3.0 * pulse, Color(1.0, 0.7, 0.95, 0.85))
	if shielding != null and is_instance_valid(shielding) and shielding.alive:
		draw_line(Vector2.ZERO, to_local(shielding.position), Color(1.0, 0.5, 0.85, 0.3 + 0.3 * pulse), 3.0)

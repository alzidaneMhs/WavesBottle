class_name LeviathanPod
extends Enemy

var engine = null
var offset := Vector2.ZERO
var role := "gun"
var lit := false
var windup := 0.0
var aim := Vector2.RIGHT


func _on_setup() -> void:
	side_gunned = false
	anchored = true
	cooldown = run.rng.randf_range(1.5, 3.0)


func attach(e, off: Vector2, r: String) -> void:
	engine = e
	offset = off
	role = r
	if role == "conduit":
		max_hull = 80.0 * (float(e.max_hull) / 2000.0) * 1.0
		hull = max_hull
	_snap()


func _snap() -> void:
	if engine != null and is_instance_valid(engine):
		position = (engine.position as Vector2) + offset.rotated(float(engine.rotation))


func _think(dt: float) -> void:
	_snap()
	velocity = Vector2.ZERO
	if role == "conduit":
		rotation += dt * (3.0 if lit else 0.6)
		return
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	if role == "gun":
		if windup > 0.0:
			windup -= dt
			if windup <= 0.0:
				winding = false
				for k in [-1.0, 0.0, 1.0]:
					fire_shot(position + aim * radius, aim.rotated(float(k) * 0.07), 450.0, float(data["damage"]), float(data["range"]) + 40.0, 6.0)
				Sound.play("enemy_cannon", position, -4.0, 0.9)
				cooldown = float(data["cooldown"]) * run.rng.randf_range(0.85, 1.15)
			return
		rotation = to.angle()
		if cooldown <= 0.0 and dist < float(data["range"]) and t.alive:
			windup = float(data["windup"])
			winding = true
			aim = to.normalized()
	else:
		rotation = to.angle()
		if cooldown <= 0.0 and dist < 900.0 and t.alive:
			cooldown = float(data["cooldown"]) * 1.5 * run.rng.randf_range(0.85, 1.15)
			var tv: Vector2 = t.velocity
			run.shots.add_mortar(tp + tv * 0.9, 1.6, 65.0, 12.0, "Engine shell")
			run.shots.add_mortar(tp + tv * 0.9 + Vector2.RIGHT.rotated(run.rng.randf() * TAU) * 120.0, 1.75, 65.0, 12.0, "Engine shell")
			Sound.play("boss", position, -10.0, 1.6)


func damage_factor(_origin: Vector2) -> float:
	if role == "conduit" and not lit:
		run.fx_over.text(position + Vector2(0, -30), "DARK", Color(0.7, 0.8, 0.9), 12, 0.3)
		return 0.0
	return 1.0


func interrupt() -> void:
	windup = 0.0
	cooldown = float(data["cooldown"]) * 0.7
	run.fx_over.text(position + Vector2(0, -30), "POD JAMMED", Color(0.6, 1.0, 0.9), 13, 0.8)


func _draw_ship() -> void:
	if role == "gun" and windup > 0.0:
		var la := aim.rotated(-rotation)
		var prog := 1.0 - clampf(windup / float(data["windup"]), 0.0, 1.0)
		draw_line(la * radius, la * float(data["range"]) * (0.3 + 0.7 * prog), Color(GameData.COL_WARN, 0.3 + 0.5 * prog), 3.0)
	var body := Color(0.08, 0.12, 0.14)
	if hit_flash > 0.0 and not SaveData.reduce_flash():
		body = body.lerp(Color(1.0, 0.9, 0.8), 0.6)
	var pts := PackedVector2Array()
	var sides := 6 if role != "conduit" else 4
	for i in sides:
		pts.append(Vector2.RIGHT.rotated(TAU * float(i) / float(sides)) * radius)
	draw_colored_polygon(pts, body)
	var closed := pts.duplicate()
	closed.append(pts[0])
	var edge := Color(0.4, 0.95, 0.85)
	if role == "conduit":
		edge = Color(1.0, 0.95, 0.5) if lit else Color(0.4, 0.5, 0.55)
	draw_polyline(closed, edge, 2.5, true)
	match role:
		"gun":
			draw_line(Vector2.ZERO, Vector2(radius + 8.0, 0), Color(0.7, 0.85, 0.85), 5.0)
		"launcher":
			draw_circle(Vector2.ZERO, 8.0, Color(0.2, 0.3, 0.3))
			draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 12, Color(0.6, 0.9, 0.85), 2.0)
		"conduit":
			draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.95, 0.6, 0.9) if lit else Color(0.25, 0.3, 0.35))

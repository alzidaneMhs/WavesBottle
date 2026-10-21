class_name Courier
extends Enemy

var exit := Vector2.ZERO
var weave := 0.0


func _on_setup() -> void:
	side_gunned = false
	weave = run.rng.randf() * TAU


func set_exit(p: Vector2) -> void:
	exit = p


func _think(dt: float) -> void:
	var to_exit := exit - position
	if to_exit.length() < 70.0:
		escape()
		return
	var dirn := to_exit.normalized()
	var goal := exit + dirn.rotated(PI / 2.0) * sin(age * 0.8 + weave) * 140.0
	var p: PlayerShip = run.player
	if p.alive:
		var away := position - p.position
		if away.length() < 240.0:
			goal += away.normalized() * 260.0
	steer_to_point(goal, speed, dt)


func escape() -> void:
	if not alive:
		return
	alive = false
	run.on_courier_escaped(self)
	queue_free()


func _draw_ship() -> void:
	draw_hull(40.0, 18.0, Color(0.22, 0.16, 0.06), Color(1.0, 0.8, 0.4))
	draw_rect(Rect2(Vector2(-12, -5), Vector2(8, 10)), Color(1.0, 0.85, 0.4, 0.9))
	draw_rect(Rect2(Vector2(-2, -5), Vector2(8, 10)), Color(1.0, 0.85, 0.4, 0.9))


func _draw_overlay() -> void:
	var to_exit := exit - position
	if to_exit.length() > 1.0:
		var d := to_exit.normalized()
		draw_line(d * (radius + 6.0), d * (radius + 40.0), Color(1.0, 0.85, 0.4, 0.7), 2.0)
		draw_colored_polygon(PackedVector2Array([d * (radius + 48.0), d * (radius + 38.0) + d.rotated(PI / 2.0) * 5.0, d * (radius + 38.0) - d.rotated(PI / 2.0) * 5.0]), Color(1.0, 0.85, 0.4, 0.8))

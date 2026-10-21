class_name Decoy
extends Node2D

var run
var hull := 60.0
var max_hull := 60.0
var radius := 16.0
var velocity := Vector2.ZERO
var alive := true
var physical := false
var life := 8.0
var age := 0.0


func setup(p_run, duration: float, p_hull: float) -> void:
	run = p_run
	life = duration
	hull = p_hull
	max_hull = p_hull


func _process(delta: float) -> void:
	if not alive:
		return
	age += delta
	life -= delta
	if life <= 0.0:
		destroy()
		return
	queue_redraw()


func take_damage(amount: float, _source: String, _from: Vector2 = Vector2.INF) -> void:
	if not alive:
		return
	hull -= amount
	run.fx_over.burst(position, 5, 90.0, Color(1.0, 0.8, 0.5), 0.3, 2.0)
	if hull <= 0.0:
		destroy()


func destroy() -> void:
	if not alive:
		return
	alive = false
	run.fx_over.burst(position, 14, 140.0, Color(1.0, 0.7, 0.4), 0.5, 3.0)
	run.on_decoy_gone(self)
	queue_free()


func _draw() -> void:
	var blink := int(age * 4.0) % 2 == 0
	draw_circle(Vector2.ZERO, radius + 30.0, Color(1.0, 0.6, 0.3, 0.06))
	draw_arc(Vector2.ZERO, radius + 30.0 + sin(age * 4.0) * 4.0, 0.0, TAU, 32, Color(1.0, 0.6, 0.3, 0.4), 1.5, true)
	draw_circle(Vector2.ZERO, radius, Color(0.15, 0.1, 0.06))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(1.0, 0.65, 0.3), 2.0, true)
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.9, 0.5) if blink else Color(0.5, 0.3, 0.1))
	draw_arc(Vector2.ZERO, radius - 4.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(life / 8.0, 0.0, 1.0), 20, Color(0.55, 0.95, 1.0, 0.8), 2.0)

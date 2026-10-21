class_name AllyShip
extends Node2D

var run
var kind := "barge"
var title := ""
var hull := 100.0
var max_hull := 100.0
var radius := 26.0
var speed := 34.0
var velocity := Vector2.ZERO
var alive := true
var physical := true
var path: Array = []
var path_i := 0
var finished := false
var hit_flash := 0.0
var age := 0.0
var font: Font


func setup(p_run, id: String, waypoints: Array, hull_mult: float) -> void:
	run = p_run
	kind = id
	var d: Dictionary = GameData.ALLIES[id]
	title = str(d["name"])
	max_hull = float(d["hull"]) * hull_mult
	hull = max_hull
	radius = float(d["radius"])
	speed = float(d["speed"])
	path = waypoints.duplicate()
	font = ThemeDB.fallback_font
	if not path.is_empty():
		position = path[0]
		path_i = 1
		if path.size() > 1:
			rotation = ((path[1] as Vector2) - position).angle()


func progress() -> float:
	if path.size() < 2:
		return 1.0
	return clampf(float(path_i - 1) / float(path.size() - 1), 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if not alive or run == null or run.state == "ended" or finished:
		return
	var dt := minf(delta, 0.05)
	age += dt
	hit_flash = maxf(0.0, hit_flash - dt)
	if path_i >= path.size():
		finished = true
		run.on_ally_arrived(self)
		return
	var goal: Vector2 = path[path_i]
	var to := goal - position
	if to.length() < 40.0:
		path_i += 1
		return
	var diff := wrapf(to.angle() - rotation, -PI, PI)
	rotation = wrapf(rotation + clampf(diff, -0.6 * dt, 0.6 * dt), -PI, PI)
	var fwd := Vector2.RIGHT.rotated(rotation)
	var go := speed * (0.4 + 0.6 * clampf(1.0 - absf(diff) / 1.2, 0.0, 1.0))
	velocity = fwd * go
	position += (velocity + run.hazards.flow_at(position) * 0.3) * dt
	run.arena.resolve_circle(self, 0.2)
	if int(age * 10.0) % 3 == 0:
		run.fx_under.wake_point(position - fwd * 30.0, 6.0, Color(0.6, 1.0, 0.8), 0.35)
	queue_redraw()


func take_damage(amount: float, _source: String, _from: Vector2 = Vector2.INF) -> void:
	if not alive or amount <= 0.0:
		return
	hull -= amount
	hit_flash = 0.2
	run.fx_over.burst(position, 6, 100.0, Color(1.0, 0.6, 0.4), 0.35, 2.5)
	run.on_ally_damaged(self, amount)
	if hull <= 0.0:
		hull = 0.0
		alive = false
		run.fx_over.explosion(position, 90.0)
		Sound.play("explosion", position, 2.0, 0.7)
		run.on_ally_destroyed(self)
		queue_redraw()


func _draw() -> void:
	if not alive:
		return
	for i in range(path_i, mini(path_i + 3, path.size())):
		var a: Vector2 = to_local(path[i - 1] if i > path_i else position)
		var b: Vector2 = to_local(path[i])
		var steps := int(a.distance_to(b) / 30.0)
		for k in steps:
			if k % 2 == 0:
				draw_line(a.lerp(b, float(k) / float(maxi(1, steps))), a.lerp(b, float(k + 1) / float(maxi(1, steps))), Color(0.45, 1.0, 0.7, 0.3), 2.0)
	var body := Color(0.08, 0.18, 0.14)
	if hit_flash > 0.0 and not SaveData.reduce_flash():
		body = body.lerp(Color(1.0, 0.6, 0.5), 0.5)
	var pts := PackedVector2Array([Vector2(32, 0), Vector2(22, -13), Vector2(-30, -13), Vector2(-32, -9), Vector2(-32, 9), Vector2(-30, 13), Vector2(22, 13)])
	draw_colored_polygon(pts, body)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, GameData.COL_ALLY, 2.0, true)
	for x in [-18.0, -4.0, 10.0]:
		draw_rect(Rect2(Vector2(x - 5.0, -7.0), Vector2(10, 14)), Color(0.4, 0.8, 0.6, 0.7))
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	var w := 70.0
	var top := Vector2(-w * 0.5, -radius - 18.0)
	draw_rect(Rect2(top, Vector2(w, 5)), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(top, Vector2(w * clampf(hull / max_hull, 0.0, 1.0), 5)), GameData.COL_ALLY)
	draw_string_outline(font, Vector2(-100, radius + 26.0), title, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 13, 4, Color(0, 0, 0, 0.8))
	draw_string(font, Vector2(-100, radius + 26.0), title, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 13, GameData.COL_ALLY)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

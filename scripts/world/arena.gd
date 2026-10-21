class_name Arena
extends Node2D

var size: Vector2 = GameData.ARENA_SIZE
var rect := Rect2(Vector2.ZERO, GameData.ARENA_SIZE)
var rocks: Array = []
var time := 0.0


func generate(rng: RandomNumberGenerator, keep_clear: Vector2, count: int, keep_path: Array = []) -> void:
	rocks.clear()
	var gap := 260.0 if count <= 9 else 150.0
	var tries := 0
	while rocks.size() < count and tries < 400:
		tries += 1
		var r := rng.randf_range(40.0, 95.0)
		var p := Vector2(rng.randf_range(260.0, size.x - 260.0), rng.randf_range(260.0, size.y - 260.0))
		if p.distance_to(keep_clear) < 480.0 + r:
			continue
		var blocked := false
		for k in range(1, keep_path.size()):
			var cp := Geometry2D.get_closest_point_to_segment(p, keep_path[k - 1], keep_path[k])
			if cp.distance_to(p) < r + 180.0:
				blocked = true
				break
		if blocked:
			continue
		var ok := true
		for other in rocks:
			if p.distance_to(other["pos"]) < r + float(other["radius"]) + gap:
				ok = false
				break
		if not ok:
			continue
		var poly := PackedVector2Array()
		var pts := 11
		for i in pts:
			var a := TAU * float(i) / float(pts)
			var rr := r * rng.randf_range(0.82, 1.12)
			poly.append(p + Vector2.RIGHT.rotated(a) * rr)
		rocks.append({"pos": p, "radius": r, "poly": poly})
	queue_redraw()


func add_debris_field(rng: RandomNumberGenerator, center: Vector2, field_r: float, pieces: int, keep_clear: Vector2) -> int:
	var placed := 0
	var tries := 0
	while placed < pieces and tries < 120:
		tries += 1
		var r := rng.randf_range(16.0, 32.0)
		var p := center + Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(80.0, field_r - r)
		if p.distance_to(keep_clear) < 260.0 + r:
			continue
		if not rect.grow(-60.0).has_point(p):
			continue
		var ok := true
		for other in rocks:
			if p.distance_to(other["pos"]) < r + float(other["radius"]) + 24.0:
				ok = false
				break
		if not ok:
			continue
		var poly := PackedVector2Array()
		var ang := rng.randf() * TAU
		var stretch := rng.randf_range(1.2, 1.9)
		var corners := [Vector2(-1.0 * stretch, -0.7), Vector2(0.6 * stretch, -0.9), Vector2(1.0 * stretch, -0.1), Vector2(0.7 * stretch, 0.8), Vector2(-0.4 * stretch, 0.9), Vector2(-1.1 * stretch, 0.3)]
		for v in corners:
			poly.append(p + ((v as Vector2) * r * 0.75 * rng.randf_range(0.85, 1.1)).rotated(ang))
		rocks.append({"pos": p, "radius": r, "poly": poly, "kind": "debris", "angle": ang})
		placed += 1
	queue_redraw()
	return placed


func clear_debris_near(center: Vector2, r: float) -> void:
	var i := rocks.size() - 1
	while i >= 0:
		if str(rocks[i].get("kind", "")) == "debris" and (rocks[i]["pos"] as Vector2).distance_to(center) <= r:
			rocks.remove_at(i)
		i -= 1
	queue_redraw()


func clear_rocks() -> void:
	rocks.clear()
	queue_redraw()


func resolve_circle(body: Node2D, bounce: float = 0.5) -> float:
	var impact := 0.0
	var br: float = body.get("radius")
	var vel: Vector2 = body.get("velocity")
	var pos := body.position
	for rock in rocks:
		var rp: Vector2 = rock["pos"]
		var min_d: float = float(rock["radius"]) * 0.92 + br
		var d := pos - rp
		var dist := d.length()
		if dist < min_d and dist > 0.001:
			var n := d / dist
			pos = rp + n * min_d
			var vn := vel.dot(n)
			if vn < 0.0:
				impact = maxf(impact, -vn)
				vel -= n * vn * (1.0 + bounce)
	if pos.x < br:
		pos.x = br
		if vel.x < 0.0:
			impact = maxf(impact, -vel.x * 0.5)
			vel.x = -vel.x * 0.4
	if pos.x > size.x - br:
		pos.x = size.x - br
		if vel.x > 0.0:
			impact = maxf(impact, vel.x * 0.5)
			vel.x = -vel.x * 0.4
	if pos.y < br:
		pos.y = br
		if vel.y < 0.0:
			impact = maxf(impact, -vel.y * 0.5)
			vel.y = -vel.y * 0.4
	if pos.y > size.y - br:
		pos.y = size.y - br
		if vel.y > 0.0:
			impact = maxf(impact, vel.y * 0.5)
			vel.y = -vel.y * 0.4
	body.position = pos
	body.set("velocity", vel)
	return impact


func point_blocked(p: Vector2) -> bool:
	for rock in rocks:
		if p.distance_to(rock["pos"]) < float(rock["radius"]) * 0.85:
			return true
	return false


func is_clear(p: Vector2, clearance: float) -> bool:
	if p.x < clearance or p.y < clearance or p.x > size.x - clearance or p.y > size.y - clearance:
		return false
	for rock in rocks:
		if p.distance_to(rock["pos"]) < float(rock["radius"]) + clearance:
			return false
	return true


func _process(delta: float) -> void:
	time += delta
	if int(time * 4.0) != int((time - delta) * 4.0):
		queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(time * 1.5)
	var border := Color(0.25, 0.75, 0.95, 0.25 + pulse * 0.15)
	var dash := 40.0
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(minf(x + dash * 0.6, size.x), 0), border, 3.0)
		draw_line(Vector2(x, size.y), Vector2(minf(x + dash * 0.6, size.x), size.y), border, 3.0)
		x += dash
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(0, minf(y + dash * 0.6, size.y)), border, 3.0)
		draw_line(Vector2(size.x, y), Vector2(size.x, minf(y + dash * 0.6, size.y)), border, 3.0)
		y += dash
	for rock in rocks:
		var poly: PackedVector2Array = rock["poly"]
		var p: Vector2 = rock["pos"]
		var r: float = rock["radius"]
		if str(rock.get("kind", "")) == "debris":
			draw_colored_polygon(poly, Color(0.17, 0.11, 0.07))
			var dc := poly.duplicate()
			dc.append(poly[0])
			draw_polyline(dc, Color(0.75, 0.48, 0.28, 0.9), 2.0, true)
			var ang: float = float(rock.get("angle", 0.0))
			var a := Vector2(-r * 0.5, 0).rotated(ang)
			draw_line(p - a, p + a, Color(0.5, 0.32, 0.2), 2.0)
			draw_circle(p + Vector2(r * 0.25, -r * 0.2).rotated(ang), 2.5, Color(0.85, 0.55, 0.3, 0.8))
			continue
		draw_circle(p, r * 1.18, Color(0.35, 0.7, 0.85, 0.06 + pulse * 0.03))
		draw_arc(p, r * 1.12, 0.0, TAU, 36, Color(0.6, 0.9, 1.0, 0.18), 2.0, true)
		draw_colored_polygon(poly, Color(0.07, 0.10, 0.14))
		var closed := poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, Color(0.35, 0.55, 0.65), 2.0, true)
		draw_circle(p + Vector2(-r * 0.2, -r * 0.25), r * 0.35, Color(0.12, 0.16, 0.21))

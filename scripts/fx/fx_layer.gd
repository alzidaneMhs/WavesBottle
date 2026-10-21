class_name FxLayer
extends Node2D

const MAX_PARTS := 1200


class Particle:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var life := 1.0
	var max_life := 1.0
	var size := 3.0
	var color := Color.WHITE
	var drag := 2.0


var parts: Array = []
var rings: Array = []
var texts: Array = []
var wakes: Array = []
var flashes: Array = []
var bolts: Array = []
var smokes: Array = []
var density := 1.0
var font: Font


func _ready() -> void:
	density = SaveData.particle_scale()
	font = ThemeDB.fallback_font


func burst(pos: Vector2, count: int, speed: float, color: Color, life: float, size: float, dir: Vector2 = Vector2.ZERO, cone: float = TAU) -> void:
	var n := int(ceil(float(count) * density))
	var base := dir.angle()
	for i in n:
		if parts.size() >= MAX_PARTS:
			return
		var a := randf() * TAU
		if dir != Vector2.ZERO:
			a = base + randf_range(-cone, cone) * 0.5
		var p := Particle.new()
		p.pos = pos
		p.vel = Vector2.RIGHT.rotated(a) * speed * randf_range(0.3, 1.0)
		p.life = life * randf_range(0.6, 1.0)
		p.max_life = p.life
		p.size = size * randf_range(0.7, 1.3)
		p.color = color
		parts.append(p)


func ring(pos: Vector2, radius: float, life: float, color: Color, width: float = 2.0, delay: float = 0.0, start: float = 2.0) -> void:
	rings.append({"pos": pos, "r0": start, "r1": radius, "life": life, "max": life, "color": color, "width": width, "delay": delay})


func text(pos: Vector2, txt: String, color: Color, size: int = 18, life: float = 1.1) -> void:
	if texts.size() > 40:
		texts.pop_front()
	var p := pos
	for _attempt in 6:
		var moved := false
		for t in texts:
			var tp: Vector2 = t["pos"]
			if absf(tp.x - p.x) < 130.0 and absf(tp.y - p.y) < float(size) + 4.0:
				p.y = tp.y - float(size) - 6.0
				moved = true
		if not moved:
			break
	texts.append({"pos": p, "text": txt, "color": color, "life": life, "max": life, "size": size})


func wake_point(pos: Vector2, width: float, color: Color, alpha: float) -> void:
	if wakes.size() > 400:
		wakes.pop_front()
	wakes.append({"pos": pos, "width": width, "color": color, "alpha": alpha, "life": 1.6, "max": 1.6})


func explosion(pos: Vector2, radius: float) -> void:
	burst(pos, int(radius * 0.35), radius * 2.2, Color(1.0, 0.6, 0.25), 0.7, 4.0)
	burst(pos, int(radius * 0.2), radius * 1.2, Color(1.0, 0.9, 0.6), 0.4, 3.0)
	burst(pos, int(radius * 0.15), radius * 0.6, Color(0.4, 0.42, 0.48, 0.7), 1.4, 9.0)
	ring(pos, radius, 0.45, Color(1.0, 0.7, 0.4, 0.9), 3.0)
	if not SaveData.reduce_flash():
		flashes.append({"pos": pos, "radius": radius * 0.8, "life": 0.18, "max": 0.18})


func bolt(a: Vector2, b: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	var n := 7
	var perp := (b - a).normalized().rotated(PI / 2.0)
	for i in n + 1:
		var t := float(i) / float(n)
		var off := 0.0 if i == 0 or i == n else randf_range(-14.0, 14.0)
		pts.append(a.lerp(b, t) + perp * off)
	bolts.append({"pts": pts, "color": color, "life": 0.22, "max": 0.22})


func smoke(pos: Vector2, radius: float, life: float) -> void:
	var puffs: Array = []
	for i in 9:
		puffs.append([Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, radius * 0.6), randf_range(radius * 0.35, radius * 0.6)])
	smokes.append({"pos": pos, "radius": radius, "life": life, "max": life, "puffs": puffs})


func spawn_cue(pos: Vector2, big: bool = false) -> void:
	var r := 90.0 if big else 46.0
	var col := Color(1.0, 0.35, 0.3, 0.85)
	for i in 3:
		ring(pos, r, 0.6, col, 2.5, float(i) * 0.3, r * 0.2)


func _process(delta: float) -> void:
	var i := parts.size() - 1
	while i >= 0:
		var p: Particle = parts[i]
		p.life -= delta
		if p.life <= 0.0:
			parts.remove_at(i)
		else:
			p.pos += p.vel * delta
			p.vel *= exp(-p.drag * delta)
		i -= 1
	_tick(rings, delta, true)
	_tick(texts, delta, false)
	_tick(wakes, delta, false)
	_tick(flashes, delta, false)
	_tick(bolts, delta, false)
	_tick(smokes, delta, false)
	for t in texts:
		t["pos"] = (t["pos"] as Vector2) + Vector2(0, -38.0 * delta)
	queue_redraw()


func _tick(list: Array, delta: float, use_delay: bool) -> void:
	var i := list.size() - 1
	while i >= 0:
		var d: Dictionary = list[i]
		if use_delay and float(d["delay"]) > 0.0:
			d["delay"] = float(d["delay"]) - delta
		else:
			d["life"] = float(d["life"]) - delta
			if float(d["life"]) <= 0.0:
				list.remove_at(i)
		i -= 1


func _draw() -> void:
	for w in wakes:
		var t: float = float(w["life"]) / float(w["max"])
		var col: Color = w["color"]
		var r: float = float(w["width"]) * (1.0 + (1.0 - t) * 1.8)
		var a: float = float(w["alpha"]) * t
		draw_circle(w["pos"], r, Color(col, a * 0.22))
		draw_arc(w["pos"], r, 0.0, TAU, 12, Color(col, a * 0.5), 1.2)
	for sm in smokes:
		var st: float = float(sm["life"]) / float(sm["max"])
		var fade := minf(1.0, st * 4.0) * minf(1.0, (1.0 - st) * 6.0 + 0.2)
		var c: Vector2 = sm["pos"]
		for pf in sm["puffs"]:
			var off: Vector2 = pf[0]
			draw_circle(c + off * (1.0 + (1.0 - st) * 0.3), float(pf[1]), Color(0.55, 0.6, 0.66, 0.32 * fade))
	for bl in bolts:
		var bt: float = float(bl["life"]) / float(bl["max"])
		var bc: Color = bl["color"]
		draw_polyline(bl["pts"], Color(bc, 0.35 * bt), 7.0)
		draw_polyline(bl["pts"], Color(1.0, 1.0, 1.0, bt), 2.0)
	for f in flashes:
		var ft: float = float(f["life"]) / float(f["max"])
		draw_circle(f["pos"], float(f["radius"]) * (1.2 - ft * 0.4), Color(1.0, 0.92, 0.75, ft * 0.6))
	for p in parts:
		var pp: Particle = p
		var pt := pp.life / pp.max_life
		draw_circle(pp.pos, maxf(0.5, pp.size * (0.4 + pt * 0.6)), Color(pp.color, pp.color.a * pt))
	for rg in rings:
		if float(rg["delay"]) > 0.0:
			continue
		var rt: float = 1.0 - float(rg["life"]) / float(rg["max"])
		var rr: float = lerpf(float(rg["r0"]), float(rg["r1"]), rt)
		var rc: Color = rg["color"]
		draw_arc(rg["pos"], rr, 0.0, TAU, 32, Color(rc, rc.a * (1.0 - rt)), float(rg["width"]), true)
	for tx in texts:
		var tt: float = float(tx["life"]) / float(tx["max"])
		var tc: Color = tx["color"]
		var size: int = int(tx["size"])
		var tp: Vector2 = (tx["pos"] as Vector2) - Vector2(150, 0)
		draw_string_outline(font, tp, str(tx["text"]), HORIZONTAL_ALIGNMENT_CENTER, 300.0, size, 4, Color(0.0, 0.02, 0.05, tt * 0.8))
		draw_string(font, tp, str(tx["text"]), HORIZONTAL_ALIGNMENT_CENTER, 300.0, size, Color(tc, minf(1.0, tt * 1.5)))

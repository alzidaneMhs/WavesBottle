class_name FittingPreview
extends Control

var stats: ShipStats
var font: Font


func _ready() -> void:
	custom_minimum_size = Vector2(380, 380)
	font = ThemeDB.fallback_font


func set_stats(s: ShipStats) -> void:
	stats = s
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.04, 0.08, 0.9))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.5, 0.65, 0.4), false, 1.0)
	if stats == null:
		return
	var c := size * 0.5
	var max_r := minf(size.x, size.y) * 0.46
	var scale_f := max_r / 900.0
	for ring in [250.0, 500.0, 750.0]:
		draw_arc(c, ring * scale_f, 0.0, TAU, 48, Color(0.3, 0.6, 0.8, 0.12), 1.0, true)
	draw_string(font, c + Vector2(500.0, -500.0) * scale_f * 0.707 + Vector2(4, -4), "500", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.7, 0.8, 0.6))
	for st in stats.stations:
		var slot: String = st["slot"]
		var w := stats.profile(st)
		var r: float = float(w["range"]) * (0.8 if str(w.get("pattern", "")) == "mortar" else 1.0) * scale_f
		var center := WeaponFire.slot_angle(slot) - PI / 2.0
		var half := WeaponFire.slot_half(slot, w)
		var col: Color = GameData.SLOT_COLORS[slot]
		var pts := PackedVector2Array([c])
		for i in 17:
			pts.append(c + Vector2.RIGHT.rotated(center - half + half * 2.0 * float(i) / 16.0) * r)
		draw_colored_polygon(pts, Color(col, 0.12))
		draw_arc(c, r, center - half, center + half, 24, Color(col, 0.8), 2.0, true)
		var lp := c + Vector2.RIGHT.rotated(center) * (r + 14.0)
		draw_string(font, lp - Vector2(40, -4), str(w["short"]), HORIZONTAL_ALIGNMENT_CENTER, 80.0, 12, col)
	var l: float = float(stats.look.get("length", 52.0)) * 1.6
	var wd: float = float(stats.look.get("width", 21.0)) * 1.6
	var b: float = float(stats.look.get("bow", 0.55))
	var shoulder := l * 0.5 - l * b * 0.4
	var hull := PackedVector2Array([Vector2(0, -l * 0.5), Vector2(-wd * 0.5, -shoulder), Vector2(-wd * 0.5, l * 0.4), Vector2(-wd * 0.33, l * 0.5), Vector2(wd * 0.33, l * 0.5), Vector2(wd * 0.5, l * 0.4), Vector2(wd * 0.5, -shoulder)])
	for i in hull.size():
		hull[i] += c
	draw_colored_polygon(hull, Color(0.05, 0.12, 0.19))
	var closed := hull.duplicate()
	closed.append(hull[0])
	draw_polyline(closed, stats.look.get("accent", GameData.COL_PLAYER), 2.0, true)
	draw_string(font, Vector2(8, size.y - 10.0), "Bow up. Rings every 250 range.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.75, 0.85, 0.7))

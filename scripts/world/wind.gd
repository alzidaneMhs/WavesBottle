class_name Wind
extends RefCounted

var angle := 0.0
var strength := 0.6
var target_angle := 0.0
var target_strength := 0.6
var timer := 24.0
var warned := false
var shifting := false
var rng: RandomNumberGenerator
var min_strength := 0.0
var pace := 1.0


func _init(p_rng: RandomNumberGenerator) -> void:
	rng = p_rng
	angle = rng.randf_range(-PI, PI)
	target_angle = angle
	strength = rng.randf_range(0.45, 0.8)
	target_strength = strength
	timer = rng.randf_range(20.0, 28.0)


func dir() -> Vector2:
	return Vector2.RIGHT.rotated(angle)


func update(dt: float) -> int:
	var event := 0
	if shifting:
		var diff := wrapf(target_angle - angle, -PI, PI)
		var step := 0.7 * dt
		if absf(diff) <= step:
			angle = target_angle
		else:
			angle = wrapf(angle + signf(diff) * step, -PI, PI)
		strength = move_toward(strength, target_strength, 0.25 * dt)
		if absf(diff) <= step and absf(strength - target_strength) < 0.01:
			shifting = false
			warned = false
			timer = rng.randf_range(22.0, 32.0) * pace
		return event
	timer -= dt
	if not warned and timer <= 3.0:
		warned = true
		var turn := rng.randf_range(0.7, 2.2) * (1.0 if rng.randf() < 0.5 else -1.0)
		target_angle = wrapf(angle + turn, -PI, PI)
		target_strength = maxf(min_strength, rng.randf_range(0.35, 1.0))
		event = 1
	if timer <= 0.0:
		shifting = true
		event = 2
	return event


func force_shift() -> void:
	timer = 3.0
	warned = false


func propulsion_factor(fwd: Vector2, stats: ShipStats) -> float:
	var d := fwd.dot(dir())
	if d >= 0.0:
		return 1.0 + stats.get_value("wind_bonus") * strength * d
	return maxf(0.7, 1.0 + stats.get_value("wind_penalty") * strength * d)


func cross_push(fwd: Vector2, stats: ShipStats) -> Vector2:
	var w := dir()
	var lat := w - fwd * fwd.dot(w)
	return lat * stats.get_value("crosswind") * strength


func compass_name() -> String:
	var names := ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
	var idx := posmod(int(round(angle / (PI / 4.0))), 8)
	return names[idx]

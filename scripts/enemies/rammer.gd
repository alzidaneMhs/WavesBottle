class_name Rammer
extends Enemy

var state := "stalk"
var state_time := 0.0
var charge_dir := Vector2.RIGHT
var hit_list: Array = []


func _on_setup() -> void:
	side_gunned = false


func _go(s: String, t: float) -> void:
	state = s
	state_time = t


func _think(dt: float) -> void:
	state_time -= dt
	var t = target()
	var tp: Vector2 = t.position
	var to := tp - position
	var dist := to.length()
	match state:
		"stalk":
			var dirn := to.normalized() if dist > 0.01 else Vector2.RIGHT
			var goal := tp - dirn * 330.0 + dirn.rotated(PI / 2.0 * orbit_sign) * 140.0
			steer_to_point(goal, speed, dt)
			if cooldown <= 0.0 and dist < 560.0 and t.alive:
				_go("aim", 1.4)
		"aim":
			steer_to_angle(to.angle(), speed * 0.3, dt)
			if absf(wrapf(to.angle() - rotation, -PI, PI)) < 0.1 or state_time <= 0.0:
				_go("windup", float(data["windup"]))
				winding = true
				Sound.play("warning", position, -6.0, 0.8)
		"windup":
			steer_to_angle(rotation, 0.0, dt)
			if state_time <= 0.0:
				winding = false
				charge_dir = forward()
				hit_list.clear()
				_go("charge", 1.3)
				Sound.play("dodge", position, 0.0, 0.5)
		"charge":
			velocity = charge_dir * float(data["charge_speed"]) * slow_factor()
			position += velocity * dt
			run.fx_under.burst(position - charge_dir * radius, 1, 40.0, Color(1.0, 0.6, 0.4, 0.7), 0.4, 3.0)
			for f in run.friendlies:
				if not f.alive or not f.physical or hit_list.has(f):
					continue
				if position.distance_to(f.position) <= radius + float(f.radius) + 6.0:
					hit_list.append(f)
					f.take_damage(float(data["damage"]), "Rammer charge", position)
					if f == run.player:
						run.player.velocity += charge_dir * 260.0
					run.add_shake(8.0)
			var ahead := position + charge_dir * (radius + 20.0)
			if state_time <= 0.0 or run.arena.point_blocked(ahead) or not run.arena.rect.grow(-30.0).has_point(ahead):
				_go("recover", 1.6)
				exposed = true
		"recover":
			velocity *= exp(-3.0 * dt)
			position += velocity * dt
			if state_time <= 0.0:
				exposed = false
				cooldown = float(data["cooldown"]) * run.rng.randf_range(0.85, 1.15)
				_go("stalk", 0.0)


func interrupt() -> void:
	_go("recover", 1.0)
	exposed = true
	run.fx_over.text(position + Vector2(0, -36), "CHARGE STALLED", Color(0.6, 1.0, 0.9), 15, 0.9)


func on_contact(f, rel: float) -> void:
	if state == "charge":
		return
	super.on_contact(f, rel)


func _draw_ship() -> void:
	if state == "windup":
		var prog := 1.0 - clampf(state_time / float(data["windup"]), 0.0, 1.0)
		draw_forward_lane(float(data["charge_speed"]) * 1.3, radius * 0.9, prog)
	if state == "aim":
		draw_forward_lane(float(data["charge_speed"]) * 1.3, radius * 0.9, 0.0)
	var body := Color(0.22, 0.08, 0.06)
	if state == "charge":
		body = Color(0.45, 0.15, 0.08)
	draw_hull(44.0, 24.0, body, GameData.COL_ENEMY if not exposed else Color(0.4, 1.0, 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(22, -6), Vector2(34, 0), Vector2(22, 6)]), Color(0.85, 0.7, 0.6))
	draw_circle(Vector2(-6, 0), 4.0, Color(1.0, 0.55, 0.35) if state in ["windup", "charge"] else Color(0.7, 0.45, 0.35))

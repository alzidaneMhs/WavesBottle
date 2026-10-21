class_name WeaponFire
extends RefCounted

const TURRET_HALF := 2.0


static func slot_dir(slot: String, fwd: Vector2) -> Vector2:
	match slot:
		"port":
			return fwd.rotated(-PI / 2.0)
		"starboard":
			return fwd.rotated(PI / 2.0)
		"stern":
			return -fwd
	return fwd


static func slot_angle(slot: String) -> float:
	match slot:
		"port":
			return -PI / 2.0
		"starboard":
			return PI / 2.0
		"stern":
			return PI
	return 0.0


static func arc_half(w: Dictionary) -> float:
	match str(w.get("pattern", "volley")):
		"pellets":
			return 0.36
		"arc":
			return float(w.get("arc", 0.75))
		"mortar":
			return 0.15
	return 0.2


static func slot_half(slot: String, w: Dictionary) -> float:
	if slot == "turret":
		return TURRET_HALF
	return arc_half(w)


static func aim_dir(ship, slot: String) -> Vector2:
	var fwd: Vector2 = Vector2.RIGHT.rotated(ship.rotation)
	if slot == "turret":
		return fwd.rotated(float(ship.get("turret_angle")))
	return slot_dir(slot, fwd)


static func _assist(run, origin: Vector2, dir: Vector2, reach: float) -> Vector2:
	if not bool(SaveData.setting("aim_assist")):
		return dir
	var best_ang := 0.25
	var best := dir
	if run.jammed:
		return dir
	for e in run.enemies:
		if not e.alive or e.hidden():
			continue
		var to: Vector2 = (e.position as Vector2) - origin
		if to.length() > reach:
			continue
		var ang := dir.angle_to(to)
		if absf(ang) < best_ang:
			best_ang = absf(ang)
			best = dir.rotated(clampf(ang, -0.12, 0.12))
	return best


static func fire(run, ship, slot: String, w: Dictionary) -> int:
	var fwd: Vector2 = Vector2.RIGHT.rotated(ship.rotation)
	var dir := aim_dir(ship, slot)
	var lateral := dir.rotated(PI / 2.0)
	var pos: Vector2 = ship.position
	var radius: float = ship.radius
	var barrels: int = int(w["barrels"])
	var pattern: String = str(w.get("pattern", "volley"))
	var count := 0
	var broadside := slot == "port" or slot == "starboard"
	var length: float = float(ship.stats.look.get("length", 52.0))
	var bonus := 1.0
	if ship.stats.has_flag("resonant_wake") and run.wake.tier >= 3:
		bonus = 1.1
	match pattern:
		"mortar":
			var shells := maxi(1, int(ceil(float(barrels) / 2.0)))
			var cluster := maxi(1, int(w.get("cluster", 1)))
			for i in shells:
				var t := 0.0 if shells == 1 else lerpf(-1.0, 1.0, float(i) / float(shells - 1))
				var target: Vector2 = pos + dir * float(w["range"]) * 0.8 + lateral * t * 70.0 + Vector2(run.rng.randf_range(-15, 15), run.rng.randf_range(-15, 15))
				for c in cluster:
					var off := Vector2.ZERO
					if cluster > 1:
						off = Vector2.RIGHT.rotated(TAU * float(c) / float(cluster) + run.rng.randf() * 0.6) * 62.0
					run.shots.add_mortar(target + off, float(w.get("delay", 1.0)) + float(i) * 0.08 + float(c) * 0.06, float(w.get("blast", 70.0)), float(w["damage"]) * bonus, "Mortar", false, 0)
				run.fx_over.burst(pos + dir * radius, 4, 80.0, Color(1.0, 0.8, 0.5), 0.3, 3.0, dir, 0.8)
				count += 1
			Sound.play("cannon", pos + dir * 40.0, -4.0, 0.7)
			return count
		"arc":
			return _fire_arc(run, ship, dir, w, bonus)
	var shots := barrels
	if pattern == "heavy":
		shots = maxi(1, int(ceil(float(barrels) / 2.0)))
	elif pattern == "single":
		shots = 1
	for i in shots:
		var t := 0.0 if shots == 1 else lerpf(-1.0, 1.0, float(i) / float(shots - 1))
		var origin: Vector2
		if slot == "turret":
			origin = pos + fwd * length * 0.08 + dir * 14.0 + lateral * t * 5.0
		elif broadside:
			origin = pos + fwd * t * length * 0.26 + dir * (radius - 4.0)
		else:
			origin = pos + dir * (length * 0.45) + lateral * t * 6.0
		var aim := _assist(run, origin, dir, float(w["range"]))
		var pellets := int(w.get("pellets", 0)) if pattern == "pellets" else 1
		for p in pellets:
			var ang: float = run.rng.randf_range(-float(w["spread"]), float(w["spread"]))
			var spd: float = float(w["speed"]) * run.rng.randf_range(0.95, 1.04)
			if pattern == "torpedo":
				spd = float(w["speed"])
			var v: Vector2 = aim.rotated(ang) * spd + (ship.velocity as Vector2) * (0.5 if pattern != "torpedo" else 1.0)
			var s = run.shots.spawn(0, origin, v, float(w["range"]) / spd, float(w["damage"]) * bonus, pattern if pattern in ["torpedo", "single"] else str(w.get("id", "roundshot")), pos, float(w.get("radius", 5.0)), w["color"])
			if s != null:
				s.armor_pierce = bool(w.get("armor_pierce", false))
				s.weapon = str(w.get("id", ""))
				s.status = str(w.get("status", ""))
				s.status_a = float(w.get("slow", 0.0))
				s.status_t = float(w.get("slow_time", w.get("harpoon_time", 0.0)))
				s.blast = float(w.get("blast", 0.0))
				s.pierce = int(w.get("pierce", 0))
				s.homing = float(w.get("homing", 0.0))
				s.spark = bool(w.get("spark", false))
			count += 1
		run.fx_over.burst(origin + dir * 6.0, 4, 90.0, Color(1.0, 0.85, 0.6), 0.25, 3.0, dir, 0.6)
		run.fx_over.burst(origin + dir * 10.0, 3, 40.0, Color(0.6, 0.65, 0.7, 0.5), 0.8, 6.0, dir, 0.9)
	var pitch: float = 1.0
	if pattern == "torpedo":
		pitch = 0.6
	elif pattern == "single":
		pitch = 1.4
	elif str(w.get("id", "")) == "longbore":
		pitch = 0.8
	Sound.play("cannon", pos + dir * 40.0, -2.0 if broadside else -5.0, pitch * run.rng.randf_range(0.94, 1.06))
	return count


static func _fire_arc(run, ship, dir: Vector2, w: Dictionary, bonus: float) -> int:
	var pos: Vector2 = ship.position
	var reach: float = float(w["range"])
	var half: float = float(w.get("arc", 0.75))
	var first = null
	var best := reach
	for e in run.enemies:
		if not e.alive or e.hidden():
			continue
		var to: Vector2 = (e.position as Vector2) - pos
		var dist := to.length()
		if dist < best and absf(dir.angle_to(to)) <= half:
			best = dist
			first = e
	Sound.play("impact", pos, -2.0, 0.55)
	if first == null:
		run.fx_over.bolt(pos + dir * 20.0, pos + dir * reach * 0.5, Color(0.6, 0.85, 1.0, 0.6))
		return 1
	var hit: Array = [first]
	var from := pos + dir * 16.0
	var dmg: float = float(w["damage"]) * bonus
	var cur = first
	var jumps := int(w.get("jumps", 2))
	var tag := "overload" if bool(w.get("overload", false)) else "arc"
	for j in jumps + 1:
		if cur == null:
			break
		run.fx_over.bolt(from, cur.position, Color(0.65, 0.9, 1.0))
		run.fx_over.burst(cur.position, 6, 120.0, Color(0.7, 0.9, 1.0), 0.3, 2.5)
		cur.receive_hit(dmg, pos, bool(w.get("armor_pierce", false)), tag)
		run.on_shot_result(true)
		from = cur.position
		dmg *= 0.8
		var nxt = null
		var nd: float = float(w.get("jump_range", 170.0))
		for e in run.enemies:
			if not e.alive or hit.has(e) or e.hidden():
				continue
			var dd: float = (e.position as Vector2).distance_to(from)
			if dd < nd:
				nd = dd
				nxt = e
		if nxt != null:
			hit.append(nxt)
		cur = nxt
	return hit.size()

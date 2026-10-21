class_name PlayerShip
extends Node2D

var run
var stats: ShipStats
var velocity := Vector2.ZERO
var ang_vel := 0.0
var throttle := 0.0
var hull := 100.0
var radius := 18.0
var forward_speed := 0.0
var lateral_speed := 0.0
var slots: Array = []
var profiles: Dictionary = {}
var reload: Dictionary = {}
var buffer: Dictionary = {}
var muzzle: Dictionary = {}
var invuln := 0.0
var immune := 0.0
var hit_flash := 0.0
var fire_lock := false
var bulkhead_used := false
var god_mode := false
var drifting := false
var drift_latched := false
var braking := false
var alive := true
var physical := true
var wake_timer := 0.0
var pass_cooldown := 0.0
var turn_accum := 0.0
var brake_time := 0.0
var ability_cd := 0.0
var charge := 0.0
var brace_energy := 1.0
var bracing := false
var surge_timer := 0.0
var module_cd: Array = []
var module_charges: Array = []
var heal_left := 0.0
var heal_rate := 0.0
var reef_hits := 0
var mastery := 1
var turret_angle := 0.0
var turret_target = null
var raid_timer := 0.0
var focus_timer := 0.0
var tether_timer := 0.0
var tether_node = null
var ward_charges := 0
var ward_recharge := 0.0
var overdrive_timer := 0.0
var slump_timer := 0.0


func setup(p_run, p_stats: ShipStats) -> void:
	run = p_run
	stats = p_stats
	hull = stats.get_value("max_hull")
	radius = stats.get_value("radius")
	rotation = -PI / 2.0
	mastery = Profile.mastery_level(stats.ship_id)
	rebuild_weapons()
	ward_charges = ward_max()
	module_cd.clear()
	module_charges.clear()
	for m in stats.modules:
		module_cd.append(0.0)
		module_charges.append(-1)


func rebuild_weapons() -> void:
	slots.clear()
	profiles.clear()
	for st in stats.stations:
		var slot: String = st["slot"]
		slots.append(slot)
		profiles[slot] = stats.profile(st)
		if not reload.has(slot):
			reload[slot] = 0.0
			buffer[slot] = 0.0
			muzzle[slot] = 0.0


func forward() -> Vector2:
	return Vector2.RIGHT.rotated(rotation)


func reload_ratio(slot: String) -> float:
	var r: float = float(profiles[slot]["reload"])
	if r <= 0.0:
		return 1.0
	return 1.0 - clampf(float(reload[slot]) / r, 0.0, 1.0)


func _ability_cooldown() -> float:
	var cd: float = float(ability_def().get("cooldown", 1.0)) * stats.get_value("ability_cd_mult")
	if stats.ability == "resonance_cascade" and stats.has_flag("feedback"):
		cd = 6.0
	return cd


func resonance_tier() -> int:
	return int(run.wake.tier) + (1 if stats.has_flag("harmonic") else 0)


func ward_max() -> int:
	if stats.ability != "ward_buoy":
		return 0
	return int(GameData.ABILITIES["ward_buoy"]["charges"]) + int(stats.get_value("ward_charges"))


func apply_tether(src, duration: float) -> void:
	if immune > 0.0 or god_mode and run.mode == "practice":
		return
	tether_timer = duration
	tether_node = src
	run.banner("TETHERED", "Turning halved - sail 560 px away to snap the line", Color(0.6, 1.0, 0.8))


func snap_tether(reason: String) -> void:
	if tether_timer <= 0.0:
		return
	tether_timer = 0.0
	tether_node = null
	run.on_style_event(reason, 8.0, 60, position)


func ability_def() -> Dictionary:
	return GameData.ABILITIES.get(stats.ability, {})


func ability_ratio() -> float:
	match stats.ability:
		"quick_reload", "side_slip", "resonance_cascade":
			var cd: float = _ability_cooldown()
			return 1.0 - clampf(ability_cd / cd, 0.0, 1.0)
		"ward_buoy":
			return float(ward_charges) / float(maxi(1, ward_max()))
		"armor_brace":
			return brace_energy
		"gale_surge":
			if surge_timer > 0.0:
				return surge_timer / float(ability_def()["duration"])
		"plunder_raid":
			if raid_timer > 0.0:
				return raid_timer / (float(ability_def()["duration"]) + stats.get_value("raid_time"))
		"steady_aim":
			if focus_timer > 0.0:
				return focus_timer / float(ability_def()["duration"])
	return charge


func ability_ready() -> bool:
	match stats.ability:
		"quick_reload", "side_slip":
			return ability_cd <= 0.0
		"resonance_cascade":
			return ability_cd <= 0.0 and run.wake.tier >= 1
		"ward_buoy":
			return ward_charges > 0
		"armor_brace":
			return brace_energy > 0.1
	return charge >= 1.0 and surge_timer <= 0.0 and raid_timer <= 0.0 and focus_timer <= 0.0


func _physics_process(delta: float) -> void:
	if not alive or run == null:
		return
	if run.state == "ended":
		return
	var dt := minf(delta, 0.05)
	invuln = maxf(0.0, invuln - dt)
	immune = maxf(0.0, immune - dt)
	hit_flash = maxf(0.0, hit_flash - dt)
	pass_cooldown = maxf(0.0, pass_cooldown - dt)
	ability_cd = maxf(0.0, ability_cd - dt)
	surge_timer = maxf(0.0, surge_timer - dt)
	raid_timer = maxf(0.0, raid_timer - dt)
	focus_timer = maxf(0.0, focus_timer - dt)
	if overdrive_timer > 0.0:
		overdrive_timer -= dt
		if overdrive_timer <= 0.0:
			slump_timer = float(GameData.ACTIVE_MODULES["overdrive"]["slump"])
	slump_timer = maxf(0.0, slump_timer - dt)
	if ward_charges < ward_max():
		ward_recharge += dt
		if ward_recharge >= float(GameData.ABILITIES["ward_buoy"]["recharge"]):
			ward_recharge = 0.0
			ward_charges += 1
	if tether_timer > 0.0:
		tether_timer -= dt
		if tether_node == null or not is_instance_valid(tether_node) or not tether_node.alive:
			tether_timer = 0.0
			tether_node = null
		elif position.distance_to(tether_node.position) > float(tether_node.data.get("break_range", 560.0)):
			snap_tether("TETHER SNAPPED")
	for slot in slots:
		muzzle[slot] = maxf(0.0, float(muzzle[slot]) - dt)
	for i in module_cd.size():
		module_cd[i] = maxf(0.0, float(module_cd[i]) - dt)
	if heal_left > 0.0:
		var h := minf(heal_left, heal_rate * dt)
		heal_left -= h
		heal(h)
	var control: bool = run.controls_enabled()
	_update_movement(dt, control)
	_update_ability(dt, control)
	_update_turret(dt)
	_update_weapons(dt, control)
	_update_modules(control)
	_update_collisions()
	_update_wake(dt)
	_check_passes()
	queue_redraw()


func _update_movement(dt: float, control: bool) -> void:
	var fwd := forward()
	var right := fwd.rotated(PI / 2.0)
	var turn_in := 0.0
	var thr_in := 0.0
	if control:
		turn_in = Input.get_axis("turn_left", "turn_right")
		thr_in = Input.get_axis("throttle_down", "throttle_up")
	throttle = clampf(throttle + thr_in * 0.9 * dt, -stats.get_value("reverse_ratio"), 1.0)
	forward_speed = velocity.dot(fwd)
	lateral_speed = velocity.dot(right)
	braking = thr_in < 0.0 and forward_speed > 20.0
	var want_drift := false
	if control:
		if bool(SaveData.setting("drift_toggle")):
			if Input.is_action_just_pressed("drift"):
				drift_latched = not drift_latched
			want_drift = drift_latched
		else:
			want_drift = Input.is_action_pressed("drift")
	drifting = want_drift and absf(forward_speed) > 80.0
	var wind_mult: float = run.wind.propulsion_factor(fwd, stats)
	var max_speed := stats.get_value("max_speed")
	var accel := stats.get_value("accel")
	if surge_timer > 0.0:
		max_speed *= 1.35
		accel *= 1.5
	if raid_timer > 0.0:
		max_speed *= 1.2
		accel *= 1.3
	if overdrive_timer > 0.0:
		max_speed *= 1.3
		accel *= 1.4
	elif slump_timer > 0.0:
		max_speed *= 0.7
		accel *= 0.6
	if bracing:
		max_speed *= 0.5
	var target := throttle * max_speed * wind_mult
	if braking:
		forward_speed = move_toward(forward_speed, minf(target, 0.0), stats.get_value("brake") * dt)
		brake_time += dt
		if brake_time > 0.35 and forward_speed > 60.0:
			run.tutorial_event("brake")
	elif absf(target) >= absf(forward_speed) or signf(target) != signf(forward_speed):
		forward_speed = move_toward(forward_speed, target, accel * dt)
	else:
		forward_speed = move_toward(forward_speed, target, accel * 0.45 * dt)
	if not braking:
		brake_time = 0.0
	var grip := stats.get_value("drift_lateral") if drifting else stats.get_value("lateral")
	lateral_speed *= exp(-grip * dt)
	velocity = fwd * forward_speed + right * lateral_speed
	velocity += run.wind.cross_push(fwd, stats) * dt
	var ratio := clampf(absf(forward_speed) / stats.get_value("max_speed"), 0.0, 1.0)
	var turn_rate := stats.get_value("turn") * lerpf(stats.get_value("low_turn"), 1.0, ratio)
	if drifting:
		turn_rate *= 1.3
	if bracing and not stats.has_flag("brace_turn"):
		turn_rate *= 0.6
	if stats.has_flag("vane_rudder") and (drifting or ratio < 0.5):
		turn_rate *= 1.3
	if tether_timer > 0.0:
		turn_rate *= 0.5
	ang_vel = move_toward(ang_vel, turn_in * turn_rate, stats.get_value("turn_accel") * dt)
	rotation = wrapf(rotation + ang_vel * dt, -PI, PI)
	turn_accum += absf(ang_vel * dt)
	if turn_accum > 2.0:
		run.tutorial_event("turn")
	if throttle > 0.4:
		run.tutorial_event("throttle")
	if drifting and absf(lateral_speed) > 80.0:
		run.tutorial_event("drift")
	velocity = velocity.limit_length(max_speed * 1.35)
	var flow: Vector2 = run.hazards.flow_at(position, stats.has_flag("storm_immune")) * stats.get_value("flow_mult")
	position += (velocity + flow) * dt
	if stats.ability == "gale_surge" and surge_timer <= 0.0 and wind_mult > 1.0:
		var bonus := maxf(0.01, stats.get_value("wind_bonus"))
		charge = minf(1.0, charge + float(ability_def()["wind_rate"]) * clampf((wind_mult - 1.0) / bonus, 0.0, 1.0) * stats.get_value("wind_charge_mult") * dt)
	if stats.ability == "speed_burst" and forward_speed > stats.get_value("max_speed") * 0.75:
		charge = minf(1.0, charge + float(ability_def()["charge_rate"]) * stats.get_value("charge_mult") * dt)
	if stats.ability == "steady_aim" and focus_timer <= 0.0:
		if absf(ang_vel) < 0.3:
			charge = minf(1.0, charge + float(ability_def()["charge_rate"]) * stats.get_value("charge_mult") * dt)
		elif absf(ang_vel) > 1.0:
			charge = maxf(0.0, charge - float(ability_def()["drain"]) * dt)
	if stats.has_flag("storm_wake") and flow.length() > 40.0 and run.state == "combat":
		run.wake.add(3.0 * dt, "RIDING THE SEA", "storm")


func _update_ability(dt: float, control: bool) -> void:
	var def := ability_def()
	if stats.ability == "armor_brace":
		var held := control and Input.is_action_pressed("ability")
		if held and brace_energy > 0.02:
			if not bracing:
				Sound.play("impact", position, -6.0, 0.6)
				run.tutorial_event("ability")
			bracing = true
			brace_energy = maxf(0.0, brace_energy - float(def["drain"]) * stats.get_value("brace_drain_mult") * dt)
		else:
			bracing = false
			brace_energy = minf(1.0, brace_energy + float(def["regen"]) * dt)
		return
	if not control or not Input.is_action_just_pressed("ability"):
		return
	match stats.ability:
		"quick_reload":
			if ability_cd > 0.0:
				Sound.ui("deny")
				return
			for slot in slots:
				reload[slot] = 0.0
			ability_cd = float(def["cooldown"]) * stats.get_value("ability_cd_mult")
			run.fx_over.ring(position, 70.0, 0.4, Color(0.55, 0.95, 1.0, 0.9), 3.0)
			Sound.play("ready", position, -2.0, 0.8)
		"speed_burst":
			if charge < 1.0:
				Sound.ui("deny")
				return
			var side := Input.get_axis("turn_left", "turn_right")
			velocity += forward() * float(def["impulse"]) + forward().rotated(PI / 2.0) * side * 140.0
			immune = float(def["immunity"]) + stats.get_value("burst_immunity")
			charge = 0.0
			run.fx_over.burst(position, 16, 200.0, Color(0.5, 1.0, 0.8), 0.5, 3.0, -forward(), 1.2)
			Sound.play("dodge", position, 0.0, 0.7)
		"gale_surge":
			if charge < 1.0 or surge_timer > 0.0:
				Sound.ui("deny")
				return
			surge_timer = float(def["duration"])
			charge = 0.0
			run.fx_over.ring(position, 120.0, 0.6, Color(0.75, 0.85, 1.0, 0.9), 3.0)
			Sound.play("wind", position, 0.0, 1.3)
		"resonance_cascade":
			if ability_cd > 0.0 or run.wake.tier < 1:
				Sound.ui("deny")
				return
			if not (stats.has_flag("feedback") and run.wake.tier >= 4):
				run.wake.drop_tier("CASCADE")
			var nb := int(def["bolts"])
			for k in nb:
				var bd := Vector2.RIGHT.rotated(TAU * float(k) / float(nb) + rotation)
				var sb = run.shots.spawn(0, position + bd * (radius + 4.0), bd * 620.0, 420.0 / 620.0, float(def["damage"]), "cascade", position, 5.0, Color(1.0, 0.6, 0.9))
				if sb != null:
					sb.pierce = 1
					sb.weapon = "cascade"
			ability_cd = _ability_cooldown()
			run.fx_over.ring(position, 120.0, 0.5, Color(1.0, 0.6, 0.9, 0.9), 4.0)
			Sound.play("ready", position, 0.0, 0.5)
		"pressure_pulse":
			if charge < 1.0:
				Sound.ui("deny")
				return
			charge = 0.0
			run.shock_pulse(position, float(def["radius"]), float(def["damage"]), 380.0, 0.5 if stats.has_flag("undertow") else 0.0)
			run.fx_over.ring(position, float(def["radius"]), 0.4, Color(1.0, 0.55, 0.6, 0.9), 5.0)
		"side_slip":
			if ability_cd > 0.0:
				Sound.ui("deny")
				return
			var dir_in := Input.get_axis("turn_left", "turn_right")
			var side_s := 1.0 if dir_in >= 0.0 else -1.0
			velocity += forward().rotated(PI / 2.0) * side_s * float(def["impulse"])
			immune = float(def["immunity"])
			ability_cd = float(def["cooldown"]) * stats.get_value("ability_cd_mult")
			run.fx_over.burst(position, 14, 180.0, Color(0.55, 0.75, 1.0), 0.4, 3.0, -forward().rotated(PI / 2.0) * side_s, 1.0)
			Sound.play("dodge", position, 0.0, 1.1)
		"ward_buoy":
			if ward_charges <= 0:
				Sound.ui("deny")
				return
			ward_charges -= 1
			run.hazards.add_ward(position - forward() * 34.0, float(def["radius"]) + stats.get_value("ward_radius"), float(def["duration"]))
		"plunder_raid":
			if charge < 1.0 or raid_timer > 0.0:
				Sound.ui("deny")
				return
			raid_timer = float(def["duration"]) + stats.get_value("raid_time")
			charge = 0.0
			run.fx_over.ring(position, 110.0, 0.5, Color(1.0, 0.8, 0.4, 0.9), 3.0)
			Sound.play("dodge", position, 0.0, 0.9)
		"steady_aim":
			if charge < 1.0 or focus_timer > 0.0:
				Sound.ui("deny")
				return
			focus_timer = float(def["duration"])
			charge = 0.0
			run.fx_over.ring(position, 90.0, 0.5, Color(0.6, 0.9, 1.0, 0.9), 2.0)
			Sound.play("ready", position, -2.0, 0.6)
		_:
			return
	run.tutorial_event("ability")


func _update_turret(dt: float) -> void:
	if not slots.has("turret"):
		return
	var w: Dictionary = profiles["turret"]
	var reach: float = float(w["range"]) * 1.05
	var fwd := forward()
	var best = null
	var best_d := reach
	for e in run.enemies:
		if run.jammed:
			break
		if not is_instance_valid(e) or not e.alive or e.hidden():
			continue
		var to: Vector2 = (e.position as Vector2) - position
		var d := to.length()
		if d > best_d or d < 1.0:
			continue
		if absf(fwd.angle_to(to)) <= WeaponFire.TURRET_HALF:
			best_d = d
			best = e
	turret_target = best
	var want := 0.0
	if best != null:
		var lead: Vector2 = (best.position as Vector2) + (best.velocity as Vector2) * clampf(best_d / maxf(1.0, float(w["speed"])), 0.0, 0.8)
		want = clampf(fwd.angle_to(lead - position), -WeaponFire.TURRET_HALF, WeaponFire.TURRET_HALF)
	var diff := want - turret_angle
	turret_angle += clampf(diff, -3.2 * dt, 3.2 * dt)


func on_pass(e) -> void:
	if stats.ability != "plunder_raid":
		return
	var def := ability_def()
	if raid_timer > 0.0:
		if is_instance_valid(e) and e.alive:
			e.receive_hit(float(def["rake"]), position, false, "rake")
			run.fx_over.text(position + Vector2(0, -56), "RAKED", Color(1.0, 0.8, 0.4), 15, 0.8)
	else:
		charge = minf(1.0, charge + float(def["pass_charge"]))
	var loot := int(def["plunder"]) + int(stats.get_value("plunder_bonus"))
	run.award_salvage(loot, position + Vector2(0, -34), "PLUNDER")


func on_dodge() -> void:
	if stats.ability == "gale_surge" and surge_timer <= 0.0:
		charge = minf(1.0, charge + float(ability_def()["dodge_charge"]) + stats.get_value("dodge_charge"))


func _update_weapons(dt: float, control: bool) -> void:
	for slot in slots:
		var before: float = reload[slot]
		reload[slot] = maxf(0.0, before - dt)
		if before > 0.0 and float(reload[slot]) <= 0.0:
			Sound.play("ready", null, -16.0, 1.0 + slots.find(slot) * 0.08)
		buffer[slot] = maxf(0.0, float(buffer[slot]) - dt)
	if not control:
		return
	if fire_lock:
		var any := false
		for slot in slots:
			if Input.is_action_pressed(GameData.SLOT_ACTIONS[slot]):
				any = true
		if not any:
			fire_lock = false
		return
	for slot in slots:
		var action: String = GameData.SLOT_ACTIONS[slot]
		if Input.is_action_just_pressed(action):
			buffer[slot] = 0.18
		if float(reload[slot]) <= 0.0 and (Input.is_action_pressed(action) or float(buffer[slot]) > 0.0):
			fire(slot)


func fire(slot: String) -> void:
	var w: Dictionary = profiles[slot]
	if focus_timer > 0.0:
		var fd := ability_def()
		w = w.duplicate()
		w["spread"] = 0.0
		w["damage"] = float(w["damage"]) * float(fd["damage"])
		w["range"] = float(w["range"]) * float(fd["range"])
		if stats.has_flag("deadeye"):
			w["armor_pierce"] = true
	if stats.ability == "resonance_cascade":
		var rt := resonance_tier()
		if rt >= 2:
			w = w.duplicate()
			w["damage"] = float(w["damage"]) * (1.0 + 0.1 * float(rt - 1))
			if rt >= 3:
				w["pierce"] = maxi(int(w.get("pierce", 0)), 1)
			if rt >= 4:
				w["spark"] = true
			if rt >= 5:
				w["homing"] = maxf(float(w.get("homing", 0.0)), 1.0)
	var count := WeaponFire.fire(run, self, slot, w)
	var dir := WeaponFire.aim_dir(self, slot)
	var broadside := slot == "port" or slot == "starboard"
	var recoil := float(w.get("recoil", 0.0)) * float(w["barrels"]) / (1.0 if broadside else (4.0 if slot == "turret" else 3.0))
	velocity -= dir * recoil
	if stats.has_flag("recoil_rig") or stats.ability == "pressure_pulse":
		velocity += forward() * recoil * 0.7
	reload[slot] = float(w["reload"]) * (0.75 if surge_timer > 0.0 else 1.0) * (0.7 if raid_timer > 0.0 or overdrive_timer > 0.0 else 1.0)
	buffer[slot] = 0.0
	muzzle[slot] = 0.12
	run.add_shake(2.5 if broadside else 1.5)
	run.on_player_fired(slot, count)


func _update_modules(control: bool) -> void:
	if not control:
		return
	for i in stats.modules.size():
		if Input.is_action_just_pressed("module_%d" % (i + 1)):
			activate_module(i)


func module_ratio(i: int) -> float:
	var id: String = stats.modules[i]
	var cd: float = float(GameData.ACTIVE_MODULES[id]["cooldown"])
	return 1.0 - clampf(float(module_cd[i]) / cd, 0.0, 1.0)


func activate_module(i: int) -> void:
	if i >= stats.modules.size():
		return
	var id: String = stats.modules[i]
	var m: Dictionary = GameData.ACTIVE_MODULES[id]
	if float(module_cd[i]) > 0.0 or int(module_charges[i]) == 0:
		Sound.ui("deny")
		return
	var fwd := forward()
	match id:
		"repair_drone":
			heal_left = float(m["heal"])
			heal_rate = float(m["heal"]) / float(m["duration"])
			run.fx_over.ring(position, 60.0, 0.5, Color(0.45, 1.0, 0.7, 0.9), 3.0)
			Sound.play("salvage", position, -2.0, 0.7)
		"boost_jets":
			velocity += fwd * float(m["impulse"])
			run.fx_over.burst(position - fwd * 24.0, 14, 160.0, Color(0.6, 0.9, 1.0), 0.4, 3.0, -fwd, 0.7)
			Sound.play("dodge", position, 0.0, 0.8)
		"flak_burst":
			snap_tether("LINE CUT")
			var n: int = run.shots.clear_enemy_near(position, float(m["radius"]))
			run.fx_over.ring(position, float(m["radius"]), 0.35, Color(1.0, 0.9, 0.6, 0.9), 3.0)
			run.fx_over.burst(position, 24, 260.0, Color(1.0, 0.85, 0.5), 0.35, 2.5)
			Sound.play("enemy_cannon", position, -2.0, 1.6)
			if n > 0:
				run.on_style_event("FLAK x%d" % n, 4.0 * n, 20 * n, position)
		"decoy_buoy":
			run.spawn_decoy(position - fwd * 40.0, float(m["duration"]), float(m["hull"]))
			Sound.play("splash", position, -2.0, 0.8)
		"smoke_screen":
			run.add_smoke(position, float(m["radius"]), float(m["duration"]))
			Sound.play("wind", position, -2.0, 0.9)
		"mine_dispenser":
			run.hazards.add_player_mine(position - fwd * (radius + 20.0), float(m["damage"]), int(m["max"]))
			Sound.play("splash", position, -4.0, 1.3)
		"shock_pulse":
			snap_tether("LINE CUT")
			run.shock_pulse(position, float(m["radius"]), float(m["damage"]))
		"sonar_pulse":
			run.sonar_timer = float(m["duration"])
			run.fx_over.ring(position, 900.0, 1.0, Color(0.5, 0.95, 1.0, 0.7), 3.0)
			Sound.play("ready", position, -2.0, 0.45)
		"depth_charges":
			for k in 3:
				var dp := position - fwd * (radius + 30.0 + float(k) * 48.0)
				run.shots.add_mortar(dp, 1.2 + float(k) * 0.12, float(m["blast"]), float(m["damage"]), "Depth charge", false, 0)
			Sound.play("splash", position, -2.0, 0.7)
		"overdrive":
			overdrive_timer = float(m["duration"])
			slump_timer = 0.0
			run.fx_over.burst(position - fwd * 24.0, 18, 180.0, Color(1.0, 0.7, 0.4), 0.5, 3.0, -fwd, 0.8)
			Sound.play("dodge", position, 0.0, 0.6)
		"target_scanner":
			run.scanner_timer = float(m["duration"])
			run.scanner_bonus = float(m["bonus"])
			run.fx_over.ring(position, 600.0, 0.8, Color(0.6, 1.0, 0.9, 0.6), 2.0)
			Sound.play("tier_up", null, -8.0, 0.6)
	module_cd[i] = float(m["cooldown"])
	if int(module_charges[i]) > 0:
		module_charges[i] = int(module_charges[i]) - 1
	run.tutorial_event("module")


func _update_collisions() -> void:
	var bounce := 0.5 * stats.get_value("collision_mult")
	var impact: float = run.arena.resolve_circle(self, bounce)
	if impact > 110.0:
		run.fx_over.burst(position, 8, 120.0, Color(0.7, 0.9, 1.0), 0.4, 3.0)
		if invuln <= 0.0:
			var dmg := (4.0 + (impact - 110.0) * 0.05) * stats.get_value("collision_mult")
			reef_hits += 1
			take_damage(dmg, "Reef collision")
			invuln = 0.5


func ram(other, rel_speed: float, contact: float) -> void:
	if rel_speed < 90.0 or invuln > 0.0:
		return
	var dmg := contact * stats.get_value("collision_mult") * clampf(rel_speed / 200.0, 0.6, 1.5)
	take_damage(dmg, "Ramming", other.position)
	invuln = 0.5


func take_damage(amount: float, source: String, from: Vector2 = Vector2.INF) -> void:
	if not alive or amount <= 0.0:
		return
	if invuln > 0.0:
		return
	if immune > 0.0 and source != "Reef collision":
		run.fx_over.ring(position, radius + 14.0, 0.25, Color(0.6, 1.0, 0.85, 0.8), 2.0)
		return
	if stats.ability == "resonance_cascade" and run.wake.tier == 0:
		amount *= 1.15
	if run.in_distortion(position):
		amount *= 1.3
	if source == "Lightning" and stats.has_flag("lightning_rod"):
		run.fx_over.ring(position, radius + 18.0, 0.3, Color(1.0, 1.0, 0.6, 0.9), 2.5)
		_rod_charge()
		return
	if source in ["Mine", "Lightning"]:
		amount *= stats.get_value("hazard_mult")
	if bracing and from != Vector2.INF:
		var to := (from - position).normalized()
		if forward().dot(to) > -0.5:
			amount *= 1.0 - minf(0.9, float(ability_def().get("reduction", 0.55)) + stats.get_value("brace_reduction"))
			run.fx_over.burst(position + to * (radius + 8.0), 8, 120.0, Color(0.8, 0.95, 1.0), 0.3, 2.5)
	hit_flash = 0.25
	run.fx_over.burst(position, 10, 140.0, Color(1.0, 0.5, 0.3), 0.45, 3.0)
	Sound.play("hurt", position, -3.0)
	run.add_shake(6.0 + amount * 0.3)
	if god_mode:
		return
	hull -= amount
	run.on_player_damaged(amount, source)
	if hull <= 0.0:
		if stats.has_flag("bulkheads") and not bulkhead_used:
			bulkhead_used = true
			hull = 1.0
			invuln = 1.5
			run.banner("BULKHEADS HOLD", "Emergency bulkheads absorbed a lethal hit", GameData.COL_SALVAGE)
		else:
			hull = 0.0
			alive = false
			run.on_player_died()


func _rod_charge() -> void:
	match stats.ability:
		"quick_reload", "side_slip", "resonance_cascade":
			ability_cd = maxf(0.0, ability_cd - _ability_cooldown() * 0.25)
		"armor_brace":
			brace_energy = minf(1.0, brace_energy + 0.25)
		"ward_buoy":
			ward_recharge += float(ability_def()["recharge"]) * 0.25
		_:
			charge = minf(1.0, charge + 0.25)
	run.fx_over.text(position + Vector2(0, -50), "LIGHTNING ROD", Color(1.0, 1.0, 0.6), 15, 0.8)


func heal(amount: float) -> void:
	hull = minf(stats.get_value("max_hull"), hull + amount)


func _update_wake(dt: float) -> void:
	wake_timer -= dt
	var speed := velocity.length()
	if wake_timer > 0.0 or speed < 25.0:
		return
	wake_timer = 0.035
	var fwd := forward()
	var right := fwd.rotated(PI / 2.0)
	var length: float = float(stats.look.get("length", 52.0))
	var stern := position - fwd * length * 0.4
	var ratio := clampf(speed / stats.get_value("max_speed"), 0.0, 1.3)
	var col: Color = GameData.wake_color(run.wake.tier)
	if mastery >= 3:
		col = col.lerp(stats.look.get("accent", col), 0.35)
	var w := 4.0 + ratio * 6.0 + float(run.wake.tier) * 0.8
	run.fx_under.wake_point(stern + right * 7.0, w, col, 0.25 + ratio * 0.45)
	run.fx_under.wake_point(stern - right * 7.0, w, col, 0.25 + ratio * 0.45)
	if absf(lateral_speed) > 70.0:
		var side_dir_v := right * -signf(lateral_speed)
		run.fx_under.burst(position + side_dir_v * 14.0, 2, 70.0, col.lerp(Color.WHITE, 0.4), 0.5, 2.5, side_dir_v, 0.8)


func _check_passes() -> void:
	if pass_cooldown > 0.0:
		return
	var speed := velocity.length()
	for e in run.enemies:
		if not is_instance_valid(e) or not e.alive:
			continue
		var d: float = position.distance_to(e.position) - float(e.radius) - radius
		if drifting and absf(lateral_speed) > 90.0 and d < 120.0:
			var gain := 16.0 if stats.has_flag("slipstream") else 10.0
			run.on_style_event("DRIFT PASS", gain, 40, position, "drift")
			pass_cooldown = 1.5
			on_pass(e)
			return
		if speed > 230.0 and d < 45.0 and d > 0.0:
			run.on_style_event("CLOSE PASS", 10.0, 40, position, "drift")
			pass_cooldown = 1.5
			on_pass(e)
			return


func hull_points() -> PackedVector2Array:
	var l: float = float(stats.look.get("length", 52.0))
	var w: float = float(stats.look.get("width", 21.0))
	var b: float = float(stats.look.get("bow", 0.55))
	var shoulder := l * 0.5 - l * b * 0.4
	return PackedVector2Array([Vector2(l * 0.5, 0), Vector2(shoulder, -w * 0.5), Vector2(-l * 0.4, -w * 0.5), Vector2(-l * 0.5, -w * 0.33), Vector2(-l * 0.5, w * 0.33), Vector2(-l * 0.4, w * 0.5), Vector2(shoulder, w * 0.5)])


func _draw() -> void:
	if not alive:
		return
	for slot in slots:
		_draw_arc(slot)
	var l: float = float(stats.look.get("length", 52.0))
	var w: float = float(stats.look.get("width", 21.0))
	var accent: Color = stats.look.get("accent", GameData.COL_PLAYER)
	if bracing:
		draw_arc(Vector2.ZERO, radius + 16.0, -PI * 0.75, PI * 0.75, 32, Color(0.8, 0.95, 1.0, 0.85), 4.0, true)
	if surge_timer > 0.0:
		draw_circle(Vector2.ZERO, radius + 14.0, Color(0.75, 0.85, 1.0, 0.12))
	if raid_timer > 0.0:
		draw_arc(Vector2.ZERO, radius + 14.0, 0.0, TAU, 32, Color(1.0, 0.8, 0.4, 0.75), 3.0, true)
	if tether_timer > 0.0 and tether_node != null and is_instance_valid(tether_node):
		draw_line(Vector2.ZERO, to_local(tether_node.position), Color(0.5, 1.0, 0.7, 0.8), 2.5)
	if focus_timer > 0.0:
		for k in 4:
			var fa := PI / 2.0 * float(k) + PI / 4.0
			draw_line(Vector2.RIGHT.rotated(fa) * (radius + 10.0), Vector2.RIGHT.rotated(fa) * (radius + 20.0), Color(0.6, 0.9, 1.0, 0.9), 2.5)
	var body_col := Color(0.05, 0.12, 0.19)
	if hit_flash > 0.0 and not SaveData.reduce_flash():
		body_col = body_col.lerp(Color(0.9, 0.35, 0.3), hit_flash * 3.0)
	var outline := accent
	if immune > 0.0:
		outline = Color.WHITE
	elif invuln > 0.0 and int(invuln * 20.0) % 2 == 0:
		outline = outline.darkened(0.5)
	var pts := hull_points()
	draw_colored_polygon(pts, body_col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, outline, 2.0, true)
	if mastery >= 2:
		draw_line(Vector2(-l * 0.4, 0), Vector2(l * 0.3, 0), Color(accent, 0.45), 3.0)
	if mastery >= 7:
		draw_polyline(PackedVector2Array([Vector2(l * 0.2, -w * 0.3), Vector2(l * 0.35, 0), Vector2(l * 0.2, w * 0.3)]), Color(1.0, 0.85, 0.4), 2.0)
	for slot in slots:
		var col: Color = GameData.SLOT_COLORS[slot]
		if float(reload[slot]) > 0.0:
			col = col.darkened(0.6)
		var barrels: int = int(profiles[slot]["barrels"])
		if slot == "port" or slot == "starboard":
			var y := -w * 0.5 if slot == "port" else w * 0.5
			for i in barrels:
				var x := 0.0 if barrels == 1 else lerpf(-l * 0.26, l * 0.26, float(i) / float(barrels - 1))
				draw_rect(Rect2(Vector2(x - 2.5, y - 2.0), Vector2(5, 4)), col)
				if float(muzzle[slot]) > 0.0:
					var a := float(muzzle[slot]) / 0.12
					var fc := Color(1.0, 0.9, 0.6, a) if not SaveData.reduce_flash() else Color(1.0, 0.8, 0.5, a * 0.5)
					draw_circle(Vector2(x, y + (-8.0 if slot == "port" else 8.0)), 5.0 * a + 2.0, fc)
		elif slot == "turret":
			var tp := Vector2(l * 0.08, 0)
			draw_circle(tp, 6.0, Color(0.08, 0.14, 0.22))
			draw_arc(tp, 6.0, 0.0, TAU, 16, col, 2.0, true)
			draw_line(tp, tp + Vector2.RIGHT.rotated(turret_angle) * 15.0, col, 3.5)
			if float(muzzle[slot]) > 0.0:
				draw_circle(tp + Vector2.RIGHT.rotated(turret_angle) * 20.0, 6.0 * float(muzzle[slot]) / 0.12 + 1.0, Color(1.0, 0.9, 0.6, 0.8))
		else:
			var gx := l * 0.42 if slot == "bow" else -l * 0.42
			draw_circle(Vector2(gx, 0), 3.5, col)
			if float(muzzle[slot]) > 0.0:
				draw_circle(Vector2(gx + (8.0 if slot == "bow" else -8.0), 0), 6.0 * float(muzzle[slot]) / 0.12 + 1.0, Color(1.0, 0.9, 0.6, 0.8))
	var masts: int = int(stats.look.get("masts", 2))
	for i in masts:
		var mx := 0.0 if masts == 1 else lerpf(-l * 0.18, l * 0.12, float(i) / float(masts - 1))
		draw_line(Vector2(mx, -w * 0.42), Vector2(mx, w * 0.42), Color(0.7, 0.9, 1.0, 0.7), 2.0)
		draw_circle(Vector2(mx, 0), 3.6, Color(0.85, 0.95, 1.0))
	draw_circle(Vector2(l * 0.48, 0), 2.0, Color.WHITE)
	if stats.ability in ["speed_burst", "gale_surge", "plunder_raid", "steady_aim"] and surge_timer <= 0.0 and raid_timer <= 0.0 and focus_timer <= 0.0 and charge > 0.0:
		var cc := Color(1.0, 0.85, 0.4, 0.9) if charge >= 1.0 else Color(1.0, 0.85, 0.4, 0.45)
		draw_arc(Vector2.ZERO, radius + 22.0, PI * 0.6, PI * 0.6 + PI * 0.8 * charge, 20, cc, 3.0, true)


func _draw_arc(slot: String) -> void:
	var w: Dictionary = profiles[slot]
	var r: float = float(w["range"]) * (0.8 if str(w.get("pattern", "")) == "mortar" else 1.0)
	var center := WeaponFire.slot_angle(slot)
	var half := WeaponFire.slot_half(slot, w)
	var col: Color = GameData.SLOT_COLORS[slot]
	if slot == "turret":
		var rdy := float(reload[slot]) <= 0.0
		draw_arc(Vector2.ZERO, r, -half, half, 40, Color(col, 0.08), 1.5, true)
		var aim := Vector2.RIGHT.rotated(turret_angle)
		draw_line(aim * (radius + 10.0), aim * r * (0.5 if turret_target == null else 1.0), Color(col, 0.35 if rdy else 0.12), 1.5)
		return
	var is_ready := float(reload[slot]) <= 0.0
	var alpha := 0.3 if is_ready else 0.07
	if slot == "bow" or slot == "stern":
		alpha *= 0.7
	draw_arc(Vector2.ZERO, r, center - half, center + half, 24, Color(col, alpha), 2.0, true)
	var e1 := Vector2.RIGHT.rotated(center - half)
	var e2 := Vector2.RIGHT.rotated(center + half)
	draw_line(e1 * (radius + 6.0), e1 * r, Color(col, alpha * 0.4), 1.0)
	draw_line(e2 * (radius + 6.0), e2 * r, Color(col, alpha * 0.4), 1.0)
	if not is_ready:
		var p := reload_ratio(slot)
		draw_arc(Vector2.ZERO, r, center - half, center - half + half * 2.0 * p, 24, Color(col, 0.2), 3.0, true)

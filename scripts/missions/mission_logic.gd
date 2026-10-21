class_name MissionLogic
extends RefCounted

const ESCORT_PATH := [Vector2(240, 900), Vector2(700, 450), Vector2(1500, 380), Vector2(2300, 600), Vector2(2500, 1300), Vector2(2100, 1800), Vector2(2950, 1850)]

var run
var cfg: Dictionary
var objective := ""
var flow := ""
var waves: Array = []
var wave_index := -1
var between := 0.0
var timeline: Array = []
var elapsed := 0.0
var done := false
var failed := false
var fail_reason := ""
var need := 0
var wrecks_total := 0
var couriers_total := 0
var couriers_spawned := 0
var couriers_killed := 0
var escaped := 0
var courier_timer := 0.0
var courier_side := 0
var ally = null
var ally_lost := false
var time_limit := 0.0
var cp_total := 0
var named = null
var named_dead := false
var bounty: Dictionary = {}
var supply_targets: Array = []
var supply_total := 0
var buoy_total := 0
var hunt_stage := 0
var hunt_ratio := 1.0
var hunt_timer := 0.0
var anchor_list: Array = []
var anchor_total := 0


func _init(p_run, p_cfg: Dictionary) -> void:
	run = p_run
	cfg = p_cfg
	objective = str(cfg.get("objective", "destroy_all"))
	flow = str(cfg.get("flow", "sequential"))
	waves = (cfg.get("waves", []) as Array).duplicate(true)
	need = int(cfg.get("need", 0))
	time_limit = float(cfg.get("time_limit", 0.0))


func start() -> void:
	run.director.configure(GameData.global_stage(cfg))
	match objective:
		"salvage":
			wrecks_total = run.hazards.wrecks.size()
			need = mini(need, wrecks_total)
		"intercept":
			couriers_total = int(cfg.get("couriers", 4))
			courier_timer = 3.0
		"escort":
			ally = run.spawn_ally(str(cfg.get("ally", "barge")), ESCORT_PATH)
		"checkpoints":
			cp_total = int(cfg.get("checkpoints", 8))
			run.hazards.set_checkpoints(_make_checkpoints(cp_total))
		"bounty":
			_spawn_bounty()
		"supply":
			_spawn_supply()
		"buoys":
			run.hazards.set_buoys(int(cfg.get("buoys", 4)))
			buoy_total = run.hazards.buoys.size()
		"hunt":
			_spawn_named(str(cfg.get("hunt_id", "devourer")))
		"anchors":
			_spawn_anchors(int(cfg.get("anchors", 3)))
	if flow == "sequential":
		_next_wave()
	elif flow == "timeline":
		for w in waves:
			var e: Dictionary = (w as Dictionary).duplicate(true)
			e["next"] = float(e.get("at", 0.0))
			timeline.append(e)


func _spawn_bounty() -> void:
	_spawn_named(str(cfg.get("bounty_id", "grey_widow")))


func _spawn_named(id: String) -> void:
	var nd: Dictionary = GameData.NAMED[id]
	var pos: Vector2 = run.director.pick_spawn(false, "any")
	named = run.spawn_enemy(str(nd["kind"]), pos, nd["variants"])
	if named != null:
		named.name_tag = str(nd["name"])
		named.named_id = id
		named.max_hull *= float(nd["hull_mult"])
		named.hull = named.max_hull
		bounty = nd["bounty"]
		run.banner("BOUNTY: " + str(nd["name"]).to_upper(), str(nd["desc"]), GameData.COL_SALVAGE)


func _spawn_supply() -> void:
	supply_total = int(cfg.get("supply", 4))
	var size: Vector2 = run.arena.size
	var anchors := [Vector2(0.15, 0.2), Vector2(0.85, 0.2), Vector2(0.15, 0.8), Vector2(0.85, 0.8), Vector2(0.5, 0.12), Vector2(0.5, 0.88)]
	var placed := 0
	for a in anchors:
		if placed >= supply_total:
			break
		var p := Vector2(size.x * float(a.x), size.y * float(a.y))
		for i in 10:
			if run.arena.is_clear(p, 60.0):
				break
			p += Vector2(run.rng.randf_range(-120, 120), run.rng.randf_range(-120, 120))
		if p.distance_to(run.player.position) < 600.0:
			continue
		var e = run.spawn_enemy("repair_barge", p, [])
		if e == null:
			continue
		e.supply = true
		e.name_tag = "Supply Ship"
		supply_targets.append(e)
		run.spawn_enemy("gunboat", p + Vector2(70, 0), [])
		placed += 1
	supply_total = supply_targets.size()
	run.banner("SUPPLY SHIPS MARKED", "Sink all %d before the reinforcements arrive" % supply_total, GameData.COL_SALVAGE)


func _spawn_anchors(n: int) -> void:
	var size: Vector2 = run.arena.size
	var spots := [Vector2(0.18, 0.22), Vector2(0.82, 0.22), Vector2(0.5, 0.85), Vector2(0.18, 0.8), Vector2(0.82, 0.8)]
	for sp in spots:
		if anchor_list.size() >= n:
			break
		var p := Vector2(size.x * float(sp.x), size.y * float(sp.y))
		for i in 8:
			if run.arena.is_clear(p, 60.0):
				break
			p += Vector2(run.rng.randf_range(-120, 120), run.rng.randf_range(-120, 120))
		if p.distance_to(run.player.position) < 500.0:
			continue
		var a = run.spawn_enemy("resonance_anchor", p, [])
		if a != null:
			anchor_list.append(a)
	anchor_total = anchor_list.size()
	run.banner("RESONANCE ANCHORS", "Destroy all %d to cut off the reinforcements" % anchor_total, Color(1.0, 0.55, 0.9))


func anchors_left() -> int:
	var n := 0
	for a in anchor_list:
		if is_instance_valid(a) and a.alive:
			n += 1
	return n


func supply_left() -> int:
	var n := 0
	for e in supply_targets:
		if is_instance_valid(e) and e.alive:
			n += 1
	return n


func _make_checkpoints(n: int) -> Array:
	var pts: Array = []
	var size: Vector2 = run.arena.size
	var cur: Vector2 = run.player.position
	var guard := 0
	while pts.size() < n and guard < 400:
		guard += 1
		var c := Vector2(run.rng.randf_range(220.0, size.x - 220.0), run.rng.randf_range(220.0, size.y - 220.0))
		if not run.arena.is_clear(c, 110.0):
			continue
		var ok := c.distance_to(cur) > 520.0 and c.distance_to(cur) < 1300.0
		for q in pts:
			if c.distance_to(q) < 420.0:
				ok = false
		if ok:
			pts.append(c)
			cur = c
	return pts


func _next_wave() -> void:
	wave_index += 1
	if wave_index >= waves.size():
		return
	var groups: Array = waves[wave_index]
	for g in groups:
		run.director.add_group(g["spawn"], str(g.get("side", "mirror" if bool(cfg.get("mirror_spawns", false)) else "any")), 0.8)
	if waves.size() > 1 and objective != "boss":
		run.banner("WAVE %d / %d" % [wave_index + 1, waves.size()], "", GameData.COL_PORT)


func update(dt: float) -> void:
	if done or failed:
		return
	elapsed += dt
	run.director.update(dt)
	if flow == "sequential":
		if run.director.finished() and run.hostile_count() == 0:
			if wave_index + 1 >= waves.size():
				if objective in ["destroy_all", "boss"]:
					_complete()
			else:
				between += dt
				if between >= 2.0:
					between = 0.0
					_next_wave()
	elif flow == "timeline":
		for e in timeline:
			if elapsed >= float(e["next"]) and (float(e.get("until", 0.0)) <= 0.0 or elapsed <= float(e["until"])):
				run.director.add_group(e["spawn"], str(e.get("side", "any")), 0.6)
				var rep := float(e.get("repeat", 0.0))
				e["next"] = float(e["next"]) + rep if rep > 0.0 else INF
	match objective:
		"salvage":
			if run.wrecks_salvaged >= need and need > 0:
				_complete()
		"intercept":
			_update_couriers(dt)
		"escort":
			if ally_lost:
				_fail("The convoy was lost")
		"survive":
			if elapsed >= time_limit:
				_complete()
		"checkpoints":
			if run.hazards.cp_index >= cp_total:
				_complete()
			elif elapsed >= time_limit:
				_fail("Out of time")
		"bounty":
			if named_dead:
				_complete()
		"supply":
			if supply_total > 0 and supply_left() == 0:
				_complete()
			elif elapsed >= time_limit:
				_fail("Reinforcements arrived")
		"buoys":
			if buoy_total > 0 and run.hazards.buoys_done() >= buoy_total:
				_complete()
		"hunt":
			_update_hunt(dt)
		"anchors":
			if anchor_total > 0 and anchors_left() == 0:
				_complete()


func _update_hunt(dt: float) -> void:
	if named_dead:
		_complete()
		return
	if hunt_timer > 0.0:
		hunt_timer -= dt
		if hunt_timer <= 0.0:
			var id := str(cfg.get("hunt_id", "devourer"))
			_spawn_named(id)
			if named != null:
				named.hull = named.max_hull * hunt_ratio
				run.banner("%s SURFACES" % str(GameData.NAMED[id]["name"]).to_upper(), "Encounter %d of 3" % (hunt_stage + 1), GameData.COL_WARN)
				for k in 3:
					run.spawn_enemy("swarm_skater", (named.position as Vector2) + Vector2.RIGHT.rotated(TAU * float(k) / 3.0) * 90.0, [])
		return
	if named == null or not is_instance_valid(named) or not named.alive:
		return
	var marks := [0.66, 0.33]
	if hunt_stage < marks.size() and named.hull <= named.max_hull * float(marks[hunt_stage]):
		hunt_ratio = named.hull / named.max_hull
		hunt_stage += 1
		var nm: String = named.name_tag
		run.fx_under.burst(named.position, 20, 140.0, Color(0.5, 0.9, 1.0, 0.8), 0.8, 4.0)
		named.alive = false
		run.on_enemy_expended(named)
		named.queue_free()
		named = null
		hunt_timer = 14.0
		run.banner("%s DIVES" % nm.to_upper(), "It will surface somewhere else - be ready", Color(0.6, 0.9, 1.0))


func _update_couriers(dt: float) -> void:
	if couriers_spawned < couriers_total:
		courier_timer -= dt
		if courier_timer <= 0.0:
			courier_timer = 11.0
			_spawn_courier()
	if escaped > couriers_total - need:
		_fail("Too many couriers escaped")
		return
	if couriers_spawned >= couriers_total and couriers_killed + escaped >= couriers_total:
		if couriers_killed >= need:
			_complete()
		else:
			_fail("Too many couriers escaped")


func _spawn_courier() -> void:
	var size: Vector2 = run.arena.size
	var left := courier_side % 2 == 0
	courier_side += 1
	var y: float = run.rng.randf_range(300.0, size.y - 300.0)
	var spawn_at := Vector2(140.0 if left else size.x - 140.0, y)
	var exit := Vector2(size.x - 40.0 if left else 40.0, run.rng.randf_range(300.0, size.y - 300.0))
	for i in 10:
		if run.arena.is_clear(spawn_at, 60.0):
			break
		spawn_at.y = run.rng.randf_range(300.0, size.y - 300.0)
	var c = run.spawn_enemy("courier", spawn_at, (cfg.get("courier_variants", []) as Array).duplicate())
	if c != null:
		c.set_exit(exit)
		c.rotation = (exit - spawn_at).angle()
		run.fx_over.spawn_cue(spawn_at)
	couriers_spawned += 1
	var escort: String = str(cfg.get("courier_escort", ""))
	if escort != "" and couriers_spawned % 2 == 0 and c != null:
		run.spawn_enemy(escort, spawn_at + (exit - spawn_at).normalized().rotated(PI / 2.0) * 70.0, [])
	if couriers_spawned == 1:
		run.banner("COURIERS SIGHTED", "Stop them before they reach the far edge", GameData.COL_SALVAGE)


func on_enemy_killed(e) -> void:
	if e.kind == "courier":
		couriers_killed += 1
	if named != null and e == named:
		named_dead = true


func on_courier_escaped() -> void:
	escaped += 1


func on_ally_destroyed() -> void:
	ally_lost = true


func on_ally_arrived() -> void:
	if objective == "escort":
		_complete()


func _complete() -> void:
	if done or failed:
		return
	done = true


func _fail(reason: String) -> void:
	if done or failed:
		return
	failed = true
	fail_reason = reason


func primary_text() -> String:
	match objective:
		"destroy_all":
			if waves.size() > 1:
				return "Destroy all enemies   Wave %d / %d" % [mini(wave_index + 1, waves.size()), waves.size()]
			return "Destroy all enemies"
		"boss":
			return "Sink %s" % GameData.enemy_name(str(cfg.get("boss", "ironwake")))
		"salvage":
			return "Recover wrecks   %d / %d" % [run.wrecks_salvaged, need]
		"intercept":
			return "Stop couriers   %d / %d   (escaped %d)" % [couriers_killed, need, escaped]
		"escort":
			if ally != null:
				return "Escort the %s   %d%%" % [ally.title, int(ally.progress() * 100.0)]
			return "Escort the convoy"
		"survive":
			var left := maxf(0.0, time_limit - elapsed)
			return "Survive   %d:%02d" % [int(left / 60.0), int(left) % 60]
		"checkpoints":
			var tl := maxf(0.0, time_limit - elapsed)
			return "Checkpoints %d / %d   %d:%02d" % [run.hazards.cp_index, cp_total, int(tl / 60.0), int(tl) % 60]
		"bounty":
			return "Hunt %s" % (named.name_tag if named != null else "the bounty")
		"buoys":
			return "Activate echo buoys   %d / %d" % [run.hazards.buoys_done(), buoy_total]
		"hunt":
			var hn: String = str(GameData.NAMED[str(cfg.get("hunt_id", "devourer"))]["name"])
			if hunt_timer > 0.0:
				return "%s has dived   %ds" % [hn, int(ceil(hunt_timer))]
			return "Hunt %s   encounter %d / 3" % [hn, hunt_stage + 1]
		"anchors":
			return "Destroy resonance anchors   %d / %d" % [anchor_total - anchors_left(), anchor_total]
		"supply":
			var sl := maxf(0.0, time_limit - elapsed)
			return "Sink supply ships %d / %d   %d:%02d" % [supply_total - supply_left(), supply_total, int(sl / 60.0), int(sl) % 60]
	return ""


func progress() -> float:
	match objective:
		"destroy_all":
			return float(maxi(wave_index, 0)) / float(maxi(1, waves.size()))
		"salvage":
			return float(run.wrecks_salvaged) / float(maxi(1, need))
		"intercept":
			return float(couriers_killed) / float(maxi(1, need))
		"escort":
			return ally.progress() if ally != null else 0.0
		"survive":
			return elapsed / maxf(1.0, time_limit)
		"checkpoints":
			return float(run.hazards.cp_index) / float(maxi(1, cp_total))
		"supply":
			return float(supply_total - supply_left()) / float(maxi(1, supply_total))
		"buoys":
			return float(run.hazards.buoys_done()) / float(maxi(1, buoy_total))
		"anchors":
			return float(anchor_total - anchors_left()) / float(maxi(1, anchor_total))
		"hunt":
			if named != null and is_instance_valid(named) and named.alive:
				return 1.0 - float(named.hull) / float(named.max_hull)
			return 1.0 - hunt_ratio
	return 0.0


func _optional_value(o: Dictionary, final: bool) -> int:
	var v: float = float(o.get("value", 0))
	var p: PlayerShip = run.player
	match str(o["kind"]):
		"hull_min":
			var ratio := p.hull / maxf(1.0, p.stats.get_value("max_hull"))
			if final:
				return 1 if ratio >= v and p.alive else -1
			return 0 if ratio >= v else -1
		"wake_tier":
			return 1 if run.wake.max_tier >= int(v) else (-1 if final else 0)
		"time_max":
			if elapsed > v:
				return -1
			return 1 if final else 0
		"no_escape":
			if escaped > 0:
				return -1
			return 1 if final else 0
		"ally_hull_min":
			if ally == null or ally.hull / ally.max_hull < v:
				return -1
			return 1 if final else 0
		"crossings":
			return 1 if run.crossings >= int(v) else (-1 if final else 0)
		"blast_kills":
			return 1 if run.blast_kills >= int(v) else (-1 if final else 0)
		"interrupts":
			return 1 if run.interrupts >= int(v) else (-1 if final else 0)
		"no_reef":
			if p.reef_hits > 0:
				return -1
			return 1 if final else 0
		"all_wrecks":
			return 1 if run.wrecks_salvaged >= int(v) else (-1 if final else 0)
		"weak_hits":
			return 1 if run.weak_hits >= int(v) else (-1 if final else 0)
		"mine_kills":
			return 1 if run.mine_kills >= int(v) else (-1 if final else 0)
		"dodges":
			return 1 if run.dodges >= int(v) else (-1 if final else 0)
		"no_mines":
			if float(run.damage_sources.get("Mine", 0.0)) > 0.0:
				return -1
			return 1 if final else 0
		"no_lightning":
			if float(run.damage_sources.get("Lightning", 0.0)) > 0.0:
				return -1
			return 1 if final else 0
	return 0


func optional_states() -> Array:
	var out: Array = []
	for o in cfg.get("optional", []):
		out.append([str(o["text"]), _optional_value(o, false)])
	return out


func optional_results() -> Array:
	var out: Array = []
	for o in cfg.get("optional", []):
		out.append(done and _optional_value(o, true) == 1)
	return out


func grade() -> String:
	if not done:
		return "D"
	var p: PlayerShip = run.player
	var pts := 50.0
	var total := 100.0
	pts += 20.0 * clampf(p.hull / maxf(1.0, p.stats.get_value("max_hull")), 0.0, 1.0)
	var results := optional_results()
	if results.size() > 0:
		var n := 0
		for r in results:
			if r:
				n += 1
		pts += 20.0 * float(n) / float(results.size())
	else:
		pts += 10.0
	pts += minf(10.0, float(run.wake.max_tier) * 2.0)
	var par: float = float(cfg.get("par_time", 0.0))
	if par > 0.0:
		pts += clampf(10.0 - (elapsed - par) / par * 20.0, 0.0, 10.0)
	else:
		pts += 10.0
	if ally != null:
		total += 10.0
		pts += 10.0 * clampf(ally.hull / ally.max_hull, 0.0, 1.0)
	var pct := pts / total
	if pct >= 0.9:
		return "S"
	if pct >= 0.75:
		return "A"
	if pct >= 0.6:
		return "B"
	if pct >= 0.45:
		return "C"
	return "D"

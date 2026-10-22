class_name Run
extends Node2D

signal wave_cleared(wave: int, report: Dictionary)
signal run_finished(result: Dictionary)

const TUTORIAL := [
	["throttle", "Press [%s] to raise throttle and [%s] to lower it - the ship holds its speed setting", ["throttle_up", "throttle_down"]],
	["turn", "[%s] / [%s] to turn - the hull is heavy, start turns early", ["turn_left", "turn_right"]],
	["port", "[%s] fires the PORT broadside (left side of the ship)", ["fire_port"]],
	["starboard", "[%s] fires the STARBOARD broadside (right side of the ship)", ["fire_starboard"]],
	["bow", "[%s] fires the BOW mount straight ahead", ["fire_bow"]],
	["stern", "[%s] fires the STERN mount behind you", ["fire_stern"]],
	["turret", "[%s] fires the TURRET - it tracks the nearest enemy ahead and to the sides", ["fire_turret"]],
	["brake", "Hold [%s] while moving fast to brake hard", ["throttle_down"]],
	["drift", "Hold [%s] while turning at speed to drift sideways", ["drift"]],
	["ability", "[%s] uses your ship ability", ["ability"]],
	["module", "[%s] activates your utility module", ["module_1"]],
	["wake", "Hit, kill and dodge without getting hit to raise your WAKE tier", []],
]

const BOSS_LINES := {
	"galleon": {2: ["ESCALATION", "The Galleon doubles its salvos and calls escorts"]},
	"ironwake": {2: ["IRONWAKE: PLATES DEPLOYED", "Her plates guard the side facing you. Flank to the open side."], 3: ["IRONWAKE: RAMMING SPEED", "She charges along the red lane. Sidestep, then strike while she recovers."]},
	"sovereign": {2: ["THE SOVEREIGN BENDS THE WAKE", "Inside its distortion your Wake grows twice as fast - and you take 30% more damage."], 3: ["THE SOVEREIGN ANCHORS ITSELF", "Destroy the three anchors while it focuses fire on you."], 4: ["THE FINAL DUEL", "Narrow windows after each volley. The higher your Wake, the harder you hit."]},
	"leviathan": {2: ["THE ENGINE LIGHTS ITS CONDUITS", "Break each lit conduit before the pressure surge."], 3: ["THE ENGINE IS CRAWLING", "It drags itself after you and vents the sea. The core overheats every few seconds."]},
	"matriarch": {2: ["THE MATRIARCH CALLS THE STORM", "Lightning lanes and a storm cell. Every lane pattern leaves one route open."], 3: ["THE MATRIARCH RIDES THE CURRENT", "A great current drags the fight. Her attacks hit harder but she rests longer after each one."]},
	"kharon": {2: ["KHARON: GUNS DEPLOYED", "Mortars and gun platforms join the fight. Keep moving and sink the platforms."], 3: ["KHARON: SEALED", "Its plates are locked. Sink the support barges to open them."]},
}


class TargetProxy:
	var position := Vector2.ZERO
	var velocity := Vector2.ZERO
	var alive := true
	var radius := 18.0


var cfg: Dictionary = {}
var mode := "campaign"
var ship_id := "wayfarer"
var build: Dictionary = {}
var seed_value := 0
var rng := RandomNumberGenerator.new()
var state := "combat"
var wave := 0
var time := 0.0
var score := 0
var salvage := 0
var salvage_earned := 0
var salvage_spent := 0
var kills := 0
var shots_fired := 0
var shots_hit := 0
var bosses_defeated := 0
var damage_taken_wave := 0.0
var kills_by_type: Dictionary = {}
var damage_sources: Dictionary = {}
var seen_types: Dictionary = {}
var repair_cost := 10
var reroll_cost := 5
var victory := false
var end_timer := 0.0
var end_emitted := false
var inter_timer := 0.0
var shake := 0.0
var dodge_cd := 0.0
var cross_cd := 0.0
var weak_cd := 0.0
var streak_timer := 0.0
var tutorial_active := false
var tutorial_done: Dictionary = {}
var boss: Enemy = null
var _wave_report: Dictionary = {}
var difficulty: Dictionary = {}
var modifiers: Array = []
var enemy_cd_rate := 1.0
var logic: MissionLogic = null
var crossings := 0
var interrupts := 0
var dodges := 0
var blast_kills := 0
var wrecks_salvaged := 0
var research_found := 0
var blast_credit := false
var scanner_timer := 0.0
var scanner_bonus := 0.2
var smokes: Array = []
var fog := false
var fail_reason := ""
var bounty_reward: Dictionary = {}
var ally_warned := false
var mine_credit := false
var mine_kills := 0
var weak_hits := 0
var practice_r2 := 0
var practice_boss := 0
var coach: TrainingCoach = null
var distortion: Dictionary = {}
var jammed := false
var sonar_timer := 0.0
var false_contacts: Array = []

var stats: ShipStats
var wind: Wind
var wake: WakeSystem
var director: SpawnDirector
var ocean: ColorRect
var arena: Arena
var hazards: Hazards
var fx_under: FxLayer
var fx_over: FxLayer
var enemies_root: Node2D
var player: PlayerShip
var shots: ProjectileSystem
var camera: Camera2D
var hud_layer: CanvasLayer
var hud: Hud
var enemies: Array = []
var friendlies: Array = []
var allies: Array = []
var decoys: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if cfg.is_empty():
		cfg = MissionBuilder.practice()
	mode = str(cfg.get("mode", "campaign"))
	if seed_value == 0:
		seed_value = randi() % 900000 + 100000
	rng.seed = seed_value
	difficulty = GameData.DIFFICULTIES.get(str(cfg.get("difficulty", "standard")), GameData.DIFFICULTIES["standard"])
	enemy_cd_rate = 1.0 / float(difficulty["cooldown"])
	var modifier: String = str(cfg.get("modifier", ""))
	if modifier != "":
		modifiers.append(modifier)
	for wx in cfg.get("weather", []):
		if not modifiers.has(str(wx)):
			modifiers.append(str(wx))
	if modifiers.has("rapid_reload"):
		enemy_cd_rate *= 1.25
	if build.is_empty():
		build = Profile.active_build(ship_id)
	stats = ShipStats.from_build(ship_id, build, Profile.perk(ship_id))
	if modifiers.has("crosswind"):
		stats.values["crosswind"] = float(stats.values["crosswind"]) * 2.0
	fog = modifiers.has("fog")
	wind = Wind.new(rng)
	wind.pace = float(cfg.get("wind_pace", 1.0))
	wind.timer *= wind.pace
	if modifiers.has("crosswind"):
		wind.min_strength = 1.0
		wind.strength = 1.0
		wind.target_strength = 1.0
	if modifiers.has("anomaly"):
		stats.values["wake_decay"] = float(stats.values["wake_decay"]) * 1.5
	wake = WakeSystem.new(stats)
	director = SpawnDirector.new(self)
	_build_world()
	var start := arena.size * 0.5
	var keep_path: Array = MissionLogic.ESCORT_PATH if str(cfg.get("objective", "")) == "escort" else []
	arena.generate(rng, start, int(cfg.get("reefs", 6)), keep_path)
	player = PlayerShip.new()
	player.position = start
	player.setup(self, stats)
	player.z_index = 2
	player.fire_lock = true
	add_child(player)
	friendlies.append(player)
	if modifiers.has("limited_modules"):
		for i in player.module_charges.size():
			player.module_charges[i] = 2
	camera.position = start
	camera.reset_smoothing()
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)
	hud = Hud.new()
	hud.run = self
	hud_layer.add_child(hud)
	tutorial_active = (mode == "practice" and not bool(cfg.get("training", false))) or (bool(cfg.get("tutorial", false)) and not bool(SaveData.data["tutorial_done"]))
	match mode:
		"practice":
			player.god_mode = true
			wake.hold = false
			if bool(cfg.get("training", false)):
				coach = TrainingCoach.new()
				coach.run = self
				add_child(coach)
			else:
				banner("SEA TRIALS", "Practice freely. Number and letter keys spawn enemies and hazards.", GameData.COL_PORT)
		"classic":
			start_wave(1)
		_:
			hazards.setup_mission(cfg, GameData.global_stage(cfg))
			logic = MissionLogic.new(self, cfg)
			wake.hold = false
			banner(str(cfg.get("name", "")).to_upper(), "%s   |   %s" % [cfg.get("type", ""), GameData.DIFFICULTIES[cfg.get("difficulty", "standard")]["name"]], GameData.COL_PORT)
			if modifier != "":
				banner("MODIFIER: " + str(GameData.MODIFIERS[modifier]["name"]).to_upper(), str(GameData.MODIFIERS[modifier]["desc"]), Color(1.0, 0.75, 0.4))
			logic.start()


func _build_world() -> void:
	var margin := GameData.ARENA_MARGIN
	ocean = ColorRect.new()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ocean.gdshader")
	var full := GameData.ARENA_SIZE + Vector2(margin, margin) * 2.0
	mat.set_shader_parameter("rect_size", full)
	mat.set_shader_parameter("arena_origin", Vector2(margin, margin))
	mat.set_shader_parameter("arena_size", GameData.ARENA_SIZE)
	mat.set_shader_parameter("detail", SaveData.particle_scale())
	var reg: Dictionary = GameData.region(int(cfg.get("region", 1)))
	mat.set_shader_parameter("deep", reg["deep"])
	mat.set_shader_parameter("shallow", reg["shallow"])
	mat.set_shader_parameter("glint", reg["glint"])
	ocean.material = mat
	ocean.position = Vector2(-margin, -margin)
	ocean.size = full
	ocean.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ocean.z_index = -10
	add_child(ocean)
	fx_under = FxLayer.new()
	fx_under.z_index = -5
	add_child(fx_under)
	arena = Arena.new()
	arena.z_index = 0
	add_child(arena)
	hazards = Hazards.new()
	hazards.run = self
	hazards.z_index = 0
	add_child(hazards)
	enemies_root = Node2D.new()
	enemies_root.z_index = 1
	add_child(enemies_root)
	shots = ProjectileSystem.new()
	shots.run = self
	shots.z_index = 3
	add_child(shots)
	fx_over = FxLayer.new()
	fx_over.z_index = 4
	add_child(fx_over)
	camera = Camera2D.new()
	camera.zoom = Vector2(0.85, 0.85)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = -260
	camera.limit_top = -260
	camera.limit_right = int(GameData.ARENA_SIZE.x) + 260
	camera.limit_bottom = int(GameData.ARENA_SIZE.y) + 260
	add_child(camera)
	camera.make_current()


func controls_enabled() -> bool:
	return state != "ended" and player != null and player.alive


func tracking() -> bool:
	return mode != "practice"


func _track(event: String, key: String = "", amount: int = 1) -> void:
	if tracking():
		Profile.track(event, key, amount)


func start_wave(n: int) -> void:
	wave = n
	var wcfg: Dictionary = GameData.get_wave(n)
	director.begin(wcfg, n)
	hazards.prepare_wave(n)
	state = "combat"
	wake.hold = false
	wake.steady()
	damage_taken_wave = 0.0
	if n == GameData.MAX_WAVE:
		banner("WARNING", "The Galleon approaches - watch its telegraphs", GameData.COL_WARN)
		Sound.play("boss", null, 0.0)
	else:
		banner("WAVE %d" % n, str(wcfg["note"]), GameData.COL_PORT)


func hazard_intro(kind: String) -> void:
	var key := "h_" + kind
	if seen_types.has(key):
		return
	seen_types[key] = true
	var info: Array = GameData.HAZARD_INTRO.get(kind, [])
	if info.size() >= 2:
		var col := GameData.COL_SALVAGE if kind == "wreck" else Color(0.6, 0.9, 1.0)
		banner(str(info[0]), str(info[1]), col)


func next_wave() -> void:
	start_wave(wave + 1)
	player.fire_lock = true


func spawn_enemy(kind: String, pos: Vector2, variants: Array = []) -> Enemy:
	var e: Enemy
	match kind:
		"frigate":
			e = Frigate.new()
		"fireship":
			e = Fireship.new()
		"galleon":
			e = Galleon.new()
		"rammer":
			e = Rammer.new()
		"courier":
			e = Courier.new()
		"ironwake":
			e = Ironwake.new()
		"mortar_monitor":
			e = MortarMonitor.new()
		"mine_layer":
			e = MineLayer.new()
		"shield_tender":
			e = ShieldTender.new()
		"repair_barge":
			e = RepairBarge.new()
		"siege_barge":
			e = SiegeBarge.new()
		"siege_platform":
			e = SiegePlatform.new()
		"kharon":
			e = Kharon.new()
		"harpooner":
			e = Harpooner.new()
		"longbow_sloop":
			e = LongbowSloop.new()
		"matriarch":
			e = Matriarch.new()
		"ghost_runner":
			e = GhostRunner.new()
		"jammer":
			e = Jammer.new()
		"swarm_skater":
			e = SwarmSkater.new()
		"leviathan_pod":
			e = LeviathanPod.new()
		"leviathan":
			e = Leviathan.new()
		"resonant_carrier":
			e = ResonantCarrier.new()
		"resonant_drone":
			e = ResonantDrone.new()
		"resonance_anchor":
			e = ResonanceAnchor.new()
		"sovereign":
			e = Sovereign.new()
		_:
			e = Gunboat.new()
	e.position = pos
	if player != null:
		e.rotation = (player.position - pos).angle()
	var hull_mult := 1.0
	if mode == "classic":
		hull_mult = GameData.hull_scale(wave)
	elif mode != "practice":
		hull_mult = float(difficulty["hull"])
	e.setup(self, kind, variants, hull_mult)
	if e.boss and float(cfg.get("boss_hull", 1.0)) != 1.0:
		e.max_hull *= float(cfg.get("boss_hull", 1.0))
		e.hull = e.max_hull
	enemies_root.add_child(e)
	enemies.append(e)
	fx_over.ring(pos, e.radius * 2.5, 0.5, Color(1.0, 0.5, 0.4, 0.8), 2.0)
	fx_under.burst(pos, 12, 80.0, Color(0.6, 0.85, 1.0, 0.8), 0.6, 3.0)
	if tracking() and SaveData.mark_seen(kind):
		research_found += 5
		fx_over.text(pos + Vector2(0, -50), "NEW CODEX ENTRY  +5 RESEARCH", GameData.COL_RESEARCH, 15, 1.6)
	if not seen_types.has(kind):
		seen_types[kind] = true
		if not e.boss and not (kind in ["siege_platform", "leviathan_pod", "resonant_drone"]):
			banner("NEW THREAT: " + GameData.enemy_name(kind).to_upper(), str(GameData.ENEMIES[kind]["intro"]), GameData.COL_ENEMY)
	if e.boss:
		boss = e
		Sound.play("boss", pos, 2.0)
		banner(e.boss_title(), str(GameData.ENEMIES[kind]["intro"]), GameData.COL_WARN)
	return e


func hostile_count() -> int:
	return enemies.size()


func _physics_process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	if state == "ended":
		end_timer -= dt
		_update_camera(dt)
		if end_timer <= 0.0 and not end_emitted:
			end_emitted = true
			run_finished.emit(build_result())
		return
	time += dt
	dodge_cd = maxf(0.0, dodge_cd - dt)
	cross_cd = maxf(0.0, cross_cd - dt)
	weak_cd = maxf(0.0, weak_cd - dt)
	scanner_timer = maxf(0.0, scanner_timer - dt)
	sonar_timer = maxf(0.0, sonar_timer - dt)
	var was_jammed := jammed
	jammed = false
	if sonar_timer <= 0.0:
		for je in enemies:
			if is_instance_valid(je) and je.alive and je.kind == "jammer" and (je as Jammer).jamming():
				jammed = true
				break
	if jammed and not was_jammed:
		banner("SENSORS JAMMED", "Markers are unreliable - find and sink the Jammer", Color(0.8, 0.6, 1.0))
	var fc := false_contacts.size() - 1
	while fc >= 0:
		false_contacts[fc]["life"] = float(false_contacts[fc]["life"]) - dt
		if float(false_contacts[fc]["life"]) <= 0.0 or not jammed:
			false_contacts.remove_at(fc)
		fc -= 1
	var i := smokes.size() - 1
	while i >= 0:
		smokes[i]["life"] = float(smokes[i]["life"]) - dt
		if float(smokes[i]["life"]) <= 0.0:
			smokes.remove_at(i)
		i -= 1
	wake.boost = (1.25 if player.surge_timer > 0.0 else 1.0) * (2.0 if in_distortion(player.position) else 1.0) * (1.5 if modifiers.has("anomaly") else 1.0)
	var wind_event := wind.update(dt)
	if wind_event == 1:
		banner("WIND SHIFT", "Wind turning toward %s" % _compass(Vector2.RIGHT.rotated(wind.target_angle)), Color(0.7, 0.9, 1.0))
		Sound.play("wind", null, -4.0)
	wake.update(dt)
	_handle_wake_change()
	match mode:
		"classic":
			if state == "combat":
				director.update(dt)
				if director.finished() and enemies.is_empty():
					_wave_cleared()
			elif state == "intermission":
				inter_timer -= dt
				if inter_timer <= 0.0:
					state = "shipyard"
					wave_cleared.emit(wave, _wave_report)
		"practice":
			pass
		_:
			if state == "combat" and logic != null:
				logic.update(dt)
				if logic.done:
					finish(true)
				elif logic.failed:
					fail_reason = logic.fail_reason
					finish(false)
	_update_camera(dt)
	_ambient(dt)
	_update_music()


func _wave_cleared() -> void:
	state = "intermission"
	inter_timer = 2.2
	wake.hold = true
	shots.clear_enemy_fire()
	var reward := 10 + wave * 3
	var clean := damage_taken_wave <= 0.0
	var bonus := 0
	if clean:
		bonus = 8
		wake.add(40.0, "CLEAN WAVE")
	add_score(500 * wave)
	award_salvage(reward + bonus, player.position + Vector2(0, -60), "")
	var repaired := 0.0
	if stats.has_flag("repair_kit"):
		var before := player.hull
		player.heal(15.0)
		repaired = player.hull - before
	_wave_report = {"wave": wave, "reward": reward, "clean_bonus": bonus, "repaired": repaired, "clean": clean}
	if wave >= GameData.MAX_WAVE:
		finish(true)
		return
	var sub := "+%d Salvage" % (reward + bonus)
	if clean:
		sub += "  |  Clean wave bonus +%d" % bonus
	banner("WAVE %d CLEARED" % wave, sub, GameData.COL_SALVAGE)
	Sound.play("confirm", null, -2.0)


func finish(won: bool) -> void:
	if state == "ended":
		return
	state = "ended"
	victory = won
	wake.hold = true
	end_timer = 3.0 if won else 2.0
	if won:
		shots.clear_enemy_fire()
	if mode == "classic":
		if won:
			banner("VICTORY", "The flagship is sunk", GameData.COL_SALVAGE)
		else:
			banner("HULL BREACHED", "Your ship is lost", GameData.COL_WARN)
	elif won:
		banner("MISSION COMPLETE", str(cfg.get("name", "")), GameData.COL_SALVAGE)
		Sound.play("tier_up", null, 0.0, 0.8)
	else:
		banner("MISSION FAILED", fail_reason if fail_reason != "" else "Your ship was sunk", GameData.COL_WARN)
	Sound.set_music(0.6, 0.0, 0.0, 0.0)


func build_result() -> Dictionary:
	var acc := 0.0
	if shots_fired > 0:
		acc = float(shots_hit) / float(shots_fired)
	var modifier := str(cfg.get("modifier", ""))
	var r := {
		"mode": mode,
		"mission_id": str(cfg.get("id", "")),
		"op": str(cfg.get("op", "")),
		"name": str(cfg.get("name", "")),
		"label": str(cfg.get("label", "")),
		"ship": ship_id,
		"difficulty": str(cfg.get("difficulty", "standard")),
		"modifier": modifier,
		"modifier_reward": float(GameData.MODIFIERS[modifier]["reward"]) if modifier != "" else 1.0,
		"success": victory,
		"victory": victory,
		"time": time,
		"wave": wave,
		"score": score,
		"kills": kills,
		"accuracy": acc,
		"max_tier": wake.max_tier,
		"bosses": bosses_defeated,
		"salvage_earned": salvage_earned,
		"salvage_spent": salvage_spent,
		"salvage_collected": salvage,
		"research_found": research_found,
		"upgrades": stats.owned.duplicate(),
		"seed": seed_value,
		"kills_by_type": kills_by_type.duplicate(),
		"damage_sources": damage_sources.duplicate(),
		"fail_reason": fail_reason,
		"hull_ratio": player.hull / maxf(1.0, stats.get_value("max_hull")),
		"wrecks": wrecks_salvaged,
		"crossings": crossings,
		"interrupts": interrupts,
		"dodges": dodges,
		"rewards": cfg.get("rewards", {}),
		"bounty": bounty_reward,
		"debrief": str(cfg.get("debrief", "")),
		"par_time": float(cfg.get("par_time", 0.0)),
		"grade": "D",
		"remix": bool(cfg.get("remix", false)),
		"optional_texts": [],
		"optional_results": [],
	}
	if logic != null:
		r["grade"] = logic.grade()
		r["optional_results"] = logic.optional_results()
		var texts: Array = []
		for o in cfg.get("optional", []):
			texts.append(str(o["text"]))
		r["optional_texts"] = texts
	return r


func _handle_wake_change() -> void:
	var c := wake.take_change()
	if c > 0:
		Sound.play("tier_up", null, -3.0)
		fx_over.text(player.position + Vector2(0, -50), "WAKE %s  %s" % [GameData.WAKE_ROMAN[wake.tier], GameData.WAKE_NAMES[wake.tier].to_upper()], GameData.wake_color(wake.tier), 22, 1.4)
		fx_under.ring(player.position, 120.0, 0.7, GameData.wake_color(wake.tier), 3.0)
		hud.pulse_wake()
		tutorial_event("wake")
	elif c < 0:
		Sound.play("tier_down", null, -5.0)
		hud.pulse_wake()


func add_score(points: float) -> void:
	var mult := wake.multiplier() * stats.get_value("score_mult")
	if stats.has_flag("resonant") and wake.tier >= 3:
		mult *= 1.25
	score += int(points * mult)


func award_salvage(amount: int, pos: Vector2, label: String) -> void:
	if amount <= 0:
		return
	salvage += amount
	salvage_earned += amount
	var txt := "+%d SALVAGE" % amount
	if label != "":
		txt += "  " + label
	fx_over.text(pos, txt, GameData.COL_SALVAGE, 16, 1.2)
	Sound.play("salvage", pos, -10.0)


func add_shake(amount: float) -> void:
	shake = minf(shake + amount, 24.0)


func banner(title: String, sub: String, color: Color) -> void:
	if hud != null:
		hud.push_banner(title, sub, color)


func target_for(e):
	var best = null
	var bd := INF
	for d in decoys:
		if d.alive:
			var dist: float = (e.position as Vector2).distance_to(d.position)
			if dist < 700.0 and dist < bd:
				best = d
				bd = dist
	if best != null:
		return best
	for f in friendlies:
		if not f.alive or not f.physical:
			continue
		var fd: float = (e.position as Vector2).distance_to(f.position) * (1.0 if f == player else 0.85)
		if fd < bd:
			best = f
			bd = fd
	if best == null:
		return player
	if best == player and _smoke_at(player.position) >= 0 and (e.position as Vector2).distance_to(player.position) > 150.0:
		var sm: Dictionary = smokes[_smoke_at(player.position)]
		var proxy := TargetProxy.new()
		var seed_f := float(e.get_instance_id() % 1000)
		proxy.position = (sm["pos"] as Vector2) + Vector2(cos(seed_f * 1.7), sin(seed_f * 2.3)) * float(sm["radius"]) * 0.8
		return proxy
	return best


func _smoke_at(p: Vector2) -> int:
	for i in smokes.size():
		if p.distance_to(smokes[i]["pos"]) <= float(smokes[i]["radius"]):
			return i
	return -1


func in_distortion(p: Vector2) -> bool:
	if distortion.is_empty():
		return false
	return p.distance_to(distortion["pos"]) <= float(distortion["radius"])


func reveals(e) -> bool:
	return scanner_timer > 0.0 or sonar_timer > 0.0 or hazards.in_bloom(e.position)


func shield_factor(e) -> float:
	if e.kind == "shield_tender":
		return 1.0
	for o in enemies:
		if o != e and o.alive and o.kind == "shield_tender" and (o as ShieldTender).covers(e):
			return 1.0 - float(o.data["shield"])
	return 1.0


func commander_aura(e) -> bool:
	for o in enemies:
		if o != e and o.alive and o.commander and (o.position as Vector2).distance_to(e.position) < 280.0:
			return true
	return false


func spawn_ally(id: String, path: Array) -> AllyShip:
	var a := AllyShip.new()
	a.setup(self, id, path, 1.0)
	a.z_index = 2
	add_child(a)
	allies.append(a)
	friendlies.append(a)
	return a


func on_ally_damaged(a: AllyShip, _amount: float) -> void:
	if not ally_warned and a.hull < a.max_hull * 0.35:
		ally_warned = true
		banner("CONVOY UNDER HEAVY FIRE", "Draw the attackers away from the barge", GameData.COL_WARN)


func on_ally_destroyed(a: AllyShip) -> void:
	allies.erase(a)
	friendlies.erase(a)
	if logic != null:
		logic.on_ally_destroyed()


func on_ally_arrived(_a: AllyShip) -> void:
	banner("CONVOY SAFE", "The barge reached open water", GameData.COL_ALLY)
	if logic != null:
		logic.on_ally_arrived()


func spawn_decoy(pos: Vector2, duration: float, hull_v: float) -> void:
	var d := Decoy.new()
	d.setup(self, duration, hull_v)
	d.position = pos
	d.z_index = 1
	add_child(d)
	decoys.append(d)
	friendlies.append(d)


func on_decoy_gone(d: Decoy) -> void:
	decoys.erase(d)
	friendlies.erase(d)


func add_smoke(pos: Vector2, radius: float, duration: float) -> void:
	smokes.append({"pos": pos, "radius": radius, "life": duration})
	fx_over.smoke(pos, radius, duration)


func shock_pulse(pos: Vector2, radius: float, damage: float, knock: float = 220.0, slow: float = 0.4) -> void:
	fx_over.ring(pos, radius, 0.4, Color(0.6, 0.9, 1.0, 0.9), 4.0)
	fx_over.burst(pos, 30, 300.0, Color(0.6, 0.9, 1.0), 0.4, 2.5)
	Sound.play("impact", pos, 0.0, 0.5)
	add_shake(4.0)
	shots.clear_enemy_near(pos, radius)
	for e in enemies.duplicate():
		if not is_instance_valid(e) or not e.alive:
			continue
		var to: Vector2 = (e.position as Vector2) - pos
		if to.length() <= radius + float(e.radius):
			e.receive_hit(damage, pos, false, "pulse")
			if is_instance_valid(e) and e.alive:
				e.apply_slow(slow, 2.0)
				if not e.boss and not e.anchored:
					e.velocity += to.normalized() * knock


func on_player_fired(slot: String, count: int) -> void:
	shots_fired += count
	tutorial_event(slot)


func on_shot_result(hit: bool) -> void:
	if hit:
		shots_hit += 1
	elif state == "combat" and not enemies.is_empty():
		wake.lose(1.5, "MISS", false)


func on_enemy_hit(e: Enemy, dmg: float, crossed: bool, pos: Vector2, weak: bool = false) -> void:
	if stats.ability == "pressure_pulse" and player.alive and player.position.distance_to(e.position) <= float(GameData.ABILITIES["pressure_pulse"]["range"]) + float(e.radius):
		player.charge = minf(1.0, player.charge + float(GameData.ABILITIES["pressure_pulse"]["per_hit"]) * stats.get_value("charge_mult") * minf(dmg / 10.0, 1.5))
	add_score(dmg * 2.0)
	wake.add(6.0 * minf(dmg / 10.0, 1.0), "HIT", "hit")
	if crossed and cross_cd <= 0.0:
		cross_cd = 0.6
		crossings += 1
		_track("crossing")
		wake.add(12.0, "CROSSED THE T", "cross")
		add_score(150)
		fx_over.text(pos + Vector2(0, -30), "CROSSED THE T", Color(1.0, 0.88, 0.4), 18, 1.2)
	if weak:
		weak_hits += 1
		_track("weak")
	if weak and weak_cd <= 0.0:
		weak_cd = 0.5
		wake.add(6.0, "WEAK POINT", "weak")
		add_score(60)
		fx_over.text(pos + Vector2(0, -50), "WEAK POINT", Color(0.6, 1.0, 0.9), 15, 0.9)


func on_interrupt(e: Enemy) -> void:
	interrupts += 1
	_track("interrupt")
	wake.add(14.0, "INTERRUPT", "interrupt")
	add_score(120)
	Sound.play("confirm", e.position, -6.0, 1.3)


func on_enemy_killed(e: Enemy) -> void:
	enemies.erase(e)
	kills += 1
	kills_by_type[e.kind] = int(kills_by_type.get(e.kind, 0)) + 1
	_track("kill", e.kind)
	if blast_credit:
		blast_kills += 1
	if e.stormbound:
		_track("stormbound")
	if e.resonant:
		wake.add(12.0, "RESONANCE", "kill")
	if mine_credit:
		mine_kills += 1
		on_style_event("MINE KILL", 10.0, 120, e.position)
	add_score(float(e.data["score"]) * (1.5 if e.elite else 1.0))
	wake.add(18.0, "KILL", "kill")
	var amount := float(int(e.data["salvage"]) + (3 if e.elite else 0)) * stats.get_value("salvage_mult")
	if modifiers.has("rich_salvage"):
		amount *= 1.5
	if stats.has_flag("resonant") and wake.tier >= 3:
		amount += 1.0
	if stats.ability == "plunder_raid" and (e.slow_timer > 0.0 or e.harpoon_timer > 0.0 or e.grapple_timer > 0.0 or e.sunder_timer > 0.0):
		amount += 3.0
	award_salvage(int(round(amount)), e.position + Vector2(0, -20), "")
	if mode != "classic":
		var no_rep := modifiers.has("no_repairs")
		if e.elite or e.commander:
			hazards.add_pickup(e.position, "repair" if not no_rep and rng.randf() < 0.6 else "salvage")
		elif rng.randf() < 0.1:
			hazards.add_pickup(e.position, "repair" if not no_rep and rng.randf() < 0.4 else "salvage")
	if logic != null:
		logic.on_enemy_killed(e)
		if e.named_id != "":
			bounty_reward = logic.bounty
			banner("BOUNTY CLAIMED", e.name_tag, GameData.COL_SALVAGE)
	if e.boss:
		bosses_defeated += 1
		boss = null
		shots.clear_enemy_fire()
		add_score(5000)
		for k in 6:
			var off := Vector2(rng.randf_range(-70, 70), rng.randf_range(-40, 40))
			fx_over.explosion(e.position + off, rng.randf_range(50.0, 110.0))
		add_shake(20.0)
		for other in enemies.duplicate():
			if is_instance_valid(other) and other.alive:
				other.take_damage(99999.0)


func on_enemy_expended(e: Enemy) -> void:
	enemies.erase(e)


func on_courier_escaped(e: Enemy) -> void:
	enemies.erase(e)
	banner("COURIER ESCAPED", "", GameData.COL_WARN)
	Sound.play("deny", null, -2.0)
	if logic != null:
		logic.on_courier_escaped()


func on_boss_phase(b: Enemy) -> void:
	var phase: int = int(b.get("phase"))
	var lines: Dictionary = BOSS_LINES.get(b.kind, {})
	var line: Array = lines.get(phase, ["PHASE %d" % phase, ""])
	banner(str(line[0]), str(line[1]), GameData.COL_WARN)
	Sound.play("boss", null, 2.0, 0.85)
	add_shake(10.0)
	wake.add(25.0, "PHASE BREAK", "phase")
	add_score(1000)
	var escorts := ["gunboat", "gunboat"]
	if b.kind == "ironwake" and phase == 3:
		escorts = ["rammer", "gunboat"]
	elif b.kind == "kharon":
		escorts = []
	elif b.kind == "sovereign":
		escorts = ["resonant_carrier"] if phase == 2 else ([] if phase == 3 else ["gunboat", "gunboat"])
	elif b.kind == "leviathan":
		escorts = ["swarm_skater", "swarm_skater", "ghost_runner"] if phase == 2 else ["swarm_skater", "swarm_skater"]
	elif b.kind == "matriarch":
		escorts = ["harpooner", "longbow_sloop"] if phase == 2 else ["gunboat", "harpooner"]
	for k in escorts:
		var pos := director.pick_spawn(false)
		fx_over.spawn_cue(pos)
		spawn_enemy(k, pos, [])


func on_player_damaged(amount: float, source: String) -> void:
	damage_taken_wave += amount
	damage_sources[source] = float(damage_sources.get(source, 0.0)) + amount
	var mult := 1.6 if stats.has_flag("resonant_wake") else 1.0
	if amount >= 15.0 and stats.has_flag("phase_anchor"):
		wake.lose(60.0 * mult, "HEAVY DAMAGE")
	elif amount >= 15.0:
		wake.drop_tier("HEAVY DAMAGE")
	else:
		wake.lose(35.0 * mult, "HULL DAMAGE")
	hud.pulse_damage()


func on_player_died() -> void:
	fx_over.explosion(player.position, 90.0)
	Sound.play("explosion", player.position, 4.0, 0.7)
	add_shake(22.0)
	fail_reason = "Your ship was sunk"
	finish(false)


func on_close_dodge(pos: Vector2) -> void:
	if dodge_cd > 0.0 or state != "combat":
		return
	dodge_cd = 0.5
	dodges += 1
	_track("dodge")
	player.on_dodge()
	wake.add(12.0, "CLOSE DODGE", "dodge")
	add_score(50)
	fx_over.text(pos + Vector2(0, -36), "CLOSE DODGE", Color(0.6, 1.0, 0.9), 16, 0.9)
	Sound.play("dodge", pos, -6.0)


func on_style_event(text: String, gain: float, points: int, pos: Vector2, category: String = "style") -> void:
	if state != "combat":
		return
	wake.add(gain, text, category)
	add_score(points)
	fx_over.text(pos + Vector2(0, -40), text, GameData.wake_color(maxi(wake.tier, 2)), 16, 0.9)


func on_wreck_salvaged(p: Vector2) -> void:
	wrecks_salvaged += 1
	var wr := int(cfg.get("wreck_research", 0))
	if wr > 0:
		research_found += wr
		fx_over.text(p + Vector2(0, -70), "+%d RESEARCH" % wr, GameData.COL_RESEARCH, 15, 1.4)
	_track("wreck")


func on_checkpoint(_i: int) -> void:
	add_score(200)
	wake.add(8.0, "CHECKPOINT", "style")


func tutorial_event(id: String) -> void:
	if coach != null:
		coach.on_event(id)
	if not tutorial_active:
		return
	tutorial_done[id] = true
	if tutorial_text() == "":
		tutorial_active = false
		if mode != "practice":
			SaveData.data["tutorial_done"] = true
			SaveData.save()


func _tutorial_applies(id: String) -> bool:
	match id:
		"port", "starboard", "bow", "stern", "turret":
			return player.slots.has(id)
		"module":
			return not stats.modules.is_empty()
		"ability":
			return stats.ability != ""
	return true


func tutorial_text() -> String:
	if not tutorial_active:
		return ""
	for step in TUTORIAL:
		if tutorial_done.has(step[0]) or not _tutorial_applies(str(step[0])):
			continue
		var keys: Array = []
		for a in step[2]:
			keys.append(Controls.key_text(a) if str(a).begins_with("fire") and not Controls.using_pad else Controls.short_text(a))
		var text: String = str(step[1])
		if step[0] == "ability":
			text = "[%s] uses your ship ability: " + str(GameData.ABILITIES[stats.ability]["name"])
		if keys.is_empty():
			return text
		return text % keys
	return ""


func roll_offers(count: int) -> Array:
	var pool: Array = []
	for u in GameData.UPGRADES:
		if stats.can_take(u):
			pool.append(u)
	var picks: Array = []
	while picks.size() < count and not pool.is_empty():
		var idx := rng.randi_range(0, pool.size() - 1)
		picks.append(pool[idx])
		pool.remove_at(idx)
	return picks


func buy_upgrade(up: Dictionary) -> bool:
	var cost := int(up["cost"])
	if salvage < cost or not stats.can_take(up):
		return false
	salvage -= cost
	salvage_spent += cost
	stats.apply(up)
	player.rebuild_weapons()
	if up.has("heal"):
		player.heal(float(up["heal"]))
	player.hull = minf(player.hull, stats.get_value("max_hull"))
	return true


func repair(amount: float) -> bool:
	if salvage < repair_cost or player.hull >= stats.get_value("max_hull"):
		return false
	salvage -= repair_cost
	salvage_spent += repair_cost
	player.heal(amount)
	repair_cost += 4
	return true


func pay_reroll() -> bool:
	if salvage < reroll_cost:
		return false
	salvage -= reroll_cost
	salvage_spent += reroll_cost
	reroll_cost += 5
	return true


func _update_camera(dt: float) -> void:
	if player == null:
		return
	camera.position = player.position + player.velocity * 0.35
	shake *= exp(-6.0 * dt)
	var s := shake * SaveData.shake_scale()
	camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s)) if s > 0.2 else Vector2.ZERO


func _ambient(dt: float) -> void:
	streak_timer -= dt
	if streak_timer > 0.0:
		return
	streak_timer = 0.09 / maxf(0.3, SaveData.particle_scale())
	var view := get_viewport_rect().size / camera.zoom
	var p := camera.position + Vector2(randf_range(-0.5, 0.5) * view.x, randf_range(-0.5, 0.5) * view.y)
	fx_under.burst(p, 1, 0.0, Color(0.6, 0.85, 1.0, 0.18 + 0.2 * wind.strength), 2.2, 1.6)
	var last: FxLayer.Particle = fx_under.parts.back() if not fx_under.parts.is_empty() else null
	if last != null:
		last.vel = wind.dir() * (60.0 + 120.0 * wind.strength)
		last.drag = 0.0


func _update_music() -> void:
	var t := float(wake.tier)
	var combat_level := 0.15
	var high := 0.0
	var boss_level := 0.0
	var fighting := state == "combat" and (not enemies.is_empty() or not director.finished())
	if fighting:
		combat_level = 0.35 + 0.65 * minf(t / 2.0, 1.0)
		high = clampf((t - 1.0) / 2.0, 0.0, 1.0)
		if boss != null and is_instance_valid(boss):
			boss_level = 1.0
			high *= 0.6
	Sound.set_music(0.75, combat_level, high, boss_level)


func _compass(v: Vector2) -> String:
	var names := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
	var idx := posmod(int(round(v.angle() / (PI / 4.0))), 8)
	return names[idx]


func _unhandled_input(event: InputEvent) -> void:
	if mode != "practice" or state == "ended" or coach != null:
		return
	var ke := event as InputEventKey
	if ke == null or not ke.pressed or ke.echo:
		return
	var basin := Profile.has_facility("training_basin")
	match ke.keycode:
		KEY_1:
			_practice_spawn("gunboat", [])
		KEY_2:
			_practice_spawn("frigate", [])
		KEY_3:
			_practice_spawn("fireship", [])
		KEY_4:
			_practice_spawn("rammer", [])
		KEY_5:
			_practice_spawn("courier", [])
		KEY_6:
			if boss == null:
				_practice_spawn("galleon", [])
		KEY_7:
			if boss == null and basin:
				var bosses: Array = []
				for bk in ["ironwake", "kharon", "matriarch", "leviathan", "sovereign"]:
					if Profile.known("bosses", bk):
						bosses.append(bk)
				if not bosses.is_empty():
					_practice_spawn(bosses[practice_boss % bosses.size()], [])
					practice_boss += 1
		KEY_9:
			var pool: Array = GameData.REGION_TWO + GameData.REGION_THREE + GameData.REGION_FOUR + GameData.REGION_FIVE
			var r2: String = pool[practice_r2 % pool.size()]
			practice_r2 += 1
			_practice_spawn(r2, [])
		KEY_Y:
			hazards.add_lightning_field(_practice_spot(380.0))
		KEY_O:
			hazards.add_vent(_practice_spot(300.0))
		KEY_E:
			hazards.add_rift(_practice_spot(360.0))
		KEY_Q:
			hazards.add_bloom(_practice_spot(260.0))
		KEY_M:
			hazards.add_wreck_field(_practice_spot(420.0))
		KEY_8:
			if basin:
				var kinds := ["gunboat", "frigate", "rammer"]
				var vs := ["veteran", "armored", "commander", "elite", "stormbound", "resonant"]
				_practice_spawn(kinds[rng.randi_range(0, 2)], [vs[rng.randi_range(0, 5)]])
		KEY_0:
			for e in enemies.duplicate():
				if is_instance_valid(e):
					e.alive = false
					e.queue_free()
			enemies.clear()
			boss = null
			shots.clear_enemy_fire()
			hazards.clear_all()
		KEY_H:
			player.heal(9999.0)
		KEY_I:
			player.god_mode = not player.god_mode
		KEY_R:
			if arena.rocks.is_empty():
				arena.generate(rng, player.position, 6)
			else:
				arena.clear_rocks()
		KEY_T:
			wind.force_shift()
		KEY_Z:
			hazards.add_minefield(_practice_spot(380.0))
		KEY_X:
			hazards.add_whirlpool(_practice_spot(420.0))
		KEY_C:
			hazards.add_storm(_practice_spot(520.0))
		KEY_V:
			hazards.add_wreck(_practice_spot(300.0))
		KEY_B:
			hazards.add_current(_practice_spot(320.0))


func _practice_spot(dist: float) -> Vector2:
	var dir := Vector2.RIGHT.rotated(player.rotation)
	var p := player.position + dir * dist
	p.x = clampf(p.x, 200.0, arena.size.x - 200.0)
	p.y = clampf(p.y, 200.0, arena.size.y - 200.0)
	return p


func _practice_spawn(kind: String, variants: Array) -> void:
	var big := GameData.is_boss(kind)
	var pos := director.pick_spawn(big)
	fx_over.spawn_cue(pos, big)
	var e := spawn_enemy(kind, pos, variants)
	if kind == "courier":
		var size: Vector2 = arena.size
		(e as Courier).set_exit(Vector2(size.x - pos.x, size.y - pos.y))

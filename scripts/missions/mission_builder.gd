class_name MissionBuilder
extends RefCounted

const PATROL_POOL := [
	[{"spawn": [["gunboat", 4]]}],
	[{"spawn": [["gunboat", 2], ["frigate", 1]]}],
	[{"spawn": [["fireship", 2], ["gunboat", 2]]}],
	[{"spawn": [["rammer", 1], ["gunboat", 2]]}],
	[{"spawn": [["frigate", 2]], "side": "left"}, {"spawn": [["gunboat", 2]], "side": "right"}],
	[{"spawn": [["gunboat", 3, ["veteran"]]]}],
	[{"spawn": [["frigate", 1, ["armored"]], ["fireship", 1], ["gunboat", 2]]}],
]

const PATROL_POOL_3 := [
	[{"spawn": [["harpooner", 1], ["gunboat", 2, ["stormbound"]]]}],
	[{"spawn": [["longbow_sloop", 1], ["frigate", 1]]}],
	[{"spawn": [["frigate", 2, ["stormbound"]], ["harpooner", 1]]}],
	[{"spawn": [["rammer", 1, ["stormbound"]], ["longbow_sloop", 1], ["gunboat", 2]]}],
]

const PATROL_POOL_5 := [
	[{"spawn": [["resonant_carrier", 1], ["gunboat", 2, ["resonant"]]]}],
	[{"spawn": [["frigate", 2, ["resonant"]], ["harpooner", 1]]}],
	[{"spawn": [["rammer", 1, ["resonant"]], ["swarm_skater", 4]]}],
	[{"spawn": [["ghost_runner", 1, ["resonant"]], ["longbow_sloop", 1], ["gunboat", 2]]}],
]

const REMIX_VARIANTS := ["veteran", "armored", "stormbound", "resonant", "elite"]

const PATROL_POOL_4 := [
	[{"spawn": [["swarm_skater", 5]]}],
	[{"spawn": [["ghost_runner", 1], ["swarm_skater", 3]]}],
	[{"spawn": [["jammer", 1], ["frigate", 1], ["gunboat", 2]]}],
	[{"spawn": [["ghost_runner", 2], ["gunboat", 2]]}],
]

const PATROL_POOL_2 := [
	[{"spawn": [["mortar_monitor", 1], ["gunboat", 3]]}],
	[{"spawn": [["mine_layer", 1], ["frigate", 1], ["gunboat", 1]]}],
	[{"spawn": [["shield_tender", 1], ["frigate", 2]]}],
	[{"spawn": [["siege_barge", 1], ["gunboat", 2]]}],
	[{"spawn": [["repair_barge", 1], ["frigate", 1, ["armored"]], ["gunboat", 2]]}],
	[{"spawn": [["gunboat", 3, ["armored"]], ["mortar_monitor", 1]]}],
]


static func campaign(id: String, difficulty: String, remix: bool = false) -> Dictionary:
	var m: Dictionary = (GameData.mission(id) as Dictionary).duplicate(true)
	m["mode"] = "campaign"
	m["id"] = id
	m["label"] = "STAGE %s" % GameData.stage_label(id)
	m["difficulty"] = difficulty
	m["modifier"] = ""
	if remix:
		_remix(m)
	return m


static func _remix(m: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(m["id"])) + 77
	m["remix"] = true
	m["label"] = "STAGE %s  REMIX" % GameData.stage_label(str(m["id"]))
	m["boss_hull"] = 1.3
	var rw: Dictionary = m.get("rewards", {})
	for k in rw.keys():
		rw[k] = int(round(float(rw[k]) * 1.5))
	var hz: Dictionary = m.get("hazards", {})
	hz["rifts"] = int(hz.get("rifts", 0)) + 1
	m["hazards"] = hz
	var waves: Array = m.get("waves", [])
	for w in waves:
		var groups: Array = []
		if w is Array:
			groups = w
		else:
			groups = [w]
		for g in groups:
			for entry in g["spawn"]:
				var kind := str(entry[0])
				if GameData.is_boss(kind) or kind == "courier":
					continue
				if int(entry[1]) >= 2:
					entry[1] = int(entry[1]) + 1
				var vars: Array = (entry[2] as Array).duplicate() if entry.size() > 2 else []
				if vars.size() < 2:
					var v: String = REMIX_VARIANTS[rng.randi_range(0, REMIX_VARIANTS.size() - 1)]
					if not vars.has(v):
						vars.append(v)
				if entry.size() > 2:
					entry[2] = vars
				else:
					entry.append(vars)
	var opts: Array = m.get("optional", [])
	opts.append({"kind": "wake_tier", "value": 5, "text": "Remix: reach Wake tier V"})
	m["optional"] = opts


static func practice() -> Dictionary:
	return {"mode": "practice", "id": "practice", "name": "Sea Trials", "type": "Practice", "label": "SEA TRIALS", "objective": "practice", "flow": "none", "waves": [], "reefs": 5, "hazards": {}, "optional": [], "region": 1, "stage": 0, "difficulty": "standard", "modifier": ""}


static func classic() -> Dictionary:
	return {"mode": "classic", "id": "op:classic", "name": "Classic Run", "type": "Score Attack", "label": "CLASSIC RUN", "objective": "classic", "flow": "classic", "waves": [], "reefs": 7, "hazards": {}, "optional": [], "region": 1, "stage": 0, "difficulty": "standard", "modifier": ""}


static func operation(op: String, difficulty: String, seed_value: int) -> Dictionary:
	if op == "classic":
		return classic()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var def: Dictionary = GameData.OPERATIONS[op]
	var m := {
		"mode": "operation", "id": "op:" + op, "op": op, "name": def["name"], "type": def["type"], "label": "OPERATION",
		"region": 1, "stage": 9, "difficulty": difficulty, "reefs": rng.randi_range(5, 8), "hazards": {},
		"rewards": (def.get("rewards", {}) as Dictionary).duplicate(), "par_time": 240.0, "optional": [],
		"brief": "Harbor Control: " + str(def["desc"]),
		"debrief": "Harbor Control: Operation complete. Good hunting, Captain.",
	}
	var mods: Array = GameData.MODIFIERS.keys()
	var modifier: String = mods[rng.randi_range(0, mods.size() - 1)]
	var roll := rng.randf()
	var reach := Profile.region_unlocked(2) and roll < 0.5
	var belt := Profile.region_unlocked(3) and roll < 0.3
	var trench := Profile.region_unlocked(4) and roll < 0.18
	var expanse := Profile.region_unlocked(5) and roll < 0.1
	var pool: Array = PATROL_POOL
	if expanse:
		m["region"] = 5
		m["stage"] = 5
		pool = PATROL_POOL + PATROL_POOL_2 + PATROL_POOL_3 + PATROL_POOL_4 + PATROL_POOL_5
	elif trench:
		m["region"] = 4
		m["stage"] = 5
		pool = PATROL_POOL + PATROL_POOL_2 + PATROL_POOL_3 + PATROL_POOL_4
	elif belt:
		m["region"] = 3
		m["stage"] = 5
		pool = PATROL_POOL + PATROL_POOL_2 + PATROL_POOL_3
	elif reach:
		m["region"] = 2
		m["stage"] = 5
		pool = PATROL_POOL + PATROL_POOL_2
	match op:
		"patrol_sweep":
			m["objective"] = "destroy_all"
			m["flow"] = "sequential"
			var waves: Array = []
			for i in 3:
				waves.append(pool[rng.randi_range(0, pool.size() - 1)])
			m["waves"] = waves
			m["hazards"] = {"wrecks": 1, "wreck_fields": 1} if reach else {"wrecks": 1}
			m["optional"] = [{"kind": "hull_min", "value": 0.6, "text": "Finish with 60% Hull or more"}]
		"salvage_rush":
			m["objective"] = "salvage"
			m["flow"] = "timeline"
			m["need"] = 5
			m["hazards"] = {"wrecks": 5, "currents": 1}
			m["waves"] = [{"at": 3.0, "spawn": [["gunboat", 3]]}, {"at": 20.0, "spawn": [["gunboat", 2], ["fireship", 1]], "repeat": 22.0, "until": 600.0}]
			m["optional"] = [{"kind": "time_max", "value": 200.0, "text": "Finish within 3:20"}]
		"convoy_breaker":
			m["objective"] = "intercept"
			m["flow"] = "timeline"
			m["couriers"] = 6
			m["need"] = 5
			m["waves"] = [{"at": 2.0, "spawn": [["gunboat", 2], ["frigate", 1]]}, {"at": 30.0, "spawn": [["gunboat", 2], ["rammer", 1]], "repeat": 30.0, "until": 600.0}]
			m["optional"] = [{"kind": "no_escape", "value": 0, "text": "Let no courier escape"}]
		"holdout":
			m["objective"] = "survive"
			m["flow"] = "timeline"
			m["time_limit"] = 240.0
			m["waves"] = [{"at": 2.0, "spawn": [["gunboat", 3]]}, {"at": 20.0, "spawn": [["gunboat", 2], ["fireship", 1]], "repeat": 25.0, "until": 230.0}, {"at": 45.0, "spawn": [["frigate", 1], ["rammer", 1]], "repeat": 35.0, "until": 230.0}]
			m["hazards"] = {"minefields": 1}
			m["optional"] = [{"kind": "hull_min", "value": 0.5, "text": "Finish with 50% Hull or more"}]
		"elite_bounty":
			var names: Array = []
			for nk in GameData.NAMED.keys():
				if bool(GameData.NAMED[nk].get("hunt_only", false)):
					continue
				if int(GameData.NAMED[nk].get("region", 1)) == 1 or Profile.region_unlocked(int(GameData.NAMED[nk].get("region", 1))):
					names.append(nk)
			m["objective"] = "bounty"
			m["flow"] = "timeline"
			m["bounty_id"] = names[rng.randi_range(0, names.size() - 1)]
			m["waves"] = [{"at": 2.0, "spawn": [["gunboat", 2]]}, {"at": 25.0, "spawn": [["gunboat", 2], ["fireship", 1]], "repeat": 30.0, "until": 600.0}]
			m["optional"] = [{"kind": "hull_min", "value": 0.5, "text": "Finish with 50% Hull or more"}]
		"boss_rematch":
			m["objective"] = "boss"
			m["flow"] = "sequential"
			var bosses: Array = ["ironwake"]
			if Profile.stage_cleared("r2s10"):
				bosses.append("kharon")
			if Profile.stage_cleared("r3s10"):
				bosses.append("matriarch")
			if Profile.stage_cleared("r4s10"):
				bosses.append("leviathan")
			if Profile.stage_cleared("r5s10"):
				bosses.append("sovereign")
			var bk: String = bosses[rng.randi_range(0, bosses.size() - 1)]
			m["boss"] = bk
			m["waves"] = [[{"spawn": [[bk, 1]]}]]
			if bk == "kharon":
				m["region"] = 2
				m["optional"] = [{"kind": "time_max", "value": 420.0, "text": "Sink it within 7:00"}]
			elif bk == "sovereign":
				m["region"] = 5
				m["optional"] = [{"kind": "time_max", "value": 540.0, "text": "Sink it within 9:00"}]
			elif bk == "leviathan":
				m["region"] = 4
				m["optional"] = [{"kind": "time_max", "value": 480.0, "text": "Sink it within 8:00"}]
			elif bk == "matriarch":
				m["region"] = 3
				m["optional"] = [{"kind": "time_max", "value": 420.0, "text": "Sink her within 7:00"}]
			else:
				m["region"] = 1
				m["optional"] = [{"kind": "time_max", "value": 300.0, "text": "Sink her within 5:00"}]
			m["stage"] = 10
			m["reefs"] = 4
		"navigation_trial":
			m["objective"] = "checkpoints"
			m["flow"] = "timeline"
			m["checkpoints"] = 8
			m["time_limit"] = 150.0
			m["hazards"] = {"currents": 2, "minefields": 1, "whirlpool": true}
			m["waves"] = [{"at": 25.0, "spawn": [["gunboat", 2]], "repeat": 40.0, "until": 140.0}]
			m["optional"] = [{"kind": "time_max", "value": 100.0, "text": "Finish within 1:40"}, {"kind": "no_reef", "value": 0, "text": "No reef collisions"}]
			modifier = "crosswind" if rng.randf() < 0.5 else ""
		"anomaly":
			m["region"] = 5
			m["stage"] = 8
			m["objective"] = "destroy_all"
			m["flow"] = "sequential"
			var aw: Array = []
			for i in 4:
				aw.append(PATROL_POOL_5[rng.randi_range(0, PATROL_POOL_5.size() - 1)])
			aw.append([{"spawn": [["frigate", 2, ["elite", "resonant"]], ["resonant_carrier", 1], ["ghost_runner", 1, ["resonant"]]]}])
			m["waves"] = aw
			m["hazards"] = {"rifts": 2, "vents": 1, "blooms": 1}
			modifier = "anomaly"
			m["optional"] = [{"kind": "wake_tier", "value": 5, "text": "Reach Wake tier V"}, {"kind": "hull_min", "value": 0.5, "text": "Finish with 50% Hull or more"}]
		"fleet_gauntlet":
			m["objective"] = "destroy_all"
			m["flow"] = "sequential"
			var gw: Array = []
			for i in 5:
				gw.append(pool[rng.randi_range(0, pool.size() - 1)])
			gw.append([{"spawn": [["frigate", 2, ["elite"]], ["rammer", 1, ["veteran"]], ["fireship", 2]]}])
			m["waves"] = gw
			modifier = "no_repairs"
			m["optional"] = [{"kind": "wake_tier", "value": 4, "text": "Reach Wake tier IV"}]
	m["modifier"] = modifier
	return m

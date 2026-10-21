class_name ShipStats
extends RefCounted

const PENALIZED := ["accel", "turn", "max_speed"]

var ship_id := "wayfarer"
var values: Dictionary = {}
var stacks: Dictionary = {}
var flags: Dictionary = {}
var owned: Array = []
var stations: Array = []
var modules: Array = []
var passives: Array = []
var ability := ""
var perk := "a"
var look: Dictionary = {}
var penalty: Dictionary = {"accel": 1.0, "turn": 1.0, "max_speed": 1.0}


static func from_build(id: String, build: Dictionary, perk_choice: String = "a") -> ShipStats:
	var s := ShipStats.new()
	s.setup(id, build, perk_choice)
	return s


func _init() -> void:
	values = GameData.BASE_STATS.duplicate(true)


func setup(id: String, build: Dictionary, perk_choice: String) -> void:
	ship_id = id
	var def: Dictionary = GameData.SHIPS[id]
	values = GameData.BASE_STATS.duplicate(true)
	var st: Dictionary = def.get("stats", {})
	for k in st.keys():
		values[k] = float(st[k])
	look = def.get("look", {})
	ability = str(def.get("ability", ""))
	perk = perk_choice
	var perks: Dictionary = def.get("perks", {})
	if perks.has(perk):
		var pk: Dictionary = perks[perk]
		apply_mods(pk.get("add", {}), pk.get("mul", {}))
		for f in pk.get("flags", []):
			flags[f] = true
	for p in build.get("passives", []):
		if not GameData.PASSIVES.has(p):
			continue
		var pd: Dictionary = GameData.PASSIVES[p]
		apply_mods(pd.get("add", {}), pd.get("mul", {}))
		for f in pd.get("flags", []):
			flags[f] = true
		passives.append(p)
	modules = (build.get("utility", []) as Array).duplicate()
	stations.clear()
	var fitted: Dictionary = build.get("stations", {})
	for sd in def.get("stations", []):
		var slot: String = sd["slot"]
		if str((sd as Dictionary).get("unlock", "")) != "" and not fitted.has(slot):
			continue
		var e: Dictionary = fitted.get(slot, {"w": "roundshot", "m": "1"})
		stations.append({"slot": slot, "barrels": int(sd["barrels"]), "weapon": GameData.weapon_stats(str(e["w"]), str(e["m"]))})
	recompute_load()


func recompute_load() -> void:
	var mass := 0.0
	var power := 0.0
	for st in stations:
		var w: Dictionary = st["weapon"]
		mass += float(w.get("mass", 1.0)) * float(st["barrels"]) / 3.0
		power += float(w.get("power", 0.0))
	for m in modules:
		if GameData.ACTIVE_MODULES.has(m):
			mass += float(GameData.ACTIVE_MODULES[m]["mass"])
			power += float(GameData.ACTIVE_MODULES[m]["power"])
	for p in passives:
		mass += float(GameData.PASSIVES[p].get("mass", 0.0))
	values["mass_used"] = mass
	values["power_used"] = power
	var excess := maxf(0.0, mass - float(values["mass_rating"]))
	penalty = {
		"accel": maxf(0.6, 1.0 - 0.05 * excess),
		"turn": maxf(0.6, 1.0 - 0.04 * excess),
		"max_speed": maxf(0.75, 1.0 - 0.02 * excess),
	}


func get_value(key: String) -> float:
	var v := float(values.get(key, 0.0))
	if penalty.has(key):
		v *= float(penalty[key])
	return v


func raw_value(key: String) -> float:
	return float(values.get(key, 0.0))


func stack_count(id: String) -> int:
	return int(stacks.get(id, 0))


func has_flag(f: String) -> bool:
	return bool(flags.get(f, false))


func can_take(up: Dictionary) -> bool:
	return stack_count(up["id"]) < int(up["max"])


func apply_mods(add: Dictionary, mul: Dictionary) -> void:
	for key in add.keys():
		values[key] = float(values.get(key, 0.0)) + float(add[key])
	for key in mul.keys():
		values[key] = float(values.get(key, 0.0)) * float(mul[key])


func apply(up: Dictionary) -> void:
	stacks[up["id"]] = stack_count(up["id"]) + 1
	owned.append(up["name"])
	apply_mods(up.get("add", {}), up.get("mul", {}))
	for f in up.get("flags", []):
		flags[f] = true


func clone() -> ShipStats:
	var s := ShipStats.new()
	s.ship_id = ship_id
	s.values = values.duplicate(true)
	s.stacks = stacks.duplicate(true)
	s.flags = flags.duplicate(true)
	s.owned = owned.duplicate()
	s.stations = stations.duplicate(true)
	s.modules = modules.duplicate()
	s.passives = passives.duplicate()
	s.ability = ability
	s.perk = perk
	s.look = look
	s.penalty = penalty.duplicate()
	return s


func station(slot: String) -> Dictionary:
	for st in stations:
		if st["slot"] == slot:
			return st
	return {}


func profile(st: Dictionary) -> Dictionary:
	var w: Dictionary = (st["weapon"] as Dictionary).duplicate()
	w["barrels"] = int(st["barrels"]) + int(get_value("extra_barrels"))
	w["damage"] = float(w.get("damage", 0.0)) * get_value("damage_mult")
	w["reload"] = float(w.get("reload", 1.5)) * get_value("reload_mult")
	w["range"] = float(w.get("range", 500.0)) * get_value("range_mult")
	w["speed"] = float(w.get("speed", 600.0)) * get_value("shot_speed_mult")
	w["spread"] = float(w.get("spread", 0.0)) * get_value("spread_mult")
	w["recoil"] = float(w.get("recoil", 0.0)) * get_value("recoil_mult")
	return w


func shots_per_volley(w: Dictionary) -> int:
	var b: int = int(w["barrels"])
	match str(w.get("pattern", "volley")):
		"pellets":
			return b * int(w.get("pellets", 3))
		"heavy":
			return maxi(1, int(ceil(float(b) / 2.0)))
		"single":
			return 1
		"arc":
			return 1 + int(w.get("jumps", 0))
		"mortar":
			return maxi(1, int(ceil(float(b) / 2.0))) * maxi(1, int(w.get("cluster", 1)))
	return b


func dps(st: Dictionary) -> float:
	var w := profile(st)
	return float(w["damage"]) * float(shots_per_volley(w)) / maxf(0.1, float(w["reload"]))


func validate() -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	if get_value("power_used") > get_value("power_cap") + 0.001:
		errors.append("Power over capacity (%.1f / %.1f). Remove energy weapons or modules." % [get_value("power_used"), get_value("power_cap")])
	var excess := get_value("mass_used") - get_value("mass_rating")
	if excess > 0.001:
		warnings.append("Overweight by %.1f: acceleration -%d%%, turning -%d%%." % [excess, int(round((1.0 - float(penalty["accel"])) * 100.0)), int(round((1.0 - float(penalty["turn"])) * 100.0))])
	var port := station("port")
	var stbd := station("starboard")
	if not port.is_empty() and not stbd.is_empty():
		var a := dps(port)
		var b := dps(stbd)
		if minf(a, b) > 0.0 and maxf(a, b) / minf(a, b) > 2.5:
			warnings.append("Asymmetric broadsides: one side deals %.1fx the damage of the other." % (maxf(a, b) / minf(a, b)))
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


func compare(up: Dictionary) -> Array:
	var after := clone()
	after.apply(up)
	var lines: Array = []
	for entry in GameData.STAT_LABELS:
		var key: String = entry[0]
		var a := get_value(key)
		var b := after.get_value(key)
		if absf(a - b) > 0.0001:
			lines.append("%s  %s -> %s" % [entry[1], GameData.format_stat(entry[2], a), GameData.format_stat(entry[2], b)])
	return lines


func summary_lines() -> Array:
	var keys := ["max_hull", "max_speed", "accel", "turn", "lateral", "reload_mult", "range_mult", "mass_rating", "power_cap"]
	var lines: Array = []
	for entry in GameData.STAT_LABELS:
		if entry[0] in keys:
			lines.append([entry[1], GameData.format_stat(entry[2], get_value(entry[0]))])
	return lines

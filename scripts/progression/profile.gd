extends Node


func d() -> Dictionary:
	return SaveData.data


func res(kind: String) -> int:
	return int(d()["resources"].get(kind, 0))


func add_res(kind: String, amount: int) -> void:
	d()["resources"][kind] = maxi(0, res(kind) + amount)


func can_afford(cost: Dictionary) -> bool:
	for k in cost.keys():
		if res(k) < int(cost[k]):
			return false
	return true


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for k in cost.keys():
		add_res(k, -int(cost[k]))
	SaveData.save()
	return true


func add_rewards(rew: Dictionary) -> void:
	for k in ["salvage", "research", "intel"]:
		if rew.has(k):
			add_res(k, int(rew[k]))


func cleared() -> Dictionary:
	return d()["campaign"]["cleared"]


func stage_cleared(id: String, tier: String = "") -> bool:
	if not cleared().has(id):
		return false
	if tier == "":
		return true
	return (cleared()[id] as Dictionary).has(tier)


func stage_unlocked(id: String) -> bool:
	var m: Dictionary = GameData.mission(id)
	if m.is_empty():
		return false
	var list: Array = GameData.REGION_STAGES.get(int(m["region"]), [])
	var idx := list.find(id)
	if idx <= 0:
		return region_unlocked(int(m["region"]))
	return stage_cleared(list[idx - 1])


func region_unlocked(n: int) -> bool:
	var r: Dictionary = GameData.region(n)
	if not bool(r["available"]):
		return false
	if n == 1:
		return true
	var prev: Array = GameData.REGION_STAGES.get(n - 1, [])
	return not prev.is_empty() and stage_cleared(prev[prev.size() - 1])


func best_grade(id: String) -> String:
	if not cleared().has(id):
		return ""
	var best := ""
	for tier in (cleared()[id] as Dictionary).keys():
		var g: String = cleared()[id][tier]
		if best == "" or GameData.GRADE_ORDER.find(g) > GameData.GRADE_ORDER.find(best):
			best = g
	return best


func optional_done(id: String, idx: int) -> bool:
	var o: Dictionary = d()["campaign"]["optional"].get(id, {})
	return bool(o.get(str(idx), false))


func cleared_count() -> int:
	return cleared().size()


func req_met(req: Dictionary) -> bool:
	if req.has("stage") and str(req["stage"]) != "" and not stage_cleared(str(req["stage"]), str(req.get("tier", ""))):
		return false
	if req.has("facility") and not has_facility(str(req["facility"])):
		return false
	if req.has("research") and not (d()["research"] as Array).has(req["research"]):
		return false
	if req.has("region") and not region_unlocked(int(req["region"])):
		return false
	if req.has("ship") and not ship_unlocked(str(req["ship"])):
		return false
	return true


func req_text(req: Dictionary) -> String:
	var parts: PackedStringArray = []
	if req.has("stage") and str(req["stage"]) != "":
		var t := "Clear stage %s %s" % [GameData.stage_label(str(req["stage"])), GameData.mission(str(req["stage"])).get("name", "")]
		if req.has("tier"):
			t += " on %s" % GameData.DIFFICULTIES[req["tier"]]["name"]
		parts.append(t)
	if req.has("facility"):
		parts.append("Build the %s" % GameData.FACILITIES[req["facility"]]["name"])
	if req.has("research"):
		parts.append("Research %s" % research_name(str(req["research"])))
	if req.has("region"):
		parts.append("Reach Region %s" % ["", "I", "II", "III", "IV", "V"][clampi(int(req["region"]), 0, 5)])
	if req.has("ship"):
		parts.append("Unlock the %s" % GameData.SHIPS[req["ship"]]["name"])
	return ", ".join(parts)


func ship_unlocked(id: String) -> bool:
	return (d()["ships"] as Array).has(id)


func ship_status(id: String) -> Dictionary:
	var s: Dictionary = GameData.SHIPS[id]
	if not bool(s.get("available", false)):
		return {"state": "future", "text": "Arrives with Region %s" % ["", "I", "II", "III", "IV", "V"][int(s["region"])]}
	if ship_unlocked(id):
		return {"state": "owned", "text": "In your fleet"}
	var u: Dictionary = s["unlock"]
	var req := {"stage": u["stage"]}
	if not req_met(req):
		return {"state": "locked", "text": req_text(req)}
	return {"state": "buyable", "text": "Blueprint ready: %s" % GameData.cost_text(u["cost"]), "cost": u["cost"]}


func unlock_ship(id: String) -> bool:
	var st := ship_status(id)
	if st["state"] != "buyable":
		return false
	if not spend(st["cost"]):
		return false
	d()["ships"].append(id)
	SaveData.save()
	return true


func selected_ship() -> String:
	var s: String = str(d()["selected"].get("ship", "wayfarer"))
	if not ship_unlocked(s):
		s = "wayfarer"
	return s


func select_ship(id: String) -> void:
	if ship_unlocked(id):
		d()["selected"]["ship"] = id
		SaveData.save()


func perk(ship: String) -> String:
	var p: String = str(d()["perks"].get(ship, "a"))
	if p == "b" and mastery_level(ship) < 5:
		return "a"
	return p


func set_perk(ship: String, p: String) -> void:
	if p == "b" and mastery_level(ship) < 5:
		return
	d()["perks"][ship] = p
	SaveData.save()


func mastery_xp(ship: String) -> int:
	return int(d()["mastery"].get(ship, 0))


func mastery_level(ship: String) -> int:
	var xp := mastery_xp(ship)
	var lvl := 1
	for i in GameData.MASTERY_XP.size():
		if xp >= int(GameData.MASTERY_XP[i]):
			lvl = i + 1
	return mini(lvl, 10)


func mastery_progress(ship: String) -> Array:
	var lvl := mastery_level(ship)
	if lvl >= 10:
		return [1.0, mastery_xp(ship), int(GameData.MASTERY_XP[9])]
	var cur := int(GameData.MASTERY_XP[lvl - 1])
	var nxt := int(GameData.MASTERY_XP[lvl])
	return [clampf(float(mastery_xp(ship) - cur) / float(nxt - cur), 0.0, 1.0), mastery_xp(ship), nxt]


func add_xp(ship: String, xp: int) -> Array:
	var before := mastery_level(ship)
	d()["mastery"][ship] = mastery_xp(ship) + xp
	var after := mastery_level(ship)
	var gained: Array = []
	for l in range(before + 1, after + 1):
		gained.append(l)
	return gained


func build_slots(ship: String) -> int:
	var lvl := mastery_level(ship)
	return 3 + (1 if lvl >= 4 else 0) + (1 if lvl >= 8 else 0)


func has_item(cat: String, id: String) -> bool:
	if not (d()["items"] as Dictionary).has(cat):
		d()["items"][cat] = []
	return (d()["items"][cat] as Array).has(id)


func owned_weapon_keys(slot: String) -> Array:
	var out: Array = []
	for key in d()["items"]["weapons"]:
		var parts: Array = GameData.split_key(str(key))
		if GameData.mount_ok(parts[0], slot):
			out.append(key)
	out.sort_custom(func(a, b) -> bool:
		var pa: Array = GameData.split_key(str(a))
		var pb: Array = GameData.split_key(str(b))
		var ia: int = GameData.WEAPON_ORDER.find(pa[0])
		var ib: int = GameData.WEAPON_ORDER.find(pb[0])
		if ia != ib:
			return ia < ib
		return str(pa[1]) < str(pb[1])
	)
	return out


func research_name(rid: String) -> String:
	if not GameData.RESEARCH.has(rid):
		return rid
	var r: Dictionary = GameData.RESEARCH[rid]
	match str(r["grant"]):
		"weapons":
			var parts: Array = GameData.split_key(str(r["id"]))
			return GameData.weapon_label(parts[0], parts[1])
		"modules":
			return str(GameData.ACTIVE_MODULES[r["id"]]["name"])
		"passives":
			return str(GameData.PASSIVES[r["id"]]["name"])
		"upgrades":
			return "Turret Ring"
	return rid


func research_desc(rid: String) -> String:
	var r: Dictionary = GameData.RESEARCH[rid]
	match str(r["grant"]):
		"weapons":
			var parts: Array = GameData.split_key(str(r["id"]))
			var w: Dictionary = GameData.WEAPONS[parts[0]]
			if parts[1] != "1":
				return str(w["marks"][parts[1]].get("desc", ""))
			return "%s. %s Limitation: %s." % [w["role"], w["desc"], w["limit"]]
		"modules":
			return str(GameData.ACTIVE_MODULES[r["id"]]["desc"])
		"passives":
			return str(GameData.PASSIVES[r["id"]]["desc"])
		"upgrades":
			return "Adds a turret mount to the Wayfarer, Bulwark, Corsair and Longshot. The turret tracks the nearest enemy in a wide forward arc and fires on its own key."
	return ""


func research_status(rid: String) -> Dictionary:
	var r: Dictionary = GameData.RESEARCH[rid]
	if (d()["research"] as Array).has(rid) or has_item(r["grant"], r["id"]):
		return {"state": "done", "text": "Researched"}
	if not req_met(r["req"]):
		return {"state": "locked", "text": req_text(r["req"])}
	if not can_afford(r["cost"]):
		return {"state": "short", "text": GameData.cost_text(r["cost"])}
	return {"state": "ready", "text": GameData.cost_text(r["cost"])}


func do_research(rid: String) -> bool:
	var st := research_status(rid)
	if st["state"] != "ready":
		return false
	var r: Dictionary = GameData.RESEARCH[rid]
	if not spend(r["cost"]):
		return false
	d()["research"].append(rid)
	var cat: String = r["grant"]
	if not has_item(cat, r["id"]):
		d()["items"][cat].append(r["id"])
	SaveData.save()
	return true


func has_facility(id: String) -> bool:
	return (d()["facilities"] as Array).has(id)


func build_facility(id: String) -> bool:
	if has_facility(id):
		return false
	if not spend(GameData.FACILITIES[id]["cost"]):
		return false
	d()["facilities"].append(id)
	refill_contracts()
	SaveData.save()
	return true


func exchange(direction: String) -> bool:
	if not has_facility("salvage_exchange"):
		return false
	var rate: Array = GameData.EXCHANGE[direction]
	var cost := {"salvage": int(rate[0])} if direction == "salvage_for_research" else {"research": int(rate[0])}
	if not spend(cost):
		return false
	if direction == "salvage_for_research":
		add_res("research", int(rate[1]))
	else:
		add_res("salvage", int(rate[1]))
	SaveData.save()
	return true


func ship_stations(ship: String) -> Array:
	var out: Array = []
	for st in GameData.SHIPS[ship].get("stations", []):
		var need: String = str((st as Dictionary).get("unlock", ""))
		if need == "" or has_item("upgrades", need):
			out.append(st)
	return out


func default_build(ship: String) -> Dictionary:
	var s: Dictionary = GameData.SHIPS[ship]
	var def: Dictionary = s.get("default", {})
	var b := {"name": "Standard", "stations": {}, "utility": [], "passives": []}
	for st in ship_stations(ship):
		var slot: String = st["slot"]
		var pick: Array = def.get(slot, ["roundshot", "1"])
		b["stations"][slot] = {"w": pick[0], "m": pick[1]}
	b["utility"] = (def.get("utility", []) as Array).duplicate()
	b["passives"] = (def.get("passives", []) as Array).duplicate()
	return b


func builds(ship: String) -> Array:
	var all: Dictionary = d()["builds"]
	if not all.has(ship) or (all[ship] as Array).is_empty():
		all[ship] = [default_build(ship)]
	return all[ship]


func active_build_index(ship: String) -> int:
	var idx := int(d()["active_build"].get(ship, 0))
	return clampi(idx, 0, builds(ship).size() - 1)


func set_active_build(ship: String, idx: int) -> void:
	d()["active_build"][ship] = clampi(idx, 0, builds(ship).size() - 1)
	SaveData.save()


func active_build(ship: String) -> Dictionary:
	return sanitize_build(ship, builds(ship)[active_build_index(ship)])


func save_build(ship: String, idx: int, build: Dictionary) -> void:
	var list := builds(ship)
	var clean := sanitize_build(ship, build)
	if idx >= 0 and idx < list.size():
		list[idx] = clean
	elif list.size() < build_slots(ship):
		list.append(clean)
	SaveData.save()


func delete_build(ship: String, idx: int) -> void:
	var list := builds(ship)
	if list.size() <= 1 or idx < 0 or idx >= list.size():
		return
	list.remove_at(idx)
	d()["active_build"][ship] = 0
	SaveData.save()


func sanitize_build(ship: String, build: Dictionary) -> Dictionary:
	var s: Dictionary = GameData.SHIPS[ship]
	var out := {"name": str(build.get("name", "Build")), "stations": {}, "utility": [], "passives": []}
	var stations: Dictionary = build.get("stations", {})
	var fallback := default_build(ship)
	for st in ship_stations(ship):
		var slot: String = st["slot"]
		var e: Dictionary = stations.get(slot, fallback["stations"][slot])
		var key := "%s:%s" % [e.get("w", "roundshot"), e.get("m", "1")]
		if not has_item("weapons", key) or not GameData.mount_ok(str(e.get("w", "")), slot):
			e = {"w": "roundshot", "m": "1"}
			if not GameData.mount_ok("roundshot", slot):
				e = fallback["stations"][slot]
		out["stations"][slot] = {"w": str(e["w"]), "m": str(e["m"])}
	var util_n: int = int(s.get("utility", 1))
	for u in build.get("utility", []):
		if (out["utility"] as Array).size() < util_n and has_item("modules", str(u)) and not (out["utility"] as Array).has(u):
			out["utility"].append(str(u))
	var pas_n: int = int(s.get("passive_slots", 2)) + (1 if stage_cleared("r1s10") else 0)
	var spec_used := false
	for p in build.get("passives", []):
		if (out["passives"] as Array).size() >= pas_n or not has_item("passives", str(p)) or (out["passives"] as Array).has(p):
			continue
		var excl: String = str(GameData.PASSIVES[p].get("exclusive", ""))
		if excl == "wake_spec":
			if spec_used:
				continue
			spec_used = true
		out["passives"].append(str(p))
	return out


func passive_slots(ship: String) -> int:
	return int(GameData.SHIPS[ship].get("passive_slots", 2)) + (1 if stage_cleared("r1s10") else 0)


func remix_unlocked() -> bool:
	return stage_cleared("r5s10")


func remix_active() -> bool:
	return remix_unlocked() and bool(d()["selected"].get("remix", false))


func set_remix(on: bool) -> void:
	d()["selected"]["remix"] = on and remix_unlocked()
	SaveData.save()


func remix_clears() -> int:
	var n := 0
	for k in cleared().keys():
		if (cleared()[k] as Dictionary).has("remix"):
			n += 1
	return n


func difficulty_unlocked(tier: String) -> bool:
	return req_met(GameData.DIFFICULTIES[tier]["unlock"])


func selected_difficulty() -> String:
	var t: String = str(d()["selected"].get("difficulty", "standard"))
	if not difficulty_unlocked(t):
		t = "standard"
	return t


func set_difficulty(t: String) -> void:
	if difficulty_unlocked(t):
		d()["selected"]["difficulty"] = t
		SaveData.save()


func discover(cat: String, id: String) -> bool:
	var codex: Dictionary = d()["codex"]
	if not codex.has(cat):
		codex[cat] = {}
	if (codex[cat] as Dictionary).has(id):
		return false
	codex[cat][id] = true
	return true


func known(cat: String, id: String) -> bool:
	return (d()["codex"].get(cat, {}) as Dictionary).has(id)


func contract_slots() -> int:
	return 3 if has_facility("navigation_room") else 2


func _contract_def(id: String) -> Dictionary:
	for c in GameData.CONTRACTS:
		if c["id"] == id:
			return c
	return {}


func refill_contracts() -> void:
	var cs: Dictionary = d()["contracts"]
	var active: Array = cs["active"]
	var guard := 0
	while active.size() < contract_slots() and guard < GameData.CONTRACTS.size() * 2:
		guard += 1
		var cursor: int = int(cs["cursor"]) % GameData.CONTRACTS.size()
		cs["cursor"] = cursor + 1
		var c: Dictionary = GameData.CONTRACTS[cursor]
		var taken := false
		for a in active:
			if a["id"] == c["id"]:
				taken = true
		if taken or not req_met(c.get("req", {})):
			continue
		active.append({"id": c["id"], "progress": 0})


func active_contracts() -> Array:
	refill_contracts()
	var out: Array = []
	for a in d()["contracts"]["active"]:
		var def := _contract_def(str(a["id"]))
		if not def.is_empty():
			out.append({"id": a["id"], "progress": int(a["progress"]), "def": def})
	return out


func track(event: String, key: String = "", amount: int = 1) -> void:
	for a in d()["contracts"]["active"]:
		var def := _contract_def(str(a["id"]))
		if def.is_empty() or def["event"] != event:
			continue
		var dk: String = def["key"]
		if dk != "" and dk != "*" and dk != key:
			continue
		if bool(def.get("max", false)):
			a["progress"] = maxi(int(a["progress"]), amount)
		else:
			a["progress"] = mini(int(def["target"]), int(a["progress"]) + amount)


func claim_contract(id: String) -> bool:
	var active: Array = d()["contracts"]["active"]
	for i in active.size():
		var a: Dictionary = active[i]
		if a["id"] != id:
			continue
		var def := _contract_def(id)
		if int(a["progress"]) < int(def["target"]):
			return false
		add_rewards(def["reward"])
		active.remove_at(i)
		d()["contracts"]["done"] = int(d()["contracts"]["done"]) + 1
		refill_contracts()
		SaveData.save()
		return true
	return false


func record_mission(result: Dictionary) -> Dictionary:
	var out := {"salvage": 0, "research": 0, "intel": 0, "xp": 0, "levels": [], "notes": [], "first_clear": false}
	var mode: String = result.get("mode", "campaign")
	if mode == "practice":
		return out
	var ship: String = result.get("ship", "wayfarer")
	var success := bool(result.get("success", false))
	var grade: String = result.get("grade", "D")
	var tier: String = result.get("difficulty", "standard")
	var tier_mult: float = float(GameData.DIFFICULTIES[tier]["reward"])
	var mod_mult: float = float(result.get("modifier_reward", 1.0))
	var collected: int = int(result.get("salvage_collected", 0))
	var r: Dictionary = d()["records"]
	r["missions"] = int(r["missions"]) + 1
	r["kills"] = int(r["kills"]) + int(result.get("kills", 0))
	r["boss_kills"] = int(r["boss_kills"]) + int(result.get("bosses", 0))
	var base: Dictionary = result.get("rewards", {})
	var remix := bool(result.get("remix", false))
	if success:
		r["missions_won"] = int(r["missions_won"]) + 1
		var mid: String = result.get("mission_id", "")
		var first := mode == "campaign" and not stage_cleared(mid, "remix" if remix else "")
		out["first_clear"] = first
		var sal := float(base.get("salvage", 0))
		var rsch := float(base.get("research", 0))
		var intel := int(base.get("intel", 0))
		if mode == "campaign" and not first:
			sal *= 0.6
			rsch *= 0.5
			intel = 0
		sal = sal * float(GameData.GRADE_SALVAGE.get(grade, 1.0)) * tier_mult * mod_mult + float(collected)
		out["salvage"] = int(round(sal))
		out["research"] = int(round(rsch * tier_mult)) + int(result.get("research_found", 0))
		out["intel"] = intel
		if mode == "campaign":
			_record_stage(mid, "remix" if remix else tier, grade, result, out)
		for k in (result.get("bounty", {}) as Dictionary).keys():
			out[k] = int(out[k]) + int(result["bounty"][k])
		track("mission_ship", ship, 1)
		if GameData.GRADE_ORDER.find(grade) >= 3:
			track("grade_a", "", 1)
	else:
		out["salvage"] = int(round(float(collected) * 0.5))
		out["research"] = int(result.get("research_found", 0))
	track("salvage", "", int(out["salvage"]))
	track("wake_tier", "", int(result.get("max_tier", 0)))
	add_rewards(out)
	var xp := 20 + int(result.get("kills", 0)) * 2 + int(result.get("max_tier", 0)) * 8
	if success:
		xp += 60 + int(GameData.GRADE_XP.get(grade, 0))
	out["xp"] = xp
	out["levels"] = add_xp(ship, xp)
	for l in out["levels"]:
		if GameData.MASTERY_UNLOCKS.has(l):
			(out["notes"] as Array).append("%s mastery %d: %s" % [GameData.SHIPS[ship]["name"], l, GameData.MASTERY_UNLOCKS[l]])
	if int(result.get("max_tier", 0)) >= 5 and not bool(d()["unlocks"]["ember"]):
		d()["unlocks"]["ember"] = true
		(out["notes"] as Array).append("Unlocked wake: Ember Tide")
	SaveData.save()
	return out


func _record_stage(mid: String, tier: String, grade: String, result: Dictionary, out: Dictionary) -> void:
	var notes: Array = out["notes"]
	var was_cleared := stage_cleared(mid)
	var before_ships: Array = []
	for sid in GameData.SHIP_ORDER:
		before_ships.append(ship_status(sid)["state"])
	var before_tiers: Array = []
	for t in GameData.DIFFICULTY_ORDER:
		before_tiers.append(difficulty_unlocked(t))
	if not cleared().has(mid):
		cleared()[mid] = {}
	var prev: String = str(cleared()[mid].get(tier, ""))
	if prev == "" or GameData.GRADE_ORDER.find(grade) > GameData.GRADE_ORDER.find(prev):
		cleared()[mid][tier] = grade
	if tier == "remix" and prev == "":
		notes.append("Remix cleared: %d / 50 stages" % remix_clears())
		if remix_clears() >= 10 and not bool(d()["unlocks"].get("prism", false)):
			d()["unlocks"]["prism"] = true
			notes.append("Unlocked wake: Prism")
	var opts: Dictionary = d()["campaign"]["optional"]
	if not opts.has(mid):
		opts[mid] = {}
	var results: Array = result.get("optional_results", [])
	for i in results.size():
		if bool(results[i]) and not bool(opts[mid].get(str(i), false)):
			opts[mid][str(i)] = true
			out["research"] = int(out["research"]) + 3
			notes.append("Optional objective complete: +3 Research")
	var best: Dictionary = d()["campaign"]["best"]
	var rec: Dictionary = best.get(mid, {})
	if float(rec.get("time", 99999.0)) > float(result.get("time", 0.0)):
		rec["time"] = float(result.get("time", 0.0))
	rec["score"] = maxi(int(rec.get("score", 0)), int(result.get("score", 0)))
	best[mid] = rec
	var m: Dictionary = GameData.mission(mid)
	if not was_cleared:
		var nxt := GameData.next_stage(mid)
		if nxt != "":
			if int(GameData.mission(nxt)["region"]) != int(m["region"]):
				var nr: Dictionary = GameData.region(int(GameData.mission(nxt)["region"]))
				notes.append("Region %s open: %s" % [["", "I", "II", "III", "IV", "V"][int(nr["id"])], nr["name"]])
			notes.append("Stage %s unlocked: %s" % [GameData.stage_label(nxt), GameData.mission(nxt)["name"]])
		if m.has("lore") and discover("lore", str(m["lore"])):
			notes.append("Lore recovered: %s" % GameData.LORE[m["lore"]]["title"])
		if mid == "r1s10":
			d()["unlocks"]["aurora"] = true
			notes.append("Unlocked wake: Aurora")
			notes.append("+1 passive slot on every ship")
			notes.append("Operations board expanded")
		if mid == "r2s10":
			d()["unlocks"]["rustfire"] = true
			notes.append("Unlocked wake: Rustfire")
			notes.append("Heavy weapon research: Mk III torpedoes and mortars")
			notes.append("Boss Rematch can now face Dreadnought Kharon")
		if mid == "r3s10":
			d()["unlocks"]["stormglass"] = true
			notes.append("Unlocked wake: Stormglass")
			notes.append("Advanced sail and rudder systems: Vane Rudder, Storm Rigging")
			notes.append("Boss Rematch can now face the Storm Matriarch")
		if mid == "r5s10":
			d()["unlocks"]["sovereign"] = true
			notes.append("CAMPAIGN COMPLETE - the sea is quiet again")
			notes.append("New Game+ Remix unlocked: replay any stage with remixed fleets and x1.5 rewards")
			notes.append("Anomaly Operations unlocked")
			notes.append("Unlocked wake: Sovereign")
			notes.append("Boss Rematch can now face the Resonant Sovereign")
		if mid == "r4s10":
			d()["unlocks"]["abyssal"] = true
			notes.append("Unlocked wake: Abyssal Glow")
			notes.append("Advanced utility modules: Depth Charges, Overdrive")
			notes.append("Boss Rematch can now face the Leviathan Engine")
	if not was_cleared:
		for tid in GameData.TAB_UNLOCK.keys():
			if str(GameData.TAB_UNLOCK[tid]) == mid:
				notes.append("New in the Harbor: %s - %s" % [GameData.TAB_HELP[tid][0], GameData.TAB_HELP[tid][1]])
	for i in GameData.SHIP_ORDER.size():
		var sid: String = GameData.SHIP_ORDER[i]
		if before_ships[i] == "locked" and ship_status(sid)["state"] == "buyable":
			notes.append("New ship blueprint: %s" % GameData.SHIPS[sid]["name"])
	for i in GameData.DIFFICULTY_ORDER.size():
		var t: String = GameData.DIFFICULTY_ORDER[i]
		if not bool(before_tiers[i]) and difficulty_unlocked(t):
			notes.append("Difficulty unlocked: %s" % GameData.DIFFICULTIES[t]["name"])
	for rid in GameData.RESEARCH_ORDER:
		var req: Dictionary = GameData.RESEARCH[rid]["req"]
		if req.get("stage", "") == mid and not was_cleared:
			notes.append("Research available: %s" % research_name(rid))


func tab_unlocked(id: String) -> bool:
	var req: String = str(GameData.TAB_UNLOCK.get(id, ""))
	return req == "" or stage_cleared(req)


func help_seen(key: String) -> bool:
	return bool((d()["help"] as Dictionary).get(key, false))


func mark_help(key: String) -> void:
	if help_seen(key):
		return
	d()["help"][key] = true
	SaveData.save()


func next_stage() -> String:
	for id in GameData.all_stages():
		if stage_unlocked(id) and not stage_cleared(id):
			return id
	return ""


func op_unlocked(id: String) -> bool:
	return req_met(GameData.OPERATIONS[id].get("unlock", {}))

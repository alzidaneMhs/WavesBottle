class_name FleetTab
extends HBoxContainer

var harbor


func build() -> void:
	add_theme_constant_override("separation", 16)
	if harbor.fleet_selected == "":
		harbor.fleet_selected = Profile.selected_ship()
	var list := UiKit.vbox(6)
	list.custom_minimum_size = Vector2(300, 0)
	add_child(list)
	list.add_child(UiKit.label("FLEET", 18, UiKit.ACCENT))
	for id in GameData.SHIP_ORDER:
		var st := Profile.ship_status(id)
		var s: Dictionary = GameData.SHIPS[id]
		var tag := ""
		match str(st["state"]):
			"owned":
				tag = "  (active)" if Profile.selected_ship() == id else ""
			"buyable":
				tag = "  [blueprint]"
			"locked":
				tag = "  [locked]"
			"future":
				tag = "  [Region %s]" % ["", "I", "II", "III", "IV", "V"][int(s["region"])]
		var b := UiKit.button(str(s["name"]) + tag, _pick.bind(id), 300)
		b.toggle_mode = true
		b.set_pressed_no_signal(id == harbor.fleet_selected)
		if st["state"] == "future":
			b.modulate = Color(1, 1, 1, 0.55)
		list.add_child(b)
	add_child(_detail(harbor.fleet_selected))


func _detail(id: String) -> Control:
	var s: Dictionary = GameData.SHIPS[id]
	var st := Profile.ship_status(id)
	var v := UiKit.vbox(10)
	v.custom_minimum_size = Vector2(920, 0)
	var head := UiKit.card(s["look"]["accent"])
	v.add_child(head)
	var hv := UiKit.vbox(6)
	head.add_child(hv)
	hv.add_child(UiKit.label(str(s["class"]).to_upper(), 14, UiKit.DIM))
	hv.add_child(UiKit.label(str(s["name"]), 34, s["look"]["accent"]))
	hv.add_child(UiKit.wrap(str(s["desc"]), 16, UiKit.TEXT, 880))
	hv.add_child(UiKit.wrap("Unique mechanic: " + str(s["mechanic"]), 16, UiKit.GOLD, 880))
	var sw := UiKit.hbox(24)
	hv.add_child(sw)
	sw.add_child(UiKit.label("Strength: %s" % s["strength"], 15, Color(0.5, 1.0, 0.7)))
	sw.add_child(UiKit.label("Weakness: %s" % s["weakness"], 15, Color(1.0, 0.6, 0.5)))
	if st["state"] == "future":
		v.add_child(UiKit.wrap("This hull is still on the drawing board. It joins the fleet when Region %s opens in a future update." % ["", "I", "II", "III", "IV", "V"][int(s["region"])], 16, UiKit.DIM, 880))
		return v
	var row := UiKit.hbox(16)
	v.add_child(row)
	var stats_card := UiKit.card()
	stats_card.custom_minimum_size = Vector2(440, 0)
	row.add_child(stats_card)
	var sv := UiKit.vbox(4)
	stats_card.add_child(sv)
	sv.add_child(UiKit.label("BASE STATS", 15, UiKit.ACCENT))
	var stt: Dictionary = s["stats"]
	var lines := [
		["Hull", str(int(stt["max_hull"]))],
		["Top speed / Acceleration", "%d / %d" % [int(stt["max_speed"]), int(stt["accel"])]],
		["Turn rate", "%.2f" % float(stt["turn"])],
		["Lateral grip / drift", "%.1f / %.1f" % [float(stt["lateral"]), float(stt["drift_lateral"])]],
		["Power capacity", "%.0f" % float(stt["power_cap"])],
		["Mass rating", "%.0f" % float(stt["mass_rating"])],
		["Utility / passive slots", "%d / %d" % [int(s["utility"]), Profile.passive_slots(id)]],
	]
	var stations: PackedStringArray = []
	for sd in s["stations"]:
		var locked := str((sd as Dictionary).get("unlock", "")) != "" and not Profile.has_item("upgrades", str(sd["unlock"]))
		stations.append("%s x%d%s" % [GameData.SLOT_LABELS[sd["slot"]], int(sd["barrels"]), " (Turret Ring)" if locked else ""])
	lines.append(["Weapon stations", ", ".join(stations)])
	for l in lines:
		var h := HBoxContainer.new()
		var a := UiKit.label(str(l[0]), 15, UiKit.DIM)
		a.custom_minimum_size = Vector2(200, 0)
		h.add_child(a)
		h.add_child(UiKit.wrap(str(l[1]), 15, UiKit.TEXT, 210))
		sv.add_child(h)
	var ab: Dictionary = GameData.ABILITIES[s["ability"]]
	sv.add_child(UiKit.spacer(4))
	sv.add_child(UiKit.label("ABILITY: %s" % ab["name"], 15, UiKit.GOLD))
	sv.add_child(UiKit.wrap(str(ab["desc"]), 14, UiKit.TEXT, 400))
	var right := UiKit.vbox(10)
	row.add_child(right)
	if st["state"] == "owned":
		right.add_child(_mastery(id))
	var actions := UiKit.card()
	right.add_child(actions)
	var av := UiKit.vbox(8)
	actions.add_child(av)
	match str(st["state"]):
		"owned":
			var active := Profile.selected_ship() == id
			var sel := UiKit.button("Active ship" if active else "Set as active ship", _select.bind(id), 420)
			sel.disabled = active
			av.add_child(sel)
			av.add_child(UiKit.button("Open Fitting Dock", _fit.bind(id), 420))
		"buyable":
			av.add_child(UiKit.label(str(st["text"]), 15, UiKit.GOLD))
			var buy := UiKit.button("Build this ship", _buy.bind(id), 420)
			buy.disabled = not Profile.can_afford(st["cost"])
			av.add_child(buy)
		"locked":
			av.add_child(UiKit.wrap("Blueprint locked: " + str(st["text"]), 15, UiKit.DIM, 420))
	av.add_child(UiKit.button("Test drive in Sea Trials", _test.bind(id), 420))
	v.add_child(_palettes())
	if Profile.has_facility("fleet_registry"):
		v.add_child(_registry())
	return v


func _mastery(id: String) -> Control:
	var c := UiKit.card(UiKit.GOLD)
	var v := UiKit.vbox(6)
	c.add_child(v)
	var lvl := Profile.mastery_level(id)
	var prog: Array = Profile.mastery_progress(id)
	v.add_child(UiKit.label("MASTERY LEVEL %d / 10" % lvl, 16, UiKit.GOLD))
	v.add_child(UiKit.bar(float(prog[0]), UiKit.GOLD, 420, 10))
	v.add_child(UiKit.label("%d / %d XP" % [int(prog[1]), int(prog[2])], 13, UiKit.DIM))
	var un: PackedStringArray = []
	for l in GameData.MASTERY_UNLOCKS.keys():
		var mark := "+" if lvl >= int(l) else "-"
		un.append("%s Lv%d %s" % [mark, int(l), GameData.MASTERY_UNLOCKS[l]])
	v.add_child(UiKit.wrap("   ".join(un), 13, UiKit.DIM, 420))
	var perks: Dictionary = GameData.SHIPS[id]["perks"]
	var cur := Profile.perk(id)
	var h := UiKit.hbox(8)
	v.add_child(h)
	for k in ["a", "b"]:
		var pk: Dictionary = perks[k]
		var txt := ("> " if cur == k else "") + str(pk["name"])
		var b := UiKit.button(txt, _perk.bind(id, k), 206)
		b.tooltip_text = str(pk["desc"])
		b.disabled = k == "b" and lvl < 5
		h.add_child(b)
	v.add_child(UiKit.wrap("Perk: " + str(perks[cur]["desc"]) + ("" if lvl >= 5 else "   (alternate perk unlocks at mastery 5)"), 13, UiKit.TEXT, 420))
	return c


func _palettes() -> Control:
	var c := UiKit.card()
	var v := UiKit.vbox(6)
	c.add_child(v)
	v.add_child(UiKit.label("WAKE COLORS", 15, UiKit.ACCENT))
	var h := GridContainer.new()
	h.columns = 2
	h.add_theme_constant_override("h_separation", 10)
	h.add_theme_constant_override("v_separation", 8)
	v.add_child(h)
	for pid in GameData.PALETTES.keys():
		var pal: Dictionary = GameData.PALETTES[pid]
		var ok := SaveData.is_unlocked(pid)
		var sel: bool = SaveData.data["palette"] == pid
		var b := UiKit.button(("> " if sel else "") + str(pal["name"]) + ("" if ok else " (locked)"), _palette.bind(pid), 430)
		b.disabled = not ok
		b.tooltip_text = str(pal["unlock"])
		h.add_child(b)
	return c


func _registry() -> Control:
	var c := UiKit.card()
	var v := UiKit.vbox(4)
	c.add_child(v)
	v.add_child(UiKit.label("FLEET REGISTRY", 15, UiKit.ACCENT))
	var r: Dictionary = SaveData.data["records"]
	v.add_child(UiKit.label("Missions %d   Won %d   Kills %d   Bosses %d   Contracts %d" % [int(r["missions"]), int(r["missions_won"]), int(r["kills"]), int(r["boss_kills"]), int(SaveData.data["contracts"]["done"])], 14, UiKit.TEXT))
	var parts: PackedStringArray = []
	for id in GameData.SHIP_ORDER:
		if Profile.ship_unlocked(id):
			parts.append("%s Lv%d" % [GameData.SHIPS[id]["name"], Profile.mastery_level(id)])
	v.add_child(UiKit.wrap("Mastery: " + "   ".join(parts), 14, UiKit.DIM, 860))
	return c


func _pick(id: String) -> void:
	harbor.fleet_selected = id
	harbor.refresh()


func _select(id: String) -> void:
	Profile.select_ship(id)
	Sound.ui("confirm")
	harbor.refresh()


func _fit(id: String) -> void:
	Profile.select_ship(id)
	harbor.fitting_ship = id
	harbor.show_tab("fitting")


func _buy(id: String) -> void:
	if Profile.unlock_ship(id):
		Profile.discover("ships", id)
		Sound.ui("confirm")
	else:
		Sound.ui("deny")
	harbor.refresh()


func _test(id: String) -> void:
	harbor.main.start_practice(id)


func _perk(id: String, k: String) -> void:
	Profile.set_perk(id, k)
	harbor.refresh()


func _palette(pid: String) -> void:
	SaveData.data["palette"] = pid
	SaveData.save()
	harbor.refresh()

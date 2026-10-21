class_name FittingTab
extends VBoxContainer

var harbor
var ship := ""
var index := 0
var work: Dictionary = {}
var dirty := false
var preview: FittingPreview
var stats_box: VBoxContainer
var name_edit: LineEdit
var status_label: Label


func has_unsaved() -> bool:
	return dirty


func build() -> void:
	add_theme_constant_override("separation", 12)
	ship = harbor.fitting_ship if harbor.fitting_ship != "" else Profile.selected_ship()
	if not Profile.ship_unlocked(ship):
		ship = Profile.selected_ship()
	harbor.fitting_ship = ship
	index = Profile.active_build_index(ship)
	work = Profile.active_build(ship).duplicate(true)
	dirty = false
	_rebuild()


func _rebuild() -> void:
	for ch in get_children():
		ch.queue_free()
	var top := UiKit.hbox(12)
	add_child(top)
	var owned: Array = []
	var ship_names: Array = []
	for id in GameData.SHIP_ORDER:
		if Profile.ship_unlocked(id):
			owned.append(id)
			ship_names.append(GameData.SHIPS[id]["name"])
	top.add_child(UiKit.label("Ship", 16, UiKit.DIM))
	top.add_child(UiKit.option(ship_names, owned.find(ship), _pick_ship.bind(owned), 200))
	var builds := Profile.builds(ship)
	var bnames: Array = []
	for b in builds:
		bnames.append(str(b.get("name", "Build")))
	if builds.size() < Profile.build_slots(ship):
		bnames.append("+ New build slot")
	top.add_child(UiKit.label("Build", 16, UiKit.DIM))
	top.add_child(UiKit.option(bnames, index, _pick_build, 220))
	name_edit = LineEdit.new()
	name_edit.text = str(work.get("name", "Build"))
	name_edit.custom_minimum_size = Vector2(220, 38)
	name_edit.max_length = 24
	name_edit.text_changed.connect(_rename)
	top.add_child(name_edit)
	top.add_child(UiKit.label("%d / %d slots" % [builds.size(), Profile.build_slots(ship)], 14, UiKit.DIM))
	var row := UiKit.hbox(16)
	add_child(row)
	var left := UiKit.vbox(10)
	row.add_child(left)
	preview = FittingPreview.new()
	left.add_child(preview)
	stats_box = UiKit.vbox(4)
	stats_box.custom_minimum_size = Vector2(380, 0)
	left.add_child(stats_box)
	var mid := UiKit.vbox(8)
	mid.custom_minimum_size = Vector2(840, 0)
	row.add_child(mid)
	var def: Dictionary = GameData.SHIPS[ship]
	mid.add_child(UiKit.label("WEAPON STATIONS", 16, UiKit.ACCENT))
	for sd in Profile.ship_stations(ship):
		mid.add_child(_station_row(str(sd["slot"]), int(sd["barrels"])))
	mid.add_child(UiKit.label("UTILITY MODULES  (active, one key each)", 16, UiKit.ACCENT))
	for i in int(def["utility"]):
		mid.add_child(_module_row(i))
	mid.add_child(UiKit.label("PASSIVE SYSTEMS  (one Wake Specialization at most)", 16, UiKit.ACCENT))
	for i in Profile.passive_slots(ship):
		mid.add_child(_passive_row(i))
	var actions := UiKit.hbox(10)
	mid.add_child(actions)
	actions.add_child(UiKit.button("Save Build", save_current, 180))
	actions.add_child(UiKit.button("Duplicate", _duplicate, 150))
	var del := UiKit.button("Delete", _delete, 130)
	del.disabled = builds.size() <= 1
	actions.add_child(del)
	actions.add_child(UiKit.button("Restore Saved", _revert, 180))
	status_label = UiKit.label("", 15, UiKit.GOLD)
	mid.add_child(status_label)
	_refresh_stats()


func _station_row(slot: String, barrels: int) -> Control:
	var h := UiKit.hbox(10)
	var lab := UiKit.label("%s  x%d" % [GameData.SLOT_LABELS[slot], barrels], 15, GameData.SLOT_COLORS[slot])
	lab.custom_minimum_size = Vector2(150, 0)
	h.add_child(lab)
	var keys: Array = Profile.owned_weapon_keys(slot)
	var names: Array = []
	var cur: Dictionary = work["stations"].get(slot, {"w": "roundshot", "m": "1"})
	var cur_key := "%s:%s" % [cur["w"], cur["m"]]
	for k in keys:
		var parts: Array = GameData.split_key(str(k))
		var w := GameData.weapon_stats(parts[0], parts[1])
		names.append("%s %s  -  %s" % [w["name"], w["mark_name"], w["role"]])
	h.add_child(UiKit.option(names, keys.find(cur_key), _set_weapon.bind(slot, keys), 470))
	var parts2: Array = GameData.split_key(cur_key)
	var wd := GameData.weapon_stats(parts2[0], parts2[1])
	h.add_child(UiKit.label("M %.1f  P %.0f" % [float(wd.get("mass", 1.0)) * float(barrels) / 3.0, float(wd.get("power", 0.0))], 13, UiKit.DIM))
	return h


func _module_row(i: int) -> Control:
	var h := UiKit.hbox(10)
	var lab := UiKit.label("Module %d  [%s]" % [i + 1, Controls.short_text("module_%d" % (i + 1))], 15, Color(0.6, 1.0, 0.85))
	lab.custom_minimum_size = Vector2(150, 0)
	h.add_child(lab)
	var ids: Array = [""]
	var names: Array = ["(empty)"]
	for id in GameData.ACTIVE_ORDER:
		if Profile.has_item("modules", id):
			ids.append(id)
			var m: Dictionary = GameData.ACTIVE_MODULES[id]
			names.append("%s  -  %s" % [m["name"], m["desc"]])
	var util: Array = work["utility"]
	var cur: String = util[i] if i < util.size() else ""
	h.add_child(UiKit.option(names, maxi(0, ids.find(cur)), _set_module.bind(i, ids), 600))
	return h


func _passive_row(i: int) -> Control:
	var h := UiKit.hbox(10)
	var lab := UiKit.label("Passive %d" % (i + 1), 15, UiKit.TEXT)
	lab.custom_minimum_size = Vector2(150, 0)
	h.add_child(lab)
	var ids: Array = [""]
	var names: Array = ["(empty)"]
	for id in GameData.PASSIVE_ORDER:
		if Profile.has_item("passives", id):
			ids.append(id)
			var p: Dictionary = GameData.PASSIVES[id]
			names.append("%s  -  %s" % [p["name"], p["desc"]])
	var pas: Array = work["passives"]
	var cur: String = pas[i] if i < pas.size() else ""
	h.add_child(UiKit.option(names, maxi(0, ids.find(cur)), _set_passive.bind(i, ids), 600))
	return h


func _stats() -> ShipStats:
	return ShipStats.from_build(ship, work, Profile.perk(ship))


func _refresh_stats() -> void:
	var s := _stats()
	preview.set_stats(s)
	for ch in stats_box.get_children():
		ch.queue_free()
	var pu := s.get_value("power_used")
	var pc := s.get_value("power_cap")
	var mu := s.get_value("mass_used")
	var mr := s.get_value("mass_rating")
	stats_box.add_child(UiKit.label("POWER  %.1f / %.1f" % [pu, pc], 14, Color(1.0, 0.4, 0.35) if pu > pc else GameData.COL_RESEARCH))
	stats_box.add_child(UiKit.bar(pu / maxf(1.0, pc), Color(1.0, 0.4, 0.35) if pu > pc else GameData.COL_RESEARCH, 380, 8))
	stats_box.add_child(UiKit.label("MASS  %.1f / %.1f rating" % [mu, mr], 14, Color(1.0, 0.75, 0.4) if mu > mr else UiKit.TEXT))
	stats_box.add_child(UiKit.bar(mu / maxf(1.0, mr), Color(1.0, 0.75, 0.4) if mu > mr else UiKit.TEXT, 380, 8))
	var base: Dictionary = GameData.SHIPS[ship]["stats"]
	stats_box.add_child(UiKit.label("Speed %d (%d)   Accel %d (%d)   Turn %.2f (%.2f)" % [int(s.get_value("max_speed")), int(base["max_speed"]), int(s.get_value("accel")), int(base["accel"]), s.get_value("turn"), float(base["turn"])], 13, UiKit.DIM))
	stats_box.add_child(UiKit.label("Hull %d   Reload x%.2f   Range x%.2f" % [int(s.get_value("max_hull")), s.get_value("reload_mult"), s.get_value("range_mult")], 13, UiKit.DIM))
	for st in s.stations:
		var w := s.profile(st)
		stats_box.add_child(UiKit.label("%s: %s  %.1f dps, range %d, reload %.1fs" % [GameData.SLOT_LABELS[st["slot"]], w["short"], s.dps(st), int(w["range"]), float(w["reload"])], 13, GameData.SLOT_COLORS[st["slot"]]))
	var v := s.validate()
	for e in v["errors"]:
		stats_box.add_child(UiKit.wrap(str(e), 13, Color(1.0, 0.4, 0.35), 380))
	for wtxt in v["warnings"]:
		stats_box.add_child(UiKit.wrap(str(wtxt), 13, Color(1.0, 0.75, 0.4), 380))
	if status_label != null:
		status_label.text = "Unsaved changes" if dirty else ""


func _changed() -> void:
	dirty = true
	_refresh_stats()


func _pick_ship(i: int, owned: Array) -> void:
	if dirty:
		save_current()
	ship = owned[i]
	harbor.fitting_ship = ship
	Profile.select_ship(ship)
	index = Profile.active_build_index(ship)
	work = Profile.active_build(ship).duplicate(true)
	dirty = false
	harbor.refresh_resources()
	_rebuild()


func _pick_build(i: int) -> void:
	if dirty:
		save_current()
	var builds := Profile.builds(ship)
	if i >= builds.size():
		var nb := Profile.default_build(ship)
		nb["name"] = "Build %d" % (builds.size() + 1)
		Profile.save_build(ship, -1, nb)
		i = Profile.builds(ship).size() - 1
	index = i
	Profile.set_active_build(ship, index)
	work = Profile.active_build(ship).duplicate(true)
	dirty = false
	_rebuild()


func _rename(t: String) -> void:
	work["name"] = t if t.strip_edges() != "" else "Build"
	dirty = true
	if status_label != null:
		status_label.text = "Unsaved changes"


func _set_weapon(i: int, slot: String, keys: Array) -> void:
	var parts: Array = GameData.split_key(str(keys[i]))
	work["stations"][slot] = {"w": parts[0], "m": parts[1]}
	_changed()
	_rebuild_keep()


func _set_module(i: int, idx: int, ids: Array) -> void:
	var util: Array = work["utility"]
	while util.size() <= idx:
		util.append("")
	util[idx] = ids[i]
	var clean: Array = []
	for u in util:
		if str(u) != "" and not clean.has(u):
			clean.append(u)
	work["utility"] = clean
	_changed()
	_rebuild_keep()


func _set_passive(i: int, idx: int, ids: Array) -> void:
	var pas: Array = work["passives"]
	while pas.size() <= idx:
		pas.append("")
	pas[idx] = ids[i]
	var clean: Array = []
	var spec := false
	for p in pas:
		if str(p) == "" or clean.has(p):
			continue
		if str(GameData.PASSIVES[p].get("exclusive", "")) == "wake_spec":
			if spec:
				Sound.ui("deny")
				continue
			spec = true
		clean.append(p)
	work["passives"] = clean
	_changed()
	_rebuild_keep()


func _rebuild_keep() -> void:
	var was := dirty
	_rebuild()
	dirty = was
	_refresh_stats()


func save_current() -> void:
	var s := _stats()
	var v := s.validate()
	if not bool(v["ok"]):
		Sound.ui("deny")
		if status_label != null:
			status_label.text = "Cannot save: power over capacity"
		return
	Profile.save_build(ship, index, work)
	Profile.set_active_build(ship, index)
	work = Profile.active_build(ship).duplicate(true)
	dirty = false
	Sound.ui("confirm")
	if status_label != null:
		status_label.text = "Build saved and set as active"


func _duplicate() -> void:
	var builds := Profile.builds(ship)
	if builds.size() >= Profile.build_slots(ship):
		Sound.ui("deny")
		status_label.text = "No free build slots (mastery 4 and 8 add more)"
		return
	var copy := work.duplicate(true)
	copy["name"] = str(work.get("name", "Build")) + " copy"
	Profile.save_build(ship, -1, copy)
	index = Profile.builds(ship).size() - 1
	Profile.set_active_build(ship, index)
	work = Profile.active_build(ship).duplicate(true)
	dirty = false
	_rebuild()


func _delete() -> void:
	Profile.delete_build(ship, index)
	index = Profile.active_build_index(ship)
	work = Profile.active_build(ship).duplicate(true)
	dirty = false
	_rebuild()


func _revert() -> void:
	work = Profile.active_build(ship).duplicate(true)
	dirty = false
	_rebuild()

class_name CodexScreen
extends Control

const CATS := ["Enemies", "Bosses", "Ships", "Weapons", "Modules", "Regions", "Factions", "Lore", "Tactics", "Records"]

var main
var on_back: Callable
var cat := "Enemies"
var entry := ""
var content: Control
var cat_button: Button = null
var focus_entry := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.dim_layer(0.6))
	_build()


func _build() -> void:
	if content != null:
		content.queue_free()
	content = UiKit.centered(self)
	var panel := UiKit.panel()
	content.add_child(panel)
	var v := UiKit.vbox(10)
	panel.add_child(v)
	var top := UiKit.hbox(14)
	v.add_child(top)
	top.add_child(UiKit.title("CODEX", 40))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UiKit.button("Back", _back, 180))
	var cats := UiKit.hbox(6)
	v.add_child(cats)
	for c in CATS:
		var b := UiKit.button(c, _pick_cat.bind(c), 128)
		b.custom_minimum_size = Vector2(128, 40)
		b.toggle_mode = true
		b.set_pressed_no_signal(c == cat)
		cats.add_child(b)
		if c == cat:
			cat_button = b
	var row := UiKit.hbox(14)
	v.add_child(row)
	var list_sc := UiKit.scroll(Vector2(320, 620))
	row.add_child(list_sc)
	var list := UiKit.vbox(6)
	list_sc.add_child(list)
	var entries := _entries()
	if entry == "" and not entries.is_empty():
		entry = str(entries[0][0])
	var focus_target: Button = cat_button
	for e in entries:
		var b := UiKit.button(str(e[1]), _pick.bind(str(e[0])), 300)
		b.toggle_mode = true
		b.set_pressed_no_signal(str(e[0]) == entry)
		if focus_entry and str(e[0]) == entry:
			focus_target = b
		if not bool(e[2]):
			b.modulate = Color(1, 1, 1, 0.5)
		list.add_child(b)
	var det_sc := UiKit.scroll(Vector2(960, 620))
	row.add_child(det_sc)
	var det := UiKit.vbox(8)
	det.custom_minimum_size = Vector2(930, 0)
	det_sc.add_child(det)
	_detail(det)
	if focus_target != null:
		focus_target.call_deferred("grab_focus")


func _entries() -> Array:
	var out: Array = []
	match cat:
		"Enemies":
			for k in GameData.ENEMY_ORDER:
				if GameData.is_boss(k) or k == "leviathan_pod":
					continue
				var known := Profile.known("enemies", k)
				out.append([k, GameData.enemy_name(k) if known else "???", known])
			for vk in GameData.VARIANTS.keys():
				out.append(["variant:" + vk, "Variant: " + str(GameData.VARIANTS[vk]["name"]), true])
		"Bosses":
			for k in ["ironwake", "kharon", "matriarch", "leviathan", "sovereign", "galleon"]:
				var kb := Profile.known("bosses", k)
				out.append([k, GameData.enemy_name(k) if kb else "???", kb])
			for r in GameData.REGIONS:
				if not bool(r["available"]):
					out.append(["future:" + str(r["id"]), str(r["boss"]) + " (Region %d)" % int(r["id"]), false])
		"Ships":
			for k in GameData.SHIP_ORDER:
				out.append([k, str(GameData.SHIPS[k]["name"]), Profile.ship_unlocked(k)])
		"Weapons":
			for k in GameData.WEAPON_ORDER:
				var owned := Profile.has_item("weapons", k + ":1")
				out.append([k, str(GameData.WEAPONS[k]["name"]) if owned else "??? weapon", owned])
		"Modules":
			for k in GameData.ACTIVE_ORDER:
				out.append(["a:" + k, str(GameData.ACTIVE_MODULES[k]["name"]), Profile.has_item("modules", k)])
			for k in GameData.PASSIVE_ORDER:
				out.append(["p:" + k, str(GameData.PASSIVES[k]["name"]), Profile.has_item("passives", k)])
		"Regions":
			for r in GameData.REGIONS:
				out.append([str(r["id"]), str(r["name"]), bool(r["available"])])
		"Factions":
			for i in GameData.FACTIONS.size():
				out.append([str(i), str(GameData.FACTIONS[i]["name"]), true])
		"Lore":
			out.append(["premise", "The Wake Phenomenon", true])
			for k in GameData.LORE_ORDER:
				var found := Profile.known("lore", k)
				out.append([k, str(GameData.LORE[k]["title"]) if found else "Unrecovered signal", found])
		"Tactics":
			for i in GameData.TACTICS.size():
				out.append([str(i), str(GameData.TACTICS[i]["title"]), true])
		"Records":
			out.append(["records", "Fleet Records", true])
	return out


func _line(det: Control, title: String, text: String, col: Color = UiKit.TEXT) -> void:
	if title != "":
		det.add_child(UiKit.label(title, 15, UiKit.ACCENT))
	det.add_child(UiKit.wrap(text, 16, col, 920))


func _detail(det: Control) -> void:
	if entry == "":
		return
	match cat:
		"Enemies":
			if entry.begins_with("variant:"):
				var vd: Dictionary = GameData.VARIANTS[entry.substr(8)]
				det.add_child(UiKit.label(str(vd["name"]), 30, vd["color"]))
				_line(det, "Effect", str(vd["desc"]))
				_line(det, "", "Variants add one clear modifier to a regular enemy. They appear more often on higher difficulties and in the Shoal Breaker stage.", UiKit.DIM)
				return
			if not Profile.known("enemies", entry):
				_line(det, "", "Not yet encountered. Meet this enemy in a mission to record its tactics.", UiKit.DIM)
				return
			_enemy(det, entry)
		"Bosses":
			if entry.begins_with("future:"):
				_line(det, "", "This flagship rules a region that has not been charted yet.", UiKit.DIM)
				return
			if not Profile.known("bosses", entry):
				_line(det, "", "Not yet encountered.", UiKit.DIM)
				return
			_enemy(det, entry)
		"Ships":
			var s: Dictionary = GameData.SHIPS[entry]
			det.add_child(UiKit.label(str(s["name"]), 30, s["look"]["accent"]))
			det.add_child(UiKit.label(str(s["class"]), 16, UiKit.DIM))
			_line(det, "Profile", str(s["desc"]))
			_line(det, "Unique mechanic", str(s["mechanic"]))
			_line(det, "Strength", str(s["strength"]), Color(0.5, 1.0, 0.7))
			_line(det, "Weakness", str(s["weakness"]), Color(1.0, 0.6, 0.5))
			_line(det, "Status", str(Profile.ship_status(entry)["text"]), UiKit.DIM)
		"Weapons":
			if not Profile.has_item("weapons", entry + ":1"):
				_line(det, "", "Blueprint not yet researched.", UiKit.DIM)
				return
			var w: Dictionary = GameData.WEAPONS[entry]
			det.add_child(UiKit.label(str(w["name"]), 30, w["color"]))
			_line(det, "Role", str(w["role"]))
			_line(det, "Description", str(w["desc"]))
			_line(det, "Limitation", str(w["limit"]), Color(1.0, 0.7, 0.5))
			_line(det, "Mk I stats", "Damage %.1f   Range %d   Reload %.1fs   Mass %.1f   Power %.0f   Mounts: %s" % [float(w["damage"]), int(w["range"]), float(w["reload"]), float(w["mass"]), float(w["power"]), ", ".join(PackedStringArray(w["mounts"]))])
			for mk in (w["marks"] as Dictionary).keys():
				var m: Dictionary = w["marks"][mk]
				var have := Profile.has_item("weapons", "%s:%s" % [entry, mk])
				_line(det, str(m["name"]) + ("" if have else " (not researched)"), str(m.get("desc", "")), UiKit.TEXT if have else UiKit.DIM)
		"Modules":
			var key := entry.substr(2)
			var d: Dictionary = GameData.ACTIVE_MODULES[key] if entry.begins_with("a:") else GameData.PASSIVES[key]
			det.add_child(UiKit.label(str(d["name"]), 30, UiKit.ACCENT))
			_line(det, "Type", "Active utility module" if entry.begins_with("a:") else "Passive system (%s)" % d.get("cat", ""))
			_line(det, "Effect", str(d["desc"]))
			if entry.begins_with("a:"):
				_line(det, "Cost", "Cooldown %.0fs   Power %.0f   Mass %.1f" % [float(d["cooldown"]), float(d["power"]), float(d["mass"])])
			else:
				_line(det, "Cost", "Mass %.1f" % float(d.get("mass", 0.0)))
			_line(det, "Status", "Owned" if (Profile.has_item("modules", key) or Profile.has_item("passives", key)) else "Not yet researched", UiKit.DIM)
		"Regions":
			var r: Dictionary = GameData.region(int(entry))
			det.add_child(UiKit.label(str(r["name"]), 30, r["glint"]))
			_line(det, "Theme", str(r["theme"]))
			_line(det, "Main pressure", str(r["pressure"]))
			_line(det, "Faction", str(r["faction"]))
			_line(det, "Boss", str(r["boss"]))
			_line(det, "Status", "Open" if Profile.region_unlocked(int(entry)) else "Not yet charted", UiKit.DIM)
		"Factions":
			var f: Dictionary = GameData.FACTIONS[int(entry)]
			det.add_child(UiKit.label(str(f["name"]), 30, UiKit.ACCENT))
			_line(det, "", str(f["desc"]))
		"Lore":
			if entry == "premise":
				det.add_child(UiKit.label("The Wake Phenomenon", 30, UiKit.PINK))
				_line(det, "", GameData.PREMISE)
				return
			if not Profile.known("lore", entry):
				_line(det, "", "Signal not yet recovered. Clear campaign stages to find more.", UiKit.DIM)
				return
			det.add_child(UiKit.label(str(GameData.LORE[entry]["title"]), 30, UiKit.PINK))
			if Profile.has_facility("signal_archive"):
				_line(det, "", str(GameData.LORE[entry]["text"]))
			else:
				_line(det, "", "Encrypted transmission. Build the Signal Archive in the Harbor to decode it.", UiKit.DIM)
		"Tactics":
			var t: Dictionary = GameData.TACTICS[int(entry)]
			det.add_child(UiKit.label(str(t["title"]), 30, UiKit.GOLD))
			_line(det, "", str(t["text"]))
		"Records":
			var rec: Dictionary = SaveData.data["records"]
			det.add_child(UiKit.label("Fleet Records", 30, UiKit.ACCENT))
			_line(det, "Campaign", "Stages cleared %d   Missions %d   Won %d" % [Profile.cleared_count(), int(rec["missions"]), int(rec["missions_won"])])
			_line(det, "Combat", "Kills %d   Bosses sunk %d   Highest Wake %s" % [int(rec["kills"]), int(rec["boss_kills"]), GameData.WAKE_ROMAN[clampi(int(rec["best_tier"]), 0, 5)]])
			_line(det, "New Game+", "Remix stages cleared %d / 50" % Profile.remix_clears())
			_line(det, "Classic Run", "Best score %d   Furthest wave %d   Runs %d   Victories %d" % [int(rec["best_score"]), int(rec["best_wave"]), int(rec["runs"]), int(rec["wins"])])
			var best: Dictionary = SaveData.data["campaign"]["best"]
			for id in GameData.all_stages():
				if best.has(id):
					var b: Dictionary = best[id]
					var tt := float(b.get("time", 0.0))
					_line(det, "", "%s %s   best %s   time %d:%02d   score %d" % [GameData.stage_label(id), GameData.mission(id)["name"], Profile.best_grade(id), int(tt / 60.0), int(tt) % 60, int(b.get("score", 0))], UiKit.DIM)


func _enemy(det: Control, k: String) -> void:
	var e: Dictionary = GameData.ENEMIES[k]
	det.add_child(UiKit.label(str(e["name"]), 30, GameData.COL_ENEMY))
	det.add_child(UiKit.label(str(e["role"]), 16, UiKit.DIM))
	_line(det, "Overview", str(e["intro"]))
	_line(det, "Attacks", str(e.get("attacks", "")))
	_line(det, "Telegraph", str(e.get("telegraph", "")), Color(1.0, 0.6, 0.5))
	_line(det, "Counterplay", str(e.get("counter", "")), Color(0.5, 1.0, 0.7))
	_line(det, "Profile", "Hull %d   Speed %d   Reward %d Salvage, %d score" % [int(e["hull"]), int(e["speed"]), int(e["salvage"]), int(e["score"])], UiKit.DIM)


func _pick_cat(c: String) -> void:
	cat = c
	entry = ""
	focus_entry = false
	_build()


func _pick(e: String) -> void:
	entry = e
	focus_entry = true
	_build()


func _back() -> void:
	if on_back.is_valid():
		on_back.call()


func _unhandled_input(event: InputEvent) -> void:
	var sh := UiKit.pad_shoulder(event)
	if sh != 0:
		get_viewport().set_input_as_handled()
		_pick_cat(CATS[posmod(CATS.find(cat) + sh, CATS.size())])
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()

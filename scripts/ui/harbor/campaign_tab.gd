class_name CampaignTab
extends VBoxContainer

var harbor


func build() -> void:
	add_theme_constant_override("separation", 14)
	var regions := UiKit.hbox(8)
	add_child(regions)
	for r in GameData.REGIONS:
		var id: int = int(r["id"])
		var unlocked := Profile.region_unlocked(id)
		var txt := "%s  %s" % [["", "I", "II", "III", "IV", "V"][id], str(r["name"]).replace("The ", "")]
		var b := UiKit.button(txt, _pick_region.bind(id), 240)
		b.toggle_mode = true
		b.set_pressed_no_signal(id == harbor.selected_region)
		if not unlocked:
			b.modulate = Color(1, 1, 1, 0.55)
		regions.add_child(b)
	if Profile.remix_unlocked():
		var rx := UiKit.hbox(12)
		add_child(rx)
		var on := Profile.remix_active()
		rx.add_child(UiKit.button("New Game+ Remix: %s" % ("ON" if on else "OFF"), _toggle_remix, 320))
		rx.add_child(UiKit.label("Remixed fleets, tougher bosses, x1.5 rewards.  Remix clears %d / 50" % Profile.remix_clears(), 15, UiKit.PINK if on else UiKit.DIM))
	var reg: Dictionary = GameData.region(harbor.selected_region)
	var info := UiKit.card(reg["glint"])
	add_child(info)
	var iv := UiKit.vbox(6)
	info.add_child(iv)
	iv.add_child(UiKit.label("REGION %s  |  STAGES %s" % [["", "I", "II", "III", "IV", "V"][int(reg["id"])], reg["stages"]], 14, UiKit.DIM))
	iv.add_child(UiKit.label(str(reg["name"]), 30, reg["glint"]))
	iv.add_child(UiKit.wrap(str(reg["theme"]), 16, UiKit.TEXT, 1180))
	var facts := UiKit.hbox(24)
	iv.add_child(facts)
	facts.add_child(UiKit.label("Pressure: %s" % reg["pressure"], 15, UiKit.DIM))
	facts.add_child(UiKit.label("Faction: %s" % reg["faction"], 15, UiKit.DIM))
	facts.add_child(UiKit.label("Boss: %s" % reg["boss"], 15, Color(1.0, 0.65, 0.35)))
	var stages: Array = GameData.REGION_STAGES.get(int(reg["id"]), [])
	var prev: Dictionary = GameData.region(int(reg["id"]) - 1) if int(reg["id"]) > 1 else {}
	if bool(reg["available"]) and not stages.is_empty() and not Profile.region_unlocked(int(reg["id"])) and not prev.is_empty():
		var gate := UiKit.card(Color(1.0, 0.55, 0.35))
		add_child(gate)
		gate.add_child(UiKit.wrap("Defeat %s at the end of %s to open this region." % [prev["boss"], prev["name"]], 16, UiKit.GOLD, 1180))
	if not bool(reg["available"]) or stages.is_empty():
		var lock := UiKit.card()
		add_child(lock)
		var lv := UiKit.vbox(8)
		lock.add_child(lv)
		lv.add_child(UiKit.label("Charts not yet drawn", 24, UiKit.GOLD))
		var before: Dictionary = GameData.region(int(reg["id"]) - 1)
		lv.add_child(UiKit.wrap("The Harbor's navigators are still charting this region. Its ten stages, new enemy faction and %s arrive in a future update. Sink %s to be ready." % [reg["boss"], before["boss"]], 16, UiKit.TEXT, 1180))
		return
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)
	for id in stages:
		grid.add_child(_stage_card(id))
	var cleared := 0
	for id in stages:
		if Profile.stage_cleared(id):
			cleared += 1
	add_child(UiKit.label("Region progress: %d / %d stages cleared" % [cleared, stages.size()], 16, UiKit.DIM))


func _stage_card(id: String) -> Control:
	var m: Dictionary = GameData.mission(id)
	var unlocked := Profile.stage_unlocked(id)
	var cleared := Profile.stage_cleared(id)
	var boss := str(m.get("objective", "")) == "boss"
	var border := Color(1.0, 0.55, 0.35) if boss else (GameData.COL_SALVAGE if cleared else Color(0.2, 0.5, 0.65))
	var card := UiKit.card(border, 12.0)
	card.custom_minimum_size = Vector2(236, 168)
	var v := UiKit.vbox(4)
	card.add_child(v)
	v.add_child(UiKit.label("STAGE %s" % GameData.stage_label(id), 13, UiKit.DIM))
	v.add_child(UiKit.wrap(str(m["name"]), 19, Color.WHITE if unlocked else UiKit.DIM, 210))
	v.add_child(UiKit.label(str(m["type"]), 14, Color(1.0, 0.65, 0.35) if boss else UiKit.ACCENT))
	var opts: Array = m.get("optional", [])
	var done := 0
	for i in opts.size():
		if Profile.optional_done(id, i):
			done += 1
	var grade := Profile.best_grade(id)
	var line := "Locked" if not unlocked else ("Best grade %s   Optional %d/%d" % [grade, done, opts.size()] if cleared else "Not yet cleared")
	if unlocked and Profile.remix_active():
		var rg: String = str((Profile.cleared().get(id, {}) as Dictionary).get("remix", ""))
		line = "Remix grade %s" % rg if rg != "" else "Remix not yet cleared"
	v.add_child(UiKit.label(line, 13, GameData.COL_SALVAGE if cleared else UiKit.DIM))
	var b := UiKit.button("Briefing" if unlocked else "Locked", _open.bind(id), 200)
	b.custom_minimum_size = Vector2(200, 36)
	b.disabled = not unlocked
	v.add_child(b)
	return card


func _toggle_remix() -> void:
	Profile.set_remix(not Profile.remix_active())
	harbor.refresh()


func _pick_region(id: int) -> void:
	harbor.selected_region = id
	harbor.refresh()


func _open(id: String) -> void:
	harbor.main.open_briefing({"kind": "campaign", "id": id})

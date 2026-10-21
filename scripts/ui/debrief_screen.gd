class_name DebriefScreen
extends Control

const GRADE_COLORS := {"S": Color(1.0, 0.85, 0.35), "A": Color(0.4, 1.0, 0.75), "B": Color(0.4, 0.85, 1.0), "C": Color(0.8, 0.85, 0.95), "D": Color(0.7, 0.6, 0.6)}

var main
var result: Dictionary = {}
var rewards: Dictionary = {}
var source: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.dim_layer(0.8))
	var c := UiKit.centered(self)
	var panel := UiKit.panel()
	c.add_child(panel)
	var v := UiKit.vbox(10)
	v.custom_minimum_size = Vector2(1100, 0)
	panel.add_child(v)
	var ok := bool(result.get("success", false))
	v.add_child(UiKit.label("%s   |   %s" % [result.get("label", ""), result.get("name", "")], 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.title("MISSION COMPLETE" if ok else "MISSION FAILED", 48, GameData.COL_SALVAGE if ok else GameData.COL_WARN))
	if not ok:
		v.add_child(UiKit.label(str(result.get("fail_reason", "")), 18, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var row := UiKit.hbox(20)
	v.add_child(row)
	var gcol := UiKit.vbox(2)
	gcol.custom_minimum_size = Vector2(200, 0)
	row.add_child(gcol)
	var g: String = str(result.get("grade", "D")) if ok else "-"
	gcol.add_child(UiKit.label("GRADE", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	gcol.add_child(UiKit.title(g, 96, GRADE_COLORS.get(g, UiKit.DIM)))
	gcol.add_child(UiKit.label(GameData.DIFFICULTIES[result.get("difficulty", "standard")]["name"], 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 4)
	row.add_child(grid)
	var t := float(result.get("time", 0.0))
	var dmg: PackedStringArray = []
	var ds: Dictionary = result.get("damage_sources", {})
	for k in ds.keys():
		dmg.append("%s %d" % [k, int(ds[k])])
	var lines := [
		["Ship", str(GameData.SHIPS[result.get("ship", "wayfarer")]["name"])],
		["Time", "%d:%02d" % [int(t / 60.0), int(t) % 60]],
		["Score", str(int(result.get("score", 0)))],
		["Enemies sunk", str(int(result.get("kills", 0)))],
		["Accuracy", "%d%%" % int(round(float(result.get("accuracy", 0.0)) * 100.0))],
		["Highest Wake tier", GameData.WAKE_ROMAN[clampi(int(result.get("max_tier", 0)), 0, 5)]],
		["Hull remaining", "%d%%" % int(round(clampf(float(result.get("hull_ratio", 0.0)), 0.0, 1.0) * 100.0))],
		["Crossings / Interrupts / Dodges", "%d / %d / %d" % [int(result.get("crossings", 0)), int(result.get("interrupts", 0)), int(result.get("dodges", 0))]],
		["Damage taken from", "none" if dmg.is_empty() else ", ".join(dmg)],
	]
	if str(result.get("modifier", "")) != "":
		lines.append(["Modifier", str(GameData.MODIFIERS[result["modifier"]]["name"])])
	for l in lines:
		grid.add_child(UiKit.label(str(l[0]), 15, UiKit.DIM))
		grid.add_child(UiKit.wrap(str(l[1]), 15, UiKit.TEXT, 560))
	var texts: Array = result.get("optional_texts", [])
	var res: Array = result.get("optional_results", [])
	if not texts.is_empty():
		v.add_child(UiKit.label("OPTIONAL OBJECTIVES", 15, UiKit.ACCENT))
		for i in texts.size():
			var done := i < res.size() and bool(res[i])
			v.add_child(UiKit.label(("[done] " if done else "[missed] ") + str(texts[i]), 15, Color(0.4, 1.0, 0.7) if done else UiKit.DIM))
	var rew := UiKit.hbox(12)
	rew.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(rew)
	rew.add_child(UiKit.chip("+%d SALVAGE" % int(rewards.get("salvage", 0)), GameData.COL_SALVAGE))
	rew.add_child(UiKit.chip("+%d RESEARCH" % int(rewards.get("research", 0)), GameData.COL_RESEARCH))
	rew.add_child(UiKit.chip("+%d INTEL" % int(rewards.get("intel", 0)), GameData.COL_INTEL))
	rew.add_child(UiKit.chip("+%d MASTERY XP" % int(rewards.get("xp", 0)), UiKit.GOLD))
	var ship: String = str(result.get("ship", "wayfarer"))
	var prog: Array = Profile.mastery_progress(ship)
	var mh := UiKit.hbox(10)
	mh.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(mh)
	mh.add_child(UiKit.label("%s mastery %d" % [GameData.SHIPS[ship]["name"], Profile.mastery_level(ship)], 15, UiKit.GOLD))
	mh.add_child(UiKit.bar(float(prog[0]), UiKit.GOLD, 300, 10))
	for n in rewards.get("notes", []):
		v.add_child(UiKit.label(str(n), 16, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	if ok and str(result.get("debrief", "")) != "":
		var dc := UiKit.card(Color(0.3, 0.7, 0.9), 10.0)
		v.add_child(dc)
		dc.add_child(UiKit.wrap(str(result["debrief"]), 16, UiKit.TEXT, 1060))
	var actions := UiKit.hbox(12)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(actions)
	var harbor := UiKit.button("Return to Harbor", _harbor, 260)
	actions.add_child(harbor)
	actions.add_child(UiKit.button("Retry", Callable(main, "retry"), 200))
	var nxt := GameData.next_stage(str(result.get("mission_id", "")))
	if ok and result.get("mode", "") == "campaign" and nxt != "" and Profile.stage_unlocked(nxt):
		actions.add_child(UiKit.button("Next Stage: %s" % GameData.mission(nxt)["name"], _next.bind(nxt), 360))
	harbor.call_deferred("grab_focus")


func _harbor() -> void:
	main.show_harbor("campaign" if result.get("mode", "") == "campaign" else "operations")


func _next(id: String) -> void:
	main.open_briefing({"kind": "campaign", "id": id})

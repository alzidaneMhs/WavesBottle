class_name SummaryScreen
extends Control

var main
var summary: Dictionary = {}
var notes: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.dim_layer(0.75))
	var c := UiKit.centered(self)
	var panel := UiKit.panel()
	c.add_child(panel)
	var v := UiKit.vbox(10)
	panel.add_child(v)
	var won := bool(summary.get("victory", false))
	var practice: bool = summary.get("mode", "standard") == "practice"
	var head := "VICTORY" if won else "SHIP LOST"
	if practice:
		head = "TRIALS ENDED"
	v.add_child(UiKit.title(head, 52, GameData.COL_SALVAGE if won else GameData.COL_WARN))
	var sub := "The Galleon is sunk and the sea is yours." if won else "The wake fades - but every run teaches the sea."
	v.add_child(UiKit.label(sub, 17, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.spacer(6))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	var t := float(summary["time"])
	var tier := int(summary["max_tier"])
	var kills_txt := str(int(summary["kills"]))
	var kbt: Dictionary = summary["kills_by_type"]
	if not kbt.is_empty():
		var parts: PackedStringArray = []
		for k in kbt.keys():
			parts.append("%d %s" % [int(kbt[k]), GameData.ENEMIES[k]["name"]])
		kills_txt += "  (" + ", ".join(parts) + ")"
	var dmg_txt := "none"
	var ds: Dictionary = summary["damage_sources"]
	if not ds.is_empty():
		var dparts: PackedStringArray = []
		for k in ds.keys():
			dparts.append("%s %d" % [k, int(ds[k])])
		dmg_txt = ", ".join(dparts)
	var ups: Array = summary["upgrades"]
	var rows := [
		["Time survived", "%d:%02d" % [int(t / 60.0), int(t) % 60]],
		["Wave reached", "%d / %d" % [int(summary["wave"]), GameData.MAX_WAVE]],
		["Score", str(int(summary["score"]))],
		["Enemies defeated", kills_txt],
		["Accuracy", "%d%%" % int(round(float(summary["accuracy"]) * 100.0))],
		["Highest Wake tier", "%s  %s" % [GameData.WAKE_ROMAN[tier], GameData.WAKE_NAMES[tier]]],
		["Bosses defeated", str(int(summary["bosses"]))],
		["Salvage earned / spent", "%d / %d" % [int(summary["salvage_earned"]), int(summary["salvage_spent"])]],
		["Damage taken from", dmg_txt],
		["Upgrades fitted", "none" if ups.is_empty() else ", ".join(PackedStringArray(ups))],
		["Ship", str(GameData.SHIPS[summary.get("ship", "wayfarer")]["name"])],
		["Run seed", str(summary["seed"])],
	]
	for r in rows:
		grid.add_child(UiKit.label(str(r[0]), 17, UiKit.DIM))
		var val := UiKit.label(str(r[1]), 17, UiKit.TEXT)
		val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		val.custom_minimum_size = Vector2(520, 0)
		grid.add_child(val)
	if not notes.is_empty():
		v.add_child(UiKit.spacer(6))
		for n in notes:
			v.add_child(UiKit.label(str(n), 18, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	elif not practice:
		v.add_child(UiKit.label("Permanent records saved. Run upgrades are left behind.", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.spacer(8))
	var buttons := UiKit.hbox(16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(buttons)
	var retry := UiKit.button("Retry", Callable(main, "retry"), 240)
	buttons.add_child(retry)
	buttons.add_child(UiKit.button("Harbor", Callable(main, "show_harbor").bind("operations"), 240))
	retry.call_deferred("grab_focus")

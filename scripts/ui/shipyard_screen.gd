class_name ShipyardScreen
extends Control

const CAT_COLORS := {
	"Hull": Color(0.4, 1.0, 0.75),
	"Sails": Color(0.55, 0.85, 1.0),
	"Rudder": Color(0.7, 0.75, 1.0),
	"Keel": Color(0.6, 0.7, 0.95),
	"Cannons": Color(1.0, 0.65, 0.45),
	"Wake": Color(1.0, 0.5, 0.85),
	"Utility": Color(1.0, 0.85, 0.4),
}

var main
var run
var report: Dictionary = {}
var offers: Array = []
var installed: Array = []
var content: Control
var message := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.dim_layer(0.72))
	offers = run.roll_offers(4)
	Sound.set_music(0.7, 0.15, 0.0, 0.0)
	build()


func build() -> void:
	if content != null:
		content.queue_free()
	content = UiKit.centered(self)
	var panel := UiKit.panel()
	content.add_child(panel)
	var v := UiKit.vbox(12)
	panel.add_child(v)
	v.add_child(UiKit.title("SHIPYARD", 46))
	var sub := "Wave %d cleared   |   Reward +%d" % [int(report.get("wave", run.wave)), int(report.get("reward", 0))]
	if int(report.get("clean_bonus", 0)) > 0:
		sub += "   |   Clean wave +%d" % int(report["clean_bonus"])
	if float(report.get("repaired", 0.0)) > 0.0:
		sub += "   |   Repair kit +%d Hull" % int(report["repaired"])
	v.add_child(UiKit.label(sub, 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.label("SALVAGE  %d" % run.salvage, 30, GameData.COL_SALVAGE, HORIZONTAL_ALIGNMENT_CENTER))
	var row := UiKit.hbox(16)
	v.add_child(row)
	row.add_child(_ship_column())
	for up in offers:
		row.add_child(_offer_card(up))
	var actions := UiKit.hbox(14)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(actions)
	var max_hull: float = run.stats.get_value("max_hull")
	var rep := UiKit.button("Repair +30 Hull  (%d)" % run.repair_cost, _repair, 280)
	rep.disabled = run.salvage < run.repair_cost or run.player.hull >= max_hull
	actions.add_child(rep)
	var reroll := UiKit.button("Reroll Offers  (%d)" % run.reroll_cost, _reroll, 260)
	reroll.disabled = run.salvage < run.reroll_cost
	actions.add_child(reroll)
	var next_wave: int = run.wave + 1
	var next_txt := "Set Sail: Wave %d" % next_wave
	if next_wave == GameData.MAX_WAVE:
		next_txt = "Set Sail: Face the Galleon"
	var go := UiKit.button(next_txt, Callable(main, "continue_run"), 320)
	actions.add_child(go)
	var cfg: Dictionary = GameData.get_wave(next_wave)
	var info := "Next: " + str(cfg["note"])
	var kinds: PackedStringArray = []
	for g in cfg["groups"]:
		kinds.append("%dx %s" % [int(g[1]), GameData.ENEMIES[g[0]]["name"]])
	info += "   (" + ", ".join(kinds) + ")"
	if int(cfg["elite"]) > 0:
		info += "   +%d elite" % int(cfg["elite"])
	v.add_child(UiKit.label(info, 15, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.label(message, 15, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	go.call_deferred("grab_focus")


func _ship_column() -> Control:
	var p := UiKit.panel()
	var col := UiKit.vbox(5)
	col.custom_minimum_size = Vector2(250, 0)
	p.add_child(col)
	col.add_child(UiKit.label("YOUR SHIP", 18, UiKit.ACCENT))
	var max_hull: float = run.stats.get_value("max_hull")
	col.add_child(UiKit.label("Hull  %d / %d" % [int(ceil(run.player.hull)), int(max_hull)], 16, Color(0.4, 1.0, 0.75)))
	for line in run.stats.summary_lines():
		var h := HBoxContainer.new()
		var a := UiKit.label(str(line[0]), 14, UiKit.DIM)
		a.custom_minimum_size = Vector2(150, 0)
		h.add_child(a)
		h.add_child(UiKit.label(str(line[1]), 14))
		col.add_child(h)
	var ammo: PackedStringArray = []
	for st in run.stats.stations:
		ammo.append("%s %s x%d" % [GameData.SLOT_LABELS[st["slot"]], st["weapon"]["short"], int(st["barrels"]) + int(run.stats.get_value("extra_barrels"))])
	var al := UiKit.label("Stations: " + ", ".join(ammo), 14, UiKit.TEXT)
	al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	al.custom_minimum_size = Vector2(250, 0)
	col.add_child(al)
	var owned: Array = run.stats.owned
	if not owned.is_empty():
		var ol := UiKit.label("Fitted: " + ", ".join(PackedStringArray(owned)), 13, UiKit.DIM)
		ol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ol.custom_minimum_size = Vector2(250, 0)
		col.add_child(ol)
	return p


func _offer_card(up: Dictionary) -> Control:
	var p := UiKit.panel()
	var col := UiKit.vbox(6)
	col.custom_minimum_size = Vector2(230, 300)
	p.add_child(col)
	var cat := str(up["cat"])
	col.add_child(UiKit.label(cat.to_upper(), 13, CAT_COLORS.get(cat, UiKit.TEXT)))
	var name_l := UiKit.label(str(up["name"]), 19, Color.WHITE)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size = Vector2(230, 0)
	col.add_child(name_l)
	var d := UiKit.label(str(up["desc"]), 14, UiKit.TEXT)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(230, 0)
	col.add_child(d)
	var done := installed.has(up["id"])
	if not done:
		for line in run.stats.compare(up):
			var cl := UiKit.label(str(line), 13, Color(0.55, 1.0, 0.75))
			cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cl.custom_minimum_size = Vector2(230, 0)
			col.add_child(cl)
		var stacks: int = run.stats.stack_count(up["id"])
		if int(up["max"]) > 1:
			col.add_child(UiKit.label("Owned %d / %d" % [stacks, int(up["max"])], 13, UiKit.DIM))
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(filler)
	var cost := int(up["cost"])
	var b: Button
	if done:
		b = UiKit.button("INSTALLED", Callable(), 230)
		b.disabled = true
	else:
		b = UiKit.button("Buy  (%d)" % cost, _buy.bind(up), 230)
		b.disabled = run.salvage < cost
	col.add_child(b)
	return p


func _buy(up: Dictionary) -> void:
	if run.buy_upgrade(up):
		installed.append(up["id"])
		message = "Installed " + str(up["name"])
		Sound.ui("confirm")
	else:
		message = "Not enough Salvage"
		Sound.ui("deny")
	build()


func _repair() -> void:
	if run.repair(30.0):
		message = "Hull repaired"
		Sound.ui("confirm")
	else:
		Sound.ui("deny")
	build()


func _reroll() -> void:
	if run.pay_reroll():
		offers = run.roll_offers(4)
		installed.clear()
		message = "New offers on the dock"
		Sound.ui("confirm")
	else:
		Sound.ui("deny")
	build()

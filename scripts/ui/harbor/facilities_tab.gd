class_name FacilitiesTab
extends VBoxContainer

var harbor


func build() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiKit.wrap("Harbor facilities unlock new capabilities rather than raw percentage bonuses. Intel comes from campaign objectives and boss missions.", 15, UiKit.DIM, 1220))
	for fid in GameData.FACILITY_ORDER:
		add_child(_row(fid))


func _row(fid: String) -> Control:
	var f: Dictionary = GameData.FACILITIES[fid]
	var built := Profile.has_facility(fid)
	var card := UiKit.card(Color(0.4, 1.0, 0.7) if built else Color(0.15, 0.4, 0.55), 12.0)
	var h := UiKit.hbox(12)
	card.add_child(h)
	var v := UiKit.vbox(4)
	v.custom_minimum_size = Vector2(860, 0)
	h.add_child(v)
	v.add_child(UiKit.label(str(f["name"]), 19, Color(0.4, 1.0, 0.7) if built else UiKit.TEXT))
	v.add_child(UiKit.wrap(str(f["desc"]), 15, UiKit.DIM, 850))
	if built and fid == "salvage_exchange":
		var ex := UiKit.hbox(10)
		v.add_child(ex)
		var a: Array = GameData.EXCHANGE["salvage_for_research"]
		var b: Array = GameData.EXCHANGE["research_for_salvage"]
		var b1 := UiKit.button("%d Salvage -> %d Research" % [int(a[0]), int(a[1])], _exchange.bind("salvage_for_research"), 300)
		b1.disabled = Profile.res("salvage") < int(a[0])
		ex.add_child(b1)
		var b2 := UiKit.button("%d Research -> %d Salvage" % [int(b[0]), int(b[1])], _exchange.bind("research_for_salvage"), 300)
		b2.disabled = Profile.res("research") < int(b[0])
		ex.add_child(b2)
	var right := UiKit.vbox(4)
	h.add_child(right)
	if built:
		right.add_child(UiKit.label("BUILT", 16, Color(0.4, 1.0, 0.7)))
	else:
		right.add_child(UiKit.label(GameData.cost_text(f["cost"]), 14, GameData.COL_SALVAGE))
		var btn := UiKit.button("Build", _build_facility.bind(fid), 200)
		btn.custom_minimum_size = Vector2(200, 36)
		btn.disabled = not Profile.can_afford(f["cost"])
		right.add_child(btn)
	return card


func _build_facility(fid: String) -> void:
	if Profile.build_facility(fid):
		Sound.ui("confirm")
	else:
		Sound.ui("deny")
	harbor.refresh()


func _exchange(dir: String) -> void:
	if Profile.exchange(dir):
		Sound.ui("confirm")
	else:
		Sound.ui("deny")
	harbor.refresh()

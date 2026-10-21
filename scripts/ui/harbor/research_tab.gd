class_name ResearchTab
extends VBoxContainer

var harbor


func build() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiKit.wrap("Research Data comes from new enemies, optional objectives, elite hunts and bosses. Salvage pays for common passive systems. Every item has a fixed unlock path - no random drops.", 15, UiKit.DIM, 1220))
	var cat := ""
	for rid in GameData.RESEARCH_ORDER:
		var r: Dictionary = GameData.RESEARCH[rid]
		if str(r["cat"]) != cat:
			cat = str(r["cat"])
			add_child(UiKit.label(cat.to_upper(), 17, UiKit.ACCENT))
		add_child(_row(rid))


func _row(rid: String) -> Control:
	var st := Profile.research_status(rid)
	var state: String = st["state"]
	var col := UiKit.TEXT
	match state:
		"done":
			col = Color(0.4, 1.0, 0.7)
		"locked":
			col = UiKit.DIM
	var card := UiKit.card(Color(0.4, 1.0, 0.7) if state == "done" else Color(0.15, 0.4, 0.55), 10.0)
	var h := UiKit.hbox(12)
	card.add_child(h)
	var v := UiKit.vbox(2)
	v.custom_minimum_size = Vector2(860, 0)
	h.add_child(v)
	v.add_child(UiKit.label(Profile.research_name(rid), 17, col))
	v.add_child(UiKit.wrap(Profile.research_desc(rid), 14, UiKit.DIM, 850))
	var right := UiKit.vbox(4)
	h.add_child(right)
	var info := UiKit.wrap(str(st["text"]), 13, GameData.COL_SALVAGE if state in ["ready", "short"] else col, 300)
	right.add_child(info)
	if state != "done" and state != "locked":
		var b := UiKit.button("Research", _research.bind(rid), 200)
		b.custom_minimum_size = Vector2(200, 36)
		b.disabled = state != "ready"
		right.add_child(b)
	return card


func _research(rid: String) -> void:
	if Profile.do_research(rid):
		Sound.ui("confirm")
	else:
		Sound.ui("deny")
	harbor.refresh()

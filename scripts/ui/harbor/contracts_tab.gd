class_name ContractsTab
extends VBoxContainer

var harbor


func build() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiKit.wrap("Harbor Compact contracts track progress across every mission and operation. Claim a finished contract to receive its reward and a new one takes its place.", 15, UiKit.DIM, 1220))
	add_child(UiKit.label("Active slots: %d   Completed so far: %d" % [Profile.contract_slots(), int(SaveData.data["contracts"]["done"])], 15, UiKit.ACCENT))
	for c in Profile.active_contracts():
		add_child(_row(c))
	if not Profile.has_facility("navigation_room"):
		add_child(UiKit.label("Build the Navigation Room for a third contract slot.", 14, UiKit.DIM))


func _row(c: Dictionary) -> Control:
	var def: Dictionary = c["def"]
	var target := int(def["target"])
	var prog := int(c["progress"])
	var complete := prog >= target
	var card := UiKit.card(GameData.COL_SALVAGE if complete else Color(0.15, 0.4, 0.55), 12.0)
	var h := UiKit.hbox(14)
	card.add_child(h)
	var v := UiKit.vbox(6)
	v.custom_minimum_size = Vector2(860, 0)
	h.add_child(v)
	v.add_child(UiKit.label(str(def["text"]), 19, Color.WHITE))
	v.add_child(UiKit.bar(float(prog) / float(maxi(1, target)), GameData.COL_SALVAGE if complete else UiKit.ACCENT, 840, 10))
	v.add_child(UiKit.label("%d / %d" % [mini(prog, target), target], 14, UiKit.DIM))
	var right := UiKit.vbox(4)
	h.add_child(right)
	right.add_child(UiKit.label("Reward: " + GameData.cost_text(def["reward"]), 14, GameData.COL_SALVAGE))
	var b := UiKit.button("Claim", _claim.bind(str(c["id"])), 200)
	b.custom_minimum_size = Vector2(200, 36)
	b.disabled = not complete
	right.add_child(b)
	return card


func _claim(id: String) -> void:
	if Profile.claim_contract(id):
		Sound.ui("confirm")
	harbor.refresh()

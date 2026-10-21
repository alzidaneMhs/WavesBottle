class_name OperationsTab
extends VBoxContainer

var harbor


func build() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiKit.wrap("Repeatable operations for Salvage, Research and mastery. Each one rolls a mission modifier that raises the reward. Classic Run is the original ten-wave score attack.", 15, UiKit.DIM, 1220))
	for op in GameData.OPS_ORDER:
		add_child(_row(op))


func _row(op: String) -> Control:
	var d: Dictionary = GameData.OPERATIONS[op]
	var open := Profile.op_unlocked(op)
	var card := UiKit.card(Color(0.15, 0.4, 0.55) if open else Color(0.1, 0.18, 0.24), 12.0)
	var h := UiKit.hbox(14)
	card.add_child(h)
	var v := UiKit.vbox(4)
	v.custom_minimum_size = Vector2(860, 0)
	h.add_child(v)
	v.add_child(UiKit.label("%s   |   %s" % [d["name"], d["type"]], 19, Color.WHITE if open else UiKit.DIM))
	v.add_child(UiKit.wrap(str(d["desc"]), 15, UiKit.DIM, 850))
	if op == "classic":
		var r: Dictionary = SaveData.data["records"]
		v.add_child(UiKit.label("Best score %d   Furthest wave %d   20%% of Salvage earned is banked" % [int(r["best_score"]), int(r["best_wave"])], 14, UiKit.ACCENT))
	elif d.has("rewards"):
		v.add_child(UiKit.label("Base reward: " + GameData.cost_text(d["rewards"]), 14, GameData.COL_SALVAGE))
	var right := UiKit.vbox(4)
	h.add_child(right)
	if open:
		var b := UiKit.button("Briefing", _open.bind(op), 200)
		b.custom_minimum_size = Vector2(200, 36)
		right.add_child(b)
	else:
		right.add_child(UiKit.wrap("Locked: " + Profile.req_text(d.get("unlock", {})), 13, UiKit.DIM, 300))
	return card


func _open(op: String) -> void:
	harbor.main.open_briefing({"kind": "op", "id": op})

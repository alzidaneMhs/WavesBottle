class_name BriefingScreen
extends Control

var main
var source: Dictionary = {}
var ship := ""
var build_idx := 0
var tier := "standard"
var seed_value := 0
var cfg: Dictionary = {}
var content: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.dim_layer(0.6))
	ship = Profile.selected_ship()
	build_idx = Profile.active_build_index(ship)
	tier = Profile.selected_difficulty()
	seed_value = randi() % 900000 + 100000
	_build()


func _make_cfg() -> Dictionary:
	if source.get("kind", "") == "campaign":
		return MissionBuilder.campaign(str(source["id"]), tier, Profile.remix_active())
	return MissionBuilder.operation(str(source["id"]), tier, seed_value)


static func objective_text(c: Dictionary) -> String:
	match str(c.get("objective", "")):
		"destroy_all":
			var n: int = (c.get("waves", []) as Array).size()
			return "Destroy every enemy wave (%d wave%s)." % [n, "" if n == 1 else "s"]
		"salvage":
			return "Recover %d wrecks by slowing down inside their gold rings." % int(c.get("need", 3))
		"intercept":
			return "Sink at least %d of %d couriers before they reach the far edge." % [int(c.get("need", 3)), int(c.get("couriers", 4))]
		"escort":
			return "Keep the barge afloat until it completes its route."
		"survive":
			var t := float(c.get("time_limit", 240.0))
			return "Stay afloat for %d:%02d." % [int(t / 60.0), int(t) % 60]
		"checkpoints":
			return "Sail through %d checkpoints in order within %d seconds." % [int(c.get("checkpoints", 8)), int(c.get("time_limit", 150.0))]
		"bounty":
			return "Find and sink %s." % GameData.NAMED[c.get("bounty_id", "grey_widow")]["name"]
		"boss":
			return "Defeat %s." % GameData.enemy_name(str(c.get("boss", "ironwake")))
		"buoys":
			return "Hold position beside each of the %d echo buoys until it answers." % int(c.get("buoys", 4))
		"hunt":
			return "Hunt down %s. It dives when wounded and surfaces somewhere else - three encounters." % GameData.NAMED[str(c.get("hunt_id", "devourer"))]["name"]
		"anchors":
			return "Destroy all %d resonance anchors to cut off the reinforcements." % int(c.get("anchors", 3))
		"supply":
			var st := float(c.get("time_limit", 210.0))
			return "Sink all %d supply ships before the reinforcements arrive (%d:%02d)." % [int(c.get("supply", 4)), int(st / 60.0), int(st) % 60]
		"classic":
			return "Survive ten waves and sink the Galleon. A Shipyard opens after every wave."
	return ""


func _build() -> void:
	if content != null:
		content.queue_free()
	cfg = _make_cfg()
	content = UiKit.centered(self)
	var panel := UiKit.panel()
	content.add_child(panel)
	var v := UiKit.vbox(10)
	v.custom_minimum_size = Vector2(1180, 0)
	panel.add_child(v)
	v.add_child(UiKit.label("%s   |   %s" % [cfg.get("label", ""), cfg.get("type", "")], 16, UiKit.DIM))
	v.add_child(UiKit.label(str(cfg.get("name", "")), 42, UiKit.ACCENT))
	var reg: Dictionary = GameData.region(int(cfg.get("region", 1)))
	v.add_child(UiKit.label(str(reg["name"]), 16, reg["glint"]))
	if cfg.has("brief"):
		var bc := UiKit.card(Color(0.3, 0.7, 0.9), 12.0)
		v.add_child(bc)
		bc.add_child(UiKit.wrap(str(cfg["brief"]), 17, UiKit.TEXT, 1130))
	var row := UiKit.hbox(16)
	v.add_child(row)
	var left := UiKit.vbox(6)
	left.custom_minimum_size = Vector2(600, 0)
	row.add_child(left)
	left.add_child(UiKit.label("OBJECTIVE", 15, UiKit.ACCENT))
	left.add_child(UiKit.wrap(objective_text(cfg), 17, Color.WHITE, 590))
	var opts: Array = cfg.get("optional", [])
	if not opts.is_empty():
		left.add_child(UiKit.label("OPTIONAL OBJECTIVES", 15, UiKit.ACCENT))
		for i in opts.size():
			var done: bool = source.get("kind", "") == "campaign" and Profile.optional_done(str(source["id"]), i)
			left.add_child(UiKit.label(("[done] " if done else "- ") + str(opts[i]["text"]), 15, Color(0.4, 1.0, 0.7) if done else UiKit.TEXT))
	var modifier: String = str(cfg.get("modifier", ""))
	if modifier != "":
		var md: Dictionary = GameData.MODIFIERS[modifier]
		left.add_child(UiKit.label("MODIFIER: %s  (reward x%.2f)" % [md["name"], float(md["reward"])], 15, Color(1.0, 0.75, 0.4)))
		left.add_child(UiKit.wrap(str(md["desc"]), 14, UiKit.DIM, 590))
	left.add_child(UiKit.label("REWARDS", 15, UiKit.ACCENT))
	left.add_child(UiKit.wrap(_reward_text(), 15, GameData.COL_SALVAGE, 590))
	var right := UiKit.vbox(8)
	row.add_child(right)
	if str(cfg.get("mode", "")) != "classic":
		var tiers: Array = []
		var names: Array = []
		for t in GameData.DIFFICULTY_ORDER:
			if Profile.difficulty_unlocked(t):
				tiers.append(t)
				names.append("%s  -  %s" % [GameData.DIFFICULTIES[t]["name"], GameData.DIFFICULTIES[t]["desc"]])
		right.add_child(UiKit.label("Difficulty", 15, UiKit.DIM))
		right.add_child(UiKit.option(names, tiers.find(tier), _pick_tier.bind(tiers), 540))
		if source.get("kind", "") == "campaign" and Profile.remix_unlocked():
			right.add_child(UiKit.label("Campaign mode", 15, UiKit.DIM))
			right.add_child(UiKit.option(["Standard campaign", "New Game+ Remix  -  remixed fleets, tougher bosses, x1.5 rewards"], 1 if Profile.remix_active() else 0, _pick_remix, 540))
	var owned: Array = []
	var snames: Array = []
	for id in GameData.SHIP_ORDER:
		if Profile.ship_unlocked(id):
			owned.append(id)
			snames.append("%s  -  %s" % [GameData.SHIPS[id]["name"], GameData.SHIPS[id]["class"]])
	right.add_child(UiKit.label("Ship", 15, UiKit.DIM))
	right.add_child(UiKit.option(snames, owned.find(ship), _pick_ship.bind(owned), 540))
	var bnames: Array = []
	for b in Profile.builds(ship):
		bnames.append(str(b.get("name", "Build")))
	right.add_child(UiKit.label("Build", 15, UiKit.DIM))
	right.add_child(UiKit.option(bnames, build_idx, _pick_build, 540))
	var build: Dictionary = Profile.sanitize_build(ship, Profile.builds(ship)[build_idx])
	var stats := ShipStats.from_build(ship, build, Profile.perk(ship))
	var parts: PackedStringArray = []
	for st in stats.stations:
		parts.append("%s %s" % [GameData.SLOT_LABELS[st["slot"]], st["weapon"]["short"]])
	right.add_child(UiKit.wrap("   ".join(parts), 14, UiKit.TEXT, 540))
	var mods: PackedStringArray = []
	for m in stats.modules:
		mods.append(str(GameData.ACTIVE_MODULES[m]["name"]))
	right.add_child(UiKit.wrap("Modules: " + (", ".join(mods) if mods.size() > 0 else "none"), 14, UiKit.DIM, 540))
	var val := stats.validate()
	for e in val["errors"]:
		right.add_child(UiKit.wrap(str(e), 14, Color(1.0, 0.4, 0.35), 540))
	for w in val["warnings"]:
		right.add_child(UiKit.wrap(str(w), 14, Color(1.0, 0.75, 0.4), 540))
	var actions := UiKit.hbox(12)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(actions)
	var launch := UiKit.button("Launch", _launch, 260)
	launch.disabled = not bool(val["ok"])
	actions.add_child(launch)
	actions.add_child(UiKit.button("Fitting Dock", _fitting, 220))
	actions.add_child(UiKit.button("Back", _back, 180))
	launch.call_deferred("grab_focus")


func _reward_text() -> String:
	var mult: float = float(GameData.DIFFICULTIES[tier]["reward"])
	if str(cfg.get("mode", "")) == "classic":
		return "20% of Salvage earned in the run is banked, plus ship mastery XP."
	var r: Dictionary = cfg.get("rewards", {})
	var mod: String = str(cfg.get("modifier", ""))
	if mod != "":
		mult *= float(GameData.MODIFIERS[mod]["reward"])
	if bool(cfg.get("remix", false)):
		return "Remix: %d Salvage, %d Research (x%.2f, includes the x1.5 remix bonus), plus Salvage collected. First remix clear pays in full." % [int(r.get("salvage", 0)), int(r.get("research", 0)), mult]
	if source.get("kind", "") == "campaign":
		var first := not Profile.stage_cleared(str(source["id"]))
		if first:
			return "First clear: %d Salvage, %d Research, %d Intel (x%.2f difficulty), plus Salvage collected in the mission and grade bonus." % [int(r.get("salvage", 0)), int(r.get("research", 0)), int(r.get("intel", 0)), mult]
		return "Replay: %d Salvage, %d Research (x%.2f), plus Salvage collected. +3 Research per new optional objective." % [int(float(r.get("salvage", 0)) * 0.6), int(float(r.get("research", 0)) * 0.5), mult]
	return "%d Salvage, %d Research (x%.2f), plus Salvage collected and any bounty." % [int(r.get("salvage", 0)), int(r.get("research", 0)), mult]


func _pick_remix(i: int) -> void:
	Profile.set_remix(i == 1)
	_build()


func _pick_tier(i: int, tiers: Array) -> void:
	tier = tiers[i]
	Profile.set_difficulty(tier)
	_build()


func _pick_ship(i: int, owned: Array) -> void:
	ship = owned[i]
	Profile.select_ship(ship)
	build_idx = Profile.active_build_index(ship)
	_build()


func _pick_build(i: int) -> void:
	build_idx = i
	Profile.set_active_build(ship, i)
	_build()


func _launch() -> void:
	main.launch(cfg, ship, Profile.sanitize_build(ship, Profile.builds(ship)[build_idx]), source)


func _fitting() -> void:
	main.show_harbor("fitting")


func _back() -> void:
	main.show_harbor("campaign" if source.get("kind", "") == "campaign" else "operations")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()

class_name MainMenu
extends Control

var main


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := UiKit.dim_layer(0.25)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var c := UiKit.centered(self)
	var v := UiKit.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	v.add_child(UiKit.title("WAVESBOTTLE", 88))
	v.add_child(UiKit.title("THE WAKE FREQUENCY", 26, UiKit.PINK))
	v.add_child(UiKit.spacer(20))
	var started := Profile.cleared_count() > 0 or int(SaveData.data["records"]["missions"]) > 0
	var buttons: Array = [
		UiKit.button("Continue" if started else "Begin Campaign", Callable(main, "show_harbor").bind("campaign")),
		UiKit.button("Campaign", Callable(main, "show_harbor").bind("campaign")),
		UiKit.button("Operations", Callable(main, "show_harbor").bind("operations")),
		UiKit.button("Hangar", Callable(main, "show_harbor").bind("fleet")),
		UiKit.button("Codex", Callable(main, "show_codex").bind(Callable(main, "show_main_menu"))),
		UiKit.button("Settings", Callable(main, "open_settings").bind(Callable(main, "show_main_menu"))),
		UiKit.button("Credits", Callable(main, "show_credits")),
	]
	if not OS.has_feature("web"):
		buttons.append(UiKit.button("Quit", Callable(main, "quit_game")))
	for b in buttons:
		(b as Button).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(b)
	v.add_child(UiKit.spacer(16))
	var stages: Array = GameData.all_stages()
	var cleared := 0
	for id in stages:
		if Profile.stage_cleared(id):
			cleared += 1
	v.add_child(UiKit.label("Campaign: %d / %d stages   |   Salvage %d   Research %d   Intel %d" % [cleared, stages.size(), Profile.res("salvage"), Profile.res("research"), Profile.res("intel")], 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var ship: String = Profile.selected_ship()
	v.add_child(UiKit.label("Active ship: %s (mastery %d)" % [GameData.SHIPS[ship]["name"], Profile.mastery_level(ship)], 16, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	(buttons[0] as Button).call_deferred("grab_focus")

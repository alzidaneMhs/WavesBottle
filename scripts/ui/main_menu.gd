class_name MainMenu
extends Control

var main
var prompt: Control = null
var play_button: Button


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
	v.add_child(UiKit.spacer(24))
	var nxt := Profile.next_stage()
	play_button = UiKit.button("Play", _play, 380)
	play_button.custom_minimum_size = Vector2(380, 64)
	play_button.add_theme_font_size_override("font_size", UiKit.fs(26))
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(play_button)
	var sub := "Next: Stage %s  %s" % [GameData.stage_label(nxt), GameData.mission(nxt)["name"]] if nxt != "" else "Campaign complete - pick any stage in the Harbor"
	v.add_child(UiKit.label(sub, 16, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.spacer(6))
	var buttons: Array = [
		UiKit.button("Harbor", Callable(main, "show_harbor").bind("campaign"), 380),
		UiKit.button("How to Play", Callable(main, "show_guide").bind(Callable(main, "show_main_menu"), "basics"), 380),
		UiKit.button("Settings", Callable(main, "open_settings").bind(Callable(main, "show_main_menu")), 380),
	]
	if not OS.has_feature("web"):
		buttons.append(UiKit.button("Quit", Callable(main, "quit_game"), 380))
	for b in buttons:
		(b as Button).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(b)
	var small := UiKit.hbox(10)
	small.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(small)
	var cod := UiKit.button("Codex", Callable(main, "show_codex").bind(Callable(main, "show_main_menu")), 185)
	var cred := UiKit.button("Credits", Callable(main, "show_credits"), 185)
	for b in [cod, cred]:
		(b as Button).custom_minimum_size = Vector2(185, 40)
		(b as Button).add_theme_font_size_override("font_size", UiKit.fs(16))
		small.add_child(b)
	v.add_child(UiKit.spacer(14))
	var ship: String = Profile.selected_ship()
	v.add_child(UiKit.label("Campaign %d / %d stages   |   Ship: %s" % [Profile.cleared_count(), GameData.all_stages().size(), GameData.SHIPS[ship]["name"]], 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	play_button.call_deferred("grab_focus")


func _play() -> void:
	if not Profile.help_seen("training") and not Profile.help_seen("training_offered"):
		_offer_training()
		return
	main.play_next()


func _offer_training() -> void:
	prompt = UiKit.dim_layer(0.6)
	add_child(prompt)
	var c := UiKit.centered(prompt)
	var p := UiKit.panel()
	c.add_child(p)
	var v := UiKit.vbox(12)
	v.custom_minimum_size = Vector2(620, 0)
	p.add_child(v)
	v.add_child(UiKit.label("New to the helm?", 30, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.wrap("A short Training mission teaches you to sail, aim your side guns and build Wake, one step at a time. It takes about three minutes and you can't sink.", 18, UiKit.TEXT, 620))
	var h := UiKit.hbox(12)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	var yes := UiKit.button("Start Training", _train, 260)
	h.add_child(yes)
	h.add_child(UiKit.button("Skip, I know how", _skip, 260))
	v.add_child(UiKit.label("You can play Training any time from How to Play.", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	yes.call_deferred("grab_focus")


func _train() -> void:
	Profile.mark_help("training_offered")
	main.start_training()


func _skip() -> void:
	Profile.mark_help("training_offered")
	main.play_next()


func _unhandled_input(event: InputEvent) -> void:
	if prompt != null and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		prompt.queue_free()
		prompt = null
		play_button.grab_focus()

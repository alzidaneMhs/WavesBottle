class_name PauseMenu
extends Control

var main
var run


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.dim_layer(0.6))
	var c := UiKit.centered(self)
	var panel := UiKit.panel()
	c.add_child(panel)
	var row := UiKit.hbox(24)
	panel.add_child(row)
	var v := UiKit.vbox(12)
	v.custom_minimum_size = Vector2(380, 0)
	row.add_child(v)
	v.add_child(UiKit.title("PAUSED", 48))
	if run != null:
		var info := "%s   Score %d   Salvage %d" % [run.cfg.get("label", ""), run.score, run.salvage]
		if run.mode == "classic":
			info = "Wave %d / %d   Score %d   Salvage %d" % [run.wave, GameData.MAX_WAVE, run.score, run.salvage]
		v.add_child(UiKit.label(info, 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var resume := UiKit.button("Resume", Callable(main, "resume"))
	v.add_child(resume)
	v.add_child(UiKit.button("How to Play", Callable(main, "show_guide").bind(Callable(main, "reopen_pause"), "shooting")))
	v.add_child(UiKit.button("Settings", Callable(main, "open_settings").bind(Callable(main, "reopen_pause"))))
	var leave := "Abandon Mission"
	if run != null and run.coach != null:
		leave = "End Training"
	elif run != null and run.mode == "practice":
		leave = "End Sea Trials"
	elif run != null and run.mode == "classic":
		leave = "Abandon Run"
	v.add_child(UiKit.button(leave, Callable(main, "abandon")))
	if run != null and run.logic != null:
		var obj := UiKit.card(UiKit.ACCENT, 12.0)
		v.add_child(obj)
		var ov := UiKit.vbox(4)
		obj.add_child(ov)
		ov.add_child(UiKit.label("OBJECTIVE", 14, UiKit.ACCENT))
		ov.add_child(UiKit.wrap(run.logic.primary_text(), 16, Color.WHITE, 340))
		for o in run.logic.optional_states():
			var st: int = int(o[1])
			var col := UiKit.TEXT if st == 0 else (Color(0.4, 1.0, 0.7) if st == 1 else Color(1.0, 0.45, 0.4))
			var mark := "- " if st == 0 else ("[done] " if st == 1 else "[failed] ")
			ov.add_child(UiKit.wrap(mark + str(o[0]), 14, col, 340))
	var keys := UiKit.vbox(4)
	row.add_child(keys)
	keys.add_child(UiKit.label("CONTROLS", 16, UiKit.ACCENT))
	for action in Controls.ORDER:
		if run != null and not _relevant(str(action)):
			continue
		var h := HBoxContainer.new()
		var l := UiKit.label(str(Controls.LABELS[action]), 15, UiKit.DIM)
		l.custom_minimum_size = Vector2(230, 0)
		h.add_child(l)
		h.add_child(UiKit.label(Controls.pad_text(action) if Controls.using_pad else Controls.key_text(action), 15))
		keys.add_child(h)
	if run != null and run.stats != null:
		keys.add_child(UiKit.spacer(6))
		var ab: String = run.stats.ability
		if ab != "":
			keys.add_child(UiKit.wrap("Ability: %s - %s" % [GameData.ABILITIES[ab]["name"], GameData.ABILITIES[ab]["desc"]], 14, UiKit.GOLD, 420))
		for m in run.stats.modules:
			keys.add_child(UiKit.wrap("Module: %s - %s" % [GameData.ACTIVE_MODULES[m]["name"], GameData.ACTIVE_MODULES[m]["desc"]], 14, Color(0.6, 1.0, 0.85), 420))
	resume.call_deferred("grab_focus")


func _relevant(action: String) -> bool:
	match action:
		"fire_port", "fire_starboard", "fire_bow", "fire_stern", "fire_turret":
			return run.player.slots.has(action.trim_prefix("fire_"))
		"ability":
			return run.stats.ability != ""
		"module_1":
			return run.stats.modules.size() >= 1
		"module_2":
			return run.stats.modules.size() >= 2
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		main.resume()

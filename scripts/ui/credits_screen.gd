class_name CreditsScreen
extends Control

var main


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.dim_layer(0.6))
	var c := UiKit.centered(self)
	var panel := UiKit.panel()
	c.add_child(panel)
	var v := UiKit.vbox(10)
	panel.add_child(v)
	v.add_child(UiKit.title("WAVESBOTTLE", 48))
	v.add_child(UiKit.label("The Wake Frequency", 22, UiKit.PINK, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.spacer(10))
	var lines := [
		["Game Design & Development", "azenenen & amukuLafaek"],
		["Visuals", "azenenen"],
		["Audio", "azenenen"],
		["Engine", "Made with Godot Engine (godotengine.org/license)"],
	]
	for l in lines:
		v.add_child(UiKit.label(str(l[0]), 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UiKit.label(str(l[1]), 20, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.spacer(10))
	v.add_child(UiKit.label("Thank you for sailing.", 18, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	var back := UiKit.button("Back", Callable(main, "show_main_menu"), 240)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(back)
	back.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		main.show_main_menu()

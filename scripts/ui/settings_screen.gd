class_name SettingsScreen
extends Control

var on_back: Callable
var waiting_action := ""
var waiting_pad := ""
var bind_buttons: Dictionary = {}
var pad_buttons: Dictionary = {}
var alt_labels: Dictionary = {}
var message: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.dim_layer(0.75))
	var c := UiKit.centered(self)
	var panel := UiKit.panel()
	c.add_child(panel)
	var v := UiKit.vbox(10)
	panel.add_child(v)
	v.add_child(UiKit.title("SETTINGS", 40))
	var row := UiKit.hbox(40)
	v.add_child(row)
	row.add_child(_left_column())
	row.add_child(_right_column())
	message = UiKit.label("", 16, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(message)
	var back := UiKit.button("Back", _go_back, 240)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(back)
	back.call_deferred("grab_focus")


func _left_column() -> Control:
	var col := UiKit.vbox(10)
	col.custom_minimum_size = Vector2(440, 0)
	col.add_child(UiKit.label("AUDIO", 18, UiKit.ACCENT))
	col.add_child(_slider_row("Master", "master"))
	col.add_child(_slider_row("Music", "music"))
	col.add_child(_slider_row("Effects", "sfx"))
	col.add_child(_slider_row("Interface", "ui"))
	col.add_child(UiKit.spacer(6))
	col.add_child(UiKit.label("DISPLAY & COMFORT", 18, UiKit.ACCENT))
	col.add_child(_slider_row("Screen Shake", "shake"))
	var particles := HBoxContainer.new()
	var pl := UiKit.label("Effects Density", 17)
	pl.custom_minimum_size = Vector2(170, 0)
	particles.add_child(pl)
	var opt := OptionButton.new()
	opt.add_item("Low")
	opt.add_item("Medium")
	opt.add_item("High")
	opt.selected = int(SaveData.setting("particles"))
	opt.custom_minimum_size = Vector2(200, 40)
	opt.item_selected.connect(func(i: int) -> void: SaveData.set_setting("particles", i))
	particles.add_child(opt)
	col.add_child(particles)
	col.add_child(_check_row("Reduce flashing", "reduce_flash"))
	col.add_child(_check_row("Fullscreen", "fullscreen"))
	col.add_child(_check_row("Drift is a toggle (press once)", "drift_toggle"))
	col.add_child(_check_row("Gentle aim assistance", "aim_assist"))
	col.add_child(_range_row("Menu text scale", "ui_scale", 0.85, 1.3))
	col.add_child(UiKit.label("Effects density and text scale apply when you leave Settings.", 13, UiKit.DIM))
	col.add_child(UiKit.spacer(10))
	col.add_child(UiKit.button("Reset Controls", _reset_controls, 260))
	col.add_child(UiKit.wrap("Alternate keys, mouse buttons and the second gamepad input always stay bound, so no action can become unreachable.", 13, UiKit.DIM, 420))
	return col


func _slider_row(text: String, key: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := UiKit.label(text, 17)
	l.custom_minimum_size = Vector2(170, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(SaveData.setting(key))
	s.custom_minimum_size = Vector2(190, 28)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var val := UiKit.label("%d%%" % int(s.value * 100.0), 16, UiKit.DIM)
	val.custom_minimum_size = Vector2(56, 0)
	s.value_changed.connect(func(x: float) -> void:
		SaveData.data["settings"][key] = x
		Sound.apply_volumes()
		val.text = "%d%%" % int(x * 100.0)
	)
	h.add_child(s)
	h.add_child(val)
	return h


func _range_row(text: String, key: String, lo: float, hi: float) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := UiKit.label(text, 17)
	l.custom_minimum_size = Vector2(170, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = float(SaveData.setting(key))
	s.custom_minimum_size = Vector2(190, 28)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var val := UiKit.label("%d%%" % int(s.value * 100.0), 16, UiKit.DIM)
	val.custom_minimum_size = Vector2(56, 0)
	s.value_changed.connect(func(x: float) -> void:
		SaveData.data["settings"][key] = x
		val.text = "%d%%" % int(round(x * 100.0))
	)
	h.add_child(s)
	h.add_child(val)
	return h


func _check_row(text: String, key: String) -> Control:
	var cb := CheckBox.new()
	cb.text = text
	cb.button_pressed = bool(SaveData.setting(key))
	cb.toggled.connect(func(on: bool) -> void: SaveData.set_setting(key, on))
	return cb


func _right_column() -> Control:
	var col := UiKit.vbox(4)
	col.custom_minimum_size = Vector2(660, 0)
	col.add_child(UiKit.label("CONTROLS  (select to rebind, Esc cancels)", 18, UiKit.ACCENT))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var hl := UiKit.label("", 13)
	hl.custom_minimum_size = Vector2(230, 0)
	head.add_child(hl)
	var hk := UiKit.label("KEYBOARD", 13, UiKit.DIM)
	hk.custom_minimum_size = Vector2(120, 0)
	head.add_child(hk)
	var hp := UiKit.label("GAMEPAD", 13, UiKit.DIM)
	hp.custom_minimum_size = Vector2(120, 0)
	head.add_child(hp)
	col.add_child(head)
	for action in Controls.ORDER:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var l := UiKit.label(str(Controls.LABELS[action]), 16)
		l.custom_minimum_size = Vector2(230, 0)
		h.add_child(l)
		var act: String = action
		var b := UiKit.button("", _start_wait.bind(act), 120)
		b.custom_minimum_size = Vector2(120, 34)
		h.add_child(b)
		bind_buttons[action] = b
		var pb := UiKit.button("", _start_pad_wait.bind(act), 120)
		pb.custom_minimum_size = Vector2(120, 34)
		h.add_child(pb)
		pad_buttons[action] = pb
		var alt := UiKit.label("", 14, UiKit.DIM)
		h.add_child(alt)
		alt_labels[action] = alt
		col.add_child(h)
	_refresh()
	return col


func _reset_controls() -> void:
	Controls.reset()
	message.text = "Controls reset to defaults"
	_refresh()


func _refresh() -> void:
	for action in Controls.ORDER:
		var b: Button = bind_buttons[action]
		b.text = Controls.key_name(Controls._keys_for(action)[0])
		(pad_buttons[action] as Button).text = Controls.pad_text(action)
		var full := Controls.key_text(action)
		var parts := full.split(" / ")
		parts.remove_at(0)
		(alt_labels[action] as Label).text = ("also: " + ", ".join(parts)) if parts.size() > 0 else ""


func _start_pad_wait(action: String) -> void:
	waiting_action = ""
	waiting_pad = action
	(pad_buttons[action] as Button).text = "press..."
	message.text = "Press a gamepad button or push a stick for: " + str(Controls.LABELS[action])


func _start_wait(action: String) -> void:
	waiting_pad = ""
	waiting_action = action
	(bind_buttons[action] as Button).text = "press key..."
	message.text = "Press a key for: " + str(Controls.LABELS[action])


func _input(event: InputEvent) -> void:
	if waiting_pad != "":
		_pad_input(event)
		return
	if waiting_action == "":
		return
	var ke := event as InputEventKey
	if ke == null or not ke.pressed or ke.echo:
		return
	get_viewport().set_input_as_handled()
	if ke.keycode == KEY_ESCAPE:
		message.text = "Rebinding cancelled"
	elif Controls.rebind(waiting_action, ke.keycode):
		message.text = "%s bound to %s" % [Controls.LABELS[waiting_action], OS.get_keycode_string(ke.keycode)]
		Sound.ui("confirm")
	else:
		message.text = "That key is already in use"
		Sound.ui("deny")
	waiting_action = ""
	_refresh()


func _pad_input(event: InputEvent) -> void:
	var ke := event as InputEventKey
	if ke != null and ke.pressed and ke.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		message.text = "Rebinding cancelled"
		waiting_pad = ""
		_refresh()
		return
	var pd: Array = Controls.pad_from_event(event)
	if pd.is_empty():
		return
	get_viewport().set_input_as_handled()
	if Controls.rebind_pad(waiting_pad, pd):
		message.text = "%s bound to %s" % [Controls.LABELS[waiting_pad], Controls.pad_name(pd)]
		Sound.ui("confirm")
	else:
		message.text = "That gamepad input is already in use"
		Sound.ui("deny")
	var btn: Button = pad_buttons[waiting_pad]
	waiting_pad = ""
	_refresh()
	btn.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if waiting_action != "" or waiting_pad != "":
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()


func _go_back() -> void:
	SaveData.save()
	if on_back.is_valid():
		on_back.call()

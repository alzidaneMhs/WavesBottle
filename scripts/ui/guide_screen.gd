class_name GuideScreen
extends Control

var main
var on_back: Callable
var topic := "basics"
var buttons: Dictionary = {}
var body: VBoxContainer
var scroller: ScrollContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.dim_layer(0.6))
	var c := UiKit.centered(self)
	var panel := UiKit.panel()
	c.add_child(panel)
	var v := UiKit.vbox(12)
	panel.add_child(v)
	var top := UiKit.hbox(16)
	v.add_child(top)
	top.add_child(UiKit.title("HOW TO PLAY", 40))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UiKit.label("Pick a topic on the left", 16, UiKit.DIM))
	var row := UiKit.hbox(18)
	v.add_child(row)
	var left := UiKit.vbox(8)
	row.add_child(left)
	for t in GameData.GUIDE:
		var id: String = t["id"]
		var b := UiKit.button(str(t["title"]), _pick.bind(id), 300)
		b.toggle_mode = true
		left.add_child(b)
		buttons[id] = b
	var cb := UiKit.button("Controls", _pick.bind("controls"), 300)
	cb.toggle_mode = true
	left.add_child(cb)
	buttons["controls"] = cb
	left.add_child(UiKit.spacer(10))
	var train_b := UiKit.button("Play Training", _training, 300)
	train_b.add_theme_color_override("font_color", UiKit.GOLD)
	left.add_child(train_b)
	left.add_child(UiKit.button("Back", _back, 300))
	scroller = UiKit.scroll(Vector2(980, 700))
	row.add_child(scroller)
	body = UiKit.vbox(10)
	body.custom_minimum_size = Vector2(950, 0)
	scroller.add_child(body)
	if not buttons.has(topic):
		topic = "basics"
	_show()
	(buttons[topic] as Button).call_deferred("grab_focus")


static func fill(text: String) -> String:
	var out := text
	for a in Controls.ORDER:
		var key := "{%s}" % a
		if out.contains(key):
			out = out.replace(key, Controls.short_text(a))
	return out


func _show() -> void:
	for k in buttons.keys():
		(buttons[k] as Button).set_pressed_no_signal(k == topic)
	for ch in body.get_children():
		ch.queue_free()
	scroller.scroll_vertical = 0
	if topic == "controls":
		_controls()
		return
	var t: Dictionary = {}
	for x in GameData.GUIDE:
		if x["id"] == topic:
			t = x
	body.add_child(UiKit.label(str(t["title"]), 32, UiKit.ACCENT))
	for line in t["lines"]:
		var card := UiKit.card(Color(0.2, 0.5, 0.65), 14.0)
		body.add_child(card)
		var cv := UiKit.vbox(4)
		card.add_child(cv)
		cv.add_child(UiKit.label(fill(str(line[0])), 18, UiKit.GOLD))
		cv.add_child(UiKit.wrap(fill(str(line[1])), 17, UiKit.TEXT, 900))


func _controls() -> void:
	body.add_child(UiKit.label("Controls", 32, UiKit.ACCENT))
	body.add_child(UiKit.wrap("You can change any key in Settings. A gamepad works too; the screen switches to gamepad buttons as soon as you use one.", 16, UiKit.DIM, 900))
	var card := UiKit.card()
	body.add_child(card)
	var cv := UiKit.vbox(6)
	card.add_child(cv)
	for a in Controls.ORDER:
		var h := UiKit.hbox(12)
		var l := UiKit.label(str(Controls.LABELS[a]), 17, UiKit.TEXT)
		l.custom_minimum_size = Vector2(380, 0)
		h.add_child(l)
		h.add_child(UiKit.label(Controls.pad_text(a) if Controls.using_pad else Controls.key_text(a), 17, UiKit.GOLD))
		cv.add_child(h)


func _pick(id: String) -> void:
	topic = id
	_show()


func _training() -> void:
	main.start_training()


func _back() -> void:
	if on_back.is_valid():
		on_back.call()


func _unhandled_input(event: InputEvent) -> void:
	var sh := UiKit.pad_shoulder(event)
	if sh != 0:
		get_viewport().set_input_as_handled()
		var ids: Array = buttons.keys()
		topic = ids[posmod(ids.find(topic) + sh, ids.size())]
		_show()
		(buttons[topic] as Button).grab_focus()
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()

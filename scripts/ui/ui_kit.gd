class_name UiKit
extends RefCounted

const ACCENT := Color(0.30, 0.90, 1.00)
const PINK := Color(1.00, 0.42, 0.78)
const GOLD := Color(1.00, 0.85, 0.40)
const TEXT := Color(0.86, 0.94, 1.00)
const DIM := Color(0.55, 0.66, 0.76)
const PANEL := Color(0.02, 0.05, 0.10, 0.94)


static func box(bg: Color, border: Color, bw: int = 2, radius: int = 6, margin: float = 14.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.55
	sb.content_margin_bottom = margin * 0.55
	return sb


static func ui_scale() -> float:
	return clampf(float(SaveData.setting("ui_scale")), 0.85, 1.3)


static func fs(size: int) -> int:
	return int(round(float(size) * ui_scale()))


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = fs(20)
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, box(Color(0.04, 0.10, 0.17, 0.95), Color(0.20, 0.50, 0.65)))
		t.set_stylebox("hover", type, box(Color(0.06, 0.18, 0.28, 0.98), ACCENT))
		t.set_stylebox("pressed", type, box(Color(0.10, 0.28, 0.38, 1.0), ACCENT))
		t.set_stylebox("focus", type, box(Color(0, 0, 0, 0), ACCENT, 2))
		t.set_stylebox("disabled", type, box(Color(0.03, 0.05, 0.08, 0.85), Color(0.14, 0.20, 0.26)))
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, Color.WHITE)
		t.set_color("font_pressed_color", type, ACCENT)
		t.set_color("font_focus_color", type, Color.WHITE)
		t.set_color("font_disabled_color", type, Color(0.40, 0.46, 0.52))
	t.set_color("font_color", "Label", TEXT)
	for st in ["normal", "pressed", "focus", "disabled", "hover_pressed"]:
		t.set_stylebox(st, "CheckBox", box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 6, 8.0))
	t.set_stylebox("hover", "CheckBox", box(Color(0.06, 0.18, 0.28, 0.6), Color(0, 0, 0, 0), 0, 6, 8.0))
	t.set_icon("checked", "CheckBox", check_icon(true))
	t.set_icon("unchecked", "CheckBox", check_icon(false))
	t.set_icon("checked_disabled", "CheckBox", check_icon(true))
	t.set_icon("unchecked_disabled", "CheckBox", check_icon(false))
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_pressed_color", "CheckBox", ACCENT)
	t.set_color("font_hover_color", "CheckBox", Color.WHITE)
	t.set_stylebox("panel", "PanelContainer", box(PANEL, Color(0.15, 0.40, 0.55), 2, 10, 22.0))
	t.set_stylebox("panel", "PopupMenu", box(Color(0.03, 0.07, 0.12, 0.98), Color(0.2, 0.5, 0.65), 1, 4, 8.0))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_stylebox("hover", "PopupMenu", box(Color(0.08, 0.22, 0.32), Color(0, 0, 0, 0), 0, 4, 6.0))
	t.set_stylebox("normal", "LineEdit", box(Color(0.03, 0.07, 0.12, 0.95), Color(0.2, 0.5, 0.65), 1, 6, 10.0))
	t.set_stylebox("focus", "LineEdit", box(Color(0, 0, 0, 0), ACCENT, 2, 6, 10.0))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_stylebox("panel", "Panel", box(PANEL, Color(0.15, 0.40, 0.55), 2, 10, 22.0))
	return t


static func check_icon(on: bool) -> ImageTexture:
	var n := 24
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in n:
		for x in n:
			var edge := x < 2 or y < 2 or x >= n - 2 or y >= n - 2
			if edge:
				img.set_pixel(x, y, ACCENT)
			elif x > 2 and y > 2 and x < n - 3 and y < n - 3:
				img.set_pixel(x, y, Color(0.02, 0.06, 0.1, 0.9))
			if on and x >= 6 and y >= 6 and x < n - 6 and y < n - 6:
				img.set_pixel(x, y, ACCENT)
	return ImageTexture.create_from_image(img)


static func button(text: String, cb: Callable, width: float = 320.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 48)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func() -> void:
		Sound.ui("click")
		if cb.is_valid():
			cb.call()
	)
	return b


static func label(text: String, size: int = 20, color: Color = TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", fs(size))
	l.add_theme_color_override("font_color", color)
	return l


static func title(text: String, size: int = 56, color: Color = ACCENT) -> Label:
	var l := label(text, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_constant_override("outline_size", 10)
	l.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.06, 0.9))
	return l


static func vbox(sep: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


static func dim_layer(alpha: float = 0.6) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.0, 0.01, 0.03, alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r


static func centered(root: Control) -> CenterContainer:
	var c := FitCenter.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(c)
	return c


static func panel() -> PanelContainer:
	return PanelContainer.new()


static func wrap(text: String, size: int, color: Color, width: float) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


static func card(border: Color = Color(0.15, 0.40, 0.55), margin: float = 14.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(Color(0.03, 0.07, 0.12, 0.92), border, 1, 8, margin))
	return p


static func bar(ratio: float, color: Color, width: float, height: float = 8.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, height)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.size = Vector2(width, height)
	c.add_child(bg)
	var fg := ColorRect.new()
	fg.color = color
	fg.size = Vector2(width * clampf(ratio, 0.0, 1.0), height)
	c.add_child(fg)
	return c


static func option(items: Array, selected: int, cb: Callable, width: float = 300.0) -> OptionButton:
	var o := OptionButton.new()
	for it in items:
		o.add_item(str(it))
	if items.size() > 0:
		o.selected = clampi(selected, 0, items.size() - 1)
	o.custom_minimum_size = Vector2(width, 38)
	o.fit_to_longest_item = false
	o.clip_text = true
	o.item_selected.connect(func(i: int) -> void:
		Sound.ui("click")
		if cb.is_valid():
			cb.call(i)
	)
	return o


static func scroll(size: Vector2) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = size
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	return sc


static func pad_shoulder(event: InputEvent) -> int:
	var jb := event as InputEventJoypadButton
	if jb == null or not jb.pressed:
		return 0
	if jb.button_index == JOY_BUTTON_LEFT_SHOULDER:
		return -1
	if jb.button_index == JOY_BUTTON_RIGHT_SHOULDER:
		return 1
	return 0


static func chip(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(Color(color, 0.12), Color(color, 0.6), 1, 12, 10.0))
	p.add_child(label(text, 15, color))
	return p

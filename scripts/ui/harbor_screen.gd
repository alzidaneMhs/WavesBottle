class_name HarborScreen
extends Control

const TABS := [["campaign", "Campaign"], ["fitting", "Fitting Dock"], ["research", "Research"], ["fleet", "Fleet"], ["operations", "Operations"], ["facilities", "Facilities"], ["contracts", "Contracts"]]
const CONTENT := Vector2(1270, 684)

var main
var tab := "campaign"
var content_holder: Control
var current: Control = null
var res_box: HBoxContainer
var tab_buttons: Dictionary = {}
var prompt: Control = null
var selected_region := 0
var fleet_selected := ""
var fitting_ship := ""
var help_text: Label
var help_popup: Control = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.dim_layer(0.55))
	var c := UiKit.centered(self)
	var panel := UiKit.panel()
	c.add_child(panel)
	var v := UiKit.vbox(12)
	panel.add_child(v)
	var top := UiKit.hbox(18)
	v.add_child(top)
	top.add_child(UiKit.title("HARBOR", 40))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	res_box = UiKit.hbox(10)
	res_box.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(res_box)
	var body := UiKit.hbox(16)
	v.add_child(body)
	var left := UiKit.vbox(8)
	body.add_child(left)
	for t in TABS:
		var id: String = t[0]
		if not Profile.tab_unlocked(id):
			continue
		var txt := str(t[1])
		if id != "campaign" and not Profile.help_seen("tab_" + id):
			txt += "  NEW"
		var b := UiKit.button(txt, show_tab.bind(id), 210)
		b.toggle_mode = true
		if txt.ends_with("NEW"):
			b.add_theme_color_override("font_color", UiKit.GOLD)
		left.add_child(b)
		tab_buttons[id] = b
	var locked := TABS.size() - tab_buttons.size()
	if locked > 0:
		left.add_child(UiKit.wrap("%d more section%s open as you clear stages" % [locked, "" if locked == 1 else "s"], 13, UiKit.DIM, 210))
	left.add_child(UiKit.spacer(14))
	left.add_child(UiKit.button("How to Play", _guide, 210))
	if Profile.tab_unlocked("fitting"):
		left.add_child(UiKit.button("Sea Trials", _sea_trials, 210))
	left.add_child(UiKit.button("Codex", _open_codex, 210))
	left.add_child(UiKit.button("Main Menu", _leave.bind("menu"), 210))
	var right := UiKit.vbox(8)
	body.add_child(right)
	var strip := UiKit.hbox(12)
	strip.custom_minimum_size = Vector2(CONTENT.x, 38)
	right.add_child(strip)
	help_text = UiKit.label("", 17, UiKit.TEXT)
	help_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	strip.add_child(help_text)
	var hb := UiKit.button("?  Help", _open_help, 130)
	hb.custom_minimum_size = Vector2(130, 38)
	strip.add_child(hb)
	content_holder = Control.new()
	content_holder.custom_minimum_size = CONTENT
	right.add_child(content_holder)
	if not Profile.tab_unlocked(tab):
		tab = "campaign"
	if selected_region <= 0:
		selected_region = 1
		for r in GameData.REGIONS:
			if Profile.region_unlocked(int(r["id"])):
				selected_region = int(r["id"])
	refresh_resources()
	_show(tab)
	if tab_buttons.has(tab):
		(tab_buttons[tab] as Button).call_deferred("grab_focus")


func refresh_resources() -> void:
	for ch in res_box.get_children():
		ch.queue_free()
	res_box.add_child(UiKit.chip("SALVAGE  %d" % Profile.res("salvage"), GameData.COL_SALVAGE))
	res_box.add_child(UiKit.chip("RESEARCH  %d" % Profile.res("research"), GameData.COL_RESEARCH))
	res_box.add_child(UiKit.chip("INTEL  %d" % Profile.res("intel"), GameData.COL_INTEL))
	var ship: String = Profile.selected_ship()
	res_box.add_child(UiKit.chip("%s  |  %s" % [GameData.SHIPS[ship]["name"], GameData.DIFFICULTIES[Profile.selected_difficulty()]["name"]], UiKit.ACCENT))


func refresh() -> void:
	refresh_resources()
	_show(tab)


func show_tab(id: String) -> void:
	var page := page_node()
	if page != null and page.has_method("has_unsaved") and page.call("has_unsaved") and id != tab:
		_ask_discard(id)
		_sync_buttons()
		return
	_show(id)


func _sync_buttons() -> void:
	for k in tab_buttons.keys():
		(tab_buttons[k] as Button).set_pressed_no_signal(k == tab)


func _show(id: String) -> void:
	tab = id
	_sync_buttons()
	var th: Array = GameData.TAB_HELP.get(id, ["", "", []])
	help_text.text = str(th[1])
	if not Profile.help_seen("tab_" + id):
		call_deferred("_open_help")
	if current != null:
		current.queue_free()
	var sc := UiKit.scroll(CONTENT)
	content_holder.add_child(sc)
	var page: Control
	match id:
		"fleet":
			page = FleetTab.new()
		"fitting":
			page = FittingTab.new()
		"research":
			page = ResearchTab.new()
		"facilities":
			page = FacilitiesTab.new()
		"contracts":
			page = ContractsTab.new()
		"operations":
			page = OperationsTab.new()
		_:
			page = CampaignTab.new()
	page.set("harbor", self)
	page.custom_minimum_size = Vector2(CONTENT.x - 20.0, 0)
	sc.add_child(page)
	current = sc
	page.call("build")


func page_node() -> Control:
	if current == null or current.get_child_count() == 0:
		return null
	return current.get_child(0) as Control


func _ask_discard(target: String) -> void:
	if prompt != null:
		prompt.queue_free()
	prompt = UiKit.dim_layer(0.6)
	add_child(prompt)
	var c := UiKit.centered(prompt)
	var p := UiKit.panel()
	c.add_child(p)
	var v := UiKit.vbox(12)
	p.add_child(v)
	v.add_child(UiKit.label("Unsaved build changes", 24, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.label("Save them before leaving the Fitting Dock?", 17, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var h := UiKit.hbox(12)
	v.add_child(h)
	var save_b := UiKit.button("Save", _resolve_prompt.bind(target, "save"), 160)
	h.add_child(save_b)
	save_b.call_deferred("grab_focus")
	h.add_child(UiKit.button("Discard", _resolve_prompt.bind(target, "discard"), 160))
	h.add_child(UiKit.button("Cancel", _resolve_prompt.bind(target, "cancel"), 160))


func _resolve_prompt(target: String, choice: String) -> void:
	if prompt != null:
		prompt.queue_free()
		prompt = null
	var page := page_node()
	match choice:
		"save":
			if page != null and page.has_method("save_current"):
				page.call("save_current")
		"cancel":
			return
	if target == "menu":
		main.show_main_menu()
	elif target == "codex":
		main.show_codex(Callable(main, "show_harbor").bind(tab))
	elif target == "trials":
		main.start_practice(Profile.selected_ship())
	elif target == "guide":
		main.show_guide(Callable(main, "show_harbor").bind(tab), "harbor")
	elif target == "settings":
		main.open_settings(Callable(main, "show_harbor").bind(tab))
	else:
		_show(target)


func _guard(target: String) -> bool:
	var page := page_node()
	if page != null and page.has_method("has_unsaved") and page.call("has_unsaved"):
		_ask_discard(target)
		return true
	return false


func _open_help() -> void:
	if help_popup != null:
		help_popup.queue_free()
	var th: Array = GameData.TAB_HELP.get(tab, [])
	if th.is_empty():
		return
	help_popup = UiKit.dim_layer(0.6)
	add_child(help_popup)
	var c := UiKit.centered(help_popup)
	var p := UiKit.panel()
	c.add_child(p)
	var v := UiKit.vbox(12)
	v.custom_minimum_size = Vector2(700, 0)
	p.add_child(v)
	v.add_child(UiKit.label(str(th[0]), 32, UiKit.ACCENT))
	v.add_child(UiKit.wrap(str(th[1]), 19, Color.WHITE, 700))
	for line in th[2]:
		var h := UiKit.hbox(10)
		h.add_child(UiKit.label("-", 17, UiKit.GOLD))
		h.add_child(UiKit.wrap(str(line), 17, UiKit.TEXT, 660))
		v.add_child(h)
	var row := UiKit.hbox(12)
	v.add_child(row)
	var ok := UiKit.button("Got it", _close_help, 240)
	row.add_child(ok)
	row.add_child(UiKit.button("Open full guide", _guide_from_help, 260))
	ok.call_deferred("grab_focus")


func _close_help() -> void:
	if help_popup != null:
		help_popup.queue_free()
		help_popup = null
	if not Profile.help_seen("tab_" + tab):
		Profile.mark_help("tab_" + tab)
		if tab_buttons.has(tab):
			var b: Button = tab_buttons[tab]
			b.text = b.text.trim_suffix("  NEW")
			b.remove_theme_color_override("font_color")
	if tab_buttons.has(tab):
		(tab_buttons[tab] as Button).grab_focus()


func _guide_from_help() -> void:
	_close_help()
	_guide()


func _guide() -> void:
	if not _guard("guide"):
		main.show_guide(Callable(main, "show_harbor").bind(tab), "harbor")


func _open_codex() -> void:
	if not _guard("codex"):
		main.show_codex(Callable(main, "show_harbor").bind(tab))


func _sea_trials() -> void:
	if not _guard("trials"):
		main.start_practice(Profile.selected_ship())


func _settings() -> void:
	if not _guard("settings"):
		main.open_settings(Callable(main, "show_harbor").bind(tab))


func _leave(target: String) -> void:
	if not _guard(target):
		main.show_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if prompt != null:
		return
	if help_popup != null:
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_close_help()
		return
	var sh := UiKit.pad_shoulder(event)
	if sh != 0:
		get_viewport().set_input_as_handled()
		var ids: Array = tab_buttons.keys()
		var nxt: String = ids[posmod(ids.find(tab) + sh, ids.size())]
		show_tab(nxt)
		if tab == nxt and tab_buttons.has(nxt):
			(tab_buttons[nxt] as Button).grab_focus()
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave("menu")

class_name HarborScreen
extends Control

const TABS := [["campaign", "Campaign"], ["fleet", "Fleet"], ["fitting", "Fitting Dock"], ["research", "Research"], ["facilities", "Facilities"], ["contracts", "Contracts"], ["operations", "Operations"]]
const CONTENT := Vector2(1270, 730)

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
		var b := UiKit.button(str(t[1]), show_tab.bind(id), 210)
		b.toggle_mode = true
		left.add_child(b)
		tab_buttons[id] = b
	left.add_child(UiKit.spacer(14))
	left.add_child(UiKit.button("Codex", _open_codex, 210))
	left.add_child(UiKit.button("Sea Trials", _sea_trials, 210))
	left.add_child(UiKit.button("Settings", _settings, 210))
	left.add_child(UiKit.button("Main Menu", _leave.bind("menu"), 210))
	content_holder = Control.new()
	content_holder.custom_minimum_size = CONTENT
	body.add_child(content_holder)
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
	var sh := UiKit.pad_shoulder(event)
	if sh != 0:
		get_viewport().set_input_as_handled()
		var ids: Array = []
		for t in TABS:
			ids.append(t[0])
		var nxt: String = ids[posmod(ids.find(tab) + sh, ids.size())]
		show_tab(nxt)
		if tab == nxt and tab_buttons.has(nxt):
			(tab_buttons[nxt] as Button).grab_focus()
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave("menu")

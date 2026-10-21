extends Node

var ui_theme: Theme
var bg_layer: CanvasLayer
var backdrop: ColorRect
var ui_layer: CanvasLayer
var screen: Control = null
var run: Run = null
var state := "menu"
var last_launch: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_theme = UiKit.make_theme()
	bg_layer = CanvasLayer.new()
	bg_layer.layer = -5
	add_child(bg_layer)
	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ocean.gdshader")
	mat.set_shader_parameter("rect_size", Vector2(2400, 1350))
	mat.set_shader_parameter("use_fog", 0.0)
	backdrop.material = mat
	bg_layer.add_child(backdrop)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	Profile.refill_contracts()
	show_main_menu()


func _set_screen(c: Control) -> void:
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	screen = c
	if c != null:
		c.theme = ui_theme
		ui_layer.add_child(c)
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _clear_run() -> void:
	if run != null and is_instance_valid(run):
		run.queue_free()
	run = null
	get_tree().paused = false


func show_main_menu() -> void:
	_clear_run()
	state = "menu"
	backdrop.visible = true
	Sound.set_music(0.7, 0.0, 0.0, 0.0)
	var m := MainMenu.new()
	m.main = self
	_set_screen(m)


func show_harbor(tab: String = "campaign") -> void:
	_clear_run()
	state = "menu"
	backdrop.visible = true
	Sound.set_music(0.7, 0.1, 0.0, 0.0)
	var h := HarborScreen.new()
	h.main = self
	h.tab = tab
	_set_screen(h)


func show_codex(back: Callable) -> void:
	var c := CodexScreen.new()
	c.main = self
	c.on_back = back
	_set_screen(c)


func show_credits() -> void:
	var c := CreditsScreen.new()
	c.main = self
	_set_screen(c)


func open_settings(back: Callable) -> void:
	var s := SettingsScreen.new()
	s.on_back = _settings_back.bind(back)
	_set_screen(s)


func _settings_back(back: Callable) -> void:
	ui_theme = UiKit.make_theme()
	if back.is_valid():
		back.call()


func open_briefing(source: Dictionary) -> void:
	_clear_run()
	backdrop.visible = true
	var b := BriefingScreen.new()
	b.main = self
	b.source = source
	_set_screen(b)


func launch(cfg: Dictionary, ship: String, build: Dictionary, source: Dictionary = {}) -> void:
	last_launch = {"cfg": cfg, "ship": ship, "build": build, "source": source}
	_start(cfg, ship, build)


func start_practice(ship: String) -> void:
	var build: Dictionary
	if Profile.ship_unlocked(ship):
		build = Profile.active_build(ship)
	else:
		build = Profile.default_build(ship)
	var cfg := MissionBuilder.practice()
	last_launch = {"cfg": cfg, "ship": ship, "build": build, "source": {"kind": "practice"}}
	_start(cfg, ship, build)


func _start(cfg: Dictionary, ship: String, build: Dictionary) -> void:
	_clear_run()
	_set_screen(null)
	run = Run.new()
	run.cfg = cfg
	run.ship_id = ship
	run.build = build
	run.wave_cleared.connect(_on_wave_cleared)
	run.run_finished.connect(_on_run_finished)
	add_child(run)
	backdrop.visible = false
	state = "combat"
	Sound.ui("confirm")


func retry() -> void:
	if last_launch.is_empty():
		show_harbor()
		return
	var cfg: Dictionary = last_launch["cfg"]
	var src: Dictionary = last_launch.get("source", {})
	if src.get("kind", "") == "op" and str(src.get("id", "")) != "classic":
		cfg = MissionBuilder.operation(str(src["id"]), str(cfg.get("difficulty", "standard")), randi() % 900000 + 100000)
		last_launch["cfg"] = cfg
	_start(cfg, str(last_launch["ship"]), last_launch["build"])


func abandon() -> void:
	var mode := run.mode if run != null else ""
	_clear_run()
	if mode == "practice" or mode == "classic":
		show_harbor("operations")
	else:
		show_harbor("campaign")


func _input(event: InputEvent) -> void:
	var ke := event as InputEventKey
	if ke == null or not ke.pressed or ke.echo:
		return
	if ke.keycode == KEY_F11 or (ke.keycode == KEY_ENTER and ke.alt_pressed):
		get_viewport().set_input_as_handled()
		SaveData.set_setting("fullscreen", not bool(SaveData.setting("fullscreen")))


func _unhandled_input(event: InputEvent) -> void:
	if state == "combat" and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		open_pause()


func open_pause() -> void:
	if run == null or run.state == "ended":
		return
	state = "paused"
	get_tree().paused = true
	_set_hud(false)
	reopen_pause()


func reopen_pause() -> void:
	var p := PauseMenu.new()
	p.main = self
	p.run = run
	_set_screen(p)


func resume() -> void:
	_set_hud(true)
	_set_screen(null)
	state = "combat"
	get_tree().paused = false
	if run != null:
		run.player.fire_lock = true


func _set_hud(on: bool) -> void:
	if run != null and is_instance_valid(run) and run.hud_layer != null:
		run.hud_layer.visible = on


func _on_wave_cleared(_wave: int, report: Dictionary) -> void:
	state = "shipyard"
	get_tree().paused = true
	_set_hud(false)
	var y := ShipyardScreen.new()
	y.main = self
	y.run = run
	y.report = report
	_set_screen(y)


func continue_run() -> void:
	_set_hud(true)
	_set_screen(null)
	state = "combat"
	get_tree().paused = false
	run.next_wave()


func _on_run_finished(result: Dictionary) -> void:
	state = "results"
	get_tree().paused = true
	_set_hud(false)
	var mode: String = str(result.get("mode", "campaign"))
	if mode == "classic" or mode == "practice":
		var notes: Array = SaveData.record_run(result)
		if mode == "classic":
			var banked := int(round(float(result.get("salvage_earned", 0)) * 0.2))
			Profile.add_res("salvage", banked)
			var xp := 30 + int(result.get("kills", 0)) * 2 + int(result.get("wave", 0)) * 10
			var lv: Array = Profile.add_xp(str(result.get("ship", "wayfarer")), xp)
			Profile.track("salvage", "", banked)
			Profile.track("wake_tier", "", int(result.get("max_tier", 0)))
			SaveData.save()
			notes.append("+%d Salvage banked, +%d mastery XP" % [banked, xp])
			for l in lv:
				if GameData.MASTERY_UNLOCKS.has(l):
					notes.append("Mastery %d: %s" % [l, GameData.MASTERY_UNLOCKS[l]])
		var r := SummaryScreen.new()
		r.main = self
		r.summary = result
		r.notes = notes
		_set_screen(r)
		return
	var rewards: Dictionary = Profile.record_mission(result)
	var d := DebriefScreen.new()
	d.main = self
	d.result = result
	d.rewards = rewards
	d.source = last_launch.get("source", {})
	_set_screen(d)


func quit_game() -> void:
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveData.save()

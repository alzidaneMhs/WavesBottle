class_name TrainingCoach
extends Node2D

const STEPS := [
	["throttle", "Welcome aboard, Captain!", "Press [{throttle_up}] to raise the throttle. The ship keeps that speed, so you don't have to hold the key.", "throttle"],
	["rings", "Steering", "Steer with [{turn_left}] and [{turn_right}] and sail through the glowing rings. Start your turns early, because the ship is heavy.", ""],
	["port", "Your guns face SIDEWAYS", "Your main guns point LEFT and RIGHT, not forward. Press [{fire_port}] or the left mouse button to fire the LEFT guns.", "port"],
	["starboard", "The other side", "Press [{fire_starboard}] or the right mouse button to fire the RIGHT guns.", "starboard"],
	["bow", "Front gun", "Press [{fire_bow}] to fire the small Bow gun straight ahead. It is weaker, but it can hit what is in front of you.", "bow"],
	["first_kill", "Your first enemy", "An enemy boat is coming. Turn so it is on your LEFT or RIGHT side, then fire that side. Red arrows at the screen edge point to enemies.", ""],
	["wake", "Build your Wake", "Hits and kills fill your WAKE meter in the top right. A higher Wake means more score and a better grade. Sink both boats.", "wake"],
	["ability", "Ship ability", "Press [{ability}] to use your ship ability: %s", "ability"],
	["module", "Utility module", "Press [{module_1}] to use your module: %s", "module"],
	["drift", "Drifting (optional)", "Get some speed, then hold [{drift}] while turning to slide sideways. It swings your guns onto targets quickly. This step skips itself after a few seconds.", ""],
	["done", "Training complete!", "You know the basics. Press Play on the main menu to start the campaign, and open How to Play whenever you need a reminder. Press Enter to finish.", ""],
]

var run
var step := 0
var pause_timer := 0.0
var step_time := 0.0
var kills_at := 0
var rings: Array = []
var ring_index := 0
var clock := 0.0
var finished := false


func _ready() -> void:
	z_index = 1
	_enter()


func current() -> Array:
	return STEPS[step]


func step_id() -> String:
	return str(STEPS[step][0])


func highlight() -> String:
	if pause_timer > 0.0:
		return ""
	return str(STEPS[step][3])


func progress_text() -> String:
	return "TRAINING  %d / %d" % [step + 1, STEPS.size()]


func title() -> String:
	return str(STEPS[step][1])


func text() -> String:
	var t: String = str(STEPS[step][2])
	match step_id():
		"ability":
			var ab: Dictionary = GameData.ABILITIES[run.stats.ability]
			t = t % ("%s. %s" % [ab["name"], ab["desc"]])
		"module":
			var md: Dictionary = GameData.ACTIVE_MODULES[run.stats.modules[0]]
			t = t % ("%s. %s" % [md["name"], md["desc"]])
		"rings":
			t += "  (%d / %d)" % [mini(ring_index + 1, rings.size()), rings.size()]
		"wake":
			t += "  (%d / 2)" % clampi(run.kills - kills_at, 0, 2)
	return GuideScreen.fill(t)


func _applies(id: String) -> bool:
	match id:
		"port", "starboard", "bow":
			return run.player.slots.has(id)
		"ability":
			return run.stats.ability != ""
		"module":
			return not run.stats.modules.is_empty()
	return true


func _enter() -> void:
	while step < STEPS.size() - 1 and not _applies(step_id()):
		step += 1
	step_time = 0.0
	kills_at = run.kills
	match step_id():
		"rings":
			_place_rings()
		"first_kill":
			_spawn(1, 0.55)
		"wake":
			_spawn(2, 0.8)


func _place_rings() -> void:
	rings.clear()
	ring_index = 0
	var mid: Vector2 = run.arena.size * 0.5
	var f := Vector2.RIGHT.rotated(run.player.rotation)
	var side := f.rotated(PI / 2.0)
	var a := mid + f * 460.0 + side * 280.0
	var b := mid - side * 320.0 + f * 160.0
	for pt in [a, b]:
		var q: Vector2 = pt
		q.x = clampf(q.x, 260.0, run.arena.size.x - 260.0)
		q.y = clampf(q.y, 260.0, run.arena.size.y - 260.0)
		rings.append(q)


func _spawn(count: int, hull_scale: float) -> void:
	var p: Vector2 = run.player.position
	var f := Vector2.RIGHT.rotated(run.player.rotation)
	var side := f.rotated(-PI / 2.0)
	for i in count:
		var pos := p + side * 640.0 + f * (float(i) * 260.0 - 80.0)
		pos.x = clampf(pos.x, 380.0, run.arena.size.x - 380.0)
		pos.y = clampf(pos.y, 380.0, run.arena.size.y - 380.0)
		run.fx_over.spawn_cue(pos, false)
		var e: Enemy = run.spawn_enemy("gunboat", pos, [])
		if e != null:
			e.hull = e.max_hull * hull_scale


func on_event(id: String) -> void:
	if pause_timer > 0.0 or finished:
		return
	match step_id():
		"throttle":
			if id == "throttle" and run.player.throttle > 0.3:
				_complete()
		"port", "starboard", "bow", "ability", "module", "drift":
			if id == step_id():
				_complete()


func _complete() -> void:
	Sound.ui("confirm")
	run.fx_over.text(run.player.position + Vector2(0, -60), "NICE!", UiKit.GOLD, 24, 1.0)
	pause_timer = 1.1


func _process(delta: float) -> void:
	clock += delta
	if finished:
		return
	if pause_timer > 0.0:
		pause_timer -= delta
		if pause_timer <= 0.0:
			step = mini(step + 1, STEPS.size() - 1)
			_enter()
		queue_redraw()
		return
	step_time += delta
	match step_id():
		"throttle":
			if run.player.throttle > 0.3:
				_complete()
		"rings":
			if ring_index < rings.size() and run.player.position.distance_to(rings[ring_index]) < 95.0:
				ring_index += 1
				Sound.ui("click")
				if ring_index >= rings.size():
					_complete()
		"first_kill":
			if run.kills - kills_at >= 1 or (step_time > 4.0 and _hostiles() == 0):
				_complete()
		"wake":
			if run.kills - kills_at >= 2 or (step_time > 4.0 and _hostiles() == 0):
				_complete()
		"drift":
			if step_time > 14.0:
				_complete()
		"done":
			if step_time > 30.0:
				_finish()
	queue_redraw()


func _hostiles() -> int:
	var n := 0
	for e in run.enemies:
		if is_instance_valid(e) and e.alive:
			n += 1
	return n


func _unhandled_input(event: InputEvent) -> void:
	if finished or step_id() != "done" or step_time < 0.6:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ability"):
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	finished = true
	Profile.mark_help("training")
	var m = run.get_parent()
	if m != null and m.has_method("finish_training"):
		m.call_deferred("finish_training")


func _draw() -> void:
	if step_id() != "rings":
		return
	for i in rings.size():
		var c: Vector2 = rings[i]
		var done := i < ring_index
		var active := i == ring_index
		var col := Color(0.4, 1.0, 0.7, 0.35) if done else (UiKit.GOLD if active else Color(UiKit.GOLD, 0.35))
		var pulse := 0.0 if not active else 8.0 * sin(clock * 5.0)
		draw_arc(c, 90.0 + pulse, 0.0, TAU, 48, col, 5.0, true)
		draw_arc(c, 70.0, 0.0, TAU, 48, Color(col, col.a * 0.4), 2.0, true)
		if active:
			var p: Vector2 = run.player.position
			var d := c - p
			if d.length() > 160.0:
				var n := d.normalized()
				for k in 3:
					var base := p + n * (90.0 + float(k) * 34.0 + fposmod(clock * 40.0, 34.0))
					var tip := base + n * 14.0
					draw_line(base + n.rotated(2.4) * 12.0, tip, Color(UiKit.GOLD, 0.8), 3.0)
					draw_line(base + n.rotated(-2.4) * 12.0, tip, Color(UiKit.GOLD, 0.8), 3.0)

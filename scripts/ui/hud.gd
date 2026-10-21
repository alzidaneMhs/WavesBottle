class_name Hud
extends Control

const CARD_W := 140.0

var run
var font: Font
var banners: Array = []
var wake_pulse := 0.0
var damage_pulse := 0.0
var clock := 0.0
var zones: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font


func push_banner(title: String, sub: String, color: Color) -> void:
	if banners.size() >= 6:
		banners.remove_at(1 if banners.size() > 1 else 0)
	var dur := 2.6 if sub.length() < 60 else 3.6
	banners.append({"title": title, "sub": sub, "color": color, "time": dur, "max": dur})


func pulse_wake() -> void:
	wake_pulse = 0.6


func pulse_damage() -> void:
	damage_pulse = 0.5


func _process(delta: float) -> void:
	clock += delta
	wake_pulse = maxf(0.0, wake_pulse - delta)
	damage_pulse = maxf(0.0, damage_pulse - delta)
	if not banners.is_empty():
		var b: Dictionary = banners[0]
		var speed := 1.0 if banners.size() < 3 else 1.8
		b["time"] = float(b["time"]) - delta * speed
		if float(b["time"]) <= 0.0:
			banners.pop_front()
	queue_redraw()


func _fit(s: String, fsize: int, width: float) -> int:
	var f := fsize
	while f > 10 and font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, f).x > width:
		f -= 1
	return f


func _text(pos: Vector2, s: String, fsize: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	if width > 0.0:
		fsize = _fit(s, fsize, width)
	draw_string_outline(font, pos, s, align, width, fsize, 5, Color(0.0, 0.02, 0.05, 0.85 * color.a))
	draw_string(font, pos, s, align, width, fsize, color)


func _bar(rect: Rect2, ratio: float, fg: Color, bg: Color = Color(0, 0, 0, 0.55)) -> void:
	draw_rect(rect, bg)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), fg)
	draw_rect(rect, Color(fg, 0.6), false, 1.5)


func _panel(rect: Rect2) -> void:
	zones.append(rect)
	draw_rect(rect, Color(0.01, 0.03, 0.07, 0.78))
	draw_rect(rect, Color(0.2, 0.5, 0.65, 0.35), false, 1.0)


func _draw() -> void:
	if run == null or run.player == null:
		return
	var s := get_viewport_rect().size
	if s.x < 200.0 or s.y < 200.0:
		return
	zones.clear()
	if run.fog:
		_draw_fog(s)
		_draw_fog_cues()
	_draw_status(s)
	if run.mode == "practice":
		_draw_practice(s)
	elif run.logic != null:
		_draw_objectives(s)
	_draw_wake(s)
	_draw_wind(s)
	_draw_weapons(s)
	_draw_boss(s)
	_draw_tutorial(s)
	_draw_banner(s)
	_draw_footer(s)
	_draw_indicators(s)
	if run.jammed:
		_draw_jam(s)
	if damage_pulse > 0.0:
		var a := damage_pulse * (0.5 if SaveData.reduce_flash() else 0.9)
		var w := 26.0
		var c := Color(1.0, 0.15, 0.1, a * 0.5)
		draw_rect(Rect2(0, 0, s.x, w), c)
		draw_rect(Rect2(0, s.y - w, s.x, w), c)
		draw_rect(Rect2(0, 0, w, s.y), c)
		draw_rect(Rect2(s.x - w, 0, w, s.y), c)


func _draw_fog(s: Vector2) -> void:
	var xf := get_viewport().get_canvas_transform()
	var c: Vector2 = xf * (run.player.position as Vector2)
	var r0 := 330.0
	var far := s.length()
	var steps := 14
	for i in steps:
		var t := float(i) / float(steps - 1)
		var r := lerpf(r0, far, t)
		var width := (far - r0) / float(steps) + 4.0
		draw_arc(c, r + width * 0.5, 0.0, TAU, 64, Color(0.0, 0.01, 0.03, lerpf(0.25, 0.92, minf(1.0, t * 2.5))), width)


func _draw_jam(s: Vector2) -> void:
	var seed_i := int(clock * 12.0)
	for k in 14:
		var fy := fposmod(sin(float(k * 31 + seed_i) * 12.9898) * 43758.5, 1.0)
		var fw := fposmod(sin(float(k * 17 + seed_i) * 78.233) * 12345.6, 1.0)
		draw_rect(Rect2(0, fy * s.y, s.x * (0.2 + 0.8 * fw), 2.0), Color(0.8, 0.6, 1.0, 0.08))
	var a := 0.6 + 0.4 * sin(clock * 6.0)
	_text(Vector2(0, 96), "SENSORS JAMMED", 18, Color(0.85, 0.65, 1.0, a), HORIZONTAL_ALIGNMENT_CENTER, s.x)


func _draw_fog_cues() -> void:
	var xf := get_viewport().get_canvas_transform()
	for e in run.enemies:
		if not is_instance_valid(e) or not e.alive or e.kind != "longbow_sloop" or not e.aiming():
			continue
		var a: Vector2 = xf * (e.position as Vector2)
		var b: Vector2 = xf * ((e.position as Vector2) + (e.aim as Vector2) * float(e.data["range"]))
		draw_line(a, b, Color(GameData.COL_WARN, 0.85 if e.locked else 0.35), 3.0 if e.locked else 1.5)
		draw_circle(a, 6.0, Color(GameData.COL_WARN, 0.8))


func _draw_status(_s: Vector2) -> void:
	var p: PlayerShip = run.player
	var max_hull: float = run.stats.get_value("max_hull")
	var ratio := clampf(p.hull / max_hull, 0.0, 1.0)
	_panel(Rect2(12, 12, 340, 150))
	_text(Vector2(26, 40), "HULL  %s" % str(GameData.SHIPS[run.ship_id]["name"]).to_upper(), 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_LEFT, 200.0)
	_text(Vector2(26, 40), "%d / %d" % [int(ceil(p.hull)), int(max_hull)], 16, UiKit.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, 312.0)
	var hc := Color(0.3, 0.95, 0.75) if ratio > 0.3 else Color(1.0, 0.3, 0.25)
	_bar(Rect2(26, 48, 312, 16), ratio, hc)
	if p.bracing:
		draw_rect(Rect2(26, 48, 312, 16), Color(0.85, 0.95, 1.0, 0.8), false, 3.0)
	if ratio <= 0.3 and p.alive:
		var a := 0.6 + 0.4 * sin(clock * 8.0)
		_text(Vector2(26, 84), "HULL CRITICAL", 16, Color(1.0, 0.35, 0.3, a))
	elif p.god_mode:
		_text(Vector2(26, 84), "INVULNERABLE", 16, UiKit.GOLD)
	elif p.immune > 0.0:
		_text(Vector2(26, 84), "EVADING", 16, Color(0.6, 1.0, 0.85))
	elif p.tether_timer > 0.0:
		_text(Vector2(26, 84), "TETHERED %.0fs" % p.tether_timer, 16, Color(0.6, 1.0, 0.8, 0.6 + 0.4 * sin(clock * 8.0)))
	_text(Vector2(26, 84), "SALVAGE  %d" % run.salvage, 18, GameData.COL_SALVAGE, HORIZONTAL_ALIGNMENT_RIGHT, 312.0)
	match run.mode:
		"practice":
			_text(Vector2(26, 114), "SEA TRIALS", 18, UiKit.ACCENT)
			_text(Vector2(26, 140), "Enemies on the water: %d" % run.enemies.size(), 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_LEFT, 312.0)
		"classic":
			_text(Vector2(26, 114), "WAVE %d / %d" % [run.wave, GameData.MAX_WAVE], 18, UiKit.ACCENT)
			var remaining: int = run.enemies.size() + run.director.remaining()
			var info := "Enemies remaining: %d" % remaining
			if run.state == "intermission" or run.state == "shipyard":
				info = "Wave cleared - heading to the Shipyard"
			_text(Vector2(26, 140), info, 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_LEFT, 312.0)
		_:
			_text(Vector2(26, 114), str(run.cfg.get("label", "")), 18, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, 170.0)
			_text(Vector2(26, 140), str(run.cfg.get("name", "")), 16, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 200.0)
			var mins := int(run.time / 60.0)
			_text(Vector2(26, 140), "%d:%02d" % [mins, int(run.time) % 60], 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT, 312.0)
	_text(Vector2(26, 114), "SCORE  %d" % run.score, 18, UiKit.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, 312.0)


func _draw_objectives(_s: Vector2) -> void:
	var lg: MissionLogic = run.logic
	var opts: Array = lg.optional_states()
	var ally = lg.ally
	var modifier: String = str(run.cfg.get("modifier", ""))
	var h := 74.0 + opts.size() * 22.0
	if ally != null:
		h += 32.0
	if modifier != "":
		h += 22.0
	var top := 172.0
	_panel(Rect2(12, top, 340, h))
	_text(Vector2(26, top + 22.0), "OBJECTIVE", 14, UiKit.ACCENT)
	_text(Vector2(26, top + 46.0), lg.primary_text(), 17, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 312.0)
	_bar(Rect2(26, top + 54.0, 312, 6), lg.progress(), UiKit.ACCENT)
	var y := top + 82.0
	for o in opts:
		var st: int = int(o[1])
		var c := Vector2(32, y - 5.0)
		var col := UiKit.DIM
		if st == 1:
			col = Color(0.4, 1.0, 0.7)
			draw_circle(c, 6.0, col)
		elif st == -1:
			col = Color(1.0, 0.4, 0.35)
			draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), col, 2.0)
			draw_line(c + Vector2(-5, 5), c + Vector2(5, -5), col, 2.0)
		else:
			draw_arc(c, 6.0, 0.0, TAU, 16, col, 1.5, true)
		_text(Vector2(46, y), str(o[0]), 14, col if st != 0 else UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 290.0)
		y += 22.0
	if ally != null:
		_text(Vector2(26, y + 2.0), str(ally.title).to_upper(), 13, GameData.COL_ALLY, HORIZONTAL_ALIGNMENT_LEFT, 200.0)
		_bar(Rect2(26, y + 8.0, 312, 10), float(ally.hull) / float(ally.max_hull), GameData.COL_ALLY)
		y += 32.0
	if modifier != "":
		_text(Vector2(26, y + 2.0), "Modifier: " + str(GameData.MODIFIERS[modifier]["name"]), 13, Color(1.0, 0.75, 0.4), HORIZONTAL_ALIGNMENT_LEFT, 312.0)


func _draw_practice(_s: Vector2) -> void:
	var p: PlayerShip = run.player
	var basin := Profile.has_facility("training_basin")
	var lines := [
		["[1] Gunboat", "[2] Frigate"],
		["[3] Fireship", "[4] Rammer"],
		["[5] Courier", "[6] Galleon"],
		["[7] Boss" if basin else "[7] Boss *", "[8] Variant" if basin else "[8] Variant *"],
		["[9] Region II/III", "[M] Wreck field"],
		["[Y] Lightning field", "[O] Vent"],
		["[Q] Glow bloom", "[E] Rift"],
		["[Z] Minefield", "[X] Whirlpool"],
		["[C] Storm", "[V] Wreck"],
		["[B] Current", "[0] Clear all"],
		["[H] Repair", "[R] Toggle reefs"],
		["[T] Wind shift", ""],
		["[I] Invulnerable", "ON" if p.god_mode else "OFF"],
	]
	var top := 172.0
	var extra := 0.0 if basin else 20.0
	_panel(Rect2(12, top, 340, 34 + lines.size() * 22 + extra))
	_text(Vector2(26, top + 24.0), "SEA TRIALS CONTROLS", 15, UiKit.ACCENT)
	for i in lines.size():
		var ly := top + 48.0 + i * 22.0
		_text(Vector2(26, ly), str(lines[i][0]), 14, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 150.0)
		var col := UiKit.TEXT
		if i == lines.size() - 1:
			col = UiKit.GOLD if p.god_mode else UiKit.DIM
		_text(Vector2(186, ly), str(lines[i][1]), 14, col, HORIZONTAL_ALIGNMENT_LEFT, 150.0)
	if not basin:
		_text(Vector2(26, top + 48.0 + lines.size() * 22.0), "* needs the Training Basin", 12, UiKit.DIM)


func _draw_wake(s: Vector2) -> void:
	var wk: WakeSystem = run.wake
	var x := s.x - 352.0
	_panel(Rect2(x, 12, 340, 150))
	var col: Color = GameData.wake_color(wk.tier)
	var big := 34 + int(wake_pulse * 14.0)
	_text(Vector2(x + 14, 52), "WAKE %s" % GameData.WAKE_ROMAN[wk.tier], big, col)
	_text(Vector2(x + 14, 52), "x%.1f" % wk.multiplier(), 30, col, HORIZONTAL_ALIGNMENT_RIGHT, 312.0)
	_text(Vector2(x + 14, 76), str(GameData.WAKE_NAMES[wk.tier]).to_upper(), 15, UiKit.DIM)
	var next_txt := "MAX TIER" if wk.tier >= 5 else "next tier"
	_text(Vector2(x + 14, 76), next_txt, 13, UiKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT, 312.0)
	_bar(Rect2(x + 14, 84, 312, 12), wk.ratio(), col)
	var state_col := UiKit.ACCENT
	match wk.state_text():
		"DECAYING":
			state_col = Color(1.0, 0.45, 0.35, 0.7 + 0.3 * sin(clock * 10.0))
		"HOLD":
			state_col = UiKit.DIM
	draw_rect(Rect2(x + 14, 100, 312.0 * wk.grace_ratio(), 3), Color(state_col, 0.8))
	_text(Vector2(x + 14, 124), wk.state_text(), 16, state_col)
	if wk.state_text() == "STEADY":
		_text(Vector2(x + 110, 124), "decay in %.1fs" % maxf(0.0, wk.grace() - wk.idle), 14, UiKit.DIM)
	if run.scanner_timer > 0.0:
		_text(Vector2(x + 14, 124), "SCANNING %.0fs" % run.scanner_timer, 14, Color(0.6, 1.0, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, 312.0)
	if wk.reason_timer > 0.0:
		var rc := Color(0.6, 1.0, 0.85) if wk.reason_good else Color(1.0, 0.5, 0.4)
		rc.a = minf(1.0, wk.reason_timer * 1.5)
		_text(Vector2(x + 14, 150), wk.reason, 16, rc, HORIZONTAL_ALIGNMENT_LEFT, 312.0)


func _draw_wind(s: Vector2) -> void:
	var w: Wind = run.wind
	var x := s.x - 352.0
	_panel(Rect2(x, 170, 340, 132))
	var r := 44.0
	var c := Vector2(s.x - 76.0, 236.0)
	draw_circle(c, r + 4.0, Color(0.0, 0.02, 0.05, 0.6))
	draw_arc(c, r, 0.0, TAU, 40, Color(0.4, 0.75, 0.9, 0.5), 1.5, true)
	for i in 4:
		var d := Vector2.RIGHT.rotated(PI / 2.0 * float(i))
		draw_line(c + d * (r - 6.0), c + d * r, Color(0.5, 0.8, 0.95, 0.6), 1.5)
	_text(c + Vector2(-4, -r + 14.0), "N", 11, UiKit.DIM)
	var dir := w.dir()
	var alen := r * (0.45 + 0.5 * w.strength)
	var tip := c + dir * alen
	draw_line(c - dir * alen * 0.6, tip, Color(0.75, 0.95, 1.0), 3.0)
	draw_colored_polygon(PackedVector2Array([tip + dir * 8.0, tip + dir.rotated(PI / 2.0) * 6.0, tip - dir.rotated(PI / 2.0) * 6.0]), Color(0.75, 0.95, 1.0))
	_text(Vector2(x + 14, 196), "WIND", 15, UiKit.DIM)
	_text(Vector2(x + 14, 222), "Strength %d%%" % int(w.strength * 100.0), 18, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 200.0)
	var p: PlayerShip = run.player
	var eff: float = w.propulsion_factor(p.forward(), run.stats)
	var eff_txt := "Sailing %+d%%" % int(round((eff - 1.0) * 100.0))
	var ec := Color(0.5, 1.0, 0.7) if eff >= 1.0 else Color(1.0, 0.6, 0.5)
	_text(Vector2(x + 14, 248), eff_txt, 16, ec, HORIZONTAL_ALIGNMENT_LEFT, 200.0)
	if run.hazards.in_storm(p.position):
		var sa := 0.6 + 0.4 * sin(clock * 7.0)
		_text(Vector2(x + 14, 284), "IN STORM - strong gusts", 15, Color(0.85, 0.9, 1.0, sa), HORIZONTAL_ALIGNMENT_LEFT, 210.0)
	elif w.warned and not w.shifting:
		var td := Vector2.RIGHT.rotated(w.target_angle)
		var a := 0.4 + 0.4 * sin(clock * 9.0)
		draw_line(c, c + td * r, Color(1.0, 0.85, 0.4, a), 2.0)
		_text(Vector2(x + 14, 284), "WIND SHIFT INCOMING", 15, Color(1.0, 0.85, 0.4, 0.5 + a), HORIZONTAL_ALIGNMENT_LEFT, 210.0)
	elif w.shifting:
		_text(Vector2(x + 14, 284), "Wind is turning", 15, Color(1.0, 0.85, 0.4), HORIZONTAL_ALIGNMENT_LEFT, 210.0)
	else:
		_text(Vector2(x + 14, 284), "Steady wind", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_LEFT, 210.0)


func _card(rect: Rect2, title: String, title_col: Color, key: String, line: String, ratio: float, is_ready: bool, status: String) -> void:
	draw_rect(rect, Color(0.03, 0.08, 0.13, 0.85))
	draw_rect(rect, Color(title_col, 0.7 if is_ready else 0.25), false, 1.5)
	_text(rect.position + Vector2(8, 18), title, 13, title_col, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0)
	_text(rect.position + Vector2(8, 18), key, 12, UiKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 16.0)
	_text(rect.position + Vector2(8, 40), line, 14, UiKit.TEXT if is_ready else UiKit.DIM, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0)
	_bar(Rect2(rect.position + Vector2(8, 50), Vector2(rect.size.x - 16.0, 8)), ratio, title_col if is_ready else Color(title_col, 0.45))
	_text(rect.position + Vector2(8, 76), status, 12, title_col if is_ready else UiKit.DIM, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0)


func _draw_weapons(s: Vector2) -> void:
	var p: PlayerShip = run.player
	var cards: Array = []
	for slot in p.slots:
		cards.append(["slot", slot])
	if run.stats.ability != "":
		cards.append(["ability", ""])
	for i in run.stats.modules.size():
		cards.append(["module", i])
	var gap := 8.0
	var total := cards.size() * (CARD_W + gap) - gap + 20.0
	var thr_w := 130.0
	var group := total + 12.0 + thr_w
	var x0 := (s.x - group) * 0.5
	var y := s.y - 112.0
	_panel(Rect2(x0, y, total, 98))
	var cx := x0 + 10.0
	for c in cards:
		var r := Rect2(cx, y + 8.0, CARD_W, 82)
		match str(c[0]):
			"slot":
				var slot: String = c[1]
				var w: Dictionary = p.profiles[slot]
				var is_ready: bool = float(p.reload[slot]) <= 0.0
				var key := Controls.short_text(GameData.SLOT_ACTIONS[slot])
				if not Controls.using_pad:
					if slot == "port":
						key += "/LMB"
					elif slot == "starboard":
						key += "/RMB"
				var mk: String = str(w.get("mark_name", "Mk I")).replace("Mk ", "")
				_card(r, "STBD" if slot == "starboard" else GameData.SLOT_LABELS[slot], GameData.SLOT_COLORS[slot], "[%s]" % key, "%s %s" % [w["short"], mk], p.reload_ratio(slot), is_ready, "READY" if is_ready else "RELOADING")
			"ability":
				var ad: Dictionary = p.ability_def()
				var rdy := p.ability_ready()
				var status := "READY" if rdy else "CHARGING"
				match run.stats.ability:
					"armor_brace":
						status = "BRACING" if p.bracing else ("READY" if rdy else "RECOVERING")
					"gale_surge":
						if p.surge_timer > 0.0:
							status = "SURGING"
					"quick_reload":
						status = "READY" if rdy else "COOLDOWN"
					"plunder_raid":
						if p.raid_timer > 0.0:
							status = "RAIDING"
					"side_slip":
						status = "READY" if rdy else "COOLDOWN"
					"pressure_pulse":
						status = "READY" if rdy else "PRESSURE %d%%" % int(p.charge * 100.0)
					"resonance_cascade":
						status = "NEED WAKE I" if run.wake.tier < 1 else ("READY" if rdy else "COOLDOWN")
					"ward_buoy":
						status = "%d CHARGE%s" % [p.ward_charges, "" if p.ward_charges == 1 else "S"]
					"steady_aim":
						if p.focus_timer > 0.0:
							status = "FOCUSED"
						elif not rdy:
							status = "HOLD STEADY"
				var active := rdy or p.bracing or p.surge_timer > 0.0 or p.raid_timer > 0.0 or p.focus_timer > 0.0
				_card(r, "ABILITY", Color(1.0, 0.85, 0.45), "[%s]" % Controls.short_text("ability"), str(ad.get("name", "")), p.ability_ratio(), active, status)
			"module":
				var i: int = c[1]
				var mid: String = run.stats.modules[i]
				var md: Dictionary = GameData.ACTIVE_MODULES[mid]
				var mr := p.module_ratio(i)
				var charges: int = int(p.module_charges[i])
				var mready := mr >= 1.0 and charges != 0
				var mstatus := "READY" if mready else ("EMPTY" if charges == 0 else "COOLDOWN")
				if charges > 0:
					mstatus += "  x%d" % charges
				_card(r, "MODULE %d" % (i + 1), Color(0.6, 1.0, 0.85), "[%s]" % Controls.short_text("module_%d" % (i + 1)), str(md["short"]), mr, mready, mstatus)
		cx += CARD_W + gap
	var tx := x0 + total + 12.0
	_panel(Rect2(tx, y, thr_w, 98))
	_text(Vector2(tx + 10, y + 20.0), "THROTTLE", 13, UiKit.DIM)
	var thr_rect := Rect2(tx + 14, y + 28.0, 14, 62)
	draw_rect(thr_rect, Color(0, 0, 0, 0.55))
	var th := p.throttle
	var zero_y := thr_rect.position.y + thr_rect.size.y * (1.0 / 1.3)
	if th >= 0.0:
		var hh := thr_rect.size.y * (1.0 / 1.3) * th
		draw_rect(Rect2(thr_rect.position.x, zero_y - hh, thr_rect.size.x, hh), UiKit.ACCENT)
	else:
		var h2 := thr_rect.size.y * (0.3 / 1.3) * (-th / 0.3)
		draw_rect(Rect2(thr_rect.position.x, zero_y, thr_rect.size.x, h2), Color(1.0, 0.6, 0.4))
	draw_line(Vector2(thr_rect.position.x - 3, zero_y), Vector2(thr_rect.end.x + 3, zero_y), UiKit.TEXT, 1.0)
	draw_rect(thr_rect, Color(UiKit.ACCENT, 0.5), false, 1.0)
	_text(Vector2(tx + 38, y + 46.0), "%d%%" % int(th * 100.0), 18, UiKit.TEXT)
	_text(Vector2(tx + 38, y + 68.0), "%d kn" % int(p.velocity.length() / 10.0), 15, UiKit.DIM)
	var mode_txt := ""
	if p.drifting:
		mode_txt = "DRIFT"
	elif p.braking:
		mode_txt = "BRAKE"
	elif p.drift_latched:
		mode_txt = "DRIFT ON"
	if mode_txt != "":
		_text(Vector2(tx + 38, y + 88.0), mode_txt, 13, UiKit.PINK)


func _draw_boss(s: Vector2) -> void:
	var b = run.boss
	if b == null or not is_instance_valid(b) or not b.alive:
		return
	var w := minf(640.0, s.x - 760.0)
	var x := (s.x - w) * 0.5
	_panel(Rect2(x - 12, 12, w + 24, 62))
	var title := "%s  -  PHASE %d" % [b.boss_title(), int(b.get("phase"))]
	var tsize := _fit(title, 18, w * 0.55)
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, tsize).x
	_text(Vector2(x, 36), title, 18, Color(1.0, 0.65, 0.35), HORIZONTAL_ALIGNMENT_LEFT, w * 0.55)
	var status: String = b.boss_status()
	if status != "":
		var sc := Color(0.4, 1.0, 0.95) if b.exposed else Color(0.85, 0.9, 1.0)
		var room := maxf(80.0, w - tw - 20.0)
		_text(Vector2(x + w - room, 36), status, 16, sc, HORIZONTAL_ALIGNMENT_RIGHT, room)
	_bar(Rect2(x, 44, w, 16), float(b.hull) / float(b.max_hull), Color(1.0, 0.45, 0.3))
	for mk in b.phase_marks():
		draw_line(Vector2(x + w * float(mk), 42), Vector2(x + w * float(mk), 62), Color(1, 1, 1, 0.6), 2.0)


func _draw_banner(s: Vector2) -> void:
	if banners.is_empty():
		return
	var b: Dictionary = banners[0]
	var t: float = float(b["time"])
	var m: float = float(b["max"])
	var a := clampf(minf((m - t) * 4.0, t * 2.0), 0.0, 1.0)
	var col: Color = b["color"]
	var y := s.y * 0.26
	var w := minf(900.0, s.x - 2.0 * 380.0)
	var bx := (s.x - w) * 0.5
	zones.append(Rect2(bx, y - 46.0, w, 80))
	draw_rect(Rect2(bx, y - 46.0, w, 80), Color(0.0, 0.02, 0.06, 0.55 * a))
	_text(Vector2(bx + 12.0, y), str(b["title"]), 40, Color(col, a), HORIZONTAL_ALIGNMENT_CENTER, w - 24.0)
	_text(Vector2(bx + 12.0, y + 26.0), str(b["sub"]), 18, Color(UiKit.TEXT, a), HORIZONTAL_ALIGNMENT_CENTER, w - 24.0)


func _draw_tutorial(s: Vector2) -> void:
	var txt: String = run.tutorial_text()
	if txt == "":
		return
	var w := minf(860.0, s.x - 40.0)
	var r := Rect2((s.x - w) * 0.5, s.y - 162.0, w, 40)
	zones.append(r)
	draw_rect(r, Color(0.02, 0.08, 0.14, 0.85))
	draw_rect(r, Color(UiKit.ACCENT, 0.6 + 0.3 * sin(clock * 4.0)), false, 2.0)
	_text(Vector2(r.position.x + 12.0, r.position.y + 27.0), txt, 17, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, w - 24.0)


func _draw_footer(s: Vector2) -> void:
	var txt := "[%s] Pause" % Controls.short_text("pause") if Controls.using_pad else "[%s] Pause   [F11] Fullscreen" % Controls.short_text("pause")
	zones.append(Rect2(s.x - 290.0, s.y - 32.0, 282, 28))
	_text(Vector2(s.x - 290.0, s.y - 14.0), txt, 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT, 274.0)


func _draw_indicators(s: Vector2) -> void:
	var xf := get_viewport().get_canvas_transform()
	var margin := 34.0
	var inner := Rect2(margin, margin, s.x - margin * 2.0, s.y - margin * 2.0)
	var center := s * 0.5
	var jam: bool = run.jammed
	for e in run.enemies:
		if not is_instance_valid(e) or not e.alive or e.hidden():
			continue
		var sp: Vector2 = xf * (e.global_position as Vector2)
		if jam:
			sp += Vector2(sin(clock * 7.0 + float(e.get_instance_id() % 97)), cos(clock * 5.0 + float(e.get_instance_id() % 53))) * 260.0
		if inner.has_point(sp):
			continue
		var col := GameData.COL_ENEMY
		var sz := 9.0
		if e.kind == "fireship":
			col = Color(1.0, 0.6, 0.2)
		elif e.kind == "courier" or e.name_tag != "":
			col = GameData.COL_SALVAGE
			sz = 12.0
		elif e.kind in ["frigate", "rammer", "mortar_monitor", "siege_barge"]:
			sz = 11.0
		elif e.kind == "shield_tender":
			col = Color(0.55, 0.8, 1.0)
		elif e.kind == "repair_barge":
			col = Color(0.5, 1.0, 0.6)
		elif e.kind == "longbow_sloop":
			sz = 11.0
		elif e.kind == "resonance_anchor":
			col = Color(1.0, 0.5, 0.85)
			sz = 13.0
		elif e.boss:
			col = Color(1.0, 0.8, 0.3)
			sz = 16.0
		_edge_arrow(sp, center, inner, col, sz)
	for fcon in run.false_contacts:
		var fpt: Vector2 = xf * (fcon["pos"] as Vector2)
		if not inner.has_point(fpt):
			_edge_arrow(fpt, center, inner, Color(GameData.COL_ENEMY, 0.6 + 0.4 * sin(clock * 9.0)), 11.0)
	for bu in run.hazards.buoys:
		if bool(bu["done"]):
			continue
		var bpt: Vector2 = xf * (bu["pos"] as Vector2)
		if not inner.has_point(bpt):
			_edge_arrow(bpt, center, inner, Color(0.6, 0.85, 1.0), 12.0)
	for a in run.allies:
		if not a.alive:
			continue
		var ap: Vector2 = xf * (a.position as Vector2)
		if not inner.has_point(ap):
			_edge_arrow(ap, center, inner, GameData.COL_ALLY, 12.0)
	for wr in run.hazards.wrecks:
		if bool(wr["looted"]):
			continue
		var wp: Vector2 = xf * (wr["pos"] as Vector2)
		if not inner.has_point(wp):
			_edge_arrow(wp, center, inner, Color(1.0, 0.85, 0.4, 0.85), 8.0)
	var hz: Hazards = run.hazards
	if hz.cp_index < hz.checkpoints.size():
		var cp: Vector2 = xf * (hz.checkpoints[hz.cp_index] as Vector2)
		if not inner.has_point(cp):
			_edge_arrow(cp, center, inner, Color(0.5, 1.0, 0.9), 13.0)
	for a in run.director.arrivals:
		var arp: Vector2 = xf * (a["pos"] as Vector2)
		var pulse := 0.5 + 0.5 * sin(clock * 12.0)
		if inner.has_point(arp):
			continue
		_edge_arrow(arp, center, inner, Color(1.0, 0.3, 0.3, 0.4 + 0.6 * pulse), 12.0)


func _edge_arrow(sp: Vector2, center: Vector2, inner: Rect2, col: Color, sz: float) -> void:
	var d := sp - center
	if d.length() < 1.0:
		return
	var tx := INF
	var ty := INF
	if absf(d.x) > 0.001:
		tx = ((inner.end.x if d.x > 0.0 else inner.position.x) - center.x) / d.x
	if absf(d.y) > 0.001:
		ty = ((inner.end.y if d.y > 0.0 else inner.position.y) - center.y) / d.y
	var t := minf(tx, ty)
	var pos := center + d * t
	var n := d.normalized()
	for _step in 60:
		var blocked := false
		for z in zones:
			if (z as Rect2).grow(sz + 4.0).has_point(pos):
				blocked = true
				break
		if not blocked:
			break
		pos = pos.move_toward(center, 10.0)
	var pts := PackedVector2Array([pos + n * sz, pos + n.rotated(2.5) * sz * 0.8, pos + n.rotated(-2.5) * sz * 0.8])
	draw_colored_polygon(pts, col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color(0, 0, 0, 0.7), 1.5)

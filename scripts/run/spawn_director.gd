class_name SpawnDirector
extends RefCounted

const THREATS := ["frigate", "fireship", "rammer", "mortar_monitor", "siege_barge", "longbow_sloop"]

var run
var queue: Array = []
var arrivals: Array = []
var timer := 0.0
var interval := 1.2
var max_alive := 8
var max_threat := 4


func _init(p_run) -> void:
	run = p_run


func begin(cfg: Dictionary, wave: int) -> void:
	queue.clear()
	arrivals.clear()
	var rng: RandomNumberGenerator = run.rng
	var list: Array = []
	for g in cfg["groups"]:
		for i in int(g[1]):
			list.append({"kind": str(g[0]), "variants": [], "side": "any"})
	var head_count := mini(2, list.size())
	var head: Array = list.slice(0, head_count)
	var tail: Array = list.slice(head_count)
	_shuffle(tail)
	list = head + tail
	var elites := int(cfg["elite"])
	for k in elites:
		var idx := rng.randi_range(int(list.size() * 0.5), list.size() - 1)
		if not GameData.is_boss(list[idx]["kind"]):
			(list[idx]["variants"] as Array).append("elite")
	queue = list
	interval = maxf(0.55, 1.3 - float(wave) * 0.07)
	max_alive = 6 + mini(int(wave * 0.5), 4)
	max_threat = 2 + mini(int(wave / 3.0), 3)
	timer = 3.5 if wave == 1 else 2.0


func configure(stage: int) -> void:
	interval = maxf(0.6, 1.2 - float(stage) * 0.04)
	max_alive = 7 + mini(int(stage * 0.5), 4)
	max_threat = 3 + mini(int(stage / 3.0), 3)


func add_group(spawns: Array, side: String, delay: float = 0.6) -> void:
	var diff: Dictionary = run.difficulty
	var mods: Array = run.modifiers
	var list: Array = []
	for entry in spawns:
		var kind := str(entry[0])
		var count := int(entry[1])
		var vars: Array = []
		if entry.size() > 2:
			vars = (entry[2] as Array).duplicate()
		for i in count:
			list.append({"kind": kind, "variants": vars.duplicate(), "side": side})
	if not list.is_empty() and not GameData.is_boss(str(list[0]["kind"])):
		for i in int(diff.get("extra", 0)):
			list.append({"kind": "gunboat", "variants": [], "side": side})
		var chance: float = float(diff.get("variants", 0.0))
		var pool := ["veteran"]
		if chance >= 0.3:
			pool = ["veteran", "armored", "commander"]
		if int(run.cfg.get("region", 1)) >= 3:
			pool.append("stormbound")
		if int(run.cfg.get("region", 1)) >= 5 or bool(run.cfg.get("remix", false)):
			pool.append("resonant")
		for e in list:
			if GameData.is_boss(e["kind"]) or e["kind"] == "courier":
				continue
			if run.rng.randf() < chance and (e["variants"] as Array).size() < 2:
				var v: String = pool[run.rng.randi_range(0, pool.size() - 1)]
				if not (e["variants"] as Array).has(v):
					(e["variants"] as Array).append(v)
			if mods.has("armored") and run.rng.randf() < 0.4 and not (e["variants"] as Array).has("armored"):
				(e["variants"] as Array).append("armored")
		if mods.has("rich_salvage") and list.size() > 0:
			var pick: Dictionary = list[run.rng.randi_range(0, list.size() - 1)]
			if not (pick["variants"] as Array).has("elite"):
				(pick["variants"] as Array).append("elite")
	if queue.is_empty():
		timer = minf(timer, delay)
	queue.append_array(list)


func _shuffle(arr: Array) -> void:
	var rng: RandomNumberGenerator = run.rng
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func update(dt: float) -> void:
	var i := arrivals.size() - 1
	while i >= 0:
		var a: Dictionary = arrivals[i]
		a["t"] = float(a["t"]) - dt
		if float(a["t"]) <= 0.0:
			run.spawn_enemy(a["kind"], a["pos"], a["variants"])
			arrivals.remove_at(i)
		i -= 1
	if queue.is_empty():
		return
	timer -= dt
	if timer > 0.0:
		return
	var alive: int = run.enemies.size() + arrivals.size()
	if alive >= max_alive:
		timer = 0.4
		return
	var nxt: Dictionary = queue[0]
	if THREATS.has(nxt["kind"]) and _threat_count() >= max_threat:
		timer = 0.4
		return
	queue.pop_front()
	var big: bool = GameData.is_boss(nxt["kind"])
	var pos := pick_spawn(big, str(nxt.get("side", "any")))
	arrivals.append({"kind": nxt["kind"], "variants": nxt["variants"], "pos": pos, "t": 2.6 if big else 1.0})
	run.fx_over.spawn_cue(pos, big)
	timer = interval * run.rng.randf_range(0.8, 1.2)


func _threat_count() -> int:
	var c := 0
	for e in run.enemies:
		if THREATS.has(e.kind):
			c += 1
	for a in arrivals:
		if THREATS.has(a["kind"]):
			c += 1
	return c


func pick_spawn(big: bool = false, side: String = "any") -> Vector2:
	var rng: RandomNumberGenerator = run.rng
	var p: Vector2 = run.player.position
	var size: Vector2 = run.arena.size
	var clearance := 130.0 if big else 60.0
	for i in 40:
		var c: Vector2
		match side:
			"left":
				c = Vector2(rng.randf_range(120.0, 320.0), rng.randf_range(200.0, size.y - 200.0))
			"right":
				c = Vector2(rng.randf_range(size.x - 320.0, size.x - 120.0), rng.randf_range(200.0, size.y - 200.0))
			"top":
				c = Vector2(rng.randf_range(300.0, size.x - 300.0), rng.randf_range(120.0, 320.0))
			"bottom":
				c = Vector2(rng.randf_range(300.0, size.x - 300.0), rng.randf_range(size.y - 320.0, size.y - 120.0))
			"mirror":
				var m := size - p
				if m.distance_to(p) < 700.0:
					m = p + (m - p).normalized() * 750.0 if m.distance_to(p) > 1.0 else p + Vector2(750.0, 0.0)
				c = m + Vector2(rng.randf_range(-160.0, 160.0), rng.randf_range(-160.0, 160.0))
			_:
				c = p + Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(650.0, 950.0)
		c.x = clampf(c.x, clearance, size.x - clearance)
		c.y = clampf(c.y, clearance, size.y - clearance)
		if c.distance_to(p) < (520.0 if i < 30 else 380.0):
			continue
		if not run.arena.is_clear(c, clearance):
			continue
		return c
	var corners := [Vector2(150, 150), Vector2(size.x - 150, 150), Vector2(150, size.y - 150), Vector2(size.x - 150, size.y - 150)]
	var best: Vector2 = corners[0]
	for c in corners:
		if (c as Vector2).distance_to(p) > best.distance_to(p):
			best = c
	return best


func finished() -> bool:
	return queue.is_empty() and arrivals.is_empty()


func remaining() -> int:
	return queue.size() + arrivals.size()

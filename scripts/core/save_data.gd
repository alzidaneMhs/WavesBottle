extends Node

const PATH := "user://wavesbottle_save.json"
const VERSION := 2

var data: Dictionary = {}


func defaults() -> Dictionary:
	return {
		"version": VERSION,
		"settings": {
			"master": 0.8,
			"music": 0.7,
			"sfx": 0.8,
			"ui": 0.7,
			"shake": 1.0,
			"reduce_flash": false,
			"particles": 2,
			"fullscreen": true,
			"ui_scale": 1.0,
			"drift_toggle": false,
			"aim_assist": false,
		},
		"bindings": {},
		"pad_bindings": {},
		"records": {
			"best_score": 0,
			"best_wave": 0,
			"best_tier": 0,
			"best_time": 0.0,
			"runs": 0,
			"wins": 0,
			"kills": 0,
			"boss_kills": 0,
			"missions": 0,
			"missions_won": 0,
		},
		"unlocks": {
			"ember": false,
			"aurora": false,
			"rustfire": false,
			"stormglass": false,
			"abyssal": false,
			"sovereign": false,
			"prism": false,
		},
		"resources": {"salvage": 0, "research": 0, "intel": 0},
		"campaign": {"cleared": {}, "optional": {}, "best": {}},
		"ships": ["wayfarer"],
		"items": {
			"weapons": (GameData.START_UNLOCKS["weapons"] as Array).duplicate(),
			"modules": (GameData.START_UNLOCKS["modules"] as Array).duplicate(),
			"passives": (GameData.START_UNLOCKS["passives"] as Array).duplicate(),
			"upgrades": [],
		},
		"research": [],
		"facilities": [],
		"builds": {},
		"active_build": {},
		"perks": {},
		"mastery": {},
		"selected": {"ship": "wayfarer", "difficulty": "standard", "remix": false},
		"codex": {"enemies": {}, "bosses": {}, "lore": {}, "regions": {"1": true}},
		"contracts": {"active": [], "cursor": 0, "done": 0},
		"palette": "classic",
		"tutorial_done": false,
	}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_data()
	apply_display()


func load_data() -> void:
	data = defaults()
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		data = _merge(defaults(), _migrate(parsed))
	data["version"] = VERSION


func _migrate(d: Dictionary) -> Dictionary:
	var v: int = int(d.get("version", 0))
	if v < 1:
		if d.has("best_score"):
			d["records"] = {"best_score": d["best_score"]}
	if v < 2:
		var seen: Variant = d.get("seen", {})
		if seen is Dictionary:
			d["codex"] = {"enemies": (seen as Dictionary).duplicate(), "bosses": {}, "lore": {}, "regions": {"1": true}}
		var runs := 0
		if d.get("records") is Dictionary:
			runs = int((d["records"] as Dictionary).get("runs", 0))
		d["resources"] = {"salvage": 100 if runs > 0 else 0, "research": 0, "intel": 0}
		d.erase("seen")
		d.erase("loadout")
		if d.get("unlocks") is Dictionary:
			var u: Dictionary = d["unlocks"]
			u.erase("scatter")
			u.erase("duelist")
	return d


func _merge(base: Dictionary, over: Dictionary) -> Dictionary:
	for k in over.keys():
		if not base.has(k):
			continue
		var bv: Variant = base[k]
		var ov: Variant = over[k]
		if bv is Dictionary and ov is Dictionary:
			if (bv as Dictionary).is_empty():
				base[k] = ov
			else:
				base[k] = _merge(bv, ov)
		elif typeof(bv) == typeof(ov):
			base[k] = ov
		elif (bv is int or bv is float) and (ov is int or ov is float):
			base[k] = ov
	return base


func save() -> void:
	var tmp := PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	var dir := DirAccess.open("user://")
	if dir != null:
		if dir.file_exists(PATH.get_file()):
			dir.remove(PATH.get_file())
		dir.rename(tmp.get_file(), PATH.get_file())


func setting(key: String) -> Variant:
	return data["settings"].get(key, defaults()["settings"].get(key))


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	if key == "fullscreen":
		apply_display()
	Sound.apply_volumes()
	save()


func apply_display() -> void:
	if Engine.is_embedded_in_editor() or DisplayServer.get_name() == "headless" or OS.has_feature("web"):
		return
	if bool(setting("fullscreen")):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	fit_window()


func fit_window() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return
	var target := Vector2(1600, 900)
	var limit := Vector2(usable.size) * 0.9
	var k := minf(1.0, minf(limit.x / target.x, limit.y / target.y))
	var win := Vector2i(int(target.x * k), int(target.y * k))
	DisplayServer.window_set_min_size(Vector2i(960, 540))
	DisplayServer.window_set_size(win)
	DisplayServer.window_set_position(usable.position + Vector2i(Vector2(usable.size - win) * 0.5))


func particle_scale() -> float:
	match int(setting("particles")):
		0:
			return 0.35
		1:
			return 0.65
	return 1.0


func shake_scale() -> float:
	return float(setting("shake"))


func reduce_flash() -> bool:
	return bool(setting("reduce_flash"))


func is_unlocked(key: String) -> bool:
	if key == "classic":
		return true
	return bool(data["unlocks"].get(key, false))


func mark_seen(kind: String) -> bool:
	var codex: Dictionary = data["codex"]
	var cat := "bosses" if GameData.is_boss(kind) else "enemies"
	if not (codex[cat] as Dictionary).has(kind):
		codex[cat][kind] = true
		save()
		return true
	return false


func record_run(summary: Dictionary) -> Array:
	var notes: Array = []
	var r: Dictionary = data["records"]
	if summary.get("mode", "classic") != "classic":
		return notes
	r["runs"] = int(r["runs"]) + 1
	r["kills"] = int(r["kills"]) + int(summary["kills"])
	r["boss_kills"] = int(r["boss_kills"]) + int(summary["bosses"])
	if bool(summary["victory"]):
		r["wins"] = int(r["wins"]) + 1
	if int(summary["score"]) > int(r["best_score"]):
		r["best_score"] = int(summary["score"])
		notes.append("New best Classic score")
	if int(summary["wave"]) > int(r["best_wave"]):
		r["best_wave"] = int(summary["wave"])
		notes.append("New furthest Classic wave")
	if int(summary["max_tier"]) > int(r["best_tier"]):
		r["best_tier"] = int(summary["max_tier"])
		notes.append("New highest Wake tier")
	if float(summary["time"]) > float(r["best_time"]):
		r["best_time"] = float(summary["time"])
	var u: Dictionary = data["unlocks"]
	if int(summary["max_tier"]) >= 5 and not u["ember"]:
		u["ember"] = true
		notes.append("Unlocked wake: Ember Tide")
	save()
	return notes

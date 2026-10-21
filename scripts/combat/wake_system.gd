class_name WakeSystem
extends RefCounted

var stats: ShipStats
var tier := 0
var progress := 0.0
var idle := 0.0
var hold := true
var max_tier := 0
var reason := ""
var reason_good := true
var reason_timer := 0.0
var pending_change := 0
var boost := 1.0


func _init(p_stats: ShipStats) -> void:
	stats = p_stats


func need() -> float:
	return float(GameData.WAKE_NEED[tier])


func ratio() -> float:
	return clampf(progress / need(), 0.0, 1.0)


func multiplier() -> float:
	return float(GameData.WAKE_MULT[tier])


func grace() -> float:
	return stats.get_value("wake_grace")


func decaying() -> bool:
	return not hold and idle > grace()


func state_text() -> String:
	if hold:
		return "HOLD"
	if decaying():
		return "DECAYING"
	return "STEADY"


func grace_ratio() -> float:
	if hold:
		return 1.0
	return clampf(1.0 - idle / grace(), 0.0, 1.0)


func _set_reason(text: String, good: bool) -> void:
	reason = text
	reason_good = good
	reason_timer = 1.6


func add(amount: float, text: String, category: String = "") -> void:
	idle = 0.0
	if stats.has_flag("predator_wake") and category in ["cross", "weak", "interrupt"]:
		amount *= 2.0
	amount *= boost
	progress += amount
	if category != "storm" or reason_timer <= 0.0:
		_set_reason("+ " + text, true)
	while tier < 5 and progress >= need():
		progress -= need()
		tier += 1
		pending_change += 1
	if tier == 5:
		progress = minf(progress, need())
	max_tier = maxi(max_tier, tier)


func steady() -> void:
	idle = 0.0


func lose(amount: float, text: String, show: bool = true) -> void:
	progress -= amount
	if show:
		_set_reason("- " + text, false)
	while progress < 0.0:
		if tier > 0:
			tier -= 1
			pending_change -= 1
			progress += need() * 0.6
		else:
			progress = 0.0


func drop_tier(text: String) -> void:
	_set_reason("- " + text, false)
	if tier > 0:
		tier -= 1
		pending_change -= 1
		progress = need() * 0.4
	else:
		progress = 0.0


func update(dt: float) -> void:
	reason_timer = maxf(0.0, reason_timer - dt)
	if hold:
		idle = 0.0
		return
	idle += dt
	if idle > grace():
		progress -= stats.get_value("wake_decay") * dt
		if progress < 0.0:
			if tier > 0:
				tier -= 1
				pending_change -= 1
				progress = need() * 0.75
				_set_reason("- DECAY", false)
			else:
				progress = 0.0


func take_change() -> int:
	var c := pending_change
	pending_change = 0
	return c

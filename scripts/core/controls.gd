extends Node

const DEFAULTS := {
	"throttle_up": [KEY_W],
	"throttle_down": [KEY_S],
	"turn_left": [KEY_A],
	"turn_right": [KEY_D],
	"drift": [KEY_SHIFT],
	"fire_port": [KEY_J, KEY_LEFT, "mouse_left"],
	"fire_starboard": [KEY_L, KEY_RIGHT, "mouse_right"],
	"fire_bow": [KEY_K, KEY_UP],
	"fire_stern": [KEY_N, KEY_DOWN],
	"fire_turret": [KEY_U],
	"ability": [KEY_SPACE],
	"module_1": [KEY_F],
	"module_2": [KEY_G],
	"pause": [KEY_P, KEY_ESCAPE],
}

const PAD_DEFAULTS := {
	"throttle_up": [["axis", JOY_AXIS_TRIGGER_RIGHT, 1], ["axis", JOY_AXIS_LEFT_Y, -1]],
	"throttle_down": [["axis", JOY_AXIS_TRIGGER_LEFT, 1], ["axis", JOY_AXIS_LEFT_Y, 1]],
	"turn_left": [["axis", JOY_AXIS_LEFT_X, -1], ["button", JOY_BUTTON_DPAD_LEFT]],
	"turn_right": [["axis", JOY_AXIS_LEFT_X, 1], ["button", JOY_BUTTON_DPAD_RIGHT]],
	"drift": [["button", JOY_BUTTON_B]],
	"fire_port": [["button", JOY_BUTTON_LEFT_SHOULDER]],
	"fire_starboard": [["button", JOY_BUTTON_RIGHT_SHOULDER]],
	"fire_bow": [["button", JOY_BUTTON_Y]],
	"fire_stern": [["button", JOY_BUTTON_X]],
	"fire_turret": [["button", JOY_BUTTON_RIGHT_STICK], ["axis", JOY_AXIS_RIGHT_Y, -1]],
	"ability": [["button", JOY_BUTTON_A]],
	"module_1": [["button", JOY_BUTTON_DPAD_UP]],
	"module_2": [["button", JOY_BUTTON_DPAD_DOWN]],
	"pause": [["button", JOY_BUTTON_START]],
}

const LABELS := {
	"throttle_up": "Throttle Up",
	"throttle_down": "Throttle Down / Brake",
	"turn_left": "Turn Left",
	"turn_right": "Turn Right",
	"drift": "Drift",
	"fire_port": "Fire Port (left side)",
	"fire_starboard": "Fire Starboard (right side)",
	"fire_bow": "Fire Bow (forward)",
	"fire_stern": "Fire Stern (rear)",
	"fire_turret": "Fire Turret",
	"ability": "Ship Ability",
	"module_1": "Utility Module 1",
	"module_2": "Utility Module 2",
	"pause": "Pause",
}

const ORDER := ["throttle_up", "throttle_down", "turn_left", "turn_right", "drift", "fire_port", "fire_starboard", "fire_bow", "fire_stern", "fire_turret", "ability", "module_1", "module_2", "pause"]

const BUTTON_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_GUIDE: "Guide", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "LS", JOY_BUTTON_RIGHT_STICK: "RS",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-Up", JOY_BUTTON_DPAD_DOWN: "D-Down", JOY_BUTTON_DPAD_LEFT: "D-Left", JOY_BUTTON_DPAD_RIGHT: "D-Right",
}

var using_pad := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	apply_all()
	_ui_pad()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
		using_pad = true
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		using_pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		using_pad = false


func _ui_pad() -> void:
	var dirs := {"ui_left": [JOY_AXIS_LEFT_X, -1.0], "ui_right": [JOY_AXIS_LEFT_X, 1.0], "ui_up": [JOY_AXIS_LEFT_Y, -1.0], "ui_down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in dirs.keys():
		if not InputMap.has_action(action):
			continue
		var has_axis := false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadMotion:
				has_axis = true
		if not has_axis:
			var m := InputEventJoypadMotion.new()
			m.axis = int(dirs[action][0]) as JoyAxis
			m.axis_value = float(dirs[action][1])
			InputMap.action_add_event(action, m)
	var pads := {"ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B}
	for action in pads.keys():
		if not InputMap.has_action(action):
			continue
		var found := false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton and (ev as InputEventJoypadButton).button_index == int(pads[action]):
				found = true
		if not found:
			var b := InputEventJoypadButton.new()
			b.button_index = int(pads[action]) as JoyButton
			InputMap.action_add_event(action, b)


func _keys_for(action: String) -> Array:
	var keys: Array = (DEFAULTS[action] as Array).duplicate()
	var b: Dictionary = SaveData.data["bindings"]
	if b.has(action):
		keys[0] = int(b[action])
	return keys


func _pads_for(action: String) -> Array:
	var pads: Array = (PAD_DEFAULTS.get(action, []) as Array).duplicate(true)
	var b: Dictionary = SaveData.data.get("pad_bindings", {})
	if b.has(action) and b[action] is Array and (b[action] as Array).size() >= 2:
		if pads.is_empty():
			pads.append(b[action])
		else:
			pads[0] = b[action]
	return pads


func apply_all() -> void:
	for action in ORDER:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, 0.3)
		for k in _keys_for(action):
			InputMap.action_add_event(action, _make_event(k))
		for pd in _pads_for(action):
			InputMap.action_add_event(action, _make_pad_event(pd))


func _make_event(k: Variant) -> InputEvent:
	if k is String:
		var m := InputEventMouseButton.new()
		m.button_index = (MOUSE_BUTTON_LEFT if k == "mouse_left" else MOUSE_BUTTON_RIGHT) as MouseButton
		return m
	var e := InputEventKey.new()
	e.keycode = int(k) as Key
	return e


func _make_pad_event(pd: Array) -> InputEvent:
	if str(pd[0]) == "axis":
		var m := InputEventJoypadMotion.new()
		m.axis = int(pd[1]) as JoyAxis
		m.axis_value = float(pd[2])
		return m
	var b := InputEventJoypadButton.new()
	b.button_index = int(pd[1]) as JoyButton
	return b


func primary_key(action: String) -> int:
	return int(_keys_for(action)[0])


func rebind(action: String, keycode: int) -> bool:
	for other in ORDER:
		if other == action:
			continue
		for k in _keys_for(other):
			if k is int and int(k) == keycode:
				return false
	var keys: Array = _keys_for(action)
	for i in range(1, keys.size()):
		if keys[i] is int and int(keys[i]) == keycode:
			return false
	SaveData.data["bindings"][action] = keycode
	SaveData.save()
	apply_all()
	return true


func pad_from_event(event: InputEvent) -> Array:
	if event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
		return ["button", int((event as InputEventJoypadButton).button_index)]
	if event is InputEventJoypadMotion:
		var jm := event as InputEventJoypadMotion
		if absf(jm.axis_value) > 0.6:
			return ["axis", int(jm.axis), 1 if jm.axis_value > 0.0 else -1]
	return []


func _same_pad(a: Array, b: Array) -> bool:
	if a.size() < 2 or b.size() < 2 or str(a[0]) != str(b[0]) or int(a[1]) != int(b[1]):
		return false
	if str(a[0]) == "axis":
		return signf(float(a[2])) == signf(float(b[2]))
	return true


func rebind_pad(action: String, pd: Array) -> bool:
	if pd.is_empty() or (str(pd[0]) == "button" and int(pd[1]) == JOY_BUTTON_START and action != "pause"):
		return false
	for other in ORDER:
		if other == action:
			continue
		for q in _pads_for(other):
			if _same_pad(q, pd):
				return false
	if not SaveData.data.has("pad_bindings"):
		SaveData.data["pad_bindings"] = {}
	SaveData.data["pad_bindings"][action] = pd
	SaveData.save()
	apply_all()
	return true


func reset() -> void:
	SaveData.data["bindings"] = {}
	SaveData.data["pad_bindings"] = {}
	SaveData.save()
	apply_all()


func key_name(k: Variant) -> String:
	if k is String:
		return "LMB" if k == "mouse_left" else "RMB"
	return OS.get_keycode_string(int(k) as Key)


func pad_name(pd: Array) -> String:
	if pd.is_empty():
		return "-"
	if str(pd[0]) == "button":
		return str(BUTTON_NAMES.get(int(pd[1]), "Button %d" % int(pd[1])))
	var axis := int(pd[1])
	var pos := float(pd[2]) > 0.0
	match axis:
		JOY_AXIS_LEFT_X:
			return "LS Right" if pos else "LS Left"
		JOY_AXIS_LEFT_Y:
			return "LS Down" if pos else "LS Up"
		JOY_AXIS_RIGHT_X:
			return "RS Right" if pos else "RS Left"
		JOY_AXIS_RIGHT_Y:
			return "RS Down" if pos else "RS Up"
		JOY_AXIS_TRIGGER_LEFT:
			return "LT"
		JOY_AXIS_TRIGGER_RIGHT:
			return "RT"
	return "Axis %d" % axis


func pad_text(action: String) -> String:
	var pads := _pads_for(action)
	if pads.is_empty():
		return "-"
	return pad_name(pads[0])


func key_text(action: String) -> String:
	var parts: PackedStringArray = []
	for k in _keys_for(action):
		parts.append(key_name(k))
	return " / ".join(parts)


func short_text(action: String) -> String:
	if using_pad:
		return pad_text(action)
	return key_name(_keys_for(action)[0])

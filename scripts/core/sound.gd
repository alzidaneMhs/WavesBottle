extends Node

const RATE := 22050
const BPM := 120.0
const BEATS := 16

var sfx: Dictionary = {}
var pool2d: Array = []
var pool: Array = []
var ui_player: AudioStreamPlayer
var next2d := 0
var next_plain := 0
var layers: Array = []
var levels: Array = [0.0, 0.0, 0.0, 0.0]
var targets: Array = [0.7, 0.0, 0.0, 0.0]
var thread: Thread
var music_started := false
var noise_rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	apply_volumes()
	noise_rng.seed = 7341
	_build_sfx()
	for i in 20:
		var p := AudioStreamPlayer2D.new()
		p.bus = "SFX"
		p.max_distance = 2600.0
		add_child(p)
		pool2d.append(p)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		pool.append(p)
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "UI"
	add_child(ui_player)
	for i in 4:
		var m := AudioStreamPlayer.new()
		m.bus = "Music"
		m.volume_db = -80.0
		add_child(m)
		layers.append(m)
	thread = Thread.new()
	thread.start(_build_music)


func _exit_tree() -> void:
	if thread != null and thread.is_started():
		thread.wait_to_finish()
	for m in layers:
		(m as AudioStreamPlayer).stop()
		(m as AudioStreamPlayer).stream = null
	for p in pool2d:
		(p as AudioStreamPlayer2D).stop()
		(p as AudioStreamPlayer2D).stream = null
	for q in pool:
		(q as AudioStreamPlayer).stop()
		(q as AudioStreamPlayer).stream = null
	ui_player.stream = null
	sfx.clear()


func _setup_buses() -> void:
	for n in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(n) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, n)
			AudioServer.set_bus_send(idx, "Master")


func apply_volumes() -> void:
	var map := {"Master": "master", "Music": "music", "SFX": "sfx", "UI": "ui"}
	for bus in map.keys():
		var idx := AudioServer.get_bus_index(bus)
		if idx == -1:
			continue
		var v: float = float(SaveData.setting(map[bus]))
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(idx, v <= 0.001)


func play(id: String, pos: Variant = null, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not sfx.has(id):
		return
	if pos is Vector2:
		var p: AudioStreamPlayer2D = pool2d[next2d]
		next2d = (next2d + 1) % pool2d.size()
		p.stream = sfx[id]
		p.global_position = pos
		p.volume_db = volume_db
		p.pitch_scale = pitch
		p.play()
	else:
		var q: AudioStreamPlayer = pool[next_plain]
		next_plain = (next_plain + 1) % pool.size()
		q.stream = sfx[id]
		q.volume_db = volume_db
		q.pitch_scale = pitch
		q.play()


func ui(id: String = "click") -> void:
	if not sfx.has(id):
		return
	ui_player.stream = sfx[id]
	ui_player.play()


func set_music(base: float, combat: float, high: float, boss: float) -> void:
	targets = [base, combat, high, boss]


func _process(delta: float) -> void:
	if not music_started:
		return
	for i in 4:
		levels[i] = move_toward(float(levels[i]), float(targets[i]), delta * 0.5)
		var m: AudioStreamPlayer = layers[i]
		m.volume_db = linear_to_db(maxf(float(levels[i]) * 0.85, 0.0001))


func _to_stream(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s


func _boom(length: float, f_start: float, f_end: float, decay: float, noise_amt: float, lp: float, tone_amt: float) -> PackedFloat32Array:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := f_end + (f_start - f_end) * exp(-t * 14.0)
		phase += TAU * f / RATE
		low += (noise_rng.randf_range(-1.0, 1.0) - low) * lp
		var env := exp(-t * decay) * minf(1.0, t * 400.0)
		out[i] = (sin(phase) * tone_amt + low * noise_amt * 2.0) * env
	return out


func _tones(freqs: Array, step: float, amp: float, decay: float) -> PackedFloat32Array:
	var n := int(step * freqs.size() * RATE + 0.1 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for k in freqs.size():
		var start := int(k * step * RATE)
		var f: float = freqs[k]
		var seg := int((step + 0.1) * RATE)
		for i in seg:
			var idx := start + i
			if idx >= n:
				break
			var t := float(i) / RATE
			var v := sin(TAU * f * t) * 0.7 + sin(TAU * f * 2.0 * t) * 0.2
			out[idx] += v * amp * exp(-t * decay) * minf(1.0, t * 300.0)
	return out


func _square(freq: float, on_time: float, gaps: int, amp: float) -> PackedFloat32Array:
	var n := int((on_time * 2.0) * gaps * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var slot := int(t / on_time)
		if slot % 2 == 1:
			continue
		out[i] = (1.0 if sin(TAU * freq * t) > 0.0 else -1.0) * amp
	return out


func _swell(length: float, lp: float, amp: float) -> PackedFloat32Array:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0
	for i in n:
		var t := float(i) / length / RATE
		low += (noise_rng.randf_range(-1.0, 1.0) - low) * lp
		out[i] = low * amp * sin(PI * t) * 2.5
	return out


func _build_sfx() -> void:
	sfx["cannon"] = _to_stream(_boom(0.6, 150.0, 45.0, 7.0, 0.55, 0.22, 0.8))
	sfx["enemy_cannon"] = _to_stream(_boom(0.45, 220.0, 70.0, 9.0, 0.5, 0.3, 0.6))
	sfx["impact"] = _to_stream(_boom(0.18, 420.0, 140.0, 26.0, 0.7, 0.6, 0.4))
	sfx["splash"] = _to_stream(_boom(0.32, 300.0, 200.0, 10.0, 0.6, 0.12, 0.0))
	sfx["explosion"] = _to_stream(_boom(1.0, 90.0, 28.0, 3.5, 0.9, 0.07, 0.7))
	sfx["hurt"] = _to_stream(_boom(0.35, 240.0, 70.0, 9.0, 0.7, 0.35, 0.7))
	sfx["ready"] = _to_stream(_tones([880.0, 1320.0], 0.05, 0.22, 30.0))
	sfx["tier_up"] = _to_stream(_tones([523.0, 659.0, 784.0, 1046.0], 0.07, 0.3, 12.0))
	sfx["tier_down"] = _to_stream(_tones([784.0, 587.0, 440.0], 0.09, 0.3, 10.0))
	sfx["salvage"] = _to_stream(_tones([1318.0, 1975.0], 0.06, 0.18, 14.0))
	sfx["click"] = _to_stream(_tones([1000.0], 0.03, 0.25, 40.0))
	sfx["confirm"] = _to_stream(_tones([660.0, 990.0], 0.06, 0.3, 18.0))
	sfx["deny"] = _to_stream(_tones([220.0, 180.0], 0.07, 0.3, 14.0))
	sfx["warning"] = _to_stream(_square(660.0, 0.09, 2, 0.16))
	sfx["fuse"] = _to_stream(_tones([1500.0], 0.03, 0.18, 50.0))
	sfx["wind"] = _to_stream(_swell(1.4, 0.05, 0.6))
	sfx["dodge"] = _to_stream(_swell(0.22, 0.4, 0.5))
	sfx["boss"] = _to_stream(_boom(1.8, 82.0, 55.0, 1.6, 0.25, 0.05, 0.9))


func _build_music() -> void:
	var beat := 60.0 / BPM
	var total := int(beat * BEATS * RATE)
	var base := PackedFloat32Array()
	var combat := PackedFloat32Array()
	var high := PackedFloat32Array()
	var boss := PackedFloat32Array()
	base.resize(total)
	combat.resize(total)
	high.resize(total)
	boss.resize(total)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9917
	var roots := [110.0, 87.31, 130.81, 98.0]
	var thirds := [1.1892, 1.2599, 1.2599, 1.2599]
	var low := 0.0
	var hp_low := 0.0
	for i in total:
		var t := float(i) / RATE
		var b := t / beat
		var bar := int(b / 4.0) % 4
		var root: float = roots[bar]
		var third: float = thirds[bar]
		var in_beat := fmod(b, 1.0) * beat
		var in_eighth := fmod(b * 2.0, 1.0) * beat * 0.5
		var in_six := fmod(b * 4.0, 1.0) * beat * 0.25
		var eighth := int(b * 2.0)
		var six := int(b * 4.0)
		var beat_i := int(b)
		var nz := rng.randf_range(-1.0, 1.0)
		low += (nz - low) * 0.02
		hp_low += (nz - hp_low) * 0.5
		var hp := nz - hp_low
		var pad := sin(TAU * root * t) * 0.35 + sin(TAU * root * 1.5 * t) * 0.22 + sin(TAU * root * 2.0 * t) * 0.15 + sin(TAU * root * third * 2.0 * t) * 0.12
		pad *= 0.75 + 0.25 * sin(TAU * 0.25 * t)
		var kick := 0.0
		if beat_i % 2 == 0:
			var kf := 45.0 + 70.0 * exp(-in_beat * 30.0)
			kick = sin(TAU * kf * in_beat) * exp(-in_beat * 9.0)
		base[i] = pad * 0.22 + kick * 0.45 + low * 0.5
		var hat := hp * exp(-in_eighth * 60.0) * 0.35
		var snare := 0.0
		if beat_i % 2 == 1:
			snare = (nz * 0.6 + sin(TAU * 185.0 * in_beat) * 0.4) * exp(-in_beat * 14.0)
		var bass_f := root * (0.5 if eighth % 4 != 3 else 0.75)
		var bass := (sin(TAU * bass_f * in_eighth) + 0.35 * sin(TAU * bass_f * 2.0 * in_eighth)) * exp(-in_eighth * 6.0)
		combat[i] = hat * 0.5 + snare * 0.4 + bass * 0.45
		var arp_notes := [root * 4.0, root * 4.0 * third, root * 6.0, root * 8.0]
		var af: float = arp_notes[six % 4]
		var pluck := sin(TAU * af * in_six) * 0.6 + sin(TAU * af * 2.0 * in_six) * 0.15
		high[i] = pluck * exp(-in_six * 16.0) * 0.32
		var saw := 0.0
		var bf := root * 0.5
		for h in range(1, 6):
			saw += sin(TAU * bf * h * t) / h
		var pulse := 0.55 + 0.45 * exp(-in_beat * 5.0)
		var tom := 0.0
		if six % 3 == 0:
			tom = sin(TAU * (90.0 + 60.0 * exp(-in_six * 25.0)) * in_six) * exp(-in_six * 12.0)
		boss[i] = saw * pulse * 0.2 + tom * 0.35
	var streams := [_to_stream(base, true), _to_stream(combat, true), _to_stream(high, true), _to_stream(boss, true)]
	call_deferred("_start_music", streams)


func _start_music(streams: Array) -> void:
	thread.wait_to_finish()
	for i in 4:
		var m: AudioStreamPlayer = layers[i]
		m.stream = streams[i]
		m.play()
	music_started = true

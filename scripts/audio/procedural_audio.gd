extends Node
## Процедурный звуковой движок (Autoload: ProceduralAudio)
## Генерирует звуки в реальном времени через AudioStreamGenerator без внешних аудиофайлов.

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _sample_rate: float = 22050.0
var _phase: float = 0.0
var _ambient_phase: float = 0.0

var is_daytime: bool = true
var muted: bool = false

# Активный звуковой импульс (частота, спад, шум, длительность)
var _active_tones: Array[Dictionary] = []
var _ambience_timer: float = 0.0
var _cello_timer: float = 8.0

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = _sample_rate
	gen.buffer_length = 0.12
	_player.stream = gen
	_player.bus = "Master"
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(delta: float) -> void:
	_ambience_timer -= delta
	if _ambience_timer <= 0.0:
		_ambience_timer = 2.6 + randf() * 1.8
		if is_daytime:
			_trigger_bird_chirp()
		elif not GameState.blackout:
			_trigger_cricket_chirp()

	if not is_daytime and not GameState.blackout:
		_cello_timer -= delta
		if _cello_timer <= 0.0:
			_cello_timer = 14.0 + randf() * 5.0
			_trigger_cello_drone()

	_fill_audio_buffer()

func _fill_audio_buffer() -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return

	var dt := 1.0 / _sample_rate
	for _i in range(frames):
		if muted:
			_playback.push_frame(Vector2.ZERO)
			continue

		var sample := 0.0

		# Мягкий фоновый гул кулеров серверной ночью
		if not is_daytime and not GameState.blackout:
			_ambient_phase = fmod(_ambient_phase + 55.0 * dt, 1.0)
			sample += sin(_ambient_phase * TAU) * 0.015
			sample += (randf() * 2.0 - 1.0) * 0.008

		# Синтез активных звуковых событий
		for idx in range(_active_tones.size() - 1, -1, -1):
			var t: Dictionary = _active_tones[idx]
			var elapsed: float = float(t["elapsed"])
			var dur: float = float(t["duration"])
			if elapsed >= dur:
				_active_tones.remove_at(idx)
				continue

			var progress := elapsed / dur
			var env := 1.0 - progress
			var freq: float = lerpf(float(t["freq_start"]), float(t["freq_end"]), progress)
			var ph: float = fmod(float(t["phase"]) + freq * dt, 1.0)
			t["phase"] = ph
			t["elapsed"] = elapsed + dt

			var wave := sin(ph * TAU)
			if t.get("wave", "sine") == "saw":
				wave = ph * 2.0 - 1.0
			elif t.get("wave", "sine") == "square":
				wave = 1.0 if ph < 0.5 else -1.0

			var noise_amt: float = float(t.get("noise", 0.0))
			if noise_amt > 0.0:
				wave = lerpf(wave, randf() * 2.0 - 1.0, noise_amt)

			sample += wave * float(t["gain"]) * env

		sample = clampf(sample, -0.85, 0.85)
		_playback.push_frame(Vector2(sample, sample))

func _add_tone(freq_start: float, freq_end: float, duration: float, gain: float, wave: String = "sine", noise: float = 0.0) -> void:
	_active_tones.append({
		"freq_start": freq_start,
		"freq_end": freq_end,
		"duration": duration,
		"gain": gain,
		"wave": wave,
		"noise": noise,
		"phase": 0.0,
		"elapsed": 0.0
	})

func set_daytime(day: bool) -> void:
	is_daytime = day

func _trigger_bird_chirp() -> void:
	var notes: Array[float] = [1950.0, 2350.0, 2700.0, 3100.0]
	var base: float = notes[randi() % notes.size()]
	_add_tone(base, base * 1.22, 0.09, 0.06, "sine")

func _trigger_cricket_chirp() -> void:
	_add_tone(4500.0, 4250.0, 0.05, 0.035, "sine")

func _trigger_cello_drone() -> void:
	var notes := [65.41, 77.78, 87.31, 98.0]
	var f: float = notes[randi() % notes.size()]
	_add_tone(f, f * 0.99, 3.2, 0.09, "saw", 0.05)

func play_switch(state: bool) -> void:
	_add_tone(620.0 if state else 420.0, 280.0, 0.055, 0.22, "square", 0.15)

func play_key_click() -> void:
	var f := 800.0 + randf() * 350.0
	_add_tone(f, f * 0.5, 0.035, 0.16, "square", 0.25)

func play_gate_slam() -> void:
	_add_tone(140.0, 42.0, 0.32, 0.35, "saw", 0.45)

func play_ping(danger: bool) -> void:
	if danger:
		_add_tone(880.0, 220.0, 0.35, 0.32, "saw", 0.2)
	else:
		_add_tone(1046.0, 1046.0, 0.14, 0.18, "sine")

func play_duck_squeak() -> void:
	_add_tone(700.0, 1450.0, 0.14, 0.26, "sine")

func play_coffee_sip() -> void:
	_add_tone(320.0, 160.0, 0.18, 0.22, "sine", 0.55)

func play_cabinet_creak() -> void:
	_add_tone(140.0, 290.0, 0.28, 0.22, "saw", 0.15)

func play_coin_sound() -> void:
	_add_tone(987.77, 1318.51, 0.26, 0.26, "sine")

func play_error_buzz() -> void:
	_add_tone(160.0, 120.0, 0.20, 0.25, "saw", 0.2)

func play_printer_beep() -> void:
	_add_tone(1200.0, 1400.0, 0.06, 0.14, "square")

func play_tadpole_splat() -> void:
	_add_tone(360.0, 90.0, 0.18, 0.28, "saw", 0.5)

func play_steam_hisser() -> void:
	_add_tone(900.0, 400.0, 0.42, 0.30, "sine", 0.85)

func play_vent_click() -> void:
	_add_tone(1600.0, 450.0, 0.04, 0.24, "square", 0.3)

func play_distortion_drone() -> void:
	_add_tone(58.0, 52.0, 0.65, 0.30, "saw", 0.35)

func play_jumpscare_scream() -> void:
	_add_tone(190.0, 95.0, 1.1, 0.45, "saw", 0.45)
	_add_tone(640.0, 1180.0, 0.95, 0.38, "square", 0.35)

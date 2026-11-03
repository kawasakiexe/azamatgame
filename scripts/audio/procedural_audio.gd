extends Node
## Процедурный звуковой движок (Autoload: ProceduralAudio)
## Воссоздаёт уютно-жуткий ночной эмбиент из alfred-game (мягкий розовый шум дождя/леса,
## трели ночных сверчков за окном, редкие низкие ноты виолончели), дневное пение птиц,
## шаги по серверной, искрение проводки, скрип кресла и звуки монстров.

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _sample_rate: float = 22050.0
var _ambient_phase: float = 0.0

# Фильтр розового шума (Paul Kellet's pink noise algorithm из alfred-game)
var _pink_b0: float = 0.0
var _pink_b1: float = 0.0
var _pink_b2: float = 0.0
var _lp_prev: float = 0.0

var is_daytime: bool = true
var muted: bool = false
var window_proximity: float = 0.5 # 0..1 насколько близко игрок к заднему окну леса

var _active_tones: Array[Dictionary] = []
var _ambience_timer: float = 0.8
var _cello_timer: float = 10.0

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
		if is_daytime:
			_ambience_timer = 1.8 + randf() * 1.6
			_trigger_bird_chirp()
		else:
			_ambience_timer = 2.1 + randf() * 1.5
			_trigger_cricket_chirp()

	if not is_daytime and not GameState.blackout:
		_cello_timer -= delta
		if _cello_timer <= 0.0:
			_cello_timer = 15.0 + randf() * 6.0
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

		# 1. Фильтрованный розовый шум из alfred-game (мягкий ночной шелест за окном / гул кулеров)
		var white := randf() * 2.0 - 1.0
		_pink_b0 = 0.99886 * _pink_b0 + white * 0.0555179
		_pink_b1 = 0.99332 * _pink_b1 + white * 0.0750759
		_pink_b2 = 0.96900 * _pink_b2 + white * 0.1538520
		var pink := (_pink_b0 + _pink_b1 + _pink_b2) * 0.045
		_lp_prev = _lp_prev + 0.18 * (pink - _lp_prev)

		if is_daytime:
			sample += _lp_prev * 0.22
		elif GameState.blackout:
			# В блэкауте гул серверов пропадает, остаётся лишь тихий ветер из окна
			sample += _lp_prev * 0.16 * (0.5 + window_proximity * 0.5)
		else:
			_ambient_phase = fmod(_ambient_phase + 52.0 * dt, 1.0)
			sample += _lp_prev * 0.38 + sin(_ambient_phase * TAU) * 0.012

		# 2. Активные синтезируемые звуки
		for idx in range(_active_tones.size() - 1, -1, -1):
			var t: Dictionary = _active_tones[idx]
			var delay_left: float = float(t.get("delay", 0.0))
			if delay_left > 0.0:
				t["delay"] = delay_left - dt
				continue

			var elapsed: float = float(t["elapsed"])
			var dur: float = float(t["duration"])
			if elapsed >= dur:
				_active_tones.remove_at(idx)
				continue

			var progress := elapsed / dur
			var env := sin(progress * PI) if bool(t.get("smooth_env", false)) else (1.0 - progress)
			var freq: float = lerpf(float(t["freq_start"]), float(t["freq_end"]), progress)
			var ph: float = fmod(float(t["phase"]) + freq * dt, 1.0)
			t["phase"] = ph
			t["elapsed"] = elapsed + dt

			var wave := sin(ph * TAU)
			var wtype: String = String(t.get("wave", "sine"))
			if wtype == "saw":
				wave = ph * 2.0 - 1.0
			elif wtype == "square":
				wave = 1.0 if ph < 0.5 else -1.0
			elif wtype == "triangle":
				wave = 1.0 - 4.0 * abs(round(ph - 0.25) - (ph - 0.25))

			var noise_amt: float = float(t.get("noise", 0.0))
			if noise_amt > 0.0:
				wave = lerpf(wave, randf() * 2.0 - 1.0, noise_amt)

			sample += wave * float(t["gain"]) * env

		sample = clampf(sample, -0.88, 0.88)
		_playback.push_frame(Vector2(sample, sample))

func _add_tone(freq_start: float, freq_end: float, duration: float, gain: float, wave: String = "sine", noise: float = 0.0, delay: float = 0.0, smooth_env: bool = false) -> void:
	_active_tones.append({
		"freq_start": freq_start,
		"freq_end": freq_end,
		"duration": duration,
		"gain": gain,
		"wave": wave,
		"noise": noise,
		"delay": delay,
		"smooth_env": smooth_env,
		"phase": 0.0,
		"elapsed": 0.0
	})

func set_daytime(day: bool) -> void:
	is_daytime = day

# --- Уютное пение птиц днём и сверчки ночью (из alfred-game) ---
func _trigger_bird_chirp() -> void:
	var notes: Array[float] = [1900.0, 2300.0, 2750.0, 3200.0, 2450.0]
	var count := 2 + (randi() % 3)
	for i in range(count):
		var f: float = notes[randi() % notes.size()]
		_add_tone(f, f * 1.18, 0.075, 0.045, "sine", 0.0, float(i) * 0.09, true)

func _trigger_cricket_chirp() -> void:
	var count := 2 + (randi() % 3)
	var prox_gain := 0.018 + window_proximity * 0.025
	for i in range(count):
		var f := 4550.0 + randf() * 350.0
		_add_tone(f, 4280.0, 0.048, prox_gain, "sine", 0.0, float(i) * 0.085, true)

func _trigger_cello_drone() -> void:
	var notes: Array[float] = [65.41, 77.78, 87.31, 98.00]
	var f: float = notes[randi() % notes.size()]
	_add_tone(f, f * 0.995, 4.2, 0.065, "saw", 0.04, 0.0, true)
	_add_tone(f * 1.5, f * 1.49, 4.0, 0.035, "triangle", 0.02, 0.0, true)

# --- Звуки передвижения, кресла и взаимодействия ---
func play_footstep() -> void:
	var f := 115.0 + randf() * 30.0
	_add_tone(f, 48.0, 0.075, 0.16, "triangle", 0.55)

func play_chair_creak(sitting_down: bool) -> void:
	if sitting_down:
		_add_tone(240.0, 130.0, 0.18, 0.20, "saw", 0.25)
	else:
		_add_tone(140.0, 260.0, 0.16, 0.18, "saw", 0.25)

func play_switch(state: bool) -> void:
	_add_tone(640.0 if state else 420.0, 260.0, 0.055, 0.22, "square", 0.15)

func play_key_click() -> void:
	var f := 820.0 + randf() * 360.0
	_add_tone(f, f * 0.5, 0.035, 0.16, "square", 0.25)

func play_gate_slam() -> void:
	_add_tone(135.0, 40.0, 0.34, 0.36, "saw", 0.45)

func play_ping(danger: bool) -> void:
	if danger:
		_add_tone(880.0, 210.0, 0.36, 0.34, "saw", 0.2)
	else:
		_add_tone(1046.0, 1046.0, 0.12, 0.18, "sine")

func play_duck_squeak() -> void:
	_add_tone(650.0, 1450.0, 0.08, 0.26, "triangle")
	_add_tone(1450.0, 480.0, 0.09, 0.24, "triangle", 0.0, 0.08)

func play_coffee_sip() -> void:
	_add_tone(320.0, 150.0, 0.18, 0.22, "sine", 0.55)

func play_cabinet_creak() -> void:
	_add_tone(130.0, 310.0, 0.28, 0.22, "saw", 0.15)

func play_spark() -> void:
	_add_tone(1800.0, 420.0, 0.09, 0.28, "saw", 0.75)

func play_coin_sound() -> void:
	_add_tone(987.77, 987.77, 0.08, 0.26, "sine")
	_add_tone(1318.51, 1318.51, 0.28, 0.26, "sine", 0.0, 0.08)

func play_error_buzz() -> void:
	_add_tone(155.0, 115.0, 0.22, 0.26, "saw", 0.25)

func play_printer_beep() -> void:
	_add_tone(1250.0, 1450.0, 0.055, 0.14, "square")

func play_tadpole_splat() -> void:
	_add_tone(380.0, 85.0, 0.18, 0.30, "saw", 0.5)

func play_steam_hisser() -> void:
	_add_tone(920.0, 380.0, 0.45, 0.32, "sine", 0.88)

func play_vent_click() -> void:
	_add_tone(1650.0, 460.0, 0.04, 0.25, "square", 0.3)
	_add_tone(1450.0, 420.0, 0.04, 0.20, "square", 0.3, 0.11)

func play_monster_step() -> void:
	_add_tone(92.0, 36.0, 0.22, 0.28, "triangle", 0.4)

func play_distortion_drone() -> void:
	_add_tone(58.0, 51.0, 0.68, 0.30, "saw", 0.35)

func play_jumpscare_scream() -> void:
	_add_tone(195.0, 90.0, 1.15, 0.46, "saw", 0.45)
	_add_tone(660.0, 1220.0, 0.98, 0.40, "square", 0.35)

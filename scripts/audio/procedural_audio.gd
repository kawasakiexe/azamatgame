extends Node
## Процедурный звуковой движок (Autoload: ProceduralAudio)
## Включает:
## - Уютно-жуткий ночной эмбиент загородного леса (розовый шум + сверчки у окна)
## - Редкую глубокую басовую виолончель и тревожную скрипку с вибрато и гармониками
## - Индивидуальные резкие многослойные скримеры для каждого монстра!

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _sample_rate: float = 22050.0
var _ambient_phase: float = 0.0

# Фильтр розового шума (из alfred-game)
var _pink_b0: float = 0.0
var _pink_b1: float = 0.0
var _pink_b2: float = 0.0
var _lp_prev: float = 0.0

var is_daytime: bool = true
var muted: bool = false
var window_proximity: float = 0.5

var _active_tones: Array[Dictionary] = []
var _ambience_timer: float = 0.8
var _cello_timer: float = 9.0

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = _sample_rate
	gen.buffer_length = 0.10
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
			_ambience_timer = 2.2 + randf() * 1.6
			_trigger_cricket_chirp()

	# Ночью изредка звучит глубокая басовая виолончель или натянутая скрипка
	if not is_daytime and not GameState.game_over:
		_cello_timer -= delta
		if _cello_timer <= 0.0:
			# Интервал 15–24 сек: не мешает слушать шаги, но держит в постоянном тонусе
			_cello_timer = 15.0 + randf() * 9.0
			_trigger_bowed_horror_strings()

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

		# 1. Мягкий розовый шум леса за окном / гул серверной
		var white := randf() * 2.0 - 1.0
		_pink_b0 = 0.99886 * _pink_b0 + white * 0.0555179
		_pink_b1 = 0.99332 * _pink_b1 + white * 0.0750759
		_pink_b2 = 0.96900 * _pink_b2 + white * 0.1538520
		var pink := (_pink_b0 + _pink_b1 + _pink_b2) * 0.042
		_lp_prev = _lp_prev + 0.18 * (pink - _lp_prev)

		if is_daytime:
			sample += _lp_prev * 0.22
		elif GameState.blackout:
			sample += _lp_prev * 0.15 * (0.5 + window_proximity * 0.5)
		else:
			_ambient_phase = fmod(_ambient_phase + 52.0 * dt, 1.0)
			sample += _lp_prev * 0.34 + sin(_ambient_phase * TAU) * 0.011

		# 2. Синтез активных голосов (включая смычковые струнные и скримеры)
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
			var env := 1.0 - progress
			var env_mode: String = String(t.get("env_mode", "linear"))
			if env_mode == "bowed":
				# Медленная смычковая атака и плавное затухание
				if progress < 0.22:
					env = progress / 0.22
				elif progress > 0.70:
					env = (1.0 - progress) / 0.30
				else:
					env = 1.0
			elif env_mode == "smooth":
				env = sin(progress * PI)
			elif env_mode == "scream":
				# Мгновенный резкий удар в 100% громкости и долгий агрессивный хвост
				env = 1.0 if progress < 0.65 else ((1.0 - progress) / 0.35)

			var freq: float = lerpf(float(t["freq_start"]), float(t["freq_end"]), progress)

			# Вибрато для живой виолончели/скрипки или модуляции скримера
			var vib_depth: float = float(t.get("vib_depth", 0.0))
			if vib_depth > 0.0:
				var vib_rate: float = float(t.get("vib_rate", 5.2))
				freq += sin(elapsed * vib_rate * TAU) * vib_depth

			var ph: float = fmod(float(t["phase"]) + freq * dt, 1.0)
			t["phase"] = ph
			t["elapsed"] = elapsed + dt

			var wave := 0.0
			var wtype: String = String(t.get("wave", "sine"))
			if wtype == "bowed":
				# Богатый смычковый тембр: фундаментальная частота + 2-я и 3-я гармоники + лёгкое трение канифоли
				wave = sin(ph * TAU) * 0.58 + sin(ph * TAU * 2.0) * 0.26 + sin(ph * TAU * 3.0) * 0.12 + (ph * 2.0 - 1.0) * 0.14
			elif wtype == "saw":
				wave = ph * 2.0 - 1.0
			elif wtype == "square":
				wave = 1.0 if ph < 0.5 else -1.0
			elif wtype == "triangle":
				wave = 1.0 - 4.0 * abs(round(ph - 0.25) - (ph - 0.25))
			else:
				wave = sin(ph * TAU)

			var noise_amt: float = float(t.get("noise", 0.0))
			if noise_amt > 0.0:
				wave = lerpf(wave, randf() * 2.0 - 1.0, noise_amt)

			sample += wave * float(t["gain"]) * env

		sample = clampf(sample, -0.95, 0.95)
		_playback.push_frame(Vector2(sample, sample))

func _add_tone(freq_start: float, freq_end: float, duration: float, gain: float, wave: String = "sine", noise: float = 0.0, delay: float = 0.0, env_mode: String = "linear", vib_depth: float = 0.0, vib_rate: float = 5.2) -> void:
	_active_tones.append({
		"freq_start": freq_start,
		"freq_end": freq_end,
		"duration": duration,
		"gain": gain,
		"wave": wave,
		"noise": noise,
		"delay": delay,
		"env_mode": env_mode,
		"vib_depth": vib_depth,
		"vib_rate": vib_rate,
		"phase": 0.0,
		"elapsed": 0.0
	})

func set_daytime(day: bool) -> void:
	is_daytime = day

# =============================================================================
# Уютное пение птиц днём и сверчки ночью + НАПРЯЖЁННАЯ ВИОЛОНЧЕЛЬ И СКРИПКА
# =============================================================================
func _trigger_bird_chirp() -> void:
	var notes: Array[float] = [1900.0, 2300.0, 2750.0, 3200.0, 2450.0]
	var count := 2 + (randi() % 3)
	for i in range(count):
		var f: float = notes[randi() % notes.size()]
		_add_tone(f, f * 1.18, 0.075, 0.045, "sine", 0.0, float(i) * 0.09, "smooth")

func _trigger_cricket_chirp() -> void:
	var count := 2 + (randi() % 3)
	var prox_gain := 0.016 + window_proximity * 0.024
	for i in range(count):
		var f := 4550.0 + randf() * 350.0
		_add_tone(f, 4280.0, 0.048, prox_gain, "sine", 0.0, float(i) * 0.085, "smooth")

func _trigger_bowed_horror_strings() -> void:
	# Глубокие мрачные басовые ноты виолончели (C1/C2, D#2, F#2 — тритоны и малые секунды)
	var bass_roots: Array[float] = [55.0, 61.74, 65.41, 73.42, 77.78]
	var root: float = bass_roots[randi() % bass_roots.size()]
	var dur := 5.8 + randf() * 2.2

	# 1. Глубокая басовая виолончель (Суб-октава + основная струна с медленным вибрато)
	_add_tone(root * 0.5, root * 0.495, dur, 0.085, "sine", 0.0, 0.0, "bowed", 0.4, 4.2)
	_add_tone(root, root * 0.99, dur, 0.075, "bowed", 0.03, 0.0, "bowed", 0.9, 4.8)

	# 2. Вторая струна (мрачная квинта или пугающая малая секунда/тритон)
	var is_tense := GameState.distortion_active or GameState.burgundy_stage > 0 or GameState.blackout or (GameState.trojan_distance < 45.0)
	var interval := 1.414 if is_tense else 1.498 # Тритон (дьявольский интервал) при угрозе, иначе квинта
	_add_tone(root * interval, root * interval * 0.985, dur * 0.9, 0.045, "bowed", 0.04, 0.35, "bowed", 1.2, 5.2)

	# 3. Изредка (или при близкой опасности) — тонкая холодная нота высокой скрипки (Sul Ponticello)
	if is_tense or randf() < 0.45:
		var violin_f := root * 4.0 * (1.059 if is_tense else 1.5)
		_add_tone(violin_f, violin_f * 0.97, dur * 0.75, 0.028, "bowed", 0.06, 0.8, "bowed", 3.5, 6.0)

# =============================================================================
# ИНДИВИДУАЛЬНЫЕ, РЕЗКИЕ И СТРАШНЫЕ СКРИМЕРЫ ДЛЯ КАЖДОГО МОНСТРА
# =============================================================================
func play_jumpscare_by_type(m_type: String) -> void:
	# Очищаем фоновые тихие звуки, чтобы скример ударил с максимальной резкостью!
	_active_tones.clear()

	match m_type:
		"distortion":
			# ИСКАЗИТЕЛЬ: Разрывающий перепонки саб-удар + расстроенный визг скрипки + цифровой глитч-рев
			_add_tone(110.0, 28.0, 1.6, 0.55, "saw", 0.35, 0.0, "scream", 12.0, 25.0)
			_add_tone(1480.0, 620.0, 1.5, 0.42, "bowed", 0.45, 0.0, "scream", 65.0, 32.0)
			_add_tone(2120.0, 2890.0, 1.3, 0.38, "square", 0.55, 0.04, "scream", 90.0, 40.0)
			for i in range(6):
				_add_tone(400.0 + float(i) * 310.0, 180.0, 0.22, 0.35, "saw", 0.7, float(i) * 0.18, "scream")

		"burgundy":
			# БОРДОВЫЙ ДУШЕГУБ: Грохот выбитой решётки + дикий хищный визг твари + быстрое клацанье челюстей
			_add_tone(180.0, 35.0, 0.45, 0.60, "square", 0.80, 0.0, "scream")
			_add_tone(920.0, 2450.0, 0.45, 0.50, "saw", 0.35, 0.02, "scream", 55.0, 28.0)
			_add_tone(2450.0, 780.0, 1.15, 0.48, "saw", 0.40, 0.35, "scream", 80.0, 35.0)
			for i in range(8):
				_add_tone(1900.0, 320.0, 0.08, 0.42, "square", 0.65, float(i) * 0.14, "scream")

		"trojan":
			# ТРОЯНСКИЙ КОНЬ В T-POSE: Треск раскалывающегося дерева + демоническое ржание и медный горн
			_add_tone(95.0, 42.0, 1.65, 0.58, "saw", 0.50, 0.0, "scream", 8.0, 18.0)
			_add_tone(190.0, 92.0, 1.55, 0.46, "square", 0.30, 0.0, "scream", 15.0, 20.0)
			# Жуткое искажённое лошадиное ржание (высокая частотная модуляция вниз)
			for i in range(5):
				var start_f := 1650.0 - float(i) * 180.0
				_add_tone(start_f, start_f * 0.45, 0.28, 0.44, "saw", 0.35, float(i) * 0.22, "scream", 45.0, 30.0)

		"gas":
			# УДУШЬЕ ГАЗОМ: Пронзительный свист прорванного клапана + глухой предсмертный хрип
			_add_tone(3200.0, 1400.0, 1.5, 0.48, "sine", 0.85, 0.0, "scream", 40.0, 22.0)
			_add_tone(140.0, 48.0, 1.6, 0.52, "saw", 0.45, 0.05, "scream", 18.0, 14.0)

		_:
			# ПУКАН / ВЗЛОМ ИИ: Термоядерный взрыв саб-баса + вой сирены
			_add_tone(160.0, 24.0, 1.7, 0.62, "saw", 0.75, 0.0, "scream")
			_add_tone(880.0, 1760.0, 0.45, 0.48, "square", 0.25, 0.0, "scream")
			_add_tone(1760.0, 440.0, 1.15, 0.48, "square", 0.35, 0.42, "scream", 70.0, 30.0)

# --- Повседневные звуки ---
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

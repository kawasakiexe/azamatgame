extends Node
## Главный синглтон состояния игры (Autoload: GameState)
## Управляет режимами «В кресле» / «На ногах», FNaF-балансом монстров по уровням 1–6,
## починкой проводов в щитке, 5 разными головоломками на монеты и дневным лобби.

signal shift_started(shift_num: int)
signal lobby_entered()
signal seated_changed(seated: bool)
signal screen_opened(screen_id: String) # "", "MAIN_TERM", "CCTV_TERM", "WIRES_BOX", "SHOP_VENDING", "LOBBY_SAFE"
signal event_logged(text: String, level: String)
signal ui_updated()
signal hand_action(action_name: String)
signal jumpscare_triggered(monster_type: String, title: String, desc: String)
signal victory_triggered(shift_num: int)

const SHIFT_CONFIGS := {
	1: {
		"name": "СМЕНА 1: ПОНЕДЕЛЬНИК («Джун на загородном проде»)",
		"subtitle": "Сеньор ушёл в лютый запой. Следи за коридорами и не дай Архитектору порвать тебе очко.",
		"dip_interval": 30.0,
		"dip_timeout": 18.0,
		"base_power_drain": 0.10,
		"distortion_enabled": true,
		"burgundy_enabled": false,
		"trojan_enabled": false,
		"tadpole_enabled": false,
		"gas_enabled": false,
		"blackout_chance": 0.0,
		"trojan_speed": 0.0,
		"puzzle_type": "PIPES",
		"puzzle_name": "CI/CD Канализация: Протолкни говнокод на Прод",
		"phone_msg": "«Алло, салага! Ты теперь ночной дежурный в нашем лесном ЦОДе. Прод держится на соплях и изоленте. По коридорам бродит старый Архитектор-Исказитель — слушай его шаги, чекай камеры на правом мониторе и закрывай нужную дверь! Все двери сразу закрыть нельзя — выбьет нахер автомат! Доживи до 06:00 утра!»"
	},
	2: {
		"name": "СМЕНА 2: ВТОРНИК («Пердёж хладагента и Тварь в трубе»)",
		"subtitle": "В вентиляции скребётся Бордовый Душегуб, а газовая труба в углу начала травить.",
		"dip_interval": 26.0,
		"dip_timeout": 15.5,
		"base_power_drain": 0.12,
		"distortion_enabled": true,
		"burgundy_enabled": true,
		"trojan_enabled": false,
		"tadpole_enabled": false,
		"gas_enabled": true,
		"blackout_chance": 0.0,
		"trojan_speed": 0.0,
		"puzzle_type": "CLUSTER_MATH",
		"puzzle_name": "Балансировка Кластера: Подбери частоту ядра",
		"phone_msg": "«Живой ещё, блять? Короче, две хуёвые новости. Во-первых, в потолочной вентиляции завелась бордовая падаль — услышишь щелчки или увидишь хвост над столом, сразу жми продувку паром в терминале! Во-вторых, труба у стены травит ядовитый пердёж — нажимай [ПРОБЕЛ], вставай с кресла и крути красный вентиль руками!»"
	},
	3: {
		"name": "СМЕНА 3: СРЕДА («Троянский Конь в T-Pose и Гнилая Проводка»)",
		"subtitle": "По центральному тоннелю едет деревянный Конь, а пробки вышибает в тотальную тьму.",
		"dip_interval": 22.0,
		"dip_timeout": 14.0,
		"base_power_drain": 0.14,
		"distortion_enabled": true,
		"burgundy_enabled": true,
		"trojan_enabled": true,
		"tadpole_enabled": false,
		"gas_enabled": true,
		"blackout_chance": 0.045,
		"trojan_speed": 1.45,
		"puzzle_type": "LIGHTS_OUT",
		"puzzle_name": "Дефрагментация Дампа: Зажги все сектора памяти",
		"phone_msg": "«Пиздец подкрался незаметно! По центральному шлюзу поехал Троянский Конь в ебучем T-Pose! Двери его не держат — печатай морковку на 3D-принтере, вставай с кресла и кидай ему в пасть! А если вырубит свет — пиздуй в темноте к заднему окну, там светится щиток: скрути провода по цветам и дёрни рубильник!»"
	},
	4: {
		"name": "СМЕНА 4: ЧЕТВЕРГ («Багогрыз на клавиатуре и Цейтнот»)",
		"subtitle": "Мерзкие головастики лезут прямо на стол и сбивают тумблеры, пока ты бегаешь к вентилю.",
		"dip_interval": 19.0,
		"dip_timeout": 12.5,
		"base_power_drain": 0.16,
		"distortion_enabled": true,
		"burgundy_enabled": true,
		"trojan_enabled": true,
		"tadpole_enabled": true,
		"gas_enabled": true,
		"blackout_chance": 0.06,
		"trojan_speed": 1.85,
		"puzzle_type": "PACKET_ORDER",
		"puzzle_name": "Сортировка Пакетов: Пропихни SQL без дедлока",
		"phone_msg": "«Из канализации полезли Багогрызы-головастики! Эта склизкая мразь прыгает прямо на твой стол и щёлкает тумблеры ядра — лупи по ней мышкой три раза, пока она не уронила прод! И смотри в оба, когда встаёшь с кресла к газу или проводам!»"
	},
	5: {
		"name": "СМЕНА 5: ПЯТНИЦА 13-е («ТЕРМОЯДЕРНАЯ ДЕТОНАЦИЯ ПУКАНА»)",
		"subtitle": "Все 4 монстра комбинируют атаки. За всем нужно следить одновременно.",
		"dip_interval": 16.0,
		"dip_timeout": 11.0,
		"base_power_drain": 0.18,
		"distortion_enabled": true,
		"burgundy_enabled": true,
		"trojan_enabled": true,
		"tadpole_enabled": true,
		"gas_enabled": true,
		"blackout_chance": 0.08,
		"trojan_speed": 2.35,
		"puzzle_type": "WAVE_SYNC",
		"puzzle_name": "Квантовый Резонанс: Синхронизируй синусоиду ядра",
		"phone_msg": "«Пятница, сука, тринадцатое! Все твари сошли с ума и лезут одновременно! Держи ухо востро, не держи двери закрытыми впустую и береги жопу от перегрева до 6 утра!»"
	},
	6: {
		"name": "СВОЯ НОЧЬ: 20/20/20/20 («АД СИСАДМИНА»)",
		"subtitle": "Максимальная агрессия всех тварей и систем. Выживет только кибер-шаман.",
		"dip_interval": 13.5,
		"dip_timeout": 9.5,
		"base_power_drain": 0.20,
		"distortion_enabled": true,
		"burgundy_enabled": true,
		"trojan_enabled": true,
		"tadpole_enabled": true,
		"gas_enabled": true,
		"blackout_chance": 0.10,
		"trojan_speed": 2.85,
		"puzzle_type": "WAVE_SYNC",
		"puzzle_name": "Root Kernel Override: Финальный резонанс",
		"phone_msg": "«Добро пожаловать в персональный ад DevOps-инженера. Надеюсь, ты затарился ништяками в дневном ларьке. С богом, ёпта!»"
	}
}

# --- Позиция и режим игрока ---
var in_lobby: bool = true
var is_seated: bool = false # false = ходит пешком (WASD), true = сидит в кресле у терминалов
var active_screen: String = "" # "", "MAIN_TERM", "CCTV_TERM", "WIRES_BOX", "SHOP_VENDING", "LOBBY_SAFE"
var player_pos: Vector3 = Vector3(0.0, 0.0, 1.45)

# --- Прогрессия и экономика (макс. 3 одноразовые монеты) ---
var current_level: int = 1
var max_unlocked_level: int = 1
var coins: int = 0
var max_coins: int = 3

var active_buffs := {
	"antiTrojanOats": false,
	"titaniumFuse": false,
	"mirrorGlasses": false,
	"asbestosSeat": false,
	"bugRepellent": false
}

# --- Интерактивные пасхалки и секреты Дневного Лобби ---
var cabinet_open: bool = false
var lobby_safe_solved: bool = false
# Секретный код сейфа Сеньора в лобби: 2248 (Порт SSH 22 + 4 тумблера ядра + 8 бит в байте)
const LOBBY_SAFE_CODE := "2248"

# --- Показатели ночной смены ---
var running: bool = false
var game_over: bool = false
var time_seconds: float = 0.0
var total_shift_seconds: float = 180.0 # 3 минуты реального времени = 6 часов ночи (12 AM -> 6 AM)

var power: float = 100.0
var pukan_temp: float = 15.0
var hack_count: int = 0
var max_hacks: int = 5

# --- Оборудование и FNaF-система шлюзов (Нельзя закрыть оба прохода сразу!) ---
var gate_left: bool = false
var gate_right: bool = false
var seat_cooler: bool = false
var dip_switches: Array[int] = [0, 1, 0, 1]
var target_dip: Array[int] = [0, 1, 0, 1]
var dip_puzzle_active: bool = false
var dip_timer: float = 0.0
var dip_max_timer: float = 15.0
var next_dip_countdown: float = 14.0

var ping_left_timer: float = 0.0
var ping_right_timer: float = 0.0
var steam_vent_cooldown: float = 0.0
var current_cam: String = "CAM01"

# --- 4 Монстра (с FNaF-логикой подходов слева/справа/сверху/по центру) ---
# 1. Исказитель / Сутулый Архитектор: ходит по маршруту CAM01 -> CAM02 (Лево) или CAM04 (Право) -> Дверь (DOOR_LEFT / DOOR_RIGHT) или Окно (WINDOW_BACK)
var distortion_active: bool = false
var distortion_pos: String = "NONE" # NONE, CAM02_APPROACH, CAM04_APPROACH, DOOR_LEFT, DOOR_RIGHT, WINDOW_BACK
var distortion_stare_timer: float = 0.0
var distortion_door_timer: float = 0.0
var distortion_next_spawn: float = 10.0
var player_looking_at_sector: String = "DESK"

# 2. Багогрыз-Головастик (с 4-й смены)
var tadpole_active: bool = false
var tadpole_health: int = 3
var tadpole_x: float = 0.0
var tadpole_mess_timer: float = 3.5
var tadpole_next_spawn: float = 18.0

# 3. Троянский Конь в T-Pose (с 3-й смены)
var trojan_distance: float = 100.0
var trojan_speed: float = 0.0
var trojan_in_room: bool = false
var trojan_gamble_timer: float = 0.0
var trojan_gamble_resolved: bool = false

# 4. Бордовый Душегуб в вентиляции (со 2-й смены)
var burgundy_stage: int = 0 # 0 = пусто, 1 = ползёт в CAM06, 2 = свесил хвост из решётки над столом
var burgundy_click_cooldown: float = 4.0
var burgundy_attack_timer: float = 0.0
var burgundy_move_cooldown: float = 6.5

# --- Помехи в комнате (требуют встать с кресла!) ---
var gas_pressure: float = 0.0
var gas_leaking: bool = false
var valve_angle: float = 0.0

var blackout: bool = false
var wires_fixed: bool = true
var wire_connections: Array[bool] = [true, true, true, true] # 4 цветных провода в щитке
var selected_wire_color: int = -1

var printer_working: bool = false
var printer_progress: float = 0.0
var carrots_count: int = 1
var holding_carrot: bool = false

# --- 5 Разных головоломок на уровнях для получения монеты ---
var puzzle_solved_this_shift: bool = false
# 1) PIPES (3x3 связная трасса от (0,0) до (2,2))
var pipe_grid: Array[Dictionary] = []
# 2) CLUSTER_MATH (4 множителя воркеров)
var cluster_sliders: Array[int] = [2, 1, 3, 1]
var cluster_weights: Array[int] = [45, 30, 60, 15]
var cluster_target_mhz: int = 345
# 3) LIGHTS_OUT (3x3 битовая матрица)
var lights_grid: Array[int] = [1, 0, 1, 0, 0, 0, 1, 0, 1]
# 4) PACKET_ORDER (последовательность из 6 пакетов)
var packet_numbers: Array[int] = [404, 22, 80, 5432, 3000, 9000]
var packet_next_idx: int = 0
# 5) WAVE_SYNC (Частота, Фаза, Амплитуда)
var wave_player: Array[int] = [2, 1, 4]
var wave_target: Array[int] = [4, 3, 2]

var event_log: Array[Dictionary] = []

func _ready() -> void:
	_init_shift_puzzle(1)
	add_event_log("☀️ Загородный ЦОД (Дневное Лобби). Ходи на [WASD], изучай комнату или садись в кресло!", "info")

func _process(delta: float) -> void:
	if ping_left_timer > 0.0:
		ping_left_timer = max(0.0, ping_left_timer - delta)
	if ping_right_timer > 0.0:
		ping_right_timer = max(0.0, ping_right_timer - delta)
	if steam_vent_cooldown > 0.0:
		steam_vent_cooldown = max(0.0, steam_vent_cooldown - delta)

	# В дневном лобби полная безопасность, никакие таймеры угроз не тикают
	if in_lobby or not running or game_over:
		return

	var cfg: Dictionary = SHIFT_CONFIGS.get(current_level, SHIFT_CONFIGS[1])

	# 1. Главная цель уровня — дожить до 06:00 AM!
	time_seconds += delta
	if time_seconds >= total_shift_seconds:
		trigger_victory()
		return

	# 2. Расход заряда ИБП и случайные выбивания пробок (с 3-й смены)
	if not blackout and power > 0.0:
		var bars := get_usage_bars()
		var drain: float = float(cfg["base_power_drain"]) * (1.0 + float(bars - 1) * 0.85)
		power = max(0.0, power - drain * delta)
		if power <= 0.0:
			_trip_power_blackout("⚡ ИБП СЕЛ В НОЛЬ! Беги к заднему окну, чини провода в щитке и врубай резервный рубильник!")

	var b_chance: float = float(cfg["blackout_chance"])
	if not blackout and not active_buffs["titaniumFuse"] and b_chance > 0.0:
		if randf() < delta * b_chance * 0.12:
			_trip_power_blackout("⚡ ПРОБКИ ВЫШИБЛО К ХУЯМ! Нажми [ПРОБЕЛ], иди к светящемуся щитку у окна, соедини провода и дёрни рычаг!")

	# 3. Нагрев Пуканометра (только ночью!)
	var heat_rate: float = 0.52
	if dip_puzzle_active:
		heat_rate += 1.35
	if gas_pressure > 45.0:
		heat_rate += 1.75
	if tadpole_active:
		heat_rate += 1.25
	heat_rate += float(hack_count) * 0.85

	if active_buffs["asbestosSeat"]:
		heat_rate *= 0.6

	if seat_cooler and is_seated and power > 0.0 and not blackout:
		heat_rate -= 4.6

	pukan_temp = clampf(pukan_temp + heat_rate * delta, 0.0, 100.0)
	if pukan_temp >= 100.0:
		trigger_jumpscare("pukan", "СВЕРХНОВАЯ ДЕТОНАЦИЯ ПУКАНА (100°C)!", "Твой пердак раскалился до состояния плазмы и разнёс загородный ЦОД в щепки!")
		return

	# 4. Мутация тумблеров ядра SW1-4 на столе
	if not dip_puzzle_active:
		next_dip_countdown -= delta
		if next_dip_countdown <= 0.0:
			_spawn_dip_puzzle(cfg)
	else:
		dip_timer -= delta
		if dip_timer <= 0.0:
			dip_puzzle_active = false
			next_dip_countdown = float(cfg["dip_interval"]) * 0.8
			increment_hack("Тумблеры ядра SW1-4 не выставлены вовремя! Дамп памяти просран!")
			if game_over:
				return

	# 5. Обновление помех (газ, 3D-принтер) и 4 монстров
	_update_hazards(delta, cfg)
	_update_monsters(delta, cfg)
	ui_updated.emit()

func _update_hazards(delta: float, cfg: Dictionary) -> void:
	if bool(cfg["gas_enabled"]) and gas_leaking:
		gas_pressure = min(100.0, gas_pressure + 2.0 * delta)
		if gas_pressure >= 100.0:
			trigger_jumpscare("gas", "УДУШЬЕ СЕРОВОДОРОДОМ (ГАЗ 100%)!", "Комната заполнилась токсичным пердежом хладагента! Надо было встать и закрутить вентиль у стены!")
			return

	if printer_working and not blackout and power > 0.0:
		printer_progress = min(100.0, printer_progress + 12.0 * delta)
		if randf() < delta * 1.4:
			ProceduralAudio.play_printer_beep()
		if printer_progress >= 100.0:
			printer_working = false
			carrots_count += 1
			ProceduralAudio.play_coin_sound()
			add_event_log("🥕 3D-Биопринтер высрал свежую морковку! (На столе: %d шт.)" % carrots_count, "ok")

func _update_monsters(delta: float, cfg: Dictionary) -> void:
	# -------------------------------------------------------------------------
	# 1. ИСКАЗИТЕЛЬ / АРХИТЕКТОР (С 1-й смены: FNaF-подход слева/справа + окно)
	# -------------------------------------------------------------------------
	if bool(cfg["distortion_enabled"]):
		if not distortion_active:
			distortion_next_spawn -= delta
			if distortion_next_spawn <= 0.0:
				distortion_active = true
				var routes := ["CAM02_APPROACH", "CAM04_APPROACH", "WINDOW_BACK"]
				distortion_pos = routes[randi() % routes.size()]
				distortion_stare_timer = 0.0
				distortion_door_timer = max(5.5, 9.0 - float(current_level) * 0.5)
				ProceduralAudio.play_monster_step()
				if distortion_pos == "CAM02_APPROACH":
					add_event_log("👣 Тяжёлые шаги в ЛЕВОМ коридоре (CAM 02 -> Порт 22)!", "warn")
				elif distortion_pos == "CAM04_APPROACH":
					add_event_log("👣 Тяжёлые шаги в ПРАВОМ коридоре (CAM 04 -> Порт 5432)!", "warn")
				else:
					ProceduralAudio.play_distortion_drone()
					add_event_log("👁️ За ЗАДНИМ ОКНОМ в лесу стоит Исказитель! НЕ СМОТРИ НА ОКНО!", "danger")
		else:
			distortion_door_timer -= delta
			# Переход из коридора вплотную к дверному проёму
			if distortion_pos == "CAM02_APPROACH" and distortion_door_timer <= 4.2:
				distortion_pos = "DOOR_LEFT"
				ProceduralAudio.play_distortion_drone()
				add_event_log("🚨 ИСКАЗИТЕЛЬ У ЛЕВОЙ ДВЕРИ (Порт 22)! Закрой левый шлюз в терминале и не пялься на него!", "danger")
			elif distortion_pos == "CAM04_APPROACH" and distortion_door_timer <= 4.2:
				distortion_pos = "DOOR_RIGHT"
				ProceduralAudio.play_distortion_drone()
				add_event_log("🚨 ИСКАЗИТЕЛЬ У ПРАВОЙ ДВЕРИ (Порт 5432)! Закрой правый шлюз в терминале и не пялься на него!", "danger")

			# Проверка прямого взгляда на Исказителя
			var blocked_by_door := false
			if distortion_pos == "DOOR_LEFT" and gate_left:
				blocked_by_door = true
			elif distortion_pos == "DOOR_RIGHT" and gate_right:
				blocked_by_door = true

			var max_stare := 4.5 if active_buffs["mirrorGlasses"] else 1.8
			if player_looking_at_sector == distortion_pos and not blocked_by_door and active_screen == "":
				distortion_stare_timer += delta
				pukan_temp = min(100.0, pukan_temp + 9.0 * delta)
				if randf() < delta * 3.0:
					ProceduralAudio.play_distortion_drone()
				if distortion_stare_timer >= max_stare:
					trigger_jumpscare("distortion", "АРХИТЕКТОР-ИСКАЗИТЕЛЬ ВЫЖЕГ ТЕБЕ ГЛАЗА!", "Нельзя пялиться в его ебало дольше %.1f сек без закрытой двери!" % max_stare)
					return
			else:
				distortion_stare_timer = max(0.0, distortion_stare_timer - delta * 1.5)

			# Когда таймер подхода у двери истёк:
			if distortion_door_timer <= 0.0:
				if (distortion_pos == "DOOR_LEFT" and not gate_left) or (distortion_pos == "DOOR_RIGHT" and not gate_right):
					trigger_jumpscare("distortion", "ИСКАЗИТЕЛЬ ПРОРВАЛ ОТКРЫТЫЙ ШЛЮЗ!", "Он стоял прямо под дверью, а ты не перекрыл соответствующий проход!")
					return
				else:
					if distortion_pos == "DOOR_LEFT" or distortion_pos == "DOOR_RIGHT":
						ProceduralAudio.play_gate_slam()
						add_event_log("🛡️ БУМ! Исказитель ударился башкой о закрытую гермодверь и ушёл в лес!", "ok")
					else:
						add_event_log("👁️ Силуэт за лесным окном растворился в темноте...", "ok")
					distortion_active = false
					distortion_pos = "NONE"
					distortion_stare_timer = 0.0
					distortion_next_spawn = max(7.0, 14.0 - float(current_level)) + randf() * 6.0

	# -------------------------------------------------------------------------
	# 2. БОРДОВЫЙ ДУШЕГУБ В ВЕНТИЛЯЦИИ (Со 2-й смены)
	# -------------------------------------------------------------------------
	if bool(cfg["burgundy_enabled"]):
		burgundy_click_cooldown -= delta
		if burgundy_click_cooldown <= 0.0:
			burgundy_click_cooldown = 3.8 + randf() * 2.5
			if burgundy_stage > 0:
				ProceduralAudio.play_vent_click()

		burgundy_move_cooldown -= delta
		if burgundy_move_cooldown <= 0.0:
			burgundy_move_cooldown = max(4.2, 6.8 - float(current_level) * 0.35)
			if burgundy_stage == 0 and randf() < 0.52:
				burgundy_stage = 1
				ProceduralAudio.play_vent_click()
				add_event_log("🩸 В вент-шахте (CAM 06) слышно клацанье когтей: клик-клик...", "warn")
			elif burgundy_stage == 1:
				burgundy_stage = 2
				burgundy_attack_timer = max(4.8, 6.5 - float(current_level) * 0.25)
				ProceduralAudio.play_vent_click()
				add_event_log("🚨 БОРДОВЫЙ ХВОСТ ТОРЧИТ ИЗ ПОТОЛКА НАД КРЕСЛОМ! Дай продувку паром в терминале!", "danger")

		if burgundy_stage == 2:
			burgundy_attack_timer -= delta
			if burgundy_attack_timer <= 0.0:
				trigger_jumpscare("burgundy", "БОРДОВЫЙ ДУШЕГУБ СПРЫГНУЛ С ПОТОЛКА ТЕБЕ НА ЛИЦО!", "Ты проебал момент и не ошпарил вентиляционную шахту паром!")
				return

	# -------------------------------------------------------------------------
	# 3. ТРОЯНСКИЙ КОНЬ В T-POSE (Строго с 3-й смены!)
	# -------------------------------------------------------------------------
	if bool(cfg["trojan_enabled"]):
		if not trojan_in_room:
			trojan_distance = max(0.0, trojan_distance - trojan_speed * delta)
			if trojan_distance <= 0.0:
				trojan_in_room = true
				trojan_gamble_timer = 2.5
				trojan_gamble_resolved = false
				ProceduralAudio.play_gate_slam()
				add_event_log("🐴 ЕБАТЬ! ТРОЯНСКИЙ КОНЬ ВЪЕХАЛ В КАБИНЕТ В T-POSE! РУЛЕТКА 50/50!", "danger")
		elif not trojan_gamble_resolved:
			trojan_gamble_timer -= delta
			if trojan_gamble_timer <= 0.0:
				trojan_gamble_resolved = true
				if randf() < 0.5:
					power = min(100.0, power + 45.0)
					pukan_temp = 12.0
					trojan_distance = 95.0
					trojan_in_room = false
					ProceduralAudio.play_coin_sound()
					add_event_log("🎁 ПОВЕЗЛО! Конь высрал золотой аккумулятор (+45% ИБП, остудил пукан) и ускакал!", "ok")
				else:
					trigger_jumpscare("trojan", "ТРОЯНСКИЙ КОНЬ РАСПАХНУЛ ДЕРЕВЯННОЕ БРЮХО!", "50/50 не прокнуло! Из коня вылезли 40 цыганских майнеров и сожгли серверную!")
					return

	# -------------------------------------------------------------------------
	# 4. БАГОГРЫЗ-ГОЛОВАСТИК НА СТОЛЕ (С 4-й смены)
	# -------------------------------------------------------------------------
	if bool(cfg["tadpole_enabled"]):
		if not tadpole_active:
			tadpole_next_spawn -= delta
			if tadpole_next_spawn <= 0.0:
				tadpole_active = true
				tadpole_health = 3
				tadpole_x = (randf() - 0.5) * 1.1
				tadpole_mess_timer = 3.2
				ProceduralAudio.play_tadpole_splat()
				add_event_log("🐀 Склизкий БАГОГРЫЗ-ГОЛОВАСТИК вылез на стол! Уеби по нему 3 раза кликом!", "warn")
		else:
			tadpole_mess_timer -= delta
			if tadpole_mess_timer <= 0.0:
				tadpole_mess_timer = 3.2
				var idx := randi() % 4
				dip_switches[idx] = 1 - dip_switches[idx]
				pukan_temp = min(100.0, pukan_temp + 6.0)
				ProceduralAudio.play_switch(false)
				add_event_log("⚠️ Головастик насрал в клавиатуру и сбил тумблер SW%d!" % (idx + 1), "danger")

# =============================================================================
# Посадка в кресло и вставание на [ПРОБЕЛ]
# =============================================================================
func sit_in_chair(open_screen_after: String = "") -> void:
	if not is_seated:
		is_seated = true
		ProceduralAudio.play_chair_creak(true)
		seated_changed.emit(true)
	if open_screen_after != "":
		open_interactive_screen(open_screen_after)
	ui_updated.emit()

func stand_up_from_chair() -> void:
	if not is_seated:
		return
	active_screen = ""
	screen_opened.emit("")
	is_seated = false
	ProceduralAudio.play_chair_creak(false)
	seated_changed.emit(false)
	ui_updated.emit()

func open_interactive_screen(scr_id: String) -> void:
	active_screen = scr_id
	ProceduralAudio.play_switch(scr_id != "")
	screen_opened.emit(scr_id)
	ui_updated.emit()

func close_interactive_screen() -> void:
	if active_screen != "":
		active_screen = ""
		ProceduralAudio.play_switch(false)
		screen_opened.emit("")
		ui_updated.emit()

# =============================================================================
# Старт смены и возврат в Дневное Лобби
# =============================================================================
func start_shift_from_lobby(lvl: int) -> void:
	if lvl > max_unlocked_level:
		add_event_log("🔒 Смена #%d ещё не открыта! Сначала выживи до 6 утра на Смене #%d!" % [lvl, lvl - 1], "warn")
		ProceduralAudio.play_error_buzz()
		return

	in_lobby = false
	current_level = lvl
	var cfg: Dictionary = SHIFT_CONFIGS.get(lvl, SHIFT_CONFIGS[1])

	running = true
	game_over = false
	is_seated = true # Начинаем смену сидя в кресле на посту управления!
	active_screen = ""
	time_seconds = 0.0
	power = 100.0
	pukan_temp = 15.0
	hack_count = 0

	gate_left = false
	gate_right = false
	seat_cooler = false
	dip_switches = [0, 1, 0, 1]
	target_dip = [0, 1, 0, 1]
	dip_puzzle_active = false
	dip_max_timer = float(cfg["dip_timeout"])
	next_dip_countdown = 12.0

	steam_vent_cooldown = 0.0
	current_cam = "CAM01"

	_init_shift_puzzle(lvl)

	distortion_active = false
	distortion_pos = "NONE"
	distortion_stare_timer = 0.0
	distortion_next_spawn = 9.0

	burgundy_stage = 0
	burgundy_move_cooldown = 7.0

	var base_tr_spd: float = float(cfg["trojan_speed"])
	trojan_distance = 140.0 if active_buffs["antiTrojanOats"] else 100.0
	trojan_speed = base_tr_spd * 0.7 if active_buffs["antiTrojanOats"] else base_tr_spd
	trojan_in_room = false
	trojan_gamble_resolved = false

	tadpole_active = false
	tadpole_health = 3
	tadpole_next_spawn = 65.0 if active_buffs["bugRepellent"] else 16.0

	gas_pressure = 0.0
	gas_leaking = bool(cfg["gas_enabled"])
	valve_angle = 0.0
	blackout = false
	wires_fixed = true
	wire_connections = [true, true, true, true]
	printer_working = false
	printer_progress = 0.0
	carrots_count = 1
	holding_carrot = false

	ProceduralAudio.set_daytime(false)
	ProceduralAudio.play_switch(true)
	add_event_log("🌙 %s началась! Продержись до 06:00 AM!" % cfg["name"], "info")
	seated_changed.emit(true)
	screen_opened.emit("")
	shift_started.emit(lvl)
	ui_updated.emit()

func return_to_lobby() -> void:
	in_lobby = true
	running = false
	game_over = false
	is_seated = false # В дневном лобби стоим посреди комнаты и свободно ходим!
	active_screen = ""
	blackout = false
	wires_fixed = true
	distortion_active = false
	distortion_stare_timer = 0.0
	tadpole_active = false
	trojan_in_room = false
	burgundy_stage = 0
	holding_carrot = false

	# Сбрасываем одноразовые баффы после сыгранной смены
	for k in active_buffs.keys():
		active_buffs[k] = false

	ProceduralAudio.set_daytime(true)
	seated_changed.emit(false)
	screen_opened.emit("")
	lobby_entered.emit()
	ui_updated.emit()

# =============================================================================
# Оперативное управление (Только сидя в кресле через терминалы!)
# =============================================================================
func toggle_door_lock(side: String) -> void:
	if not running or game_over:
		return
	if not is_seated:
		add_event_log("⚠️ Чтобы управлять гермодверями, сядь в кресло за терминал!", "warn")
		return
	if power <= 0.0 or blackout:
		ProceduralAudio.play_error_buzz()
		add_event_log("⚡ Щиток вышибло! Двери обесточены!", "danger")
		return

	# FNaF-баланс: одновременно может быть закрыта ТОЛЬКО ОДНА дверь!
	if side == "left":
		gate_left = not gate_left
		if gate_left and gate_right:
			gate_right = false
			add_event_log("⚡ Питание переброшено на ЛЕВЫЙ шлюз (Правый шлюз открыт!)", "warn")
	elif side == "right":
		gate_right = not gate_right
		if gate_right and gate_left:
			gate_left = false
			add_event_log("⚡ Питание переброшено на ПРАВЫЙ шлюз (Левый шлюз открыт!)", "warn")

	ProceduralAudio.play_gate_slam()
	hand_action.emit("press")
	ui_updated.emit()

func toggle_seat_cooler() -> void:
	if not running or game_over or not is_seated:
		return
	if power <= 0.0 or blackout:
		return
	seat_cooler = not seat_cooler
	ProceduralAudio.play_switch(seat_cooler)
	hand_action.emit("press")
	ui_updated.emit()

func toggle_dip(index: int) -> void:
	if not is_seated:
		sit_in_chair()
		return
	if not running or game_over or index < 0 or index >= 4:
		return
	dip_switches[index] = 1 - dip_switches[index]
	ProceduralAudio.play_switch(dip_switches[index] == 1)
	hand_action.emit("press")
	_check_dip_match()
	ui_updated.emit()

func ping_corridor(side: String) -> void:
	if not running or game_over or power <= 0.0 or blackout:
		return
	power = max(0.0, power - 0.3)
	hand_action.emit("press")
	if side == "left":
		ping_left_timer = 0.75
		var danger := (distortion_active and (distortion_pos == "DOOR_LEFT" or distortion_pos == "CAM02_APPROACH"))
		ProceduralAudio.play_ping(danger)
		if danger:
			add_event_log("🚨 РАДАР ПОРТ 22: ИСКАЗИТЕЛЬ В ЛЕВОМ ПРОХОДЕ!", "danger")
	else:
		ping_right_timer = 0.75
		var danger := (distortion_active and (distortion_pos == "DOOR_RIGHT" or distortion_pos == "CAM04_APPROACH"))
		ProceduralAudio.play_ping(danger)
		if danger:
			add_event_log("🚨 РАДАР ПОРТ 5432: ИСКАЗИТЕЛЬ В ПРАВОМ ПРОХОДЕ!", "danger")
	ui_updated.emit()

func purge_vents_with_steam() -> void:
	if not running or game_over or steam_vent_cooldown > 0.0:
		return
	if not is_seated:
		add_event_log("⚠️ Продувка вентиляции запускается с терминала безопасности (сядь в кресло)!", "warn")
		return
	if power <= 0.0 or blackout:
		ProceduralAudio.play_error_buzz()
		return
	steam_vent_cooldown = 4.0
	power = max(0.0, power - 1.5)
	pukan_temp = max(0.0, pukan_temp - 7.0)
	ProceduralAudio.play_steam_hisser()
	hand_action.emit("press")
	if burgundy_stage > 0:
		burgundy_stage = 0
		burgundy_move_cooldown = 8.5
		add_event_log("💨 ПШШШ! Кипящий пар ошпарил жопу Бордовому Душегубу! Он съебался по трубе!", "ok")
	else:
		add_event_log("💨 Вентиляционная шахта продута паром (-7°C пукана).", "info")
	ui_updated.emit()

func start_printing_carrot() -> void:
	if in_lobby:
		add_event_log("🖨️ Днём 3D-биопринтер в спящем режиме. Морковки нужны ночью с 3-й смены!", "info")
		return
	if not running or game_over or printer_working:
		return
	if power <= 0.0 or blackout:
		add_event_log("⚡ 3D-биопринтер обесточен!", "danger")
		return
	printer_working = true
	printer_progress = 0.0
	power = max(0.0, power - 2.0)
	ProceduralAudio.play_printer_beep()
	hand_action.emit("press")
	add_event_log("🖨️ 3D-биопринтер печатает кормовую морковку (~8 сек)...", "info")
	ui_updated.emit()

func pickup_or_throw_carrot() -> void:
	if in_lobby or not running or game_over:
		return
	if carrots_count <= 0:
		add_event_log("⚠️ Нет напечатанных морковок! Запусти 3D-принтер на столе!", "warn")
		ProceduralAudio.play_error_buzz()
		return
	carrots_count -= 1
	trojan_distance = min(130.0, trojan_distance + 45.0)
	trojan_in_room = false
	ProceduralAudio.play_switch(true)
	hand_action.emit("throw_carrot")
	add_event_log("🥕 Морковка запущена в центральный тоннель! Конь в T-Pose отъехал на +45м!", "ok")
	ui_updated.emit()

func hit_tadpole() -> void:
	if not running or game_over or not tadpole_active:
		return
	tadpole_health -= 1
	ProceduralAudio.play_tadpole_splat()
	hand_action.emit("smack")
	if tadpole_health <= 0:
		tadpole_active = false
		tadpole_next_spawn = 18.0 + randf() * 10.0
		add_event_log("💥 ХРЯСЬ! Багогрыз размазан в сопли по столу!", "ok")
	else:
		add_event_log("💥 На леща! Осталось ударов по головастику: %d" % tadpole_health, "warn")
	ui_updated.emit()

# =============================================================================
# Действия в комнате стоя (Вентиль газа, Щиток с проводами, Рычаг света)
# =============================================================================
func turn_gas_valve(angle_delta: float) -> void:
	if in_lobby:
		hand_action.emit("turn_valve")
		return
	if not running or game_over:
		return
	if is_seated:
		add_event_log("⚠️ Не дотянуться! Нажми [ПРОБЕЛ], встань с кресла и подойди к вентилю!", "warn")
		return
	valve_angle += abs(angle_delta)
	hand_action.emit("turn_valve")
	if valve_angle >= TAU:
		valve_angle -= TAU
		gas_pressure = max(0.0, gas_pressure - 38.0)
		ProceduralAudio.play_steam_hisser()
		add_event_log("🔧 Вентиль провёрнут на 360°! Утечка стравлена (-38% давления).", "ok")
	ui_updated.emit()

func _trip_power_blackout(reason: String) -> void:
	if active_buffs["titaniumFuse"]:
		return
	blackout = true
	wires_fixed = false
	wire_connections = [false, false, false, false]
	selected_wire_color = -1
	gate_left = false
	gate_right = false
	seat_cooler = false
	if active_screen == "MAIN_TERM" or active_screen == "CCTV_TERM":
		active_screen = ""
		screen_opened.emit("")
	ProceduralAudio.play_spark()
	ProceduralAudio.play_gate_slam()
	add_event_log(reason, "danger")
	ui_updated.emit()

func connect_wire_pair(color_idx: int) -> void:
	if color_idx < 0 or color_idx >= 4:
		return
	wire_connections[color_idx] = true
	ProceduralAudio.play_spark()
	hand_action.emit("press")
	if wire_connections[0] and wire_connections[1] and wire_connections[2] and wire_connections[3]:
		wires_fixed = true
		add_event_log("🔌 Все 4 провода скручены! Теперь дёрни КРАСНЫЙ РЫЧАГ рядом со щитком!", "ok")
	ui_updated.emit()

func pull_breaker_lever() -> void:
	if in_lobby:
		ProceduralAudio.play_switch(true)
		hand_action.emit("press")
		add_event_log("💡 Днём питание работает штатно.", "info")
		return
	if is_seated:
		add_event_log("⚠️ С кресла до рычага не достать! Встань на [ПРОБЕЛ] и подойди к задней стене!", "warn")
		return
	if not blackout:
		add_event_log("💡 Рубильник уже взведён, питание в норме.", "info")
		return
	if not wires_fixed:
		ProceduralAudio.play_spark()
		ProceduralAudio.play_error_buzz()
		open_interactive_screen("WIRES_BOX")
		add_event_log("⚠️ КЗ В ЩИТКЕ! Сначала соедини оборванные провода в открытой коробке!", "danger")
		return

	blackout = false
	if power <= 0.0:
		power = 25.0
	close_interactive_screen()
	ProceduralAudio.play_switch(true)
	hand_action.emit("press")
	add_event_log("💡 ВЖУХ! Рубильник взведён, свет и терминалы снова пашут!", "ok")
	ui_updated.emit()

# =============================================================================
# Пасхалки и приколы (Шкафчик AZAMAT SASI, Уточка без механик, Кофе, Сейф)
# =============================================================================
func toggle_cabinet() -> void:
	cabinet_open = not cabinet_open
	ProceduralAudio.play_cabinet_creak()
	hand_action.emit("press")
	if cabinet_open:
		add_event_log("🚪 Внутри шкафчика висит священная скрижаль: «AZAMAT SASI» ( ͡° ͜ʖ ͡°) [Улика #3 для сейфа: в байте 8 бит]", "warn")
	ui_updated.emit()

func click_rubber_duck() -> void:
	# Уточка работает и днём, и ночью чисто для фана: крякает и анимируется в 2D-руках!
	ProceduralAudio.play_duck_squeak()
	hand_action.emit("duck")
	var jokes := [
		"🦆 Уточка: «КРЯ, БЛЯТЬ! Сделай git reset --hard своей жизни!»",
		"🦆 Резиновый дебаггер осуждающе крякнул на твой говнокод.",
		"🦆 КРЯ-Я! Уточка счастлива, что не она дежурит в эту ночь."
	]
	add_event_log(jokes[randi() % jokes.size()], "info")
	ui_updated.emit()

func drink_coffee() -> void:
	ProceduralAudio.play_coffee_sip()
	hand_action.emit("coffee")
	if not in_lobby and running:
		power = min(100.0, power + 3.0)
		add_event_log("☕ Хлебнул холодного эспрессо с пеплом (+3% бодрости ИБП).", "info")
	else:
		add_event_log("☕ Дневной кофеёк со вкусом слёз джуна. Заебись!", "info")
	ui_updated.emit()

func inspect_clue(clue_id: int) -> void:
	ProceduralAudio.play_switch(true)
	hand_action.emit("press")
	match clue_id:
		1:
			add_event_log("📝 Стикер на окне (Улика Сейфа #1): «Первые две цифры кода — стандартный порт SSH (22)».", "warn")
		2:
			add_event_log("📝 Стикер на серверной стойке (Улика Сейфа #2): «Третья цифра — количество тумблеров SW на твоём столе (4)».", "warn")
		3:
			add_event_log("📝 Записка в шкафчике AZAMAT SASI (Улика Сейфа #3): «Четвёртая цифра — сколько бит в одном байте (8)».", "warn")
	ui_updated.emit()

func try_unlock_lobby_safe(entered_code: String) -> bool:
	if entered_code.strip_edges() == LOBBY_SAFE_CODE:
		if not lobby_safe_solved:
			lobby_safe_solved = true
			if coins < max_coins:
				coins = min(max_coins, coins + 1)
			ProceduralAudio.play_coin_sound()
			add_event_log("🔓 СЕКРЕТНЫЙ СЕЙФ СЕНЬОРА ОТКРЫТ! Внутри заначка (+1🪙 Монета) и золотой дилдак Линуса!", "ok")
		else:
			add_event_log("🔓 Сейф уже открыт! Заначка Сеньора у тебя в кармане.", "info")
		ui_updated.emit()
		return true
	else:
		ProceduralAudio.play_error_buzz()
		add_event_log("❌ НЕВЕРНЫЙ PIN-КОД! Ищи 3 жёлтых стикера-улики по комнате!", "danger")
		ui_updated.emit()
		return false

func buy_buff(buff_key: String) -> void:
	if coins < 1:
		add_event_log("⚠️ Нищеброд! В кармане 0 монет. Проходи головоломки на уровнях!", "warn")
		ProceduralAudio.play_error_buzz()
		return
	if active_buffs.get(buff_key, false):
		add_event_log("⚠️ Этот ништяк уже куплен на ближайшую смену!", "info")
		return
	coins -= 1
	active_buffs[buff_key] = true
	ProceduralAudio.play_coin_sound()
	add_event_log("🛒 Ништяк «%s» активирован на следующую ночь! (Осталось монет: %d/%d)" % [buff_key, coins, max_coins], "ok")
	ui_updated.emit()

# =============================================================================
# 5 РАЗНЫХ ГОЛОВОЛОМОК НА УРОВНЯХ (Заработок одноразовой монетки!)
# =============================================================================
func _init_shift_puzzle(lvl: int) -> void:
	puzzle_solved_this_shift = false
	var cfg: Dictionary = SHIFT_CONFIGS.get(lvl, SHIFT_CONFIGS[1])
	var ptype: String = String(cfg["puzzle_type"])

	match ptype:
		"PIPES":
			# Чтобы собрать путь от (0,0) до (2,2), игрок должен выставить правильные повороты
			pipe_grid = [
				{"type": "straight", "rot": 1}, {"type": "elbow", "rot": 0}, {"type": "elbow", "rot": 2},
				{"type": "elbow", "rot": 1},    {"type": "cross", "rot": 0}, {"type": "straight", "rot": 1},
				{"type": "elbow", "rot": 0},    {"type": "straight", "rot": 0}, {"type": "elbow", "rot": 1}
			]
		"CLUSTER_MATH":
			cluster_weights = [45, 30, 60, 15]
			cluster_sliders = [1, 1, 1, 1]
			# Целевая сумма: например 2*45 + 3*30 + 2*60 + 3*15 = 90 + 90 + 120 + 45 = 345 МГц
			cluster_target_mhz = 345
		"LIGHTS_OUT":
			lights_grid = [1, 0, 1, 0, 0, 0, 1, 0, 1]
		"PACKET_ORDER":
			packet_numbers = [5432, 22, 9000, 80, 3000, 443]
			packet_next_idx = 0
		"WAVE_SYNC":
			wave_player = [1, 4, 2]
			wave_target = [4, 2, 5]

func get_current_puzzle_type() -> String:
	var cfg: Dictionary = SHIFT_CONFIGS.get(current_level, SHIFT_CONFIGS[1])
	return String(cfg["puzzle_type"])

func rotate_pipe_tile(idx: int) -> void:
	if puzzle_solved_this_shift or idx < 0 or idx >= pipe_grid.size():
		return
	pipe_grid[idx]["rot"] = (int(pipe_grid[idx]["rot"]) + 1) % 4
	ProceduralAudio.play_switch(true)
	# Проверяем: маршрут (0,0)->(1,0)->(1,1)->(2,1)->(2,2) или верхний контур
	# Сделаем честную проверку направления входов/выходов тайлов 3x3!
	if _is_pipe_grid_connected():
		_reward_puzzle_coin()
	ui_updated.emit()

func _get_pipe_dirs(t_type: String, rot: int) -> Array[Vector2i]:
	# Направления: UP=(0,-1), RIGHT=(1,0), DOWN=(0,1), LEFT=(-1,0)
	var dirs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	var r := rot % 4
	if t_type == "cross":
		return dirs
	elif t_type == "straight":
		if r % 2 == 0:
			return [dirs[0], dirs[2]] # Вертикальная
		else:
			return [dirs[1], dirs[3]] # Горизонтальная
	else: # elbow: при rot=0 соединяет UP и RIGHT; rot=1 RIGHT и DOWN; rot=2 DOWN и LEFT; rot=3 LEFT и UP
		return [dirs[r], dirs[(r + 1) % 4]]

func _is_pipe_grid_connected() -> bool:
	# BFS от (0,0) до (2,2)
	var visited := {}
	var queue: Array[Vector2i] = [Vector2i(0, 0)]
	visited[Vector2i(0, 0)] = true
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == Vector2i(2, 2):
			return true
		var cur_idx := cur.y * 3 + cur.x
		var cur_tile: Dictionary = pipe_grid[cur_idx]
		var my_dirs := _get_pipe_dirs(String(cur_tile["type"]), int(cur_tile["rot"]))
		for d in my_dirs:
			var nxt: Vector2i = cur + d
			if nxt.x < 0 or nxt.x >= 3 or nxt.y < 0 or nxt.y >= 3:
				continue
			if visited.has(nxt):
				continue
			var nxt_idx := nxt.y * 3 + nxt.x
			var nxt_tile: Dictionary = pipe_grid[nxt_idx]
			var nxt_dirs := _get_pipe_dirs(String(nxt_tile["type"]), int(nxt_tile["rot"]))
			if nxt_dirs.has(-d):
				visited[nxt] = true
				queue.append(nxt)
	return false

func adjust_cluster_slider(idx: int) -> void:
	if puzzle_solved_this_shift or idx < 0 or idx >= 4:
		return
	cluster_sliders[idx] = (cluster_sliders[idx] % 5) + 1
	ProceduralAudio.play_switch(true)
	var total := 0
	for i in range(4):
		total += cluster_sliders[i] * cluster_weights[i]
	if total == cluster_target_mhz:
		_reward_puzzle_coin()
	ui_updated.emit()

func toggle_lights_out_cell(idx: int) -> void:
	if puzzle_solved_this_shift or idx < 0 or idx >= 9:
		return
	var cx := idx % 3
	var cy := idx / 3
	var offsets := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for off in offsets:
		var nx: int = cx + off.x
		var ny: int = cy + off.y
		if nx >= 0 and nx < 3 and ny >= 0 and ny < 3:
			var n_idx: int = ny * 3 + nx
			lights_grid[n_idx] = 1 - lights_grid[n_idx]
	ProceduralAudio.play_switch(true)
	var all_on := true
	for v in lights_grid:
		if v == 0:
			all_on = false
			break
	if all_on:
		_reward_puzzle_coin()
	ui_updated.emit()

func click_packet_number(num: int) -> void:
	if puzzle_solved_this_shift:
		return
	var sorted_nums := packet_numbers.duplicate()
	sorted_nums.sort()
	var expected: int = sorted_nums[packet_next_idx]
	if num == expected:
		packet_next_idx += 1
		ProceduralAudio.play_switch(true)
		if packet_next_idx >= sorted_nums.size():
			_reward_puzzle_coin()
	else:
		packet_next_idx = 0
		ProceduralAudio.play_error_buzz()
		add_event_log("❌ Неверный порядок пакета! Сортируй строго по возрастанию порта!", "warn")
	ui_updated.emit()

func adjust_wave_param(idx: int) -> void:
	if puzzle_solved_this_shift or idx < 0 or idx >= 3:
		return
	wave_player[idx] = (wave_player[idx] % 5) + 1
	ProceduralAudio.play_switch(true)
	if wave_player == wave_target:
		_reward_puzzle_coin()
	ui_updated.emit()

func _reward_puzzle_coin() -> void:
	if puzzle_solved_this_shift:
		return
	puzzle_solved_this_shift = true
	if coins < max_coins:
		coins += 1
		ProceduralAudio.play_coin_sound()
		add_event_log("🎉 ЗАДАЧА УРОВНЯ РЕШЕНА! +1🪙 Монета в карман (Всего: %d/%d)!" % [coins, max_coins], "ok")
	else:
		ProceduralAudio.play_coin_sound()
		add_event_log("🎉 Задача решена! (Карман забит до упора: 3/3 монет)", "ok")

# =============================================================================
# Служебные проверки
# =============================================================================
func _spawn_dip_puzzle(cfg: Dictionary) -> void:
	var next_t: Array[int] = [0, 0, 0, 0]
	while true:
		next_t = [randi() % 2, randi() % 2, randi() % 2, randi() % 2]
		if next_t != dip_switches:
			break
	target_dip = next_t
	dip_puzzle_active = true
	dip_max_timer = float(cfg["dip_timeout"])
	dip_timer = dip_max_timer
	ProceduralAudio.play_ping(false)
	add_event_log("🔧 СБОЙ РЕГИСТРОВ ЯДРА! Выстави тумблеры SW1-4 на столе в [%d %d %d %d]!" % [next_t[0], next_t[1], next_t[2], next_t[3]], "warn")

func _check_dip_match() -> void:
	if not dip_puzzle_active:
		return
	if dip_switches == target_dip:
		var cfg: Dictionary = SHIFT_CONFIGS.get(current_level, SHIFT_CONFIGS[1])
		dip_puzzle_active = false
		next_dip_countdown = float(cfg["dip_interval"])
		pukan_temp = max(0.0, pukan_temp - 5.0)
		ProceduralAudio.play_coin_sound()
		add_event_log("✅ Тумблеры ядра SW1-4 синхронизированы (-5°C пукана)!", "ok")

func increment_hack(reason: String) -> void:
	hack_count += 1
	pukan_temp = min(100.0, pukan_temp + 15.0)
	add_event_log("💀 ВЗЛОМ СИСТЕМЫ (%d/%d): %s" % [hack_count, max_hacks, reason], "danger")
	if hack_count >= max_hacks:
		trigger_jumpscare("ai", "5/5 ВЗЛОМОВ — ТОТАЛЬНЫЙ ROOTKIT-СКРИМЕР!", "Прод окончательно лёг под натиском багов и взбесившихся демонов!")

func trigger_jumpscare(m_type: String, title: String, desc: String) -> void:
	running = false
	game_over = true
	active_screen = ""
	screen_opened.emit("")
	ProceduralAudio.play_jumpscare_by_type(m_type)
	jumpscare_triggered.emit(m_type, title, desc)
	ui_updated.emit()

func trigger_victory() -> void:
	running = false
	game_over = false
	active_screen = ""
	screen_opened.emit("")
	if current_level >= max_unlocked_level and max_unlocked_level < 6:
		max_unlocked_level = current_level + 1
	ProceduralAudio.play_coin_sound()
	victory_triggered.emit(current_level)
	ui_updated.emit()

func get_usage_bars() -> int:
	if power <= 0.0 or blackout:
		return 0
	var bars := 1
	if gate_left or gate_right:
		bars += 2
	if seat_cooler and is_seated:
		bars += 1
	if active_screen == "CCTV_TERM":
		bars += 1
	if printer_working:
		bars += 1
	return min(6, bars)

func get_formatted_clock() -> String:
	if in_lobby:
		return "ДЕНЬ ☀️"
	var hour := mini(6, int((time_seconds / total_shift_seconds) * 6.0))
	var display_hour := "12" if hour == 0 else "0%d" % hour
	return "%s:00 AM" % display_hour

func add_event_log(msg: String, level: String = "info") -> void:
	var entry := {
		"time": get_formatted_clock(),
		"msg": msg,
		"level": level
	}
	event_log.push_front(entry)
	while event_log.size() > 6:
		event_log.pop_back()
	event_logged.emit(msg, level)

extends Node
## Главный синглтон состояния игры (Autoload: GameState)
## Отвечает за прогрессию смен, показатели дежурного, 4 монстров,
## магазин баффов, дневное лобби и рассылку сигналов для 3D-мира, 2D-рук и UI.

signal shift_started(shift_num: int)
signal lobby_entered()
signal event_logged(text: String, level: String)
signal ui_updated()
signal hand_action(action_name: String)
signal jumpscare_triggered(monster_type: String, title: String, desc: String)
signal victory_triggered(shift_num: int)

const SHIFT_CONFIGS := {
	1: {
		"name": "СМЕНА 1: ПОНЕДЕЛЬНИК («Джуниор на ночном дежурстве»)",
		"subtitle": "Сеньор ушёл в запой. Не дай ИИ спалить стул и береги пукан.",
		"dip_interval": 28.0,
		"dip_timeout": 16.0,
		"patch_speed": 1.6,
		"base_power_drain": 0.12,
		"trojan_speed": 1.1,
		"gas_enabled": false,
		"blackout_chance": 0.0,
		"puzzle_name": "CI/CD Pipeline: Провести билд по трубам",
		"phone_msg": "«Алло, джун! Добро пожаловать на прод. По тоннелям ползёт Троянский конь в T-pose. Напечатай морковку на 3D-принтере справа, чтобы оттолкнуть его! И собери трубы CI/CD пайплайна [P] ради монеты на ништяки!»"
	},
	2: {
		"name": "СМЕНА 2: ВТОРНИК («Утечка хладагента и Бордовый Сталкер»)",
		"subtitle": "В вентиляции зашевелились хвосты, а трубу с газом прорвало.",
		"dip_interval": 24.0,
		"dip_timeout": 14.0,
		"patch_speed": 1.45,
		"base_power_drain": 0.14,
		"trojan_speed": 1.5,
		"gas_enabled": true,
		"blackout_chance": 0.0,
		"puzzle_name": "Kubernetes Pods: Балансировка контейнеров",
		"phone_msg": "«Слушай сюда: в потолочной решётке завёлся Бордовый Душегуб. Слышишь щелчки или видишь хвост — жми ПРОДУВКУ ВЕНТИЛЯЦИИ [V]! А если свистит газ — крути красный вентиль на трубе!»"
	},
	3: {
		"name": "СМЕНА 3: СРЕДА («Нашествие Багогрызов и Блэкауты»)",
		"subtitle": "По столу бегают склизкие твари, а проводка искрит.",
		"dip_interval": 20.0,
		"dip_timeout": 12.5,
		"patch_speed": 1.35,
		"base_power_drain": 0.16,
		"trojan_speed": 1.9,
		"gas_enabled": true,
		"blackout_chance": 0.035,
		"puzzle_name": "Fiber Cross: Оптоволоконная матрица",
		"phone_msg": "«Алярм! Багогрызы-головастики лезут прямо на стол — бей их кликами! А если выбьет свет — обернись на 180° к окну и щёлкни рубильник на электрощитке!»"
	},
	4: {
		"name": "СМЕНА 4: ЧЕТВЕРГ («Релизный цейтнот и Троянская рулетка»)",
		"subtitle": "Троянский конь ускорил шаг, а пукан греется как ядро реактора.",
		"dip_interval": 17.0,
		"dip_timeout": 11.0,
		"patch_speed": 1.25,
		"base_power_drain": 0.18,
		"trojan_speed": 2.3,
		"gas_enabled": true,
		"blackout_chance": 0.05,
		"puzzle_name": "Hash Decryptor: Крипто-регистры",
		"phone_msg": "«Конь прёт напролом! Всегда держи готовую морковку. Если он заедет в комнату — шанс 50/50: либо отсыпет батарей и остудит стул, либо разорвёт тебя на куски!»"
	},
	5: {
		"name": "СМЕНА 5: ПЯТНИЦА 13-е («СИНГУЛЯРНОСТЬ ПУКАНА»)",
		"subtitle": "Все монстры вышли на охоту одновременно. Твой стул на грани взрыва.",
		"dip_interval": 14.0,
		"dip_timeout": 9.5,
		"patch_speed": 1.15,
		"base_power_drain": 0.21,
		"trojan_speed": 2.8,
		"gas_enabled": true,
		"blackout_chance": 0.065,
		"puzzle_name": "Quantum Phase: Синхронизация 3 фаз ядра",
		"phone_msg": "«Ты последняя надежда продакшена. Пили хотфикс, крути вентиль, отбивайся морковкой и не дай Исказителю выжечь тебе мозг!»"
	},
	6: {
		"name": "СВОЯ НОЧЬ: 20/20/20/20 («АД СИСАДМИНА»)",
		"subtitle": "Хардкорная смена с максимальной агрессией монстров.",
		"dip_interval": 12.0,
		"dip_timeout": 8.5,
		"patch_speed": 1.1,
		"base_power_drain": 0.23,
		"trojan_speed": 3.3,
		"gas_enabled": true,
		"blackout_chance": 0.08,
		"puzzle_name": "Master Kernel Bypass",
		"phone_msg": "«Максимальный уровень ада. Да пребудет с тобой Святой Линус Торвальдс.»"
	}
}

const CODE_SNIPPETS := [
	"if (ai.wantsToDestroyWorld()) { ai.setNiceness(9999); }",
	"sudo iptables -A INPUT -s 666.666.0.0/16 -j DROP // Block AI",
	"try { fixProd(); } catch (PukanDetonationError e) { applyIcePack(); }",
	"const patch = await bypassSkufNet({ force: true });",
	"while (server.isBurning) { pourKombuchaOnMotherboard(); }",
	"git commit -m 'hotfix: запретил трояну ломать БД по пятницам'",
	"killall -9 distortion_daemon trojan_horse tadpole_virus vent_stalker",
	"export PUKAN_MAX_TEMP=9000; sysctl -w kernel.panic_on_ai=0;"
]

# Прогрессия и экономика
var in_lobby: bool = true
var lobby_inspect_mode: bool = false
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

# Пасхалки
var cabinet_open: bool = false

# Состояние смены
var running: bool = false
var game_over: bool = false
var time_seconds: float = 0.0
var total_shift_seconds: float = 180.0

var power: float = 100.0
var pukan_temp: float = 15.0
var patch_progress: float = 0.0
var hack_count: int = 0
var max_hacks: int = 5

# Тумблеры и оборудование
var gate_left: bool = false
var gate_center: bool = false
var gate_right: bool = false
var seat_cooler: bool = false
var overclock: bool = false
var dip_switches: Array[int] = [0, 1, 0, 1]
var target_dip: Array[int] = [0, 1, 0, 1]
var dip_puzzle_active: bool = false
var dip_timer: float = 0.0
var dip_max_timer: float = 15.0
var next_dip_countdown: float = 12.0

var ping_left_timer: float = 0.0
var ping_right_timer: float = 0.0
var crank_cooldown: float = 0.0
var steam_vent_cooldown: float = 0.0
var cctv_open: bool = false
var current_cam: String = "CAM01"

# Состояние 4 Монстров
var distortion_active: bool = false
var distortion_pos: String = "NONE" # NONE, DOOR_LEFT, DOOR_RIGHT, WINDOW_BACK, HALL_FRONT
var distortion_stare_timer: float = 0.0
var distortion_patience: float = 6.0
var distortion_next_spawn: float = 12.0
var player_looking_at_sector: String = "DESK"

var tadpole_active: bool = false
var tadpole_health: int = 3
var tadpole_x: float = 0.0
var tadpole_mess_timer: float = 3.5
var tadpole_next_spawn: float = 18.0

var trojan_distance: float = 100.0
var trojan_speed: float = 1.2
var trojan_in_room: bool = false
var trojan_gamble_timer: float = 0.0
var trojan_gamble_resolved: bool = false

var burgundy_stage: int = 0 # 0 = hidden, 1 = crawling, 2 = dangling tail in ceiling grate
var burgundy_click_cooldown: float = 4.0
var burgundy_attack_timer: float = 0.0
var burgundy_move_cooldown: float = 6.0

# Аварии и 3D-принтер
var gas_pressure: float = 0.0
var gas_leaking: bool = false
var valve_angle: float = 0.0
var blackout: bool = false
var printer_working: bool = false
var printer_progress: float = 0.0
var carrots_count: int = 1

# Доп. головоломка
var puzzle_modal_open: bool = false
var puzzle_solved_this_shift: bool = false
var pipe_grid: Array[Dictionary] = []

# Логи и строки кода на ЭЛТ-мониторе
var code_lines: Array[String] = [
	"// СЕРВЕРНЫЙ ТЕРМИНАЛ ДЕЖУРНОГО v6.0 (GODOT 4 EDITION)",
	"// Выбери смену на планшете Дневного Лобби!"
]
var event_log: Array[Dictionary] = []

func _ready() -> void:
	_init_pipeline_puzzle()
	add_event_log("Дневное Лобби активно. Поют птицы, все системы в норме.", "info")

func _process(delta: float) -> void:
	if ping_left_timer > 0.0:
		ping_left_timer = max(0.0, ping_left_timer - delta)
	if ping_right_timer > 0.0:
		ping_right_timer = max(0.0, ping_right_timer - delta)

	if not running or game_over:
		return

	var cfg: Dictionary = SHIFT_CONFIGS.get(current_level, SHIFT_CONFIGS[1])

	# 1. Время смены
	time_seconds += delta
	if time_seconds >= total_shift_seconds:
		trigger_victory()
		return

	# 2. Кулдауны и расход ИБП
	if crank_cooldown > 0.0:
		crank_cooldown = max(0.0, crank_cooldown - delta)
	if steam_vent_cooldown > 0.0:
		steam_vent_cooldown = max(0.0, steam_vent_cooldown - delta)

	if not blackout and power > 0.0:
		var bars := get_usage_bars()
		var drain: float = float(cfg["base_power_drain"]) * (1.0 + float(bars - 1) * 0.9)
		power = max(0.0, power - drain * delta)
		if power <= 0.0:
			gate_left = false
			gate_center = false
			gate_right = false
			seat_cooler = false
			overclock = false
			cctv_open = false
			trigger_blackout("БЛЭКАУТ: ИБП разряжен в 0%! Щёлкни рубильник на задней стене!")

	var b_chance: float = float(cfg["blackout_chance"])
	if not blackout and not active_buffs["titaniumFuse"] and b_chance > 0.0:
		if randf() < delta * b_chance * 0.1:
			trigger_blackout("⚡ ВЫБИЛО ПРОБКИ! Повернись назад на 180° к окну и включи рубильник!")

	# 3. Пуканометр
	var heat_rate: float = 0.65
	if overclock:
		heat_rate += 2.2
	if dip_puzzle_active:
		heat_rate += 1.4
	if gas_pressure > 50.0:
		heat_rate += 1.8
	if tadpole_active:
		heat_rate += 1.2
	heat_rate += float(hack_count) * 0.9

	if active_buffs["asbestosSeat"]:
		heat_rate *= 0.6

	if seat_cooler and power > 0.0 and not blackout:
		heat_rate -= 4.8

	pukan_temp = clamp(pukan_temp + heat_rate * delta, 0.0, 100.0)
	if pukan_temp >= 100.0:
		trigger_jumpscare("pukan", "ТЕРМОЯДЕРНОЕ ИЗВЕРЖЕНИЕ ПУКАНА!", "Температура кресла пробила 100°C! Стул дежурного сдетонировал!")
		return

	# 4. Мутация тумблеров SW1-4
	if not dip_puzzle_active:
		next_dip_countdown -= delta
		if next_dip_countdown <= 0.0:
			_spawn_dip_puzzle(cfg)
	else:
		dip_timer -= delta
		if dip_timer <= 0.0:
			dip_puzzle_active = false
			next_dip_countdown = float(cfg["dip_interval"]) * 0.75
			increment_hack("Вирус изменил флаги SW1-4 ядра! Защита пробита!")
			if game_over:
				return

	# 5. Опасности и монстры
	_update_hazards(delta)
	_update_monsters(delta)
	ui_updated.emit()

func _update_hazards(delta: float) -> void:
	if gas_leaking:
		gas_pressure = min(100.0, gas_pressure + 2.2 * delta)
		if gas_pressure >= 100.0:
			trigger_jumpscare("gas", "ОТРАВЛЕНИЕ ТОКСИЧНЫМ ХЛАДАГЕНТОМ!", "Давление газа достигло 100%! Ты не закрутил вентиль вовремя!")
			return

	if printer_working:
		printer_progress = min(100.0, printer_progress + 11.5 * delta)
		if randf() < delta * 1.5:
			ProceduralAudio.play_printer_beep()
		if printer_progress >= 100.0:
			printer_working = false
			carrots_count += 1
			ProceduralAudio.play_coin_sound()
			add_event_log("🥕 Морковка напечатана! (В запасе: %d шт.)" % carrots_count, "ok")

func _update_monsters(delta: float) -> void:
	# A. Исказитель
	if not distortion_active:
		distortion_next_spawn -= delta
		if distortion_next_spawn <= 0.0:
			distortion_active = true
			var positions := ["DOOR_LEFT", "DOOR_RIGHT", "WINDOW_BACK", "HALL_FRONT"]
			distortion_pos = positions[randi() % positions.size()]
			distortion_stare_timer = 0.0
			distortion_patience = max(4.0, 7.5 - float(current_level) * 0.5)
			ProceduralAudio.play_distortion_drone()
			add_event_log("👁️ ИСКАЗИТЕЛЬ появился в секторе %s! НЕ СМОТРИ НА НЕГО!" % distortion_pos, "danger")
	else:
		distortion_patience -= delta
		var blocked := false
		if distortion_pos == "DOOR_LEFT" and gate_left:
			blocked = true
		elif distortion_pos == "DOOR_RIGHT" and gate_right:
			blocked = true
		elif distortion_pos == "HALL_FRONT" and gate_center:
			blocked = true

		var max_stare := 4.5 if active_buffs["mirrorGlasses"] else 1.8
		if player_looking_at_sector == distortion_pos and not blocked and not cctv_open:
			distortion_stare_timer += delta
			pukan_temp = min(100.0, pukan_temp + 8.0 * delta)
			if randf() < delta * 2.5:
				ProceduralAudio.play_distortion_drone()
			if distortion_stare_timer >= max_stare:
				trigger_jumpscare("distortion", "ИСКАЗИТЕЛЬ ВЫЖЕГ ТВОЙ МОЗГ!", "Ты слишком долго смотрел в его пронзающий взгляд!")
				return
		else:
			distortion_stare_timer = max(0.0, distortion_stare_timer - delta * 1.5)

		if distortion_patience <= 0.0:
			distortion_active = false
			distortion_pos = "NONE"
			distortion_stare_timer = 0.0
			distortion_next_spawn = 12.0 + randf() * 10.0
			add_event_log("Исказитель растворился в темноте...", "ok")

	# B. Багогрыз-головастик
	if not tadpole_active:
		tadpole_next_spawn -= delta
		if tadpole_next_spawn <= 0.0:
			tadpole_active = true
			tadpole_health = 3
			tadpole_x = (randf() - 0.5) * 1.3
			tadpole_mess_timer = 3.0
			ProceduralAudio.play_tadpole_splat()
			add_event_log("🐀 БАГОГРЫЗ-ГОЛОВАСТИК на столе! Кликни по нему 3 раза!", "warn")
	else:
		tadpole_mess_timer -= delta
		if tadpole_mess_timer <= 0.0:
			tadpole_mess_timer = 3.2
			var idx := randi() % 4
			dip_switches[idx] = 1 - dip_switches[idx]
			patch_progress = max(0.0, patch_progress - 4.0)
			ProceduralAudio.play_switch(false)
			add_event_log("⚠️ Головастик сгрыз патч (-4%) и переключил тумблер SW%d!" % (idx + 1), "danger")

	# C. Троянский Конь (T-Pose)
	if not trojan_in_room:
		trojan_distance = max(0.0, trojan_distance - trojan_speed * delta)
		if trojan_distance <= 0.0:
			trojan_in_room = true
			trojan_gamble_timer = 2.4
			trojan_gamble_resolved = false
			ProceduralAudio.play_gate_slam()
			add_event_log("🐴 ТРОЯНСКИЙ КОНЬ ЗАЕХАЛ В КАБИНЕТ В T-POSE! РУЛЕТКА 50/50!", "danger")
	elif not trojan_gamble_resolved:
		trojan_gamble_timer -= delta
		if trojan_gamble_timer <= 0.0:
			trojan_gamble_resolved = true
			if randf() < 0.5:
				power = min(100.0, power + 50.0)
				pukan_temp = 10.0
				patch_progress = min(100.0, patch_progress + 20.0)
				trojan_distance = 90.0
				trojan_in_room = false
				ProceduralAudio.play_coin_sound()
				add_event_log("🎁 ТРОЯНСКИЙ ДАР! Конь отсыпал +50% ИБП, остудил стул и уехал!", "ok")
			else:
				trigger_jumpscare("trojan", "ТРОЯНСКИЙ КОНЬ РАСПАХНУЛ БРЮХО!", "Рулетка 50/50 подвела! Из коня вырвался рой шифровальщиков!")
				return

	# D. Бордовый Душегуб (Вентиляция)
	burgundy_click_cooldown -= delta
	if burgundy_click_cooldown <= 0.0:
		burgundy_click_cooldown = 4.0 + randf() * 3.0
		if burgundy_stage > 0:
			ProceduralAudio.play_vent_click()

	burgundy_move_cooldown -= delta
	if burgundy_move_cooldown <= 0.0:
		burgundy_move_cooldown = 5.5
		if burgundy_stage == 0 and randf() < 0.45:
			burgundy_stage = 1
			ProceduralAudio.play_vent_click()
			add_event_log("В потолочной вентиляции слышно клацанье: клик-клик...", "warn")
		elif burgundy_stage == 1:
			burgundy_stage = 2
			burgundy_attack_timer = 5.5
			ProceduralAudio.play_vent_click()
			add_event_log("🚨 БОРДОВЫЙ ДУШЕГУБ СВИСАЕТ ИЗ РЕШЁТКИ НАД ТОБОЙ! ЖМИ ПРОДУВКУ [V]!", "danger")

	if burgundy_stage == 2:
		burgundy_attack_timer -= delta
		if burgundy_attack_timer <= 0.0:
			trigger_jumpscare("burgundy", "БОРДОВЫЙ ДУШЕГУБ СОРВАЛ РЕШЁТКУ!", "Ты не продул потолочную вентиляцию паром вовремя!")
			return

# -----------------------------------------------------------------------------
# Управление сменами и Лобби
# -----------------------------------------------------------------------------
func start_shift_from_lobby(lvl: int) -> void:
	if lvl > max_unlocked_level:
		add_event_log("⚠️ Смена #%d закрыта! Сначала пройди предыдущую смену до 06:00 AM!" % lvl, "warn")
		return

	in_lobby = false
	lobby_inspect_mode = false
	current_level = lvl
	var cfg: Dictionary = SHIFT_CONFIGS.get(lvl, SHIFT_CONFIGS[1])

	running = true
	game_over = false
	time_seconds = 0.0
	power = 100.0
	pukan_temp = 15.0
	patch_progress = 0.0
	hack_count = 0

	gate_left = false
	gate_center = false
	gate_right = false
	seat_cooler = false
	overclock = false
	dip_switches = [0, 1, 0, 1]
	target_dip = [0, 1, 0, 1]
	dip_puzzle_active = false
	dip_max_timer = float(cfg["dip_timeout"])
	next_dip_countdown = 10.0

	crank_cooldown = 0.0
	steam_vent_cooldown = 0.0
	cctv_open = false
	current_cam = "CAM01"

	_init_pipeline_puzzle()

	distortion_active = false
	distortion_pos = "NONE"
	distortion_stare_timer = 0.0
	distortion_next_spawn = 12.0

	tadpole_active = false
	tadpole_health = 3
	tadpole_next_spawn = 60.0 if active_buffs["bugRepellent"] else 16.0

	trojan_distance = 140.0 if active_buffs["antiTrojanOats"] else 100.0
	var base_spd: float = float(cfg["trojan_speed"])
	trojan_speed = base_spd * 0.7 if active_buffs["antiTrojanOats"] else base_spd
	trojan_in_room = false
	trojan_gamble_resolved = false

	burgundy_stage = 0
	burgundy_move_cooldown = 6.0

	gas_pressure = 0.0
	gas_leaking = bool(cfg["gas_enabled"])
	valve_angle = 0.0
	blackout = false
	printer_working = false
	printer_progress = 0.0
	carrots_count = 1

	code_lines = [
		"// === ЗАПУСК: %s ===" % cfg["name"],
		"// Выживи до 06:00 AM! Хотфикс [SPACE], Камеры [TAB], Пайплайн [P]"
	]

	ProceduralAudio.set_daytime(false)
	ProceduralAudio.play_switch(true)
	add_event_log("Ночная смена #%d началась! Держи оборону до 06:00 AM!" % lvl, "info")
	shift_started.emit(lvl)
	ui_updated.emit()

func return_to_lobby() -> void:
	in_lobby = true
	lobby_inspect_mode = false
	running = false
	game_over = false
	cctv_open = false
	puzzle_modal_open = false
	blackout = false
	distortion_active = false
	distortion_stare_timer = 0.0
	tadpole_active = false
	trojan_in_room = false
	burgundy_stage = 0

	for k in active_buffs.keys():
		active_buffs[k] = false

	ProceduralAudio.set_daytime(true)
	lobby_entered.emit()
	ui_updated.emit()

# -----------------------------------------------------------------------------
# Действия игрока
# -----------------------------------------------------------------------------
func toggle_switch(key: String) -> void:
	if not running or game_over:
		return
	if power <= 0.0 or blackout:
		ProceduralAudio.play_error_buzz()
		add_event_log("⚡ Питание отрублено! Включи рубильник на задней стене!", "danger")
		return

	match key:
		"gateLeft":
			gate_left = not gate_left
			ProceduralAudio.play_gate_slam()
		"gateCenter":
			gate_center = not gate_center
			ProceduralAudio.play_gate_slam()
		"gateRight":
			gate_right = not gate_right
			ProceduralAudio.play_gate_slam()
		"seatCooler":
			seat_cooler = not seat_cooler
			ProceduralAudio.play_switch(seat_cooler)
		"overclock":
			overclock = not overclock
			ProceduralAudio.play_switch(overclock)

	hand_action.emit("press")
	ui_updated.emit()

func toggle_dip(index: int) -> void:
	if not running or game_over or index < 0 or index >= 4:
		return
	dip_switches[index] = 1 - dip_switches[index]
	ProceduralAudio.play_switch(dip_switches[index] == 1)
	hand_action.emit("press")
	_check_dip_match()
	ui_updated.emit()

func ping_port(side: String) -> void:
	if not running or game_over or power <= 0.0 or blackout:
		return
	power = max(0.0, power - 0.35)
	hand_action.emit("press")
	if side == "left":
		ping_left_timer = 0.65
		var danger := (distortion_active and distortion_pos == "DOOR_LEFT")
		ProceduralAudio.play_ping(danger)
		if danger:
			add_event_log("🚨 ПИНГ 22: ИСКАЗИТЕЛЬ В ЛЕВОМ ШЛЮЗЕ! ЗАКРЫВАЙ [Q]!", "danger")
	else:
		ping_right_timer = 0.65
		var danger := (distortion_active and distortion_pos == "DOOR_RIGHT")
		ProceduralAudio.play_ping(danger)
		if danger:
			add_event_log("🚨 ПИНГ 5432: ИСКАЗИТЕЛЬ В ПРАВОМ ШЛЮЗЕ! ЗАКРЫВАЙ [E]!", "danger")
	ui_updated.emit()

func write_patch_chunk() -> void:
	if not running or game_over:
		return
	if tadpole_active:
		add_event_log("⚠️ ГОЛОВАСТИК ЖРЁТ КЛАВИАТУРУ! Сначала раздави его на столе!", "warn")
		ProceduralAudio.play_error_buzz()
		return
	if cctv_open:
		cctv_open = false

	var cfg: Dictionary = SHIFT_CONFIGS.get(current_level, SHIFT_CONFIGS[1])
	var gain: float = float(cfg["patch_speed"])
	if overclock and power > 0.0 and not blackout:
		gain *= 1.85
	if dip_puzzle_active:
		gain *= 0.45

	patch_progress = min(100.0, patch_progress + gain)
	pukan_temp = min(100.0, pukan_temp + 0.32)
	ProceduralAudio.play_key_click()
	hand_action.emit("type")

	var snippet: String = CODE_SNIPPETS[randi() % CODE_SNIPPETS.size()]
	code_lines.append("[%d%%] > %s" % [int(patch_progress), snippet])
	while code_lines.size() > 8:
		code_lines.pop_front()
	ui_updated.emit()

func start_printing_carrot() -> void:
	if not running or game_over or printer_working:
		return
	if power <= 0.0 or blackout:
		add_event_log("⚡ 3D-биопринтер обесточен!", "danger")
		return
	printer_working = true
	printer_progress = 0.0
	power = max(0.0, power - 2.5)
	ProceduralAudio.play_printer_beep()
	hand_action.emit("press")
	add_event_log("🖨️ 3D-Биопринтер печатает морковку (~9 сек)...", "info")
	ui_updated.emit()

func throw_carrot_at_trojan() -> void:
	if not running or game_over:
		return
	if carrots_count <= 0:
		add_event_log("⚠️ Нет морковок! Напечатай на 3D-биопринтере на столе!", "warn")
		ProceduralAudio.play_error_buzz()
		return
	carrots_count -= 1
	trojan_distance = min(120.0, trojan_distance + 42.0)
	trojan_in_room = false
	ProceduralAudio.play_switch(true)
	hand_action.emit("throw_carrot")
	add_event_log("🥕 Морковка брошена в тоннель! Троянский конь отступил на +42м!", "ok")
	ui_updated.emit()

func hit_tadpole() -> void:
	if not running or game_over or not tadpole_active:
		return
	tadpole_health -= 1
	ProceduralAudio.play_tadpole_splat()
	hand_action.emit("smack")
	if tadpole_health <= 0:
		tadpole_active = false
		tadpole_next_spawn = 18.0 + randf() * 12.0
		add_event_log("💥 ХРЯСЬ! Багогрыз-головастик раздавлен и вышвырнут!", "ok")
	else:
		add_event_log("💥 Удар по головастику! Осталось ударов: %d" % tadpole_health, "warn")
	ui_updated.emit()

func turn_gas_valve(angle_delta: float) -> void:
	if not running or game_over:
		return
	valve_angle += abs(angle_delta)
	hand_action.emit("turn_valve")
	if valve_angle >= TAU:
		valve_angle -= TAU
		gas_pressure = max(0.0, gas_pressure - 35.0)
		ProceduralAudio.play_steam_hisser()
		add_event_log("🔧 Вентиль провёрнут на 360°! Давление газа сброшено (-35%).", "ok")
	ui_updated.emit()

func purge_vents_with_steam() -> void:
	if not running or game_over or steam_vent_cooldown > 0.0:
		return
	steam_vent_cooldown = 4.0
	pukan_temp = max(0.0, pukan_temp - 9.0)
	ProceduralAudio.play_steam_hisser()
	hand_action.emit("press")
	if burgundy_stage > 0:
		burgundy_stage = 0
		burgundy_move_cooldown = 8.0
		add_event_log("💨 ПШШШ! Кипящий пар ошпарил Бордового Душегуба в вентиляции!", "ok")
	else:
		add_event_log("💨 Вентиляция продута паром (-9°C пукана).", "info")
	ui_updated.emit()

func crank_generator() -> void:
	if not running or game_over or crank_cooldown > 0.0:
		return
	crank_cooldown = 7.0
	power = min(100.0, power + 15.0)
	pukan_temp = min(100.0, pukan_temp + 7.0)
	ProceduralAudio.play_gate_slam()
	hand_action.emit("press")
	add_event_log("⛽ Дизель-генератор дёрнут (+15% ИБП, +7°C пукана)!", "warn")
	ui_updated.emit()

func reset_breaker() -> void:
	if not running or game_over or not blackout:
		return
	blackout = false
	if power <= 0.0:
		power = 20.0
	ProceduralAudio.play_switch(true)
	hand_action.emit("press")
	add_event_log("💡 Главный рубильник взведён! Свет и питание восстановлены!", "ok")
	ui_updated.emit()

func toggle_cctv() -> void:
	if not running or game_over:
		return
	if power <= 0.0 or blackout:
		cctv_open = false
		return
	cctv_open = not cctv_open
	ProceduralAudio.play_switch(cctv_open)
	ui_updated.emit()

func toggle_cabinet() -> void:
	cabinet_open = not cabinet_open
	ProceduralAudio.play_cabinet_creak()
	hand_action.emit("press")
	if cabinet_open:
		add_event_log("🚪 Ты распахнул шкафчик дежурного... Внутри записка: «AZAMAT SASI» ( ͡° ͜ʖ ͡°)", "warn")
	ui_updated.emit()

func click_rubber_duck() -> void:
	ProceduralAudio.play_duck_squeak()
	pukan_temp = max(0.0, pukan_temp - 3.0)
	hand_action.emit("duck")
	add_event_log("🦆 Резиновая уточка: КРЯ-Я! Пукан охлаждён на -3°C.", "info")
	ui_updated.emit()

func drink_coffee() -> void:
	ProceduralAudio.play_coffee_sip()
	power = min(100.0, power + 4.0)
	hand_action.emit("coffee")
	add_event_log("☕ Глыть! Крепкий кофе восполнил +4% энергии ИБП.", "info")
	ui_updated.emit()

func buy_buff(buff_key: String) -> void:
	if coins < 1:
		add_event_log("⚠️ Недостаточно монет! Решай головоломки [P] в сменах!", "warn")
		ProceduralAudio.play_error_buzz()
		return
	if active_buffs.get(buff_key, false):
		add_event_log("⚠️ Этот ништяк уже куплен на следующую смену!", "info")
		return
	coins -= 1
	active_buffs[buff_key] = true
	ProceduralAudio.play_coin_sound()
	add_event_log("🛒 Куплен бафф на смену: %s!" % buff_key, "ok")
	ui_updated.emit()

# -----------------------------------------------------------------------------
# Вспомогательные методы
# -----------------------------------------------------------------------------
func _init_pipeline_puzzle() -> void:
	pipe_grid = [
		{"type": "elbow", "rot": 1}, {"type": "straight", "rot": 1}, {"type": "elbow", "rot": 2},
		{"type": "straight", "rot": 0}, {"type": "cross", "rot": 0}, {"type": "straight", "rot": 0},
		{"type": "elbow", "rot": 0}, {"type": "straight", "rot": 1}, {"type": "elbow", "rot": 3}
	]
	puzzle_solved_this_shift = false

func rotate_pipe_tile(idx: int) -> void:
	if puzzle_solved_this_shift or idx < 0 or idx >= pipe_grid.size():
		return
	pipe_grid[idx]["rot"] = (int(pipe_grid[idx]["rot"]) + 1) % 4
	ProceduralAudio.play_switch(true)
	ui_updated.emit()

func complete_pipeline_puzzle() -> void:
	if puzzle_solved_this_shift:
		return
	puzzle_solved_this_shift = true
	if coins < max_coins:
		coins += 1
		ProceduralAudio.play_coin_sound()
		add_event_log("🎉 ПАЙПЛАЙН СОБРАН! +1 МОНЕТА В КОПИЛКУ ДЕЖУРНОГО!", "ok")
	else:
		add_event_log("🎉 Пайплайн собран! (Копилка полна: 3/3 монет)", "ok")
	ui_updated.emit()

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
	add_event_log("🔧 МУТАЦИЯ ЯДРА! Выстави тумблеры SW1-4 в [%d %d %d %d]!" % [next_t[0], next_t[1], next_t[2], next_t[3]], "warn")

func _check_dip_match() -> void:
	if not dip_puzzle_active:
		return
	if dip_switches == target_dip:
		var cfg: Dictionary = SHIFT_CONFIGS.get(current_level, SHIFT_CONFIGS[1])
		dip_puzzle_active = false
		next_dip_countdown = float(cfg["dip_interval"])
		pukan_temp = max(0.0, pukan_temp - 6.0)
		ProceduralAudio.play_coin_sound()
		add_event_log("✅ Реестр ядра синхронизирован (-6°C пукана)!", "ok")

func increment_hack(reason: String) -> void:
	hack_count += 1
	pukan_temp = min(100.0, pukan_temp + 16.0)
	add_event_log("💀 ПРОБОЙ ЗАЩИТЫ (%d/%d): %s" % [hack_count, max_hacks, reason], "danger")
	if hack_count >= max_hacks:
		trigger_jumpscare("ai", "КРИТИЧЕСКАЯ МАССА ВЗЛОМОВ (5/5)!", "5 взломов переполнили ядро! Серверная захвачена ИИ!")

func trigger_blackout(reason: String) -> void:
	if active_buffs["titaniumFuse"]:
		return
	blackout = true
	ProceduralAudio.play_gate_slam()
	add_event_log(reason, "danger")

func trigger_jumpscare(m_type: String, title: String, desc: String) -> void:
	running = false
	game_over = true
	cctv_open = false
	puzzle_modal_open = false
	ProceduralAudio.play_jumpscare_scream()
	jumpscare_triggered.emit(m_type, title, desc)
	ui_updated.emit()

func trigger_victory() -> void:
	running = false
	game_over = false
	cctv_open = false
	puzzle_modal_open = false
	if current_level >= max_unlocked_level and max_unlocked_level < 6:
		max_unlocked_level = current_level + 1
	ProceduralAudio.play_coin_sound()
	victory_triggered.emit(current_level)
	ui_updated.emit()

func get_usage_bars() -> int:
	if power <= 0.0 or blackout:
		return 0
	var bars := 1
	if gate_left: bars += 1
	if gate_center: bars += 1
	if gate_right: bars += 1
	if seat_cooler: bars += 1
	if overclock: bars += 1
	if cctv_open: bars += 1
	if printer_working: bars += 1
	return min(6, bars)

func get_formatted_clock() -> String:
	if in_lobby:
		return "12:00 PM (ДЕНЬ)"
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

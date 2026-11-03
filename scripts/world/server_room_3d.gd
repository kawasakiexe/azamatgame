extends Node3D
## 3D-сцена загородной серверной дежурного (Godot 4 + PS1 Shader)
## Поддерживает ходьбу по комнате (WASD), посадку в кресло по клику на кресло/терминалы,
## подъём на [ПРОБЕЛ], ночной лес за окном, ярко подсвеченные в блэкауте провода и рычаг,
## дневной автомат ништяков, секретный сейф с уликами и шкафчик AZAMAT SASI.

signal hover_changed(hint_text: String)
signal camera_rotated(delta_yaw: float, delta_pitch: float)
signal walking_updated(is_walking: bool, delta: float)

const PSX_SHADER := preload("res://shaders/psx_lit.gdshader")
const INTERACT_RANGE := 3.45

var camera: Camera3D
var world_env: WorldEnvironment

# Поворот головы и передвижение
var yaw: float = 0.0
var pitch: float = 0.0
var target_yaw: float = 0.0
var target_pitch: float = 0.0
var is_dragging_look: bool = false
var is_dragging_valve: bool = false
var _step_timer: float = 0.0
var _walk_bob_phase: float = 0.0

# 3D-объекты комнаты
var chair_group: Node3D
var left_door_mesh: MeshInstance3D
var right_door_mesh: MeshInstance3D
var fan_blades: Node3D
var gas_valve_wheel: Node3D
var carrot_hologram: Node3D
var breaker_lever: Node3D
var wires_box_door: Node3D
var cabinet_door_pivot: Node3D
var burgundy_tail_node: Node3D
var vending_machine_group: Node3D
var dip_knobs: Array[MeshInstance3D] = []

# Живые 3D-надписи на мониторах (видны стоя в комнате!)
var main_term_label3d: Label3D
var cctv_term_label3d: Label3D
var sky_backdrop_mat: ShaderMaterial

# Освещение
var office_omni: OmniLight3D
var monitor_glow: OmniLight3D
var left_ping_light: SpotLight3D
var right_ping_light: SpotLight3D
var window_sun_light: DirectionalLight3D
var breaker_emergency_light: OmniLight3D # Яркая подсветка щитка и проводов в темноте!

# 4 Монстра в 3D
var monster_distortion: Node3D
var monster_tadpole: Node3D
var monster_trojan: Node3D
var monster_burgundy: Node3D

# Скример
var jumpscare_active: bool = false
var jumpscare_timer: float = 0.0

var cam_positions := {
	"CAM01": {"pos": Vector3(0.0, 3.5, -11.5), "look": Vector3(0.0, 1.5, -18.0)},
	"CAM02": {"pos": Vector3(-7.0, 3.3, -3.5), "look": Vector3(-5.8, 1.4, 0.0)},
	"CAM03": {"pos": Vector3(0.0, 3.6, -6.5), "look": Vector3(0.0, 1.3, -15.0)},
	"CAM04": {"pos": Vector3(7.0, 3.3, -3.5), "look": Vector3(5.8, 1.4, 0.0)},
	"CAM05": {"pos": Vector3(0.0, 3.1, -15.0), "look": Vector3(0.0, 1.4, -21.0)},
	"CAM06": {"pos": Vector3(0.0, 3.5, -2.5), "look": Vector3(0.0, 3.8, -0.8)}
}

func _ready() -> void:
	_setup_environment_and_camera()
	_build_room_geometry()
	_build_desk_chair_and_terminals()
	_build_forest_window_breaker_and_cabinet()
	_build_lobby_vending_and_secrets()
	_build_monsters()
	_setup_lights()

	GameState.shift_started.connect(_on_shift_started)
	GameState.lobby_entered.connect(_on_lobby_entered)
	GameState.jumpscare_triggered.connect(_on_jumpscare)
	_apply_daytime_visuals(GameState.in_lobby)

func _setup_environment_and_camera() -> void:
	world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.025, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.14, 0.17, 0.22)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.03, 0.045)
	env.fog_density = 0.042
	world_env.environment = env
	add_child(world_env)

	camera = Camera3D.new()
	camera.fov = 72.0
	camera.position = Vector3(0.0, 1.74, 1.45)
	add_child(camera)

func _make_psx_mat(col: Color, emit_col: Color = Color.BLACK, emit_energy: float = 0.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = PSX_SHADER
	mat.set_shader_parameter("albedo_color", col)
	mat.set_shader_parameter("emission_color", emit_col)
	mat.set_shader_parameter("emission_energy", emit_energy)
	return mat

func _add_box(parent: Node3D, size: Vector3, pos: Vector3, col: Color, rot_deg: Vector3 = Vector3.ZERO, emit_col: Color = Color.BLACK, emit_e: float = 0.0, action: String = "", hint: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = _make_psx_mat(col, emit_col, emit_e)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)

	if action != "":
		var sb := StaticBody3D.new()
		sb.set_meta("interact_action", action)
		sb.set_meta("interact_hint", hint)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size * 1.18
		cs.shape = shape
		sb.add_child(cs)
		mi.add_child(sb)

	return mi

func _build_room_geometry() -> void:
	# Пол и потолок загородного офиса
	_add_box(self, Vector3(12.0, 0.2, 12.0), Vector3(0.0, -0.1, 0.0), Color(0.11, 0.13, 0.16))
	_add_box(self, Vector3(12.0, 0.2, 12.0), Vector3(0.0, 4.1, 0.0), Color(0.07, 0.09, 0.12))

	# Потолочная вентиляционная шахта над креслом
	_add_box(self, Vector3(1.6, 0.16, 1.6), Vector3(0.0, 3.96, -0.6), Color(0.15, 0.19, 0.25))
	_add_box(
		self, Vector3(1.35, 0.06, 1.35), Vector3(0.0, 3.90, -0.6),
		Color(0.28, 0.34, 0.42), Vector3.ZERO, Color.BLACK, 0.0,
		"inspect_vent", "🕳️ Вентиляционная шахта (продувается с терминала безопасности)"
	)

	burgundy_tail_node = Node3D.new()
	burgundy_tail_node.position = Vector3(0.0, 3.75, -0.6)
	add_child(burgundy_tail_node)
	_add_box(burgundy_tail_node, Vector3(0.15, 0.80, 0.15), Vector3(0.0, -0.25, 0.0), Color(0.72, 0.08, 0.18), Vector3(18.0, 0.0, 12.0), Color(0.6, 0.05, 0.12), 1.2)
	burgundy_tail_node.visible = false

	# Передняя стена (Z = -4.5) с центральным тоннелем Троянского коня
	var wall_col := Color(0.12, 0.15, 0.20)
	_add_box(self, Vector3(4.6, 4.0, 0.4), Vector3(-4.2, 2.0, -4.5), wall_col)
	_add_box(self, Vector3(4.6, 4.0, 0.4), Vector3(4.2, 2.0, -4.5), wall_col)
	_add_box(self, Vector3(3.8, 1.1, 0.4), Vector3(0.0, 3.45, -4.5), wall_col)

	# Лоток/кормушка у центрального тоннеля для броска морковки коню!
	_add_box(
		self, Vector3(1.6, 0.75, 0.45), Vector3(0.0, 0.38, -4.25),
		Color(0.25, 0.28, 0.32), Vector3.ZERO, Color(0.45, 0.25, 0.05), 0.5,
		"throw_carrot", "🥕 Бросить напечатанную морковку в тоннель Троянскому Коню"
	)

	# Центральный тоннель ЦОД
	_add_box(self, Vector3(4.2, 0.2, 18.0), Vector3(0.0, -0.1, -13.5), Color(0.06, 0.07, 0.10))
	_add_box(self, Vector3(0.3, 4.0, 18.0), Vector3(-2.0, 2.0, -13.5), Color(0.08, 0.10, 0.14))
	_add_box(self, Vector3(0.3, 4.0, 18.0), Vector3(2.0, 2.0, -13.5), Color(0.08, 0.10, 0.14))

	# Левая стена (X = -5.2) и проход Порт 22 SSH
	_add_box(self, Vector3(0.4, 4.0, 4.4), Vector3(-5.2, 2.0, -2.5), wall_col)
	_add_box(self, Vector3(0.4, 4.0, 4.4), Vector3(-5.2, 2.0, 2.5), wall_col)
	_add_box(self, Vector3(0.4, 1.2, 2.2), Vector3(-5.2, 3.4, 0.0), wall_col)
	left_door_mesh = _add_box(self, Vector3(0.18, 2.8, 2.1), Vector3(-5.1, 4.2, 0.0), Color(0.26, 0.31, 0.39))
	# Фонарь-подсветка у левого прохода (можно мигнуть стоя у двери!)
	_add_box(
		self, Vector3(0.16, 0.26, 0.26), Vector3(-4.98, 1.45, -1.25),
		Color(0.95, 0.72, 0.15), Vector3.ZERO, Color(0.9, 0.65, 0.1), 1.4,
		"ping_left", "🔦 Посветить в левый коридор (Порт 22)"
	)

	# Правая стена (X = 5.2) и проход Порт 5432 SQL
	_add_box(self, Vector3(0.4, 4.0, 4.4), Vector3(5.2, 2.0, -2.5), wall_col)
	_add_box(self, Vector3(0.4, 4.0, 4.4), Vector3(5.2, 2.0, 2.5), wall_col)
	_add_box(self, Vector3(0.4, 1.2, 2.2), Vector3(5.2, 3.4, 0.0), wall_col)
	right_door_mesh = _add_box(self, Vector3(0.18, 2.8, 2.1), Vector3(5.1, 4.2, 0.0), Color(0.26, 0.31, 0.39))
	_add_box(
		self, Vector3(0.16, 0.26, 0.26), Vector3(4.98, 1.45, -1.25),
		Color(0.95, 0.72, 0.15), Vector3.ZERO, Color(0.9, 0.65, 0.1), 1.4,
		"ping_right", "🔦 Посветить в правый коридор (Порт 5432)"
	)

	# Серверная стойка в правом переднем углу + Стикер-улика #2
	_add_box(self, Vector3(1.1, 2.6, 0.9), Vector3(4.1, 1.3, -3.5), Color(0.10, 0.12, 0.16))
	_add_box(
		self, Vector3(0.28, 0.28, 0.04), Vector3(3.52, 1.55, -3.35),
		Color(0.98, 0.88, 0.22), Vector3.ZERO, Color(0.95, 0.82, 0.15), 1.5,
		"clue_2", "📝 Прочитать жёлтый стикер на серверной стойке (Улика #2)"
	)

func _build_desk_chair_and_terminals() -> void:
	# Рабочий стол дежурного (Z = -1.65)
	_add_box(self, Vector3(3.5, 0.12, 1.35), Vector3(0.0, 0.92, -1.65), Color(0.19, 0.22, 0.27))
	_add_box(self, Vector3(0.16, 0.92, 1.2), Vector3(-1.6, 0.46, -1.65), Color(0.12, 0.14, 0.18))
	_add_box(self, Vector3(0.16, 0.92, 1.2), Vector3(1.6, 0.46, -1.65), Color(0.12, 0.14, 0.18))

	# ОФИСНОЕ КРЕСЛО ДЕЖУРНОГО (Z = -0.35) — Клик по нему сажает на пост управления!
	chair_group = Node3D.new()
	chair_group.position = Vector3(0.0, 0.0, -0.35)
	add_child(chair_group)
	_add_box(
		chair_group, Vector3(0.72, 0.10, 0.72), Vector3(0.0, 0.55, 0.0),
		Color(0.22, 0.25, 0.32), Vector3.ZERO, Color.BLACK, 0.0,
		"sit_chair", "🪑 Сесть в кресло (Занять пост управления терминалами)"
	)
	_add_box(
		chair_group, Vector3(0.70, 0.85, 0.12), Vector3(0.0, 1.02, 0.32),
		Color(0.20, 0.23, 0.30), Vector3.ZERO, Color.BLACK, 0.0,
		"sit_chair", "🪑 Сесть в кресло (Занять пост управления терминалами)"
	)
	_add_box(chair_group, Vector3(0.12, 0.55, 0.12), Vector3(0.0, 0.27, 0.0), Color(0.14, 0.16, 0.20))

	# 1. ЦЕНТРАЛЬНЫЙ ТЕРМИНАЛ (Головоломки на монету / Выбор смены днём)
	_add_box(self, Vector3(0.88, 0.68, 0.55), Vector3(-0.38, 1.34, -1.68), Color(0.24, 0.27, 0.33))
	_add_box(
		self, Vector3(0.76, 0.54, 0.05), Vector3(-0.38, 1.35, -1.39),
		Color(0.05, 0.38, 0.44), Vector3.ZERO, Color(0.08, 0.68, 0.75), 1.8,
		"open_main_term", "🖥️ Главный Терминал (Головоломка на монету / Запуск смены)"
	)
	main_term_label3d = Label3D.new()
	main_term_label3d.text = "DEVOPS IDE\n[CLICK TO USE]"
	main_term_label3d.font_size = 24
	main_term_label3d.modulate = Color(0.45, 0.98, 0.95)
	main_term_label3d.position = Vector3(-0.38, 1.36, -1.35)
	add_child(main_term_label3d)

	# 2. ПРАВЫЙ ТЕРМИНАЛ БЕЗОПАСНОСТИ (Камеры CCTV, Двери, Продувка вентиляции)
	_add_box(self, Vector3(0.82, 0.64, 0.52), Vector3(0.58, 1.32, -1.64), Color(0.20, 0.23, 0.29), Vector3(0.0, -14.0, 0.0))
	_add_box(
		self, Vector3(0.70, 0.50, 0.05), Vector3(0.54, 1.33, -1.37),
		Color(0.06, 0.32, 0.22), Vector3(0.0, -14.0, 0.0), Color(0.10, 0.65, 0.42), 1.8,
		"open_cctv_term", "📹 Терминал Безопасности (Камеры CCTV, Блокировка Дверей и Вентиляции)"
	)
	cctv_term_label3d = Label3D.new()
	cctv_term_label3d.text = "CCTV & DOORS\nRADAR ONLINE"
	cctv_term_label3d.font_size = 22
	cctv_term_label3d.modulate = Color(0.35, 0.98, 0.62)
	cctv_term_label3d.position = Vector3(0.53, 1.34, -1.33)
	cctv_term_label3d.rotation_degrees = Vector3(0.0, -14.0, 0.0)
	add_child(cctv_term_label3d)

	# Блок бинарных тумблеров ядра SW1-4 слева на столе
	_add_box(self, Vector3(0.66, 0.16, 0.34), Vector3(-1.22, 1.03, -1.48), Color(0.14, 0.17, 0.22))
	dip_knobs.clear()
	for i in range(4):
		var kx := -1.42 + float(i) * 0.135
		var knob := _add_box(
			self, Vector3(0.075, 0.14, 0.075), Vector3(kx, 1.14, -1.48),
			Color(0.15, 0.85, 0.45), Vector3.ZERO, Color(0.1, 0.8, 0.4), 1.3,
			"dip_%d" % i, "🔧 Тумблер ядра SW%d [%d]" % [i + 1, i + 1]
		)
		dip_knobs.append(knob)

	# 3D-Биопринтер морковок справа на краю стола
	_add_box(
		self, Vector3(0.48, 0.56, 0.48), Vector3(1.36, 1.25, -1.62),
		Color(0.16, 0.22, 0.29), Vector3.ZERO, Color(0.08, 0.45, 0.55), 0.6,
		"print_carrot", "🖨️ 3D-Биопринтер (Напечатать морковку для Троянского Коня)"
	)
	carrot_hologram = Node3D.new()
	carrot_hologram.position = Vector3(1.36, 1.25, -1.42)
	add_child(carrot_hologram)
	_add_box(carrot_hologram, Vector3(0.11, 0.26, 0.11), Vector3.ZERO, Color(0.98, 0.48, 0.12), Vector3.ZERO, Color(0.98, 0.45, 0.1), 2.2)

	# Жёлтая резиновая уточка (чисто фановая анимация + звук и днём, и ночью!)
	_add_box(
		self, Vector3(0.18, 0.16, 0.22), Vector3(-0.88, 1.04, -1.14),
		Color(0.96, 0.82, 0.12), Vector3(0.0, 22.0, 0.0), Color(0.4, 0.3, 0.0), 0.4,
		"rubber_duck", "🦆 Жмякнуть резиновую уточку [КРЯ!]"
	)

	# Кружка кофе
	_add_box(
		self, Vector3(0.15, 0.21, 0.15), Vector3(0.95, 1.05, -1.16),
		Color(0.16, 0.68, 0.82), Vector3.ZERO, Color(0.05, 0.25, 0.35), 0.4,
		"coffee_mug", "☕ Хлебнуть кофе"
	)

	# Настольный вентилятор
	fan_blades = Node3D.new()
	fan_blades.position = Vector3(-1.52, 1.30, -1.78)
	add_child(fan_blades)
	_add_box(fan_blades, Vector3(0.36, 0.06, 0.04), Vector3.ZERO, Color(0.45, 0.52, 0.6))
	_add_box(fan_blades, Vector3(0.06, 0.36, 0.04), Vector3.ZERO, Color(0.45, 0.52, 0.6))

	# Газовая труба и красный вентиль (у правой стены, X = 4.65, Z = -2.8) — нужно встать и подойти!
	_add_box(self, Vector3(0.20, 3.8, 0.20), Vector3(4.65, 1.9, -2.8), Color(0.38, 0.40, 0.44))
	gas_valve_wheel = Node3D.new()
	gas_valve_wheel.position = Vector3(4.42, 1.48, -2.8)
	add_child(gas_valve_wheel)
	_add_box(
		gas_valve_wheel, Vector3(0.12, 0.56, 0.56), Vector3.ZERO,
		Color(0.90, 0.16, 0.16), Vector3.ZERO, Color(0.85, 0.12, 0.12), 1.2,
		"gas_valve", "🔧 Зажми ЛКМ и крути вентиль газа по кругу (нужно стоять рядом!)"
	)

func _build_forest_window_breaker_and_cabinet() -> void:
	var wall_col := Color(0.12, 0.15, 0.20)
	# Задняя стена (Z = 4.5) с панорамным окном в ночной лес
	_add_box(self, Vector3(3.8, 4.0, 0.4), Vector3(-4.3, 2.0, 4.5), wall_col)
	_add_box(self, Vector3(3.8, 4.0, 0.4), Vector3(4.3, 2.0, 4.5), wall_col)
	_add_box(self, Vector3(4.8, 1.1, 0.4), Vector3(0.0, 0.55, 4.5), wall_col)
	_add_box(self, Vector3(4.8, 0.9, 0.4), Vector3(0.0, 3.55, 4.5), wall_col)

	# Стикер-улика #1 на раме лесного окна
	_add_box(
		self, Vector3(0.26, 0.26, 0.05), Vector3(-2.15, 1.65, 4.28),
		Color(0.98, 0.88, 0.22), Vector3.ZERO, Color(0.95, 0.82, 0.15), 1.5,
		"clue_1", "📝 Прочитать стикер на окне (Улика Сейфа #1)"
	)

	# Небо и силуэты сосен загородного леса за окном (Z = 6.5..8.5)
	var sky_plane := _add_box(self, Vector3(11.0, 6.0, 0.1), Vector3(0.0, 2.3, 8.2), Color(0.03, 0.05, 0.12), Vector3.ZERO, Color(0.04, 0.07, 0.16), 1.0)
	sky_backdrop_mat = sky_plane.material_override as ShaderMaterial

	# Луна / Солнце и силуэты елей за окном
	_add_box(self, Vector3(0.85, 0.85, 0.08), Vector3(-1.8, 3.1, 7.8), Color(0.95, 0.92, 0.78), Vector3.ZERO, Color(0.95, 0.92, 0.78), 2.5)
	var tree_positions := [-3.2, -1.9, -0.7, 0.6, 1.8, 3.1]
	for tx in tree_positions:
		_add_box(self, Vector3(0.28, 2.2, 0.28), Vector3(tx, 1.1, 6.4), Color(0.05, 0.07, 0.06))
		_add_box(self, Vector3(1.15, 1.4, 0.6), Vector3(tx, 2.1, 6.4), Color(0.04, 0.12, 0.08))
		_add_box(self, Vector3(0.82, 1.2, 0.5), Vector3(tx, 2.9, 6.4), Color(0.05, 0.15, 0.10))

	# -------------------------------------------------------------------------
	# ШКАФЧИК С ПРОВОДАМИ И РЫЧАГ СВЕТА (У задней стены, X = -3.2, Z = 4.2)
	# В темноте (блэкаут) они отчётливо светятся, чтобы игрок видел, куда идти!
	# -------------------------------------------------------------------------
	# 1) Коробка с проводами
	_add_box(
		self, Vector3(0.72, 0.88, 0.22), Vector3(-3.45, 1.68, 4.25),
		Color(0.24, 0.28, 0.35), Vector3.ZERO, Color(0.95, 0.55, 0.12), 1.6,
		"open_wires_box", "🔌 Электрощиток с проводами (Починить проводку перед включением света)"
	)
	# Цветные полоски проводов внутри щитка (светятся в темноте!)
	_add_box(self, Vector3(0.45, 0.06, 0.04), Vector3(-3.45, 1.88, 4.12), Color.RED, Vector3.ZERO, Color.RED, 3.2)
	_add_box(self, Vector3(0.45, 0.06, 0.04), Vector3(-3.45, 1.74, 4.12), Color.CYAN, Vector3.ZERO, Color.CYAN, 3.2)
	_add_box(self, Vector3(0.45, 0.06, 0.04), Vector3(-3.45, 1.60, 4.12), Color.YELLOW, Vector3.ZERO, Color.YELLOW, 3.2)
	_add_box(self, Vector3(0.45, 0.06, 0.04), Vector3(-3.45, 1.46, 4.12), Color.GREEN, Vector3.ZERO, Color.GREEN, 3.2)

	# 2) Рубильник подачи света рядом со щитком проводов
	_add_box(self, Vector3(0.42, 0.58, 0.18), Vector3(-2.65, 1.68, 4.25), Color(0.20, 0.24, 0.30))
	breaker_lever = Node3D.new()
	breaker_lever.position = Vector3(-2.65, 1.68, 4.12)
	add_child(breaker_lever)
	_add_box(
		breaker_lever, Vector3(0.22, 0.44, 0.16), Vector3.ZERO,
		Color(0.96, 0.22, 0.18), Vector3.ZERO, Color(1.0, 0.25, 0.15), 3.2,
		"pull_breaker", "⚡ Главный Рычаг Света (Врубить питание после починки проводов)"
	)

	# ШКАФЧИК ДЕЖУРНОГО С ПАСХАЛКОЙ «AZAMAT SASI» (Сзади слева, X = 3.45, Z = 4.05)
	_add_box(self, Vector3(1.1, 2.1, 0.55), Vector3(3.45, 1.25, 4.05), Color(0.18, 0.22, 0.28))
	_add_box(
		self, Vector3(0.78, 0.48, 0.04), Vector3(3.45, 1.55, 3.82),
		Color(0.95, 0.88, 0.25), Vector3.ZERO, Color(0.95, 0.82, 0.2), 1.8,
		"clue_3", "📝 Надпись AZAMAT SASI и Улика Сейфа #3"
	)
	var label3d := Label3D.new()
	label3d.text = "AZAMAT SASI\n( ͡° ͜ʖ ͡°)\n[1 BYTE = 8 BIT]"
	label3d.font_size = 32
	label3d.modulate = Color(0.05, 0.05, 0.05)
	label3d.position = Vector3(3.45, 1.55, 3.78)
	label3d.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	add_child(label3d)

	cabinet_door_pivot = Node3D.new()
	cabinet_door_pivot.position = Vector3(3.97, 1.25, 3.76)
	add_child(cabinet_door_pivot)
	_add_box(
		cabinet_door_pivot, Vector3(1.04, 2.02, 0.08), Vector3(-0.52, 0.0, 0.0),
		Color(0.26, 0.31, 0.38), Vector3.ZERO, Color.BLACK, 0.0,
		"toggle_cabinet", "🚪 Открыть/закрыть шкафчик дежурного"
	)

func _build_lobby_vending_and_secrets() -> void:
	# 1. ТОРГОВЫЙ АВТОМАТ «ЛАРЁК НИШТЯКОВ» (Работает в Дневном Лобби у левой стены, X = -4.2, Z = -3.3)
	vending_machine_group = Node3D.new()
	vending_machine_group.position = Vector3(-4.15, 0.0, -3.35)
	add_child(vending_machine_group)
	_add_box(
		vending_machine_group, Vector3(1.15, 2.25, 0.85), Vector3(0.0, 1.12, 0.0),
		Color(0.16, 0.14, 0.26), Vector3.ZERO, Color(0.95, 0.58, 0.12), 0.7,
		"open_shop_vending", "🛒 Торговый автомат «Ларёк Ништяков» (Купить баффы за монетки)"
	)
	var vend_lbl := Label3D.new()
	vend_lbl.text = "ЛАРЁК НИШТЯКОВ\n[1🪙 = 1 БАФФ]"
	vend_lbl.font_size = 28
	vend_lbl.modulate = Color(1.0, 0.85, 0.25)
	vend_lbl.position = Vector3(0.0, 1.75, 0.45)
	vending_machine_group.add_child(vend_lbl)

	# 2. СЕКРЕТНЫЙ КРИПТО-СЕЙФ СЕНЬОРА (Сложная головоломка в Дневном Лобби, X = -4.45, Z = 2.8)
	_add_box(
		self, Vector3(0.65, 0.65, 0.65), Vector3(-4.45, 0.95, 2.8),
		Color(0.28, 0.30, 0.34), Vector3.ZERO, Color(0.15, 0.75, 0.45), 0.9,
		"open_lobby_safe", "🔐 Кодовый Сейф Сеньора (Секретная головоломка лобби)"
	)

func _build_monsters() -> void:
	# 1. Исказитель / Архитектор
	monster_distortion = Node3D.new()
	add_child(monster_distortion)
	_add_box(monster_distortion, Vector3(0.75, 2.65, 0.45), Vector3(0.0, 1.32, 0.0), Color(0.03, 0.03, 0.05))
	_add_box(monster_distortion, Vector3(0.42, 0.52, 0.42), Vector3(0.0, 2.85, 0.0), Color(0.04, 0.04, 0.06))
	_add_box(monster_distortion, Vector3(0.10, 0.08, 0.06), Vector3(-0.11, 2.88, 0.22), Color.WHITE, Vector3.ZERO, Color(1.0, 0.2, 0.2), 5.0)
	_add_box(monster_distortion, Vector3(0.10, 0.08, 0.06), Vector3(0.11, 2.88, 0.22), Color.WHITE, Vector3.ZERO, Color(1.0, 0.2, 0.2), 5.0)
	monster_distortion.visible = false

	# 2. Багогрыз-головастик на столе
	monster_tadpole = Node3D.new()
	monster_tadpole.position = Vector3(0.0, 1.08, -1.22)
	add_child(monster_tadpole)
	_add_box(
		monster_tadpole, Vector3(0.34, 0.22, 0.42), Vector3.ZERO,
		Color(0.18, 0.55, 0.22), Vector3.ZERO, Color(0.2, 0.8, 0.3), 1.4,
		"hit_tadpole", "💥 УЕБАТЬ БАГОГРЫЗА КЛИКОМ!"
	)
	monster_tadpole.visible = false

	# 3. Троянский Конь в T-Pose (с 3-го уровня)
	monster_trojan = Node3D.new()
	monster_trojan.position = Vector3(0.0, 0.0, -14.0)
	add_child(monster_trojan)
	var wood_col := Color(0.58, 0.38, 0.18)
	_add_box(monster_trojan, Vector3(0.95, 1.35, 1.65), Vector3(0.0, 1.35, 0.0), wood_col)
	_add_box(monster_trojan, Vector3(2.5, 0.28, 0.32), Vector3(0.0, 1.75, 0.2), wood_col)
	_add_box(monster_trojan, Vector3(0.48, 0.95, 0.55), Vector3(0.0, 2.25, 0.55), wood_col, Vector3(-20.0, 0.0, 0.0))
	_add_box(monster_trojan, Vector3(0.44, 0.42, 0.85), Vector3(0.0, 2.62, 0.85), wood_col)
	_add_box(monster_trojan, Vector3(0.10, 0.10, 0.10), Vector3(-0.16, 2.68, 1.26), Color(1.0, 0.3, 0.1), Vector3.ZERO, Color(1.0, 0.2, 0.1), 4.0)
	_add_box(monster_trojan, Vector3(0.10, 0.10, 0.10), Vector3(0.16, 2.68, 1.26), Color(1.0, 0.3, 0.1), Vector3.ZERO, Color(1.0, 0.2, 0.1), 4.0)
	monster_trojan.visible = false

	# 4. Бордовый Душегуб
	monster_burgundy = Node3D.new()
	monster_burgundy.position = Vector3(0.0, 3.6, -2.5)
	add_child(monster_burgundy)
	_add_box(monster_burgundy, Vector3(0.68, 0.55, 0.95), Vector3.ZERO, Color(0.65, 0.06, 0.16), Vector3.ZERO, Color(0.8, 0.05, 0.15), 1.5)
	monster_burgundy.visible = false

func _setup_lights() -> void:
	office_omni = OmniLight3D.new()
	office_omni.position = Vector3(0.0, 3.45, 0.0)
	office_omni.light_color = Color(0.72, 0.78, 0.88)
	office_omni.light_energy = 1.25
	office_omni.omni_range = 10.5
	add_child(office_omni)

	monitor_glow = OmniLight3D.new()
	monitor_glow.position = Vector3(0.0, 1.42, -1.15)
	monitor_glow.light_color = Color(0.15, 0.88, 0.82)
	monitor_glow.light_energy = 0.95
	monitor_glow.omni_range = 4.2
	add_child(monitor_glow)

	left_ping_light = SpotLight3D.new()
	left_ping_light.position = Vector3(-3.2, 2.2, 0.0)
	left_ping_light.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	left_ping_light.light_color = Color(1.0, 0.85, 0.45)
	left_ping_light.light_energy = 0.0
	left_ping_light.spot_range = 6.5
	add_child(left_ping_light)

	right_ping_light = SpotLight3D.new()
	right_ping_light.position = Vector3(3.2, 2.2, 0.0)
	right_ping_light.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	right_ping_light.light_color = Color(1.0, 0.85, 0.45)
	right_ping_light.light_energy = 0.0
	right_ping_light.spot_range = 6.5
	add_child(right_ping_light)

	window_sun_light = DirectionalLight3D.new()
	window_sun_light.rotation_degrees = Vector3(-28.0, 180.0, 0.0)
	window_sun_light.light_color = Color(1.0, 0.95, 0.82)
	window_sun_light.light_energy = 1.2
	add_child(window_sun_light)

	# Аварийный светильник над щитком с проводами и рычагом (включается в блэкаут!)
	breaker_emergency_light = OmniLight3D.new()
	breaker_emergency_light.position = Vector3(-3.05, 2.15, 3.65)
	breaker_emergency_light.light_color = Color(1.0, 0.32, 0.16)
	breaker_emergency_light.light_energy = 0.25
	breaker_emergency_light.omni_range = 4.2
	add_child(breaker_emergency_light)

func _apply_daytime_visuals(is_day: bool) -> void:
	if world_env and world_env.environment:
		var env := world_env.environment
		if is_day:
			env.ambient_light_color = Color(0.62, 0.70, 0.80)
			env.ambient_light_energy = 0.98
			env.fog_light_color = Color(0.38, 0.52, 0.68)
			env.fog_density = 0.014
		else:
			env.ambient_light_color = Color(0.09, 0.11, 0.15)
			env.ambient_light_energy = 0.34
			env.fog_light_color = Color(0.02, 0.025, 0.04)
			env.fog_density = 0.048

	if window_sun_light:
		window_sun_light.light_energy = 1.35 if is_day else 0.10
		window_sun_light.light_color = Color(1.0, 0.94, 0.80) if is_day else Color(0.22, 0.34, 0.65)

	if sky_backdrop_mat:
		var sky_col := Color(0.42, 0.72, 0.96) if is_day else Color(0.02, 0.03, 0.08)
		sky_backdrop_mat.set_shader_parameter("albedo_color", sky_col)
		sky_backdrop_mat.set_shader_parameter("emission_color", sky_col)
		sky_backdrop_mat.set_shader_parameter("emission_energy", 1.5 if is_day else 0.6)

func _on_shift_started(_lvl: int) -> void:
	jumpscare_active = false
	target_yaw = 0.0
	target_pitch = -0.05
	_apply_daytime_visuals(false)

func _on_lobby_entered() -> void:
	jumpscare_active = false
	GameState.player_pos = Vector3(0.0, 0.0, 1.55)
	_apply_daytime_visuals(true)

func _on_jumpscare(_m_type: String, _title: String, _desc: String) -> void:
	jumpscare_active = true
	jumpscare_timer = 1.2

func _unhandled_input(event: InputEvent) -> void:
	if GameState.active_screen != "":
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var hit := _raycast_from_mouse(mb.position)
				if not hit.is_empty():
					var act: String = hit.get("action", "")
					var dist: float = float(hit.get("dist", 99.0))
					if dist <= INTERACT_RANGE:
						if act == "gas_valve" and not GameState.is_seated:
							is_dragging_valve = true
							return
						_execute_interact_action(act)
					else:
						GameState.add_event_log("🚶 Слишком далеко! Подойди ближе на [WASD] (или встань с кресла на [ПРОБЕЛ]).", "info")
				is_dragging_look = true
			else:
				is_dragging_look = false
				is_dragging_valve = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			is_dragging_look = not is_dragging_look

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if is_dragging_valve:
			var delta_ang: float = (mm.relative.x + mm.relative.y) * 0.045
			GameState.turn_gas_valve(delta_ang)
			if gas_valve_wheel:
				gas_valve_wheel.rotate_x(delta_ang)
		elif is_dragging_look:
			var dyaw: float = -mm.relative.x * 0.0055
			var dpitch: float = clampf(target_pitch - mm.relative.y * 0.0045, -0.72, 0.75) - target_pitch
			target_yaw = fposmod(target_yaw + dyaw, TAU)
			target_pitch = clampf(target_pitch + dpitch, -0.72, 0.75)
			camera_rotated.emit(dyaw, dpitch)
		else:
			var hit := _raycast_from_mouse(mm.position)
			if not hit.is_empty():
				var d: float = float(hit.get("dist", 99.0))
				var h_text: String = String(hit.get("hint", ""))
				if d > INTERACT_RANGE:
					h_text += " [Подойди ближе]"
				hover_changed.emit(h_text)
			else:
				hover_changed.emit("")

func _raycast_from_mouse(screen_pos: Vector2) -> Dictionary:
	if camera == null:
		return {}
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 14.0
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var res := space.intersect_ray(query)
	if res.is_empty():
		return {}
	var col_obj: Object = res.get("collider")
	var hit_pos: Vector3 = res.get("position", Vector3.ZERO)
	if col_obj and col_obj.has_meta("interact_action"):
		return {
			"action": String(col_obj.get_meta("interact_action")),
			"hint": String(col_obj.get_meta("interact_hint")),
			"dist": camera.global_position.distance_to(hit_pos)
		}
	return {}

func _execute_interact_action(act: String) -> void:
	match act:
		"sit_chair":
			GameState.sit_in_chair()
		"open_main_term":
			# Пункт 1 & 8: нажатие по терминалу стоя сажает в кресло и открывает экран!
			if not GameState.is_seated:
				GameState.sit_in_chair("MAIN_TERM")
			else:
				GameState.open_interactive_screen("MAIN_TERM")
		"open_cctv_term":
			if not GameState.is_seated:
				GameState.sit_in_chair("CCTV_TERM")
			else:
				if GameState.in_lobby:
					GameState.add_event_log("📹 Днём камеры и шлюзы в режиме ожидания. Выбери смену на левом мониторе!", "info")
				elif GameState.blackout or GameState.power <= 0.0:
					ProceduralAudio.play_error_buzz()
					GameState.add_event_log("⚡ Терминал безопасности обесточен! Почини провода и включи рычаг у окна!", "danger")
				else:
					GameState.open_interactive_screen("CCTV_TERM")
		"open_wires_box":
			if GameState.is_seated:
				GameState.add_event_log("⚠️ Встань с кресла на [ПРОБЕЛ] и подойди к щитку с проводами!", "warn")
			else:
				GameState.open_interactive_screen("WIRES_BOX")
		"pull_breaker":
			GameState.pull_breaker_lever()
		"open_shop_vending":
			if not GameState.in_lobby:
				GameState.add_event_log("🛒 Ночью ларёк ништяков закрыт! Закупайся днём в лобби!", "warn")
			else:
				GameState.open_interactive_screen("SHOP_VENDING")
		"open_lobby_safe":
			if not GameState.in_lobby:
				GameState.add_event_log("🔐 Не до сейфа сейчас — переживи ночь до 06:00 AM!", "warn")
			else:
				GameState.open_interactive_screen("LOBBY_SAFE")
		"clue_1": GameState.inspect_clue(1)
		"clue_2": GameState.inspect_clue(2)
		"clue_3": GameState.inspect_clue(3)
		"ping_left": GameState.ping_corridor("left")
		"ping_right": GameState.ping_corridor("right")
		"print_carrot": GameState.start_printing_carrot()
		"throw_carrot": GameState.pickup_or_throw_carrot()
		"toggle_cabinet": GameState.toggle_cabinet()
		"rubber_duck": GameState.click_rubber_duck()
		"coffee_mug": GameState.drink_coffee()
		"hit_tadpole": GameState.hit_tadpole()
		"dip_0": GameState.toggle_dip(0)
		"dip_1": GameState.toggle_dip(1)
		"dip_2": GameState.toggle_dip(2)
		"dip_3": GameState.toggle_dip(3)
		"inspect_vent":
			GameState.add_event_log("🕳️ Потолочная вентиляция. Блокировка паром — с правого терминала на столе!", "info")

func _process(delta: float) -> void:
	# 1. Ходьба на WASD (когда не сидим в кресле и не открыта модалка)
	var is_walking := false
	if not GameState.is_seated and GameState.active_screen == "":
		var move_input := Vector2.ZERO
		if Input.is_key_pressed(KEY_W): move_input.y += 1.0
		if Input.is_key_pressed(KEY_S): move_input.y -= 1.0
		if Input.is_key_pressed(KEY_A): move_input.x -= 1.0
		if Input.is_key_pressed(KEY_D): move_input.x += 1.0

		if move_input.length_squared() > 0.01:
			move_input = move_input.normalized()
			is_walking = true
			var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
			var right := Vector3(cos(yaw), 0.0, -sin(yaw))
			var vel := (forward * move_input.y + right * move_input.x) * 3.4 * delta
			var next_pos := GameState.player_pos + vel

			# Коллизия со стенами комнаты и рабочим столом в центре
			next_pos.x = clampf(next_pos.x, -4.3, 4.3)
			next_pos.z = clampf(next_pos.z, -3.55, 3.65)
			if next_pos.x > -1.85 and next_pos.x < 1.85 and next_pos.z > -2.35 and next_pos.z < -0.65:
				next_pos = GameState.player_pos
			GameState.player_pos = next_pos

			_walk_bob_phase += delta * 10.5
			_step_timer -= delta
			if _step_timer <= 0.0:
				_step_timer = 0.42
				ProceduralAudio.play_footstep()

	walking_updated.emit(is_walking, delta)

	# Передаём близость к заднему окну в аудио-движок (чтобы сверчки за окном звучали громче у окна)
	var prox := clampf((GameState.player_pos.z + 2.0) / 6.0, 0.15, 1.0)
	ProceduralAudio.window_proximity = prox

	# 2. Камера: либо CCTV, либо сидя в кресле, либо стоя пешком
	yaw = lerp_angle(yaw, target_yaw, min(1.0, delta * 14.0))
	pitch = lerpf(pitch, target_pitch, min(1.0, delta * 14.0))

	if GameState.active_screen == "CCTV_TERM" and cam_positions.has(GameState.current_cam):
		var c_info: Dictionary = cam_positions[GameState.current_cam]
		camera.position = c_info["pos"]
		camera.look_at(c_info["look"], Vector3.UP)
	elif GameState.is_seated:
		var seat_eye := Vector3(0.0, 1.54, -0.35)
		camera.position = camera.position.lerp(seat_eye, min(1.0, delta * 10.0))
		camera.rotation = Vector3(pitch, yaw, 0.0)
		_update_looked_sector()
	else:
		var head_bob := sin(_walk_bob_phase) * 0.045 if is_walking else 0.0
		var stand_eye := GameState.player_pos + Vector3(0.0, 1.74 + head_bob, 0.0)
		camera.position = camera.position.lerp(stand_eye, min(1.0, delta * 14.0))
		camera.rotation = Vector3(pitch, yaw, 0.0)
		_update_looked_sector()

	if jumpscare_active:
		jumpscare_timer = max(0.0, jumpscare_timer - delta)
		camera.fov = lerpf(camera.fov, 42.0, min(1.0, delta * 24.0))
		camera.position += Vector3(randf_range(-0.18, 0.18), randf_range(-0.18, 0.18), randf_range(-0.10, 0.10))
		if office_omni:
			office_omni.light_color = Color(1.0, 0.12, 0.12)
			office_omni.light_energy = 4.5 if (int(jumpscare_timer * 30.0) % 2 == 0) else 0.2
	else:
		camera.fov = lerpf(camera.fov, 72.0, min(1.0, delta * 10.0))
		if office_omni:
			office_omni.light_color = Color(0.72, 0.78, 0.88)

	# 3. Живое обновление текста на 3D-экранах мониторов (чтобы было видно даже стоя!)
	_update_3d_monitor_screens()

	# 4. Анимация дверей, рычага, вентилятора и шкафчика
	if left_door_mesh:
		var ly := 1.45 if GameState.gate_left else 4.2
		left_door_mesh.position.y = lerpf(left_door_mesh.position.y, ly, min(1.0, delta * 10.0))
	if right_door_mesh:
		var ry := 1.45 if GameState.gate_right else 4.2
		right_door_mesh.position.y = lerpf(right_door_mesh.position.y, ry, min(1.0, delta * 10.0))

	if cabinet_door_pivot:
		var target_cab_rot := -115.0 if GameState.cabinet_open else 0.0
		cabinet_door_pivot.rotation_degrees.y = lerpf(cabinet_door_pivot.rotation_degrees.y, target_cab_rot, min(1.0, delta * 8.0))

	if breaker_lever:
		var target_lev_rot := 38.0 if GameState.blackout else -25.0
		breaker_lever.rotation_degrees.x = lerpf(breaker_lever.rotation_degrees.x, target_lev_rot, min(1.0, delta * 10.0))

	if fan_blades and not GameState.blackout and GameState.power > 0.0:
		fan_blades.rotate_z(delta * 12.0)
	if carrot_hologram:
		carrot_hologram.visible = GameState.printer_working or GameState.carrots_count > 0
		carrot_hologram.rotate_y(delta * 3.0)

	# 5. Освещение в темноте (Блэкаут): в комнате почти ничего не видно,
	# но отчётливо подсвечен рычаг и шкафчик с проводами!
	var is_dark := (not GameState.in_lobby) and (GameState.blackout or GameState.power <= 0.0)
	if office_omni:
		office_omni.light_energy = 0.02 if is_dark else 1.25
	if monitor_glow:
		monitor_glow.light_energy = 0.0 if is_dark else 0.95
	if breaker_emergency_light:
		breaker_emergency_light.light_energy = 2.8 if is_dark else 0.2
	if world_env and world_env.environment and not GameState.in_lobby:
		world_env.environment.ambient_light_energy = 0.035 if is_dark else 0.34

	if left_ping_light:
		left_ping_light.light_energy = 4.5 if GameState.ping_left_timer > 0.0 else 0.0
	if right_ping_light:
		right_ping_light.light_energy = 4.5 if GameState.ping_right_timer > 0.0 else 0.0

	_sync_monsters_3d()

func _update_3d_monitor_screens() -> void:
	if main_term_label3d:
		if GameState.in_lobby:
			main_term_label3d.text = "ПОСТ ДЕЖУРНОГО\n[ВЫБОР СМЕНЫ 1-%d]\nМОНЕТЫ: %d/3" % [GameState.max_unlocked_level, GameState.coins]
		elif GameState.blackout:
			main_term_label3d.text = "NO POWER!\nПОЧИНИ ПРОВОДА\nУ ЗАДНЕГО ОКНА!"
		else:
			main_term_label3d.text = "%s\nЗАДАЧА НА +1🪙:\n%s" % [
				GameState.get_formatted_clock(),
				"РЕШЕНО ✅" if GameState.puzzle_solved_this_shift else "НАЖМИ ДЛЯ ВХОДА"
			]

	if cctv_term_label3d:
		if GameState.in_lobby:
			cctv_term_label3d.text = "CCTV & ЗАМКИ\nРЕЖИМ ДНЯ: ОК\nВСЕ УГРОЗЫ СНЯТЫ"
		elif GameState.blackout:
			cctv_term_label3d.text = "ERR: BLACKOUT\nШЛЮЗЫ ОТКРЫТЫ!"
		else:
			var warn := "ЧИСТО"
			if GameState.distortion_active:
				warn = "⚠️ " + GameState.distortion_pos
			elif GameState.burgundy_stage > 0:
				warn = "🩸 ВЕНТ. СТАДИЯ %d" % GameState.burgundy_stage
			cctv_term_label3d.text = "ИБП: %d%% | ПУКАН: %d°C\nРАДАР: %s\nТРОЯН: %dм" % [
				int(GameState.power), int(GameState.pukan_temp), warn, int(GameState.trojan_distance)
			]

func _update_looked_sector() -> void:
	var deg := fposmod(rad_to_deg(yaw), 360.0)
	if pitch > 0.35:
		GameState.player_looking_at_sector = "CEILING_VENT"
	elif deg < 45.0 or deg >= 315.0:
		GameState.player_looking_at_sector = "DESK"
	elif deg >= 45.0 and deg < 135.0:
		GameState.player_looking_at_sector = "DOOR_LEFT"
	elif deg >= 135.0 and deg < 225.0:
		GameState.player_looking_at_sector = "WINDOW_BACK"
	else:
		GameState.player_looking_at_sector = "DOOR_RIGHT"

func _sync_monsters_3d() -> void:
	# 1. Исказитель
	if monster_distortion:
		monster_distortion.visible = GameState.distortion_active
		if GameState.distortion_active:
			match GameState.distortion_pos:
				"CAM02_APPROACH":
					monster_distortion.position = Vector3(-6.8, 0.0, -3.2)
					monster_distortion.rotation_degrees.y = 90.0
				"DOOR_LEFT":
					monster_distortion.position = Vector3(-5.9, 0.0, 0.0)
					monster_distortion.rotation_degrees.y = 90.0
				"CAM04_APPROACH":
					monster_distortion.position = Vector3(6.8, 0.0, -3.2)
					monster_distortion.rotation_degrees.y = -90.0
				"DOOR_RIGHT":
					monster_distortion.position = Vector3(5.9, 0.0, 0.0)
					monster_distortion.rotation_degrees.y = -90.0
				"WINDOW_BACK":
					monster_distortion.position = Vector3(0.0, 0.0, 5.3)
					monster_distortion.rotation_degrees.y = 180.0

	# 2. Багогрыз-головастик
	if monster_tadpole:
		monster_tadpole.visible = GameState.tadpole_active
		if GameState.tadpole_active:
			monster_tadpole.position.x = GameState.tadpole_x + sin(Time.get_ticks_msec() * 0.01) * 0.12

	# 3. Троянский конь в T-Pose (только если включён на уровне >= 3)
	if monster_trojan:
		var cfg: Dictionary = GameState.SHIFT_CONFIGS.get(GameState.current_level, GameState.SHIFT_CONFIGS[1])
		monster_trojan.visible = (not GameState.in_lobby) and bool(cfg["trojan_enabled"])
		var z_pos := lerpf(-2.4, -20.0, clampf(GameState.trojan_distance / 100.0, 0.0, 1.0))
		monster_trojan.position = Vector3(0.0, 0.0, z_pos)

	# 4. Бордовый Душегуб и хвост в потолке
	if burgundy_tail_node:
		burgundy_tail_node.visible = (GameState.burgundy_stage == 2)
		if burgundy_tail_node.visible:
			burgundy_tail_node.rotation.z = sin(Time.get_ticks_msec() * 0.015) * 0.35
	if monster_burgundy:
		monster_burgundy.visible = (GameState.burgundy_stage > 0 and GameState.active_screen == "CCTV_TERM" and GameState.current_cam == "CAM06")

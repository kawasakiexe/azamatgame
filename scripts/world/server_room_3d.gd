extends Node3D
## 3D-сцена серверной дежурного (Godot 4 + PS1 Shader + 360° Raycast Interaction)
## Строит геометрию кабинета, шлюзов, рабочего стола, окна, вентиляции и 4 монстров.

signal hover_changed(hint_text: String)
signal camera_rotated(delta_yaw: float, delta_pitch: float)

const PSX_SHADER := preload("res://shaders/psx_lit.gdshader")

var camera: Camera3D
var world_env: WorldEnvironment

# Углы 360° обзора
var yaw: float = 0.0
var pitch: float = 0.0
var target_yaw: float = 0.0
var target_pitch: float = 0.0
var is_dragging_look: bool = false
var is_dragging_valve: bool = false

# Ссылки на анимируемые 3D-узлы
var left_door_mesh: MeshInstance3D
var right_door_mesh: MeshInstance3D
var center_door_mesh: MeshInstance3D
var fan_blades: Node3D
var gas_valve_wheel: Node3D
var carrot_hologram: Node3D
var breaker_lever: Node3D
var cabinet_door_pivot: Node3D
var vent_grate_mesh: MeshInstance3D
var burgundy_tail_node: Node3D
var dip_knobs: Array[MeshInstance3D] = []

# Небо за задним окном
var sky_backdrop_mat: ShaderMaterial

# Освещение
var office_omni: OmniLight3D
var monitor_glow: OmniLight3D
var left_ping_light: SpotLight3D
var right_ping_light: SpotLight3D
var window_sun_light: DirectionalLight3D

# 3D-узлы 4 монстров
var monster_distortion: Node3D
var monster_tadpole: Node3D
var monster_trojan: Node3D
var monster_burgundy: Node3D

# Скример
var jumpscare_active: bool = false
var jumpscare_timer: float = 0.0

# Позиции камер видеонаблюдения (CCTV)
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
	_build_desk_and_props()
	_build_back_window_and_cabinet()
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
	camera.position = Vector3(0.0, 1.62, 0.25)
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
		shape.size = size * 1.15
		cs.shape = shape
		sb.add_child(cs)
		mi.add_child(sb)

	return mi

func _build_room_geometry() -> void:
	# Пол и потолок
	_add_box(self, Vector3(14.0, 0.2, 14.0), Vector3(0.0, -0.1, 0.0), Color(0.09, 0.11, 0.15))
	_add_box(self, Vector3(14.0, 0.2, 14.0), Vector3(0.0, 4.1, 0.0), Color(0.06, 0.08, 0.11))

	# Потолочная вентиляционная шахта над столом
	_add_box(self, Vector3(1.6, 0.16, 1.6), Vector3(0.0, 3.96, -0.8), Color(0.14, 0.18, 0.24))
	vent_grate_mesh = _add_box(
		self, Vector3(1.35, 0.06, 1.35), Vector3(0.0, 3.90, -0.8),
		Color(0.28, 0.34, 0.42), Vector3.ZERO, Color.BLACK, 0.0,
		"purge_steam", "💨 Продуть потолочную вентиляцию паром [V]"
	)

	# Хвост Бордового Душегуба в вентиляции
	burgundy_tail_node = Node3D.new()
	burgundy_tail_node.position = Vector3(0.0, 3.75, -0.8)
	add_child(burgundy_tail_node)
	_add_box(burgundy_tail_node, Vector3(0.14, 0.75, 0.14), Vector3(0.0, -0.25, 0.0), Color(0.65, 0.08, 0.18), Vector3(18.0, 0.0, 12.0), Color(0.5, 0.04, 0.1), 0.8)
	burgundy_tail_node.visible = false

	# Передняя стена (Z = -4.5) с центральным тоннелем для Троянского Коня
	var wall_col := Color(0.11, 0.14, 0.19)
	_add_box(self, Vector3(5.0, 4.0, 0.4), Vector3(-4.5, 2.0, -4.5), wall_col)
	_add_box(self, Vector3(5.0, 4.0, 0.4), Vector3(4.5, 2.0, -4.5), wall_col)
	_add_box(self, Vector3(4.2, 1.1, 0.4), Vector3(0.0, 3.45, -4.5), wall_col)

	# Длинный центральный тоннель ЦОД (до Z = -22)
	_add_box(self, Vector3(4.6, 0.2, 18.0), Vector3(0.0, -0.1, -13.5), Color(0.06, 0.07, 0.10))
	_add_box(self, Vector3(0.3, 4.0, 18.0), Vector3(-2.3, 2.0, -13.5), Color(0.08, 0.10, 0.14))
	_add_box(self, Vector3(0.3, 4.0, 18.0), Vector3(2.3, 2.0, -13.5), Color(0.08, 0.10, 0.14))

	# Центральная гермодверь
	center_door_mesh = _add_box(self, Vector3(4.1, 2.9, 0.16), Vector3(0.0, 4.25, -4.38), Color(0.24, 0.29, 0.36))

	# Левая стена (X = -5.5) и шлюз Port 22 SSH
	_add_box(self, Vector3(0.4, 4.0, 4.8), Vector3(-5.5, 2.0, -2.6), wall_col)
	_add_box(self, Vector3(0.4, 4.0, 4.8), Vector3(-5.5, 2.0, 2.6), wall_col)
	_add_box(self, Vector3(0.4, 1.2, 2.4), Vector3(-5.5, 3.4, 0.0), wall_col)
	left_door_mesh = _add_box(self, Vector3(0.18, 2.8, 2.2), Vector3(-5.4, 4.2, 0.0), Color(0.25, 0.30, 0.38))

	# Кнопки левого шлюза
	_add_box(
		self, Vector3(0.15, 0.28, 0.28), Vector3(-5.28, 1.55, -1.35),
		Color(0.85, 0.18, 0.18), Vector3.ZERO, Color(0.9, 0.1, 0.1), 1.4,
		"gate_left", "🔒 Левая гермодверь (Порт 22 SSH) [Q]"
	)
	_add_box(
		self, Vector3(0.15, 0.28, 0.28), Vector3(-5.28, 1.15, -1.35),
		Color(0.95, 0.72, 0.15), Vector3.ZERO, Color(0.9, 0.65, 0.1), 1.2,
		"ping_left", "🔦 Подсветить левый шлюз [A]"
	)

	# Правая стена (X = 5.5) и шлюз Port 5432 SQL
	_add_box(self, Vector3(0.4, 4.0, 4.8), Vector3(5.5, 2.0, -2.6), wall_col)
	_add_box(self, Vector3(0.4, 4.0, 4.8), Vector3(5.5, 2.0, 2.6), wall_col)
	_add_box(self, Vector3(0.4, 1.2, 2.4), Vector3(5.5, 3.4, 0.0), wall_col)
	right_door_mesh = _add_box(self, Vector3(0.18, 2.8, 2.2), Vector3(5.4, 4.2, 0.0), Color(0.25, 0.30, 0.38))

	# Кнопки правого шлюза
	_add_box(
		self, Vector3(0.15, 0.28, 0.28), Vector3(5.28, 1.55, -1.35),
		Color(0.85, 0.18, 0.18), Vector3.ZERO, Color(0.9, 0.1, 0.1), 1.4,
		"gate_right", "🔒 Правая гермодверь (Порт 5432 SQL) [E]"
	)
	_add_box(
		self, Vector3(0.15, 0.28, 0.28), Vector3(5.28, 1.15, -1.35),
		Color(0.95, 0.72, 0.15), Vector3.ZERO, Color(0.9, 0.65, 0.1), 1.2,
		"ping_right", "🔦 Подсветить правый шлюз [D]"
	)

func _build_desk_and_props() -> void:
	# Стол дежурного (Z = -1.65)
	_add_box(self, Vector3(3.4, 0.12, 1.35), Vector3(0.0, 0.92, -1.65), Color(0.18, 0.21, 0.26))
	_add_box(self, Vector3(0.16, 0.92, 1.2), Vector3(-1.55, 0.46, -1.65), Color(0.12, 0.14, 0.18))
	_add_box(self, Vector3(0.16, 0.92, 1.2), Vector3(1.55, 0.46, -1.65), Color(0.12, 0.14, 0.18))

	# ЭЛТ-Монитор IDE по центру стола
	_add_box(self, Vector3(0.96, 0.74, 0.65), Vector3(0.0, 1.38, -1.72), Color(0.24, 0.27, 0.32))
	_add_box(
		self, Vector3(0.82, 0.58, 0.05), Vector3(0.0, 1.39, -1.39),
		Color(0.06, 0.38, 0.42), Vector3.ZERO, Color(0.08, 0.65, 0.72), 1.6,
		"write_patch", "⌨️ Пилить хотфикс на проде [SPACE]"
	)

	# Механическая клавиатура
	_add_box(
		self, Vector3(0.76, 0.06, 0.28), Vector3(0.0, 1.0, -1.18),
		Color(0.32, 0.36, 0.42), Vector3(6.0, 0.0, 0.0), Color.BLACK, 0.0,
		"write_patch", "⌨️ Пилить хотфикс [SPACE]"
	)

	# Блок бинарных тумблеров ядра SW1-4 слева от монитора
	_add_box(self, Vector3(0.68, 0.18, 0.36), Vector3(-0.92, 1.04, -1.45), Color(0.14, 0.17, 0.22))
	dip_knobs.clear()
	for i in range(4):
		var kx := -1.14 + float(i) * 0.15
		var knob := _add_box(
			self, Vector3(0.08, 0.14, 0.08), Vector3(kx, 1.15, -1.45),
			Color(0.15, 0.85, 0.45), Vector3.ZERO, Color(0.1, 0.8, 0.4), 1.2,
			"dip_%d" % i, "🔧 Переключить тумблер SW%d [%d]" % [i + 1, i + 1]
		)
		dip_knobs.append(knob)

	# 3D-Биопринтер морковок справа на столе
	_add_box(
		self, Vector3(0.55, 0.62, 0.52), Vector3(1.12, 1.28, -1.62),
		Color(0.16, 0.22, 0.29), Vector3.ZERO, Color(0.08, 0.45, 0.55), 0.5,
		"print_carrot", "🖨️ Напечатать морковку для Троянского Коня"
	)
	carrot_hologram = Node3D.new()
	carrot_hologram.position = Vector3(1.12, 1.28, -1.48)
	add_child(carrot_hologram)
	_add_box(carrot_hologram, Vector3(0.12, 0.28, 0.12), Vector3.ZERO, Color(0.98, 0.48, 0.12), Vector3.ZERO, Color(0.98, 0.45, 0.1), 2.2)

	# Жёлтая резиновая уточка (слева спереди на столе)
	_add_box(
		self, Vector3(0.18, 0.16, 0.22), Vector3(-0.62, 1.04, -1.15),
		Color(0.96, 0.82, 0.12), Vector3(0.0, 22.0, 0.0), Color(0.4, 0.3, 0.0), 0.4,
		"rubber_duck", "🦆 Крякнуть резиновой уточкой (-3°C пукана)"
	)

	# Кружка кофе (справа спереди на столе)
	_add_box(
		self, Vector3(0.16, 0.22, 0.16), Vector3(0.62, 1.06, -1.16),
		Color(0.16, 0.68, 0.82), Vector3.ZERO, Color(0.05, 0.25, 0.35), 0.4,
		"coffee_mug", "☕ Сделать глоток кофе (+4% энергии ИБП)"
	)

	# Настольный вентилятор
	fan_blades = Node3D.new()
	fan_blades.position = Vector3(-1.35, 1.32, -1.75)
	add_child(fan_blades)
	_add_box(fan_blades, Vector3(0.38, 0.06, 0.04), Vector3.ZERO, Color(0.45, 0.52, 0.6))
	_add_box(fan_blades, Vector3(0.06, 0.38, 0.04), Vector3.ZERO, Color(0.45, 0.52, 0.6))

	# Газовая труба и красный вентиль (справа от стола)
	_add_box(self, Vector3(0.18, 3.8, 0.18), Vector3(2.35, 1.9, -3.8), Color(0.35, 0.38, 0.42))
	gas_valve_wheel = Node3D.new()
	gas_valve_wheel.position = Vector3(2.35, 1.55, -3.62)
	add_child(gas_valve_wheel)
	_add_box(
		gas_valve_wheel, Vector3(0.52, 0.52, 0.10), Vector3.ZERO,
		Color(0.88, 0.16, 0.16), Vector3.ZERO, Color(0.7, 0.1, 0.1), 0.9,
		"gas_valve", "🔧 Зажми ЛКМ и крути вентиль газа по кругу!"
	)

func _build_back_window_and_cabinet() -> void:
	var wall_col := Color(0.11, 0.14, 0.19)
	# Задняя стена (Z = 4.5) с панорамным окном
	_add_box(self, Vector3(4.2, 4.0, 0.4), Vector3(-4.6, 2.0, 4.5), wall_col)
	_add_box(self, Vector3(4.2, 4.0, 0.4), Vector3(4.6, 2.0, 4.5), wall_col)
	_add_box(self, Vector3(5.2, 1.1, 0.4), Vector3(0.0, 0.55, 4.5), wall_col)
	_add_box(self, Vector3(5.2, 0.9, 0.4), Vector3(0.0, 3.55, 4.5), wall_col)

	# Задник неба за окном (Z = 6.2)
	var sky_plane := _add_box(self, Vector3(9.5, 5.5, 0.1), Vector3(0.0, 2.2, 6.2), Color(0.03, 0.05, 0.12), Vector3.ZERO, Color(0.04, 0.07, 0.16), 1.0)
	sky_backdrop_mat = sky_plane.material_override as ShaderMaterial

	# Силовой электрощиток с главным рубильником (справа от заднего окна)
	_add_box(self, Vector3(0.75, 0.95, 0.22), Vector3(-3.3, 1.75, 4.25), Color(0.22, 0.26, 0.32))
	breaker_lever = Node3D.new()
	breaker_lever.position = Vector3(-3.3, 1.75, 4.12)
	add_child(breaker_lever)
	_add_box(
		breaker_lever, Vector3(0.24, 0.42, 0.16), Vector3.ZERO,
		Color(0.92, 0.22, 0.18), Vector3.ZERO, Color(0.9, 0.2, 0.1), 1.5,
		"reset_breaker", "⚡ Щёлкни рубильник электрощитка (Сброс Блэкаута)"
	)

	# Шкафчик дежурного с секретом «AZAMAT SASI» (слева сзади при повороте на 180°)
	_add_box(self, Vector3(1.1, 2.1, 0.55), Vector3(3.5, 1.25, 4.05), Color(0.18, 0.22, 0.28))
	# Внутренняя табличка с пасхалкой
	_add_box(self, Vector3(0.78, 0.48, 0.04), Vector3(3.5, 1.55, 3.82), Color(0.95, 0.88, 0.25), Vector3.ZERO, Color(0.95, 0.82, 0.2), 1.8)
	var label3d := Label3D.new()
	label3d.text = "AZAMAT SASI\n( ͡° ͜ʖ ͡°)"
	label3d.font_size = 38
	label3d.modulate = Color(0.05, 0.05, 0.05)
	label3d.position = Vector3(3.5, 1.55, 3.78)
	label3d.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	add_child(label3d)

	cabinet_door_pivot = Node3D.new()
	cabinet_door_pivot.position = Vector3(4.02, 1.25, 3.76)
	add_child(cabinet_door_pivot)
	_add_box(
		cabinet_door_pivot, Vector3(1.04, 2.02, 0.08), Vector3(-0.52, 0.0, 0.0),
		Color(0.26, 0.31, 0.38), Vector3.ZERO, Color.BLACK, 0.0,
		"toggle_cabinet", "🚪 Открыть/закрыть шкафчик дежурного"
	)

func _build_monsters() -> void:
	# 1. Исказитель (высокий непропорциональный силуэт с яркими глазами)
	monster_distortion = Node3D.new()
	add_child(monster_distortion)
	_add_box(monster_distortion, Vector3(0.75, 2.65, 0.45), Vector3(0.0, 1.32, 0.0), Color(0.03, 0.03, 0.05))
	_add_box(monster_distortion, Vector3(0.42, 0.52, 0.42), Vector3(0.0, 2.85, 0.0), Color(0.04, 0.04, 0.06))
	_add_box(monster_distortion, Vector3(0.10, 0.08, 0.06), Vector3(-0.11, 2.88, 0.22), Color.WHITE, Vector3.ZERO, Color(1.0, 0.2, 0.2), 5.0)
	_add_box(monster_distortion, Vector3(0.10, 0.08, 0.06), Vector3(0.11, 2.88, 0.22), Color.WHITE, Vector3.ZERO, Color(1.0, 0.2, 0.2), 5.0)
	monster_distortion.visible = false

	# 2. Багогрыз-головастик на столе
	monster_tadpole = Node3D.new()
	monster_tadpole.position = Vector3(0.0, 1.08, -1.25)
	add_child(monster_tadpole)
	_add_box(
		monster_tadpole, Vector3(0.34, 0.22, 0.42), Vector3.ZERO,
		Color(0.18, 0.55, 0.22), Vector3.ZERO, Color(0.2, 0.8, 0.3), 1.4,
		"hit_tadpole", "💥 РАЗДАВИТЬ БАГОГРЫЗА КЛИКОМ!"
	)
	monster_tadpole.visible = false

	# 3. Троянский Конь в T-Pose
	monster_trojan = Node3D.new()
	monster_trojan.position = Vector3(0.0, 0.0, -14.0)
	add_child(monster_trojan)
	var wood_col := Color(0.58, 0.38, 0.18)
	_add_box(monster_trojan, Vector3(0.95, 1.35, 1.65), Vector3(0.0, 1.35, 0.0), wood_col)
	# Руки/передние ноги в жёстком T-Pose
	_add_box(monster_trojan, Vector3(2.5, 0.28, 0.32), Vector3(0.0, 1.75, 0.2), wood_col)
	# Шея и голова коня
	_add_box(monster_trojan, Vector3(0.48, 0.95, 0.55), Vector3(0.0, 2.25, 0.55), wood_col, Vector3(-20.0, 0.0, 0.0))
	_add_box(monster_trojan, Vector3(0.44, 0.42, 0.85), Vector3(0.0, 2.62, 0.85), wood_col)
	_add_box(monster_trojan, Vector3(0.10, 0.10, 0.10), Vector3(-0.16, 2.68, 1.26), Color(1.0, 0.3, 0.1), Vector3.ZERO, Color(1.0, 0.2, 0.1), 4.0)
	_add_box(monster_trojan, Vector3(0.10, 0.10, 0.10), Vector3(0.16, 2.68, 1.26), Color(1.0, 0.3, 0.1), Vector3.ZERO, Color(1.0, 0.2, 0.1), 4.0)

	# 4. Бордовый Душегуб (для скримера и камер)
	monster_burgundy = Node3D.new()
	monster_burgundy.position = Vector3(0.0, 3.6, -2.5)
	add_child(monster_burgundy)
	_add_box(monster_burgundy, Vector3(0.68, 0.55, 0.95), Vector3.ZERO, Color(0.65, 0.06, 0.16), Vector3.ZERO, Color(0.8, 0.05, 0.15), 1.5)
	monster_burgundy.visible = false

func _setup_lights() -> void:
	office_omni = OmniLight3D.new()
	office_omni.position = Vector3(0.0, 3.45, 0.0)
	office_omni.light_color = Color(0.65, 0.78, 0.95)
	office_omni.light_energy = 1.35
	office_omni.omni_range = 11.0
	add_child(office_omni)

	monitor_glow = OmniLight3D.new()
	monitor_glow.position = Vector3(0.0, 1.45, -1.15)
	monitor_glow.light_color = Color(0.15, 0.88, 0.92)
	monitor_glow.light_energy = 0.85
	monitor_glow.omni_range = 3.8
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

func _apply_daytime_visuals(is_day: bool) -> void:
	if world_env and world_env.environment:
		var env := world_env.environment
		if is_day:
			env.ambient_light_color = Color(0.58, 0.66, 0.78)
			env.ambient_light_energy = 0.95
			env.fog_light_color = Color(0.35, 0.48, 0.65)
			env.fog_density = 0.015
		else:
			env.ambient_light_color = Color(0.10, 0.13, 0.18)
			env.ambient_light_energy = 0.38
			env.fog_light_color = Color(0.02, 0.025, 0.04)
			env.fog_density = 0.048

	if window_sun_light:
		window_sun_light.light_energy = 1.35 if is_day else 0.12
		window_sun_light.light_color = Color(1.0, 0.94, 0.80) if is_day else Color(0.25, 0.38, 0.72)

	if sky_backdrop_mat:
		var sky_col := Color(0.38, 0.68, 0.96) if is_day else Color(0.02, 0.04, 0.10)
		sky_backdrop_mat.set_shader_parameter("albedo_color", sky_col)
		sky_backdrop_mat.set_shader_parameter("emission_color", sky_col)
		sky_backdrop_mat.set_shader_parameter("emission_energy", 1.6 if is_day else 0.7)

func _on_shift_started(_lvl: int) -> void:
	jumpscare_active = false
	_apply_daytime_visuals(false)

func _on_lobby_entered() -> void:
	jumpscare_active = false
	_apply_daytime_visuals(true)

func _on_jumpscare(_m_type: String, _title: String, _desc: String) -> void:
	jumpscare_active = true
	jumpscare_timer = 1.2

func _unhandled_input(event: InputEvent) -> void:
	if GameState.in_lobby and not GameState.lobby_inspect_mode:
		return
	if GameState.cctv_open or GameState.puzzle_modal_open:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var hit := _raycast_from_mouse(mb.position)
				if not hit.is_empty():
					var act: String = hit.get("action", "")
					if act == "gas_valve":
						is_dragging_valve = true
						return
					_execute_interact_action(act)
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
				gas_valve_wheel.rotate_z(delta_ang)
		elif is_dragging_look:
			var dyaw: float = -mm.relative.x * 0.0055
			var dpitch: float = clampf(target_pitch - mm.relative.y * 0.0045, -0.68, 0.72) - target_pitch
			target_yaw = fposmod(target_yaw + dyaw, TAU)
			target_pitch = clampf(target_pitch + dpitch, -0.68, 0.72)
			camera_rotated.emit(dyaw, dpitch)
		else:
			var hit := _raycast_from_mouse(mm.position)
			hover_changed.emit(hit.get("hint", ""))

func _raycast_from_mouse(screen_pos: Vector2) -> Dictionary:
	if camera == null:
		return {}
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 12.0
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var res := space.intersect_ray(query)
	if res.is_empty():
		return {}
	var col_obj: Object = res.get("collider")
	if col_obj and col_obj.has_meta("interact_action"):
		return {
			"action": String(col_obj.get_meta("interact_action")),
			"hint": String(col_obj.get_meta("interact_hint"))
		}
	return {}

func _execute_interact_action(act: String) -> void:
	match act:
		"gate_left": GameState.toggle_switch("gateLeft")
		"gate_right": GameState.toggle_switch("gateRight")
		"ping_left": GameState.ping_port("left")
		"ping_right": GameState.ping_port("right")
		"write_patch": GameState.write_patch_chunk()
		"print_carrot": GameState.start_printing_carrot()
		"purge_steam": GameState.purge_vents_with_steam()
		"reset_breaker": GameState.reset_breaker()
		"toggle_cabinet": GameState.toggle_cabinet()
		"rubber_duck": GameState.click_rubber_duck()
		"coffee_mug": GameState.drink_coffee()
		"hit_tadpole": GameState.hit_tadpole()
		"dip_0": GameState.toggle_dip(0)
		"dip_1": GameState.toggle_dip(1)
		"dip_2": GameState.toggle_dip(2)
		"dip_3": GameState.toggle_dip(3)

func _process(delta: float) -> void:
	# 1. Плавное вращение камеры или режим CCTV
	if GameState.cctv_open and cam_positions.has(GameState.current_cam):
		var c_info: Dictionary = cam_positions[GameState.current_cam]
		camera.position = c_info["pos"]
		camera.look_at(c_info["look"], Vector3.UP)
	else:
		yaw = lerp_angle(yaw, target_yaw, min(1.0, delta * 14.0))
		pitch = lerpf(pitch, target_pitch, min(1.0, delta * 14.0))
		camera.position = Vector3(0.0, 1.62, 0.25)
		if jumpscare_active:
			jumpscare_timer = max(0.0, jumpscare_timer - delta)
			camera.position += Vector3(randf_range(-0.08, 0.08), randf_range(-0.08, 0.08), 0.0)
		camera.rotation = Vector3(pitch, yaw, 0.0)
		_update_looked_sector()

	# 2. Анимация гермодверей и шкафчика
	if left_door_mesh:
		var ly := 1.45 if GameState.gate_left else 4.2
		left_door_mesh.position.y = lerpf(left_door_mesh.position.y, ly, min(1.0, delta * 10.0))
	if right_door_mesh:
		var ry := 1.45 if GameState.gate_right else 4.2
		right_door_mesh.position.y = lerpf(right_door_mesh.position.y, ry, min(1.0, delta * 10.0))
	if center_door_mesh:
		var cy := 1.45 if GameState.gate_center else 4.25
		center_door_mesh.position.y = lerpf(center_door_mesh.position.y, cy, min(1.0, delta * 10.0))

	if cabinet_door_pivot:
		var target_cab_rot := -115.0 if GameState.cabinet_open else 0.0
		cabinet_door_pivot.rotation_degrees.y = lerpf(cabinet_door_pivot.rotation_degrees.y, target_cab_rot, min(1.0, delta * 8.0))

	# 3. Вентилятор и голограмма морковки
	if fan_blades and not GameState.blackout and GameState.power > 0.0:
		fan_blades.rotate_z(delta * 12.0)
	if carrot_hologram:
		carrot_hologram.visible = GameState.printer_working or GameState.carrots_count > 0
		carrot_hologram.rotate_y(delta * 3.0)

	# 4. Освещение и блэкаут
	if office_omni:
		office_omni.light_energy = 0.05 if (GameState.blackout or GameState.power <= 0.0) else 1.35
	if monitor_glow:
		monitor_glow.light_energy = 0.0 if (GameState.blackout or GameState.power <= 0.0) else 0.85
	if left_ping_light:
		left_ping_light.light_energy = 4.5 if GameState.ping_left_timer > 0.0 else 0.0
	if right_ping_light:
		right_ping_light.light_energy = 4.5 if GameState.ping_right_timer > 0.0 else 0.0

	# 5. Синхронизация 4 монстров в 3D
	_sync_monsters_3d(delta)

func _update_looked_sector() -> void:
	var deg := fposmod(rad_to_deg(yaw), 360.0)
	if pitch > 0.35:
		GameState.player_looking_at_sector = "CEILING_VENT"
	elif deg < 45.0 or deg >= 315.0:
		GameState.player_looking_at_sector = "HALL_FRONT" if abs(deg) < 20.0 else "DESK"
	elif deg >= 45.0 and deg < 135.0:
		GameState.player_looking_at_sector = "DOOR_LEFT"
	elif deg >= 135.0 and deg < 225.0:
		GameState.player_looking_at_sector = "WINDOW_BACK"
	else:
		GameState.player_looking_at_sector = "DOOR_RIGHT"

func _sync_monsters_3d(delta: float) -> void:
	# 1. Исказитель
	if monster_distortion:
		monster_distortion.visible = GameState.distortion_active
		if GameState.distortion_active:
			match GameState.distortion_pos:
				"DOOR_LEFT":
					monster_distortion.position = Vector3(-6.4, 0.0, 0.0)
					monster_distortion.rotation_degrees.y = 90.0
				"DOOR_RIGHT":
					monster_distortion.position = Vector3(6.4, 0.0, 0.0)
					monster_distortion.rotation_degrees.y = -90.0
				"WINDOW_BACK":
					monster_distortion.position = Vector3(0.0, 0.0, 5.2)
					monster_distortion.rotation_degrees.y = 180.0
				"HALL_FRONT":
					monster_distortion.position = Vector3(0.0, 0.0, -5.8)
					monster_distortion.rotation_degrees.y = 0.0

	# 2. Багогрыз-головастик
	if monster_tadpole:
		monster_tadpole.visible = GameState.tadpole_active
		if GameState.tadpole_active:
			monster_tadpole.position.x = GameState.tadpole_x + sin(Time.get_ticks_msec() * 0.01) * 0.12

	# 3. Троянский конь (T-Pose)
	if monster_trojan:
		monster_trojan.visible = not GameState.in_lobby
		var z_pos := lerpf(-2.4, -20.0, clampf(GameState.trojan_distance / 100.0, 0.0, 1.0))
		monster_trojan.position = Vector3(0.0, 0.0, z_pos)

	# 4. Бордовый Душегуб и хвост в потолке
	if burgundy_tail_node:
		burgundy_tail_node.visible = (GameState.burgundy_stage == 2)
		if burgundy_tail_node.visible:
			burgundy_tail_node.rotation.z = sin(Time.get_ticks_msec() * 0.015) * 0.35
	if monster_burgundy:
		monster_burgundy.visible = (GameState.burgundy_stage > 0 and GameState.cctv_open and GameState.current_cam == "CAM06")

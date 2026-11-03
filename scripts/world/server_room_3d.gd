extends Node3D
## 3D-сцена загородной серверной (Godot 4 + PS1 Textures + Deep Forest Exterior)
## Включает:
## - Захват курсора (Input.MOUSE_MODE_CAPTURED) и полноценный FPS-обзор мышью
## - Взаимодействие по клавише [E] (по прицелу в центре экрана)
## - Настоящие тайловые PS1-текстуры на всех поверхностях
## - Глубокий многоярусный 3D-лес за панорамным окном с радиовышкой и забором (в духе Voices of the Void)

signal hover_changed(hint_text: String)
signal camera_rotated(delta_yaw: float, delta_pitch: float)
signal walking_updated(is_walking: bool, delta: float)

const PSX_SHADER := preload("res://shaders/psx_lit.gdshader")
const INTERACT_RANGE := 3.55

var camera: Camera3D
var world_env: WorldEnvironment

# Текстурный кэш
var textures: Dictionary = {}

# FPS-обзор и передвижение
var yaw: float = 0.0
var pitch: float = 0.0
var target_yaw: float = 0.0
var target_pitch: float = 0.0
var _step_timer: float = 0.0
var _walk_bob_phase: float = 0.0
var _current_aim_hit: Dictionary = {}

# 3D-узлы комнаты
var chair_group: Node3D
var left_door_mesh: MeshInstance3D
var right_door_mesh: MeshInstance3D
var fan_blades: Node3D
var gas_valve_wheel: Node3D
var carrot_hologram: Node3D
var breaker_lever: Node3D
var cabinet_door_pivot: Node3D
var burgundy_tail_node: Node3D
var vending_machine_group: Node3D
var radio_tower_beacon: OmniLight3D
var dip_knobs: Array[MeshInstance3D] = []

# Живые 3D-надписи на мониторах
var main_term_label3d: Label3D
var cctv_term_label3d: Label3D
var sky_backdrop_mat: ShaderMaterial

# Освещение
var office_omni: OmniLight3D
var monitor_glow: OmniLight3D
var left_ping_light: SpotLight3D
var right_ping_light: SpotLight3D
var window_sun_light: DirectionalLight3D
var breaker_emergency_light: OmniLight3D
var exterior_yard_light: SpotLight3D

# 4 Монстра в 3D
var monster_distortion: Node3D
var monster_tadpole: Node3D
var monster_trojan: Node3D
var monster_burgundy: Node3D

# Скример
var jumpscare_active: bool = false
var jumpscare_timer: float = 0.0

var cam_positions := {
	"CAM01": {"pos": Vector3(0.0, 3.4, 5.2), "look": Vector3(0.0, 1.8, 14.0)},
	"CAM02": {"pos": Vector3(-6.8, 3.2, -3.4), "look": Vector3(-5.8, 1.4, 0.0)},
	"CAM03": {"pos": Vector3(0.0, 3.5, -6.5), "look": Vector3(0.0, 1.3, -15.0)},
	"CAM04": {"pos": Vector3(6.8, 3.2, -3.4), "look": Vector3(5.8, 1.4, 0.0)},
	"CAM05": {"pos": Vector3(0.0, 3.1, -15.0), "look": Vector3(0.0, 1.4, -21.0)},
	"CAM06": {"pos": Vector3(0.0, 3.5, -2.4), "look": Vector3(0.0, 3.8, -0.6)}
}

func _ready() -> void:
	_load_all_textures()
	_setup_environment_and_camera()
	_build_room_geometry()
	_build_desk_chair_and_terminals()
	_build_window_breaker_and_cabinet()
	_build_deep_forest_exterior()
	_build_lobby_vending_and_secrets()
	_build_monsters()
	_setup_lights()

	GameState.shift_started.connect(_on_shift_started)
	GameState.lobby_entered.connect(_on_lobby_entered)
	GameState.jumpscare_triggered.connect(_on_jumpscare)
	_apply_daytime_visuals(GameState.in_lobby)

func _load_all_textures() -> void:
	var names := [
		"floor_steel", "wall_concrete", "ceiling_tiles", "door_hazard",
		"server_rack", "wood_desk", "rust_metal", "forest_ground",
		"pine_bark", "pine_needles", "forest_panorama"
	]
	for n in names:
		var path := ProjectSettings.globalize_path("res://assets/textures/%s.png" % n)
		var img := Image.new()
		if FileAccess.file_exists(path) and img.load(path) == OK:
			textures[n] = ImageTexture.create_from_image(img)

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
	env.fog_density = 0.038
	world_env.environment = env
	add_child(world_env)

	camera = Camera3D.new()
	camera.fov = 72.0
	camera.position = Vector3(0.0, 1.74, 1.45)
	add_child(camera)

func _make_psx_mat(col: Color, tex_name: String = "", uv_scale: Vector2 = Vector2.ONE, emit_col: Color = Color.BLACK, emit_energy: float = 0.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = PSX_SHADER
	mat.set_shader_parameter("albedo_color", col)
	mat.set_shader_parameter("uv_scale", uv_scale)
	mat.set_shader_parameter("emission_color", emit_col)
	mat.set_shader_parameter("emission_energy", emit_energy)
	if tex_name != "" and textures.has(tex_name):
		mat.set_shader_parameter("use_texture", true)
		mat.set_shader_parameter("albedo_tex", textures[tex_name])
	else:
		mat.set_shader_parameter("use_texture", false)
	return mat

func _add_box(parent: Node3D, size: Vector3, pos: Vector3, col: Color, rot_deg: Vector3 = Vector3.ZERO, emit_col: Color = Color.BLACK, emit_e: float = 0.0, action: String = "", hint: String = "", tex_name: String = "", uv_sc: Vector2 = Vector2.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = _make_psx_mat(col, tex_name, uv_sc, emit_col, emit_e)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)

	if action != "":
		var sb := StaticBody3D.new()
		sb.set_meta("interact_action", action)
		sb.set_meta("interact_hint", hint)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size * 1.2
		cs.shape = shape
		sb.add_child(cs)
		mi.add_child(sb)

	return mi

func _add_cylinder(parent: Node3D, top_r: float, bot_r: float, height: float, pos: Vector3, col: Color, rot_deg: Vector3 = Vector3.ZERO, tex_name: String = "", uv_sc: Vector2 = Vector2.ONE, radial_segs: int = 7) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r
	cyl.height = height
	cyl.radial_segments = radial_segs
	cyl.rings = 1
	mi.mesh = cyl
	mi.material_override = _make_psx_mat(col, tex_name, uv_sc)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

func _build_room_geometry() -> void:
	# Текстурированный рифлёный стальной пол и индустриальный потолок
	_add_box(self, Vector3(11.0, 0.2, 10.0), Vector3(0.0, -0.1, 0.0), Color(0.85, 0.88, 0.92), Vector3.ZERO, Color.BLACK, 0.0, "", "", "floor_steel", Vector2(6.0, 6.0))
	_add_box(self, Vector3(11.0, 0.2, 10.0), Vector3(0.0, 4.1, 0.0), Color(0.75, 0.80, 0.85), Vector3.ZERO, Color.BLACK, 0.0, "", "", "ceiling_tiles", Vector2(5.0, 5.0))

	# Потолочные двутавровые стальные балки (добавляют глубину и индустриальный объём)
	for bz in [-3.2, -1.2, 1.2, 3.2]:
		_add_box(self, Vector3(10.4, 0.24, 0.28), Vector3(0.0, 3.88, bz), Color(0.55, 0.58, 0.64), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal", Vector2(4.0, 1.0))

	# Потолочная вентиляционная шахта над креслом
	_add_box(self, Vector3(1.6, 0.22, 1.6), Vector3(0.0, 3.92, -0.5), Color(0.65, 0.70, 0.75), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")
	_add_box(
		self, Vector3(1.35, 0.06, 1.35), Vector3(0.0, 3.82, -0.5),
		Color(0.35, 0.42, 0.50), Vector3.ZERO, Color.BLACK, 0.0,
		"inspect_vent", "[E] Вентиляционная шахта (продувается с терминала безопасности)",
		"floor_steel", Vector2(2.0, 2.0)
	)

	burgundy_tail_node = Node3D.new()
	burgundy_tail_node.position = Vector3(0.0, 3.72, -0.5)
	add_child(burgundy_tail_node)
	_add_cylinder(burgundy_tail_node, 0.02, 0.14, 0.85, Vector3(0.0, -0.32, 0.0), Color(0.78, 0.08, 0.18), Vector3(16.0, 0.0, 14.0))
	burgundy_tail_node.visible = false

	# Передняя бетонная стена (Z = -4.5) с центральным тоннелем Троянского коня
	var wall_tint := Color(0.88, 0.90, 0.94)
	_add_box(self, Vector3(4.6, 4.0, 0.4), Vector3(-4.1, 2.0, -4.5), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(2.0, 1.0))
	_add_box(self, Vector3(4.6, 4.0, 0.4), Vector3(4.1, 2.0, -4.5), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(2.0, 1.0))
	_add_box(self, Vector3(3.6, 1.1, 0.4), Vector3(0.0, 3.45, -4.5), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(1.5, 0.4))

	# Бункерный лоток сброса морковки в тоннель
	_add_box(
		self, Vector3(1.5, 0.78, 0.48), Vector3(0.0, 0.39, -4.22),
		Color(0.85, 0.85, 0.85), Vector3.ZERO, Color(0.45, 0.25, 0.05), 0.4,
		"throw_carrot", "[E] Бросить морковку в тоннель Троянскому Коню",
		"door_hazard", Vector2(1.0, 1.0)
	)

	# Центральный тоннель ЦОД (до Z = -22)
	_add_box(self, Vector3(4.0, 0.2, 18.0), Vector3(0.0, -0.1, -13.5), Color(0.55, 0.60, 0.68), Vector3.ZERO, Color.BLACK, 0.0, "", "", "floor_steel", Vector2(2.0, 8.0))
	_add_box(self, Vector3(0.3, 4.0, 18.0), Vector3(-1.95, 2.0, -13.5), Color(0.65, 0.70, 0.76), Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(6.0, 1.0))
	_add_box(self, Vector3(0.3, 4.0, 18.0), Vector3(1.95, 2.0, -13.5), Color(0.65, 0.70, 0.76), Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(6.0, 1.0))

	# Левая стена (X = -5.2) и гермодверь Порт 22 SSH
	_add_box(self, Vector3(0.4, 4.0, 4.2), Vector3(-5.2, 2.0, -2.5), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(2.0, 1.0))
	_add_box(self, Vector3(0.4, 4.0, 4.2), Vector3(-5.2, 2.0, 2.5), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(2.0, 1.0))
	_add_box(self, Vector3(0.4, 1.2, 2.2), Vector3(-5.2, 3.4, 0.0), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(1.0, 0.4))
	left_door_mesh = _add_box(self, Vector3(0.20, 2.85, 2.15), Vector3(-5.08, 4.2, 0.0), Color.WHITE, Vector3.ZERO, Color.BLACK, 0.0, "", "", "door_hazard", Vector2(1.0, 1.0))

	_add_box(
		self, Vector3(0.16, 0.28, 0.28), Vector3(-4.96, 1.45, -1.25),
		Color(0.95, 0.72, 0.15), Vector3.ZERO, Color(0.9, 0.65, 0.1), 1.4,
		"ping_left", "[E] Посветить прожектором в левый шлюз (Порт 22)"
	)

	# Правая стена (X = 5.2) и гермодверь Порт 5432 SQL
	_add_box(self, Vector3(0.4, 4.0, 4.2), Vector3(5.2, 2.0, -2.5), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(2.0, 1.0))
	_add_box(self, Vector3(0.4, 4.0, 4.2), Vector3(5.2, 2.0, 2.5), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(2.0, 1.0))
	_add_box(self, Vector3(0.4, 1.2, 2.2), Vector3(5.2, 3.4, 0.0), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(1.0, 0.4))
	right_door_mesh = _add_box(self, Vector3(0.20, 2.85, 2.15), Vector3(5.08, 4.2, 0.0), Color.WHITE, Vector3.ZERO, Color.BLACK, 0.0, "", "", "door_hazard", Vector2(1.0, 1.0))

	_add_box(
		self, Vector3(0.16, 0.28, 0.28), Vector3(4.96, 1.45, -1.25),
		Color(0.95, 0.72, 0.15), Vector3.ZERO, Color(0.9, 0.65, 0.1), 1.4,
		"ping_right", "[E] Посветить прожектором в правый шлюз (Порт 5432)"
	)

	# Серверные стойки в углах с настоящей текстурой блейд-серверов и светодиодов + Стикер-улика #2
	_add_box(self, Vector3(1.05, 2.65, 0.92), Vector3(4.15, 1.32, -3.55), Color.WHITE, Vector3(0, -18, 0), Color(0.1, 0.35, 0.25), 0.35, "", "", "server_rack")
	_add_box(self, Vector3(1.05, 2.65, 0.92), Vector3(2.95, 1.32, -3.75), Color.WHITE, Vector3.ZERO, Color(0.1, 0.35, 0.25), 0.35, "", "", "server_rack")
	_add_box(
		self, Vector3(0.28, 0.28, 0.05), Vector3(2.95, 1.62, -3.26),
		Color(0.98, 0.88, 0.22), Vector3.ZERO, Color(0.95, 0.82, 0.15), 1.5,
		"clue_2", "[E] Прочитать жёлтый стикер на серверной стойке (Улика Сейфа #2)"
	)

func _build_desk_chair_and_terminals() -> void:
	# Текстурированный рабочий стол дежурного (Z = -1.65)
	_add_box(self, Vector3(3.55, 0.12, 1.38), Vector3(0.0, 0.92, -1.65), Color.WHITE, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wood_desk", Vector2(2.0, 1.0))
	_add_box(self, Vector3(0.18, 0.92, 1.25), Vector3(-1.62, 0.46, -1.65), Color(0.7, 0.7, 0.75), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")
	_add_box(self, Vector3(0.18, 0.92, 1.25), Vector3(1.62, 0.46, -1.65), Color(0.7, 0.7, 0.75), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")

	# Детализированное офисное кресло на крестовине (Z = -0.35)
	chair_group = Node3D.new()
	chair_group.position = Vector3(0.0, 0.0, -0.35)
	add_child(chair_group)
	_add_box(
		chair_group, Vector3(0.70, 0.10, 0.70), Vector3(0.0, 0.54, 0.0),
		Color(0.32, 0.36, 0.44), Vector3.ZERO, Color.BLACK, 0.0,
		"sit_chair", "[E] Сесть в кресло дежурного (Занять пост управления)", "rust_metal"
	)
	_add_box(
		chair_group, Vector3(0.68, 0.88, 0.12), Vector3(0.0, 1.02, 0.31),
		Color(0.28, 0.32, 0.40), Vector3.ZERO, Color.BLACK, 0.0,
		"sit_chair", "[E] Сесть в кресло дежурного (Занять пост управления)", "rust_metal"
	)
	# Подлокотники и газлифт кресла
	_add_box(chair_group, Vector3(0.08, 0.28, 0.52), Vector3(-0.36, 0.72, 0.04), Color(0.2, 0.22, 0.26))
	_add_box(chair_group, Vector3(0.08, 0.28, 0.52), Vector3(0.36, 0.72, 0.04), Color(0.2, 0.22, 0.26))
	_add_cylinder(chair_group, 0.06, 0.06, 0.52, Vector3(0.0, 0.26, 0.0), Color(0.2, 0.22, 0.25))
	_add_box(chair_group, Vector3(0.65, 0.05, 0.10), Vector3(0.0, 0.04, 0.0), Color(0.18, 0.2, 0.22))
	_add_box(chair_group, Vector3(0.10, 0.05, 0.65), Vector3(0.0, 0.04, 0.0), Color(0.18, 0.2, 0.22))

	# 1. ЛЕВЫЙ / ЦЕНТРАЛЬНЫЙ ТЕРМИНАЛ (Головоломки на монету / Выбор смены)
	_add_box(self, Vector3(0.88, 0.68, 0.55), Vector3(-0.38, 1.34, -1.68), Color(0.75, 0.78, 0.82), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")
	_add_box(
		self, Vector3(0.76, 0.54, 0.05), Vector3(-0.38, 1.35, -1.39),
		Color(0.05, 0.38, 0.44), Vector3.ZERO, Color(0.08, 0.68, 0.75), 1.8,
		"open_main_term", "[E] Главный Терминал (Головоломка на монету / Выбор смены)"
	)
	main_term_label3d = Label3D.new()
	main_term_label3d.text = "DEVOPS IDE\n[PRESS E]"
	main_term_label3d.font_size = 24
	main_term_label3d.modulate = Color(0.45, 0.98, 0.95)
	main_term_label3d.position = Vector3(-0.38, 1.36, -1.35)
	add_child(main_term_label3d)

	# 2. ПРАВЫЙ ТЕРМИНАЛ БЕЗОПАСНОСТИ (Камеры CCTV, Двери, Продувка вентиляции)
	_add_box(self, Vector3(0.82, 0.64, 0.52), Vector3(0.58, 1.32, -1.64), Color(0.68, 0.72, 0.78), Vector3(0.0, -14.0, 0.0), Color.BLACK, 0.0, "", "", "rust_metal")
	_add_box(
		self, Vector3(0.70, 0.50, 0.05), Vector3(0.54, 1.33, -1.37),
		Color(0.06, 0.32, 0.22), Vector3(0.0, -14.0, 0.0), Color(0.10, 0.65, 0.42), 1.8,
		"open_cctv_term", "[E] Терминал Безопасности (Камеры CCTV, Блокировка Дверей и Вентиляции)"
	)
	cctv_term_label3d = Label3D.new()
	cctv_term_label3d.text = "CCTV & DOORS\nRADAR ONLINE"
	cctv_term_label3d.font_size = 22
	cctv_term_label3d.modulate = Color(0.35, 0.98, 0.62)
	cctv_term_label3d.position = Vector3(0.53, 1.34, -1.33)
	cctv_term_label3d.rotation_degrees = Vector3(0.0, -14.0, 0.0)
	add_child(cctv_term_label3d)

	# Блок бинарных тумблеров ядра SW1-4 слева на столе
	_add_box(self, Vector3(0.66, 0.16, 0.34), Vector3(-1.22, 1.03, -1.48), Color(0.5, 0.55, 0.6), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")
	dip_knobs.clear()
	for i in range(4):
		var kx := -1.42 + float(i) * 0.135
		var knob := _add_box(
			self, Vector3(0.075, 0.14, 0.075), Vector3(kx, 1.14, -1.48),
			Color(0.15, 0.85, 0.45), Vector3.ZERO, Color(0.1, 0.8, 0.4), 1.3,
			"dip_%d" % i, "[E] Переключить тумблер ядра SW%d (или клавиша [%d])" % [i + 1, i + 1]
		)
		dip_knobs.append(knob)

	# 3D-Биопринтер морковок справа на столе
	_add_box(
		self, Vector3(0.48, 0.56, 0.48), Vector3(1.36, 1.25, -1.62),
		Color(0.65, 0.75, 0.85), Vector3.ZERO, Color(0.08, 0.45, 0.55), 0.5,
		"print_carrot", "[E] Запустить 3D-Биопринтер (Печать морковки для Коня)", "rust_metal"
	)
	carrot_hologram = Node3D.new()
	carrot_hologram.position = Vector3(1.36, 1.25, -1.42)
	add_child(carrot_hologram)
	_add_cylinder(carrot_hologram, 0.01, 0.08, 0.28, Vector3.ZERO, Color(0.98, 0.48, 0.12), Vector3(180, 0, 0))

	# Жёлтая резиновая уточка
	_add_box(
		self, Vector3(0.18, 0.16, 0.22), Vector3(-0.88, 1.04, -1.14),
		Color(0.96, 0.82, 0.12), Vector3(0.0, 22.0, 0.0), Color(0.4, 0.3, 0.0), 0.4,
		"rubber_duck", "[E] Жмякнуть резиновую уточку [КРЯ!]"
	)

	# Кружка кофе
	_add_box(
		self, Vector3(0.15, 0.21, 0.15), Vector3(0.95, 1.05, -1.16),
		Color(0.16, 0.68, 0.82), Vector3.ZERO, Color(0.05, 0.25, 0.35), 0.4,
		"coffee_mug", "[E] Хлебнуть кофе"
	)

	# Настольный вентилятор
	fan_blades = Node3D.new()
	fan_blades.position = Vector3(-1.52, 1.30, -1.78)
	add_child(fan_blades)
	_add_box(fan_blades, Vector3(0.36, 0.06, 0.04), Vector3.ZERO, Color(0.45, 0.52, 0.6))
	_add_box(fan_blades, Vector3(0.06, 0.36, 0.04), Vector3.ZERO, Color(0.45, 0.52, 0.6))

	# Цилиндрическая газовая магистраль и красный вентиль у правой стены (X = 4.65, Z = -2.8)
	_add_cylinder(self, 0.11, 0.11, 4.0, Vector3(4.72, 2.0, -2.8), Color(0.75, 0.75, 0.78), Vector3.ZERO, "rust_metal", Vector2(1.0, 3.0))
	gas_valve_wheel = Node3D.new()
	gas_valve_wheel.position = Vector3(4.52, 1.48, -2.8)
	add_child(gas_valve_wheel)
	_add_box(
		gas_valve_wheel, Vector3(0.12, 0.58, 0.58), Vector3.ZERO,
		Color(0.92, 0.18, 0.18), Vector3.ZERO, Color(0.85, 0.12, 0.12), 1.2,
		"gas_valve", "[Зажми E] Крутить вентиль газа (Сброс давления)", "rust_metal"
	)

func _build_window_breaker_and_cabinet() -> void:
	var wall_tint := Color(0.88, 0.90, 0.94)
	# Задняя стена (Z = 4.5) с широким панорамным окном в ночной лес
	_add_box(self, Vector3(3.4, 4.0, 0.4), Vector3(-3.8, 2.0, 4.5), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(1.5, 1.0))
	_add_box(self, Vector3(3.4, 4.0, 0.4), Vector3(3.8, 2.0, 4.5), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(1.5, 1.0))
	_add_box(self, Vector3(4.4, 1.05, 0.4), Vector3(0.0, 0.52, 4.5), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(2.0, 0.4))
	_add_box(self, Vector3(4.4, 0.85, 0.4), Vector3(0.0, 3.58, 4.5), wall_tint, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wall_concrete", Vector2(2.0, 0.4))

	# Металлическая рама панорамного окна, переплёты и широкий подоконник
	_add_box(self, Vector3(4.3, 0.12, 0.56), Vector3(0.0, 1.06, 4.46), Color(0.55, 0.58, 0.62), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")
	_add_box(self, Vector3(0.10, 2.15, 0.14), Vector3(-0.72, 2.12, 4.48), Color(0.32, 0.36, 0.42), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")
	_add_box(self, Vector3(0.10, 2.15, 0.14), Vector3(0.72, 2.12, 4.48), Color(0.32, 0.36, 0.42), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")

	# Стикер-улика #1 на раме лесного окна
	_add_box(
		self, Vector3(0.26, 0.26, 0.05), Vector3(-1.95, 1.65, 4.28),
		Color(0.98, 0.88, 0.22), Vector3.ZERO, Color(0.95, 0.82, 0.15), 1.5,
		"clue_1", "[E] Прочитать стикер на раме окна (Улика Сейфа #1)"
	)

	# ШКАФЧИК С ПРОВОДАМИ И РЫЧАГ СВЕТА (Ярко подсвечены в темноте во время блэкаута!)
	_add_box(
		self, Vector3(0.74, 0.90, 0.22), Vector3(-3.35, 1.68, 4.25),
		Color(0.75, 0.78, 0.82), Vector3.ZERO, Color(0.95, 0.55, 0.12), 1.6,
		"open_wires_box", "[E] Электрощиток с проводами (Починить проводку перед включением света)", "rust_metal"
	)
	_add_box(self, Vector3(0.45, 0.06, 0.04), Vector3(-3.35, 1.88, 4.12), Color.RED, Vector3.ZERO, Color.RED, 3.4)
	_add_box(self, Vector3(0.45, 0.06, 0.04), Vector3(-3.35, 1.74, 4.12), Color.CYAN, Vector3.ZERO, Color.CYAN, 3.4)
	_add_box(self, Vector3(0.45, 0.06, 0.04), Vector3(-3.35, 1.60, 4.12), Color.YELLOW, Vector3.ZERO, Color.YELLOW, 3.4)
	_add_box(self, Vector3(0.45, 0.06, 0.04), Vector3(-3.35, 1.46, 4.12), Color.GREEN, Vector3.ZERO, Color.GREEN, 3.4)

	_add_box(self, Vector3(0.42, 0.58, 0.18), Vector3(-2.55, 1.68, 4.25), Color(0.65, 0.68, 0.72), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")
	breaker_lever = Node3D.new()
	breaker_lever.position = Vector3(-2.55, 1.68, 4.12)
	add_child(breaker_lever)
	_add_box(
		breaker_lever, Vector3(0.22, 0.44, 0.16), Vector3.ZERO,
		Color(0.96, 0.22, 0.18), Vector3.ZERO, Color(1.0, 0.25, 0.15), 3.4,
		"pull_breaker", "[E] Главный Рычаг Света (Врубить питание после починки проводов)"
	)

	# ШКАФЧИК ДЕЖУРНОГО С ПАСХАЛКОЙ «AZAMAT SASI» (Сзади слева, X = 3.45, Z = 4.05)
	_add_box(self, Vector3(1.1, 2.1, 0.55), Vector3(3.45, 1.25, 4.05), Color(0.65, 0.70, 0.78), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")
	_add_box(
		self, Vector3(0.78, 0.48, 0.04), Vector3(3.45, 1.55, 3.82),
		Color(0.95, 0.88, 0.25), Vector3.ZERO, Color(0.95, 0.82, 0.2), 1.8,
		"clue_3", "[E] Надпись AZAMAT SASI и Улика Сейфа #3"
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
		Color(0.75, 0.80, 0.86), Vector3.ZERO, Color.BLACK, 0.0,
		"toggle_cabinet", "[E] Открыть/закрыть шкафчик дежурного", "rust_metal"
	)

# =============================================================================
# ГЛУБОКИЙ АТМОСФЕРНЫЙ ЛЕС И РАДИОВЫШКА ЗА ОКНОМ (В ДУХЕ VOICES OF THE VOID)
# =============================================================================
func _build_deep_forest_exterior() -> void:
	var ext := Node3D.new()
	ext.name = "ForestExterior"
	add_child(ext)

	# 1. Рельеф лесной долины и холмов за окном (Z от 4.7 до 34.0)
	_add_box(ext, Vector3(36.0, 0.4, 30.0), Vector3(0.0, -0.2, 19.5), Color(0.85, 0.90, 0.85), Vector3.ZERO, Color.BLACK, 0.0, "", "", "forest_ground", Vector2(12.0, 10.0))
	# Боковые лесные холмы
	_add_box(ext, Vector3(14.0, 3.2, 24.0), Vector3(-11.5, 1.1, 19.0), Color(0.70, 0.78, 0.70), Vector3(0.0, 0.0, -14.0), Color.BLACK, 0.0, "", "", "forest_ground", Vector2(6.0, 8.0))
	_add_box(ext, Vector3(14.0, 3.2, 24.0), Vector3(11.5, 1.1, 19.0), Color(0.70, 0.78, 0.70), Vector3(0.0, 0.0, 14.0), Color.BLACK, 0.0, "", "", "forest_ground", Vector2(6.0, 8.0))

	# 2. Панорамный текстурированный задник гор, тумана и дальнего леса (Z = 31.0)
	var sky_plane := _add_box(ext, Vector3(38.0, 16.0, 0.2), Vector3(0.0, 6.8, 31.0), Color.WHITE, Vector3.ZERO, Color(0.18, 0.26, 0.42), 1.1, "", "", "forest_panorama", Vector2(2.0, 1.0))
	sky_backdrop_mat = sky_plane.material_override as ShaderMaterial

	# 3. Забор периметра загородного ЦОД и уличный фонарь на столбе (Z = 7.4)
	for fx in [-6.0, -4.0, -2.0, 2.0, 4.0, 6.0]:
		_add_cylinder(ext, 0.07, 0.08, 2.1, Vector3(fx, 1.0, 7.4), Color(0.55, 0.58, 0.62), Vector3.ZERO, "rust_metal")
	_add_box(ext, Vector3(14.0, 0.08, 0.06), Vector3(0.0, 1.75, 7.4), Color(0.5, 0.52, 0.56), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")
	_add_box(ext, Vector3(14.0, 0.08, 0.06), Vector3(0.0, 1.15, 7.4), Color(0.5, 0.52, 0.56), Vector3.ZERO, Color.BLACK, 0.0, "", "", "rust_metal")

	# Столб уличного фонаря справа за окном
	_add_cylinder(ext, 0.08, 0.10, 4.4, Vector3(2.4, 2.2, 7.2), Color(0.45, 0.48, 0.52), Vector3.ZERO, "rust_metal")
	_add_box(ext, Vector3(0.42, 0.14, 0.28), Vector3(2.15, 4.35, 7.2), Color(0.95, 0.85, 0.65), Vector3.ZERO, Color(1.0, 0.82, 0.52), 3.0)

	# 4. Высокая решётчатая Радиовышка ЦОД в лесу с красным маячком (как в Voices of the Void!)
	var tower_pos := Vector3(-4.8, 0.0, 22.5)
	_add_cylinder(ext, 0.18, 0.85, 13.5, tower_pos + Vector3(0.0, 6.75, 0.0), Color(0.75, 0.25, 0.22), Vector3.ZERO, "rust_metal", Vector2(2.0, 8.0), 4)
	_add_box(ext, Vector3(0.32, 0.32, 0.32), tower_pos + Vector3(0.0, 13.7, 0.0), Color.RED, Vector3.ZERO, Color.RED, 5.0)
	radio_tower_beacon = OmniLight3D.new()
	radio_tower_beacon.position = tower_pos + Vector3(0.0, 13.9, 0.0)
	radio_tower_beacon.light_color = Color(1.0, 0.12, 0.08)
	radio_tower_beacon.light_energy = 3.5
	radio_tower_beacon.omni_range = 12.0
	ext.add_child(radio_tower_beacon)

	# 5. Многослойный густой 3D-лес из 44 многоярусных конических сосен и елей!
	var rng := RandomNumberGenerator.new()
	rng.seed = 42069
	for i in range(44):
		var row := i / 11 # 4 эшелона в глубину
		var tz := 8.2 + float(row) * 4.8 + rng.randf_range(-1.4, 1.4)
		var tx := rng.randf_range(-12.5, 12.5)
		# В ближнем ряду оставляем узкую тропу прямо перед центром окна для силуэта Исказителя
		if row == 0 and abs(tx) < 1.35:
			tx = 1.85 if tx >= 0.0 else -1.85
		var scale_h := rng.randf_range(0.85, 1.45) * (1.0 + float(row) * 0.12)
		var tilt := Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(0.0, 360.0), rng.randf_range(-3.0, 3.0))
		_spawn_detailed_pine_tree(ext, Vector3(tx, 0.0, tz), scale_h, tilt)

func _spawn_detailed_pine_tree(parent: Node3D, pos: Vector3, h_scale: float, rot_deg: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = pos
	tree.rotation_degrees = rot_deg
	parent.add_child(tree)

	# Ствол с текстурой сосновой коры
	var trunk_h := 2.4 * h_scale
	_add_cylinder(tree, 0.11 * h_scale, 0.22 * h_scale, trunk_h, Vector3(0.0, trunk_h * 0.5, 0.0), Color.WHITE, Vector3.ZERO, "pine_bark", Vector2(1.0, 2.0), 6)

	# 4 яруса конусообразной густой хвои с текстурой pine_needles.png
	var tiers := 4
	for t in range(tiers):
		var frac := float(t) / float(tiers)
		var cone_h := (1.85 - frac * 0.35) * h_scale
		var bot_r := (1.35 - frac * 0.26) * h_scale
		var top_r := 0.04 * h_scale if t == tiers - 1 else (0.35 - frac * 0.08) * h_scale
		var cy := (1.55 + float(t) * 1.05) * h_scale
		var tint := Color(0.78 - frac * 0.1, 0.88, 0.80 - frac * 0.1)
		_add_cylinder(tree, top_r, bot_r, cone_h, Vector3(0.0, cy, 0.0), tint, Vector3.ZERO, "pine_needles", Vector2(2.0, 2.0), 7)

func _build_lobby_vending_and_secrets() -> void:
	vending_machine_group = Node3D.new()
	vending_machine_group.position = Vector3(-4.15, 0.0, -3.35)
	add_child(vending_machine_group)
	_add_box(
		vending_machine_group, Vector3(1.15, 2.25, 0.85), Vector3(0.0, 1.12, 0.0),
		Color(0.75, 0.70, 0.90), Vector3.ZERO, Color(0.95, 0.58, 0.12), 0.7,
		"open_shop_vending", "[E] Торговый автомат «Ларёк Ништяков» (Баффы за монетки)", "server_rack"
	)
	var vend_lbl := Label3D.new()
	vend_lbl.text = "ЛАРЁК НИШТЯКОВ\n[НАЖМИ E]"
	vend_lbl.font_size = 28
	vend_lbl.modulate = Color(1.0, 0.85, 0.25)
	vend_lbl.position = Vector3(0.0, 1.75, 0.45)
	vending_machine_group.add_child(vend_lbl)

	# Секретный кодовый Сейф Сеньора в углу комнаты
	_add_box(
		self, Vector3(0.68, 0.68, 0.68), Vector3(-4.40, 0.95, 2.8),
		Color(0.75, 0.80, 0.85), Vector3.ZERO, Color(0.15, 0.75, 0.45), 0.8,
		"open_lobby_safe", "[E] Кодовый Сейф Сеньора (Секретная головоломка лобби)", "rust_metal"
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
		"hit_tadpole", "[E / ЛКМ] УЕБАТЬ БАГОГРЫЗА!"
	)
	monster_tadpole.visible = false

	# 3. Троянский Конь в T-Pose (с текстурой дерева!)
	monster_trojan = Node3D.new()
	monster_trojan.position = Vector3(0.0, 0.0, -14.0)
	add_child(monster_trojan)
	_add_box(monster_trojan, Vector3(0.95, 1.35, 1.65), Vector3(0.0, 1.35, 0.0), Color.WHITE, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wood_desk")
	_add_box(monster_trojan, Vector3(2.5, 0.28, 0.32), Vector3(0.0, 1.75, 0.2), Color.WHITE, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wood_desk")
	_add_box(monster_trojan, Vector3(0.48, 0.95, 0.55), Vector3(0.0, 2.25, 0.55), Color.WHITE, Vector3(-20.0, 0.0, 0.0), Color.BLACK, 0.0, "", "", "wood_desk")
	_add_box(monster_trojan, Vector3(0.44, 0.42, 0.85), Vector3(0.0, 2.62, 0.85), Color.WHITE, Vector3.ZERO, Color.BLACK, 0.0, "", "", "wood_desk")
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
	office_omni.light_color = Color(0.75, 0.80, 0.90)
	office_omni.light_energy = 1.35
	office_omni.omni_range = 11.5
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

	breaker_emergency_light = OmniLight3D.new()
	breaker_emergency_light.position = Vector3(-2.95, 2.15, 3.65)
	breaker_emergency_light.light_color = Color(1.0, 0.32, 0.16)
	breaker_emergency_light.light_energy = 0.25
	breaker_emergency_light.omni_range = 4.5
	add_child(breaker_emergency_light)

	# Уличный фонарь во дворе перед лесом за окном
	exterior_yard_light = SpotLight3D.new()
	exterior_yard_light.position = Vector3(2.15, 4.25, 7.2)
	exterior_yard_light.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	exterior_yard_light.light_color = Color(1.0, 0.78, 0.48)
	exterior_yard_light.light_energy = 2.6
	exterior_yard_light.spot_range = 14.0
	exterior_yard_light.spot_angle = 52.0
	add_child(exterior_yard_light)

func _apply_daytime_visuals(is_day: bool) -> void:
	if world_env and world_env.environment:
		var env := world_env.environment
		if is_day:
			env.ambient_light_color = Color(0.65, 0.72, 0.82)
			env.ambient_light_energy = 0.95
			env.fog_light_color = Color(0.42, 0.56, 0.72)
			env.fog_density = 0.012
		else:
			env.ambient_light_color = Color(0.10, 0.13, 0.18)
			env.ambient_light_energy = 0.35
			env.fog_light_color = Color(0.02, 0.03, 0.05)
			env.fog_density = 0.036

	if window_sun_light:
		window_sun_light.light_energy = 1.35 if is_day else 0.14
		window_sun_light.light_color = Color(1.0, 0.94, 0.80) if is_day else Color(0.28, 0.42, 0.75)

	if sky_backdrop_mat:
		var sky_col := Color(0.65, 0.82, 0.98) if is_day else Color(0.18, 0.26, 0.44)
		sky_backdrop_mat.set_shader_parameter("albedo_color", sky_col)
		sky_backdrop_mat.set_shader_parameter("emission_color", sky_col)
		sky_backdrop_mat.set_shader_parameter("emission_energy", 1.2 if is_day else 0.55)

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
	jumpscare_timer = 1.65

func _unhandled_input(event: InputEvent) -> void:
	if GameState.active_screen != "" or GameState.game_over:
		return

	# Полноценный FPS-обзор движением мыши (курсор скрыт!)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		var dyaw: float = -mm.relative.x * 0.0032
		var dpitch: float = clampf(target_pitch - mm.relative.y * 0.0028, -0.78, 0.78) - target_pitch
		target_yaw = fposmod(target_yaw + dyaw, TAU)
		target_pitch = clampf(target_pitch + dpitch, -0.78, 0.78)
		camera_rotated.emit(dyaw, dpitch)

	# Поддержка взаимодействия по клавише [E] (и дополнительно ЛКМ по прицелу)
	elif event is InputEventKey and event.pressed and not event.echo:
		var ke := event as InputEventKey
		if ke.keycode == KEY_E:
			_trigger_aimed_interaction()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_trigger_aimed_interaction()

func _trigger_aimed_interaction() -> void:
	if _current_aim_hit.is_empty():
		return
	var act: String = _current_aim_hit.get("action", "")
	var dist: float = float(_current_aim_hit.get("dist", 99.0))
	if dist <= INTERACT_RANGE:
		if act == "gas_valve":
			GameState.turn_gas_valve(1.6)
			if gas_valve_wheel:
				gas_valve_wheel.rotate_x(1.6)
		else:
			_execute_interact_action(act)
	else:
		GameState.add_event_log("🚶 Слишком далеко! Подойди ближе на [WASD] (или встань с кресла на [ПРОБЕЛ]).", "info")

func _raycast_center_crosshair() -> Dictionary:
	if camera == null:
		return {}
	var vp_center := get_viewport().get_visible_rect().size * 0.5
	var from := camera.project_ray_origin(vp_center)
	var to := from + camera.project_ray_normal(vp_center) * 14.0
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
	# 1. Обновление прицела в центре экрана и удержание [E] на вентиле газа
	if GameState.active_screen == "" and not GameState.game_over:
		_current_aim_hit = _raycast_center_crosshair()
		if not _current_aim_hit.is_empty():
			var d: float = float(_current_aim_hit.get("dist", 99.0))
			var h_text: String = String(_current_aim_hit.get("hint", ""))
			if d > INTERACT_RANGE:
				h_text += " [Подойди ближе]"
			elif _current_aim_hit.get("action", "") == "gas_valve" and Input.is_key_pressed(KEY_E) and not GameState.is_seated:
				GameState.turn_gas_valve(delta * 4.5)
				if gas_valve_wheel:
					gas_valve_wheel.rotate_x(delta * 4.5)
			hover_changed.emit(h_text)
		else:
			hover_changed.emit("")
	else:
		_current_aim_hit = {}
		hover_changed.emit("")

	# 2. Ходьба на WASD (когда не сидим в кресле и не открыт экран терминала)
	var is_walking := false
	if not GameState.is_seated and GameState.active_screen == "" and not GameState.game_over:
		var move_input := Vector2.ZERO
		if Input.is_key_pressed(KEY_W): move_input.y += 1.0
		if Input.is_key_pressed(KEY_S): move_input.y -= 1.0
		if Input.is_key_pressed(KEY_A): move_input.x -= 1.0
		if Input.is_key_pressed(KEY_D): move_input.x -= 1.0

		if move_input.length_squared() > 0.01:
			move_input = move_input.normalized()
			is_walking = true
			var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
			var right := Vector3(cos(yaw), 0.0, -sin(yaw))
			var vel := (forward * move_input.y + right * move_input.x) * 3.5 * delta
			var next_pos := GameState.player_pos + vel

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

	var prox := clampf((GameState.player_pos.z + 2.0) / 6.0, 0.15, 1.0)
	ProceduralAudio.window_proximity = prox

	# 3. Позиция и вращение камеры
	yaw = lerp_angle(yaw, target_yaw, min(1.0, delta * 16.0))
	pitch = lerpf(pitch, target_pitch, min(1.0, delta * 16.0))

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
			office_omni.light_color = Color(0.75, 0.80, 0.90)

	# Мигание красного маячка радиовышки над лесом
	if radio_tower_beacon:
		radio_tower_beacon.light_energy = 4.0 if (sin(Time.get_ticks_msec() * 0.005) > 0.0) else 0.3

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

	# 5. Освещение в темноте (Блэкаут)
	var is_dark := (not GameState.in_lobby) and (GameState.blackout or GameState.power <= 0.0)
	if office_omni and not jumpscare_active:
		office_omni.light_energy = 0.02 if is_dark else 1.35
	if monitor_glow:
		monitor_glow.light_energy = 0.0 if is_dark else 0.95
	if breaker_emergency_light:
		breaker_emergency_light.light_energy = 3.2 if is_dark else 0.25
	if world_env and world_env.environment and not GameState.in_lobby:
		world_env.environment.ambient_light_energy = 0.035 if is_dark else 0.35

	if left_ping_light:
		left_ping_light.light_energy = 4.5 if GameState.ping_left_timer > 0.0 else 0.0
	if right_ping_light:
		right_ping_light.light_energy = 4.5 if GameState.ping_right_timer > 0.0 else 0.0

	_sync_monsters_3d()

func _update_3d_monitor_screens() -> void:
	if main_term_label3d:
		if GameState.in_lobby:
			main_term_label3d.text = "ПОСТ ДЕЖУРНОГО\n[E — ВЫБОР СМЕНЫ]\nМОНЕТЫ: %d/3" % GameState.coins
		elif GameState.blackout:
			main_term_label3d.text = "NO POWER!\nПОЧИНИ ПРОВОДА\nУ ЗАДНЕГО ОКНА!"
		else:
			main_term_label3d.text = "%s\nЗАДАЧА НА +1🪙:\n%s" % [
				GameState.get_formatted_clock(),
				"РЕШЕНО ✅" if GameState.puzzle_solved_this_shift else "[НАЖМИ E]"
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
					monster_distortion.position = Vector3(0.0, 0.0, 5.8)
					monster_distortion.rotation_degrees.y = 180.0

	if monster_tadpole:
		monster_tadpole.visible = GameState.tadpole_active
		if GameState.tadpole_active:
			monster_tadpole.position.x = GameState.tadpole_x + sin(Time.get_ticks_msec() * 0.01) * 0.12

	if monster_trojan:
		var cfg: Dictionary = GameState.SHIFT_CONFIGS.get(GameState.current_level, GameState.SHIFT_CONFIGS[1])
		monster_trojan.visible = (not GameState.in_lobby) and bool(cfg["trojan_enabled"])
		var z_pos := lerpf(-2.4, -20.0, clampf(GameState.trojan_distance / 100.0, 0.0, 1.0))
		monster_trojan.position = Vector3(0.0, 0.0, z_pos)

	if burgundy_tail_node:
		burgundy_tail_node.visible = (GameState.burgundy_stage == 2)
		if burgundy_tail_node.visible:
			burgundy_tail_node.rotation.z = sin(Time.get_ticks_msec() * 0.015) * 0.35
	if monster_burgundy:
		monster_burgundy.visible = (GameState.burgundy_stage > 0 and GameState.active_screen == "CCTV_TERM" and GameState.current_cam == "CAM06")

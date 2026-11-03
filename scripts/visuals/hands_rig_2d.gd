extends Node2D
## 2D-риг рук дежурного и Полноэкранных Хоррор-Скримеров в стиле White Knuckle
## Отрисовывает 2D-руки на переднем плане и резкие индивидуальные скримеры для каждого монстра.

var sway_offset: Vector2 = Vector2.ZERO
var _target_sway: Vector2 = Vector2.ZERO
var _bob_time: float = 0.0
var _walk_bob_time: float = 0.0
var _is_walking: bool = false

var _action_name: String = ""
var _action_timer: float = 0.0

var _jumpscare_active: bool = false
var _jumpscare_type: String = ""
var _jumpscare_timer: float = 0.0

var scene_light_tint: Color = Color(0.75, 0.85, 0.95, 1.0)

func _ready() -> void:
	GameState.hand_action.connect(_on_hand_action)
	GameState.jumpscare_triggered.connect(_on_jumpscare_triggered)
	GameState.shift_started.connect(func(_lvl): _jumpscare_active = false)
	GameState.lobby_entered.connect(func(): _jumpscare_active = false)

func add_camera_sway(delta_yaw: float, delta_pitch: float) -> void:
	_target_sway.x = clampf(_target_sway.x - delta_yaw * 135.0, -48.0, 48.0)
	_target_sway.y = clampf(_target_sway.y - delta_pitch * 105.0, -32.0, 32.0)

func set_walking_state(walking: bool, delta: float) -> void:
	_is_walking = walking
	if walking:
		_walk_bob_time += delta * 11.0

func _on_hand_action(act: String) -> void:
	_action_name = act
	_action_timer = 0.34

func _on_jumpscare_triggered(m_type: String, _title: String, _desc: String) -> void:
	_jumpscare_active = true
	_jumpscare_type = m_type
	_jumpscare_timer = 0.0

func _process(delta: float) -> void:
	_bob_time += delta * (3.0 if GameState.running else 1.8)
	_target_sway = _target_sway.lerp(Vector2.ZERO, min(1.0, delta * 8.0))
	sway_offset = sway_offset.lerp(_target_sway, min(1.0, delta * 14.0))

	if _action_timer > 0.0:
		_action_timer = max(0.0, _action_timer - delta)
		if _action_timer <= 0.0:
			_action_name = ""

	if _jumpscare_active:
		_jumpscare_timer += delta

	_update_scene_lighting_tint()
	queue_redraw()

func _update_scene_lighting_tint() -> void:
	if _jumpscare_active:
		var strobe := (sin(_jumpscare_timer * 55.0) > 0.0)
		scene_light_tint = Color(1.0, 0.25, 0.25, 1.0) if strobe else Color(0.85, 0.85, 0.95, 1.0)
		return

	if GameState.in_lobby:
		scene_light_tint = scene_light_tint.lerp(Color(0.95, 0.92, 0.84, 1.0), 0.15)
		return

	if GameState.blackout or GameState.power <= 0.0:
		var dist_to_breaker := GameState.player_pos.distance_to(Vector3(-3.1, 0.0, 3.8))
		if dist_to_breaker < 2.8:
			scene_light_tint = scene_light_tint.lerp(Color(0.85, 0.28, 0.22, 1.0), 0.18)
		else:
			scene_light_tint = scene_light_tint.lerp(Color(0.11, 0.13, 0.18, 1.0), 0.18)
		return

	var base := Color(0.56, 0.70, 0.80, 1.0)
	if GameState.is_seated and GameState.player_looking_at_sector == "DESK":
		base = Color(0.52, 0.88, 0.90, 1.0)
	elif GameState.player_looking_at_sector == "WINDOW_BACK":
		base = Color(0.38, 0.48, 0.72, 1.0)

	if GameState.pukan_temp > 70.0 or GameState.dip_puzzle_active:
		var pulse := (sin(_bob_time * 4.5) * 0.5 + 0.5) * 0.35
		base = base.lerp(Color(1.0, 0.36, 0.30, 1.0), pulse)

	scene_light_tint = scene_light_tint.lerp(base, 0.15)

func _draw() -> void:
	var vp_size := get_viewport_rect().size

	# 1. Если сработал СКРИМЕР — рисуем жуткий индивидуальный 2D-хоррор-фрейм монстра и руки в панике!
	if _jumpscare_active:
		_draw_monster_jumpscare(vp_size)
		var panic_shake := Vector2(randf_range(-28.0, 28.0), randf_range(-28.0, 28.0))
		_draw_stylized_hand(Vector2(vp_size.x * 0.26, vp_size.y * 0.62) + panic_shake, false)
		_draw_stylized_hand(Vector2(vp_size.x * 0.74, vp_size.y * 0.62) - panic_shake, true)
		return

	if GameState.active_screen != "":
		return

	var breath := Vector2(sin(_bob_time * 0.9) * 4.0, cos(_bob_time * 1.8) * 5.0)
	var walk_offset := Vector2.ZERO
	if _is_walking and not GameState.is_seated:
		walk_offset = Vector2(cos(_walk_bob_time * 0.5) * 14.0, abs(sin(_walk_bob_time)) * 16.0)

	var left_pos := Vector2(vp_size.x * 0.22, vp_size.y * 0.87) + sway_offset + breath + walk_offset
	var right_pos := Vector2(vp_size.x * 0.78, vp_size.y * 0.87) + sway_offset - breath * 0.6 + Vector2(-walk_offset.x, walk_offset.y)

	if _action_timer > 0.0:
		var t := sin((_action_timer / 0.34) * PI)
		match _action_name:
			"press":
				right_pos += Vector2(-38.0 * t, -72.0 * t)
			"smack":
				right_pos += Vector2(-88.0 * t, -98.0 * t)
				left_pos += Vector2(45.0 * t, -50.0 * t)
			"turn_valve":
				var ang := _bob_time * 11.0
				right_pos += Vector2(cos(ang) * 30.0, sin(ang) * 30.0 - 48.0)
				left_pos += Vector2(-cos(ang) * 24.0, -sin(ang) * 24.0 - 38.0)
			"throw_carrot":
				right_pos += Vector2(-62.0 * t, -112.0 * t)
			"duck", "coffee":
				right_pos += Vector2(-46.0 * t, -64.0 * t)

	_draw_stylized_hand(left_pos, false)
	_draw_stylized_hand(right_pos, true)

	if _action_name == "coffee":
		_draw_held_coffee(right_pos + Vector2(-28.0, -74.0))
	elif _action_name == "duck":
		_draw_held_duck(right_pos + Vector2(-26.0, -72.0))
	elif GameState.carrots_count > 0 and not GameState.in_lobby:
		_draw_held_carrot(left_pos + Vector2(26.0, -68.0))

# =============================================================================
# ИНДИВИДУАЛЬНЫЕ 2D-ХОРРОР СКРИМЕРЫ ПОД КАЖДОГО МОНСТРА
# =============================================================================
func _draw_monster_jumpscare(vp: Vector2) -> void:
	var center := vp * 0.5 + Vector2(randf_range(-34.0, 34.0), randf_range(-34.0, 34.0))
	var zoom := minf(1.35, 0.75 + _jumpscare_timer * 1.8)
	var strobe := (int(_jumpscare_timer * 28.0) % 2 == 0)

	match _jumpscare_type:
		"distortion":
			# 1. ИСКАЗИТЕЛЬ: Вывернутый угольно-чёрный череп во весь экран, слепящие белые глаза и длинная пасть
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.0, 0.04, 0.88) if not strobe else Color(0.28, 0.02, 0.05, 0.85), true)
			var head_pts := PackedVector2Array([
				center + Vector2(-175.0, -250.0) * zoom,
				center + Vector2(185.0, -230.0) * zoom,
				center + Vector2(140.0, 280.0) * zoom,
				center + Vector2(-150.0, 290.0) * zoom
			])
			draw_colored_polygon(head_pts, Color(0.03, 0.03, 0.04))
			draw_polyline(head_pts + PackedVector2Array([head_pts[0]]), Color(0.95, 0.12, 0.18), 5.0)

			# Безумные белые глаза с кровавыми точками-зрачками
			var eye_l := center + Vector2(-78.0, -75.0) * zoom
			var eye_r := center + Vector2(82.0, -62.0) * zoom
			draw_circle(eye_l, 48.0 * zoom, Color.WHITE)
			draw_circle(eye_r, 52.0 * zoom, Color.WHITE)
			draw_circle(eye_l + Vector2(randf_range(-8, 8), randf_range(-8, 8)), 16.0 * zoom, Color(0.95, 0.05, 0.05))
			draw_circle(eye_r + Vector2(randf_range(-8, 8), randf_range(-8, 8)), 16.0 * zoom, Color(0.95, 0.05, 0.05))
			draw_circle(eye_l, 6.0 * zoom, Color.BLACK)
			draw_circle(eye_r, 6.0 * zoom, Color.BLACK)

			# Вытянутая кричащая пасть с длинными редкими зубами
			var maw_rect := Rect2(center + Vector2(-85.0, 20.0) * zoom, Vector2(170.0, 230.0) * zoom)
			draw_rect(maw_rect, Color(0.18, 0.01, 0.03), true)
			draw_rect(maw_rect, Color.WHITE, false, 4.0)
			for t in range(6):
				var tx := maw_rect.position.x + 16.0 + float(t) * 26.0 * zoom
				draw_line(Vector2(tx, maw_rect.position.y), Vector2(tx, maw_rect.position.y + 68.0 * zoom), Color(0.92, 0.88, 0.82), 6.0)
				draw_line(Vector2(tx, maw_rect.end.y), Vector2(tx, maw_rect.end.y - 68.0 * zoom), Color(0.92, 0.88, 0.82), 6.0)

		"burgundy":
			# 2. БОРДОВЫЙ ДУШЕГУБ: Смыкающаяся с потолка мясная багровая пасть с десятками клыков и 4 жёлтыми глазами!
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0.16, 0.01, 0.04, 0.86), true)
			draw_circle(center, 270.0 * zoom, Color(0.48, 0.04, 0.10))
			draw_circle(center, 195.0 * zoom, Color(0.08, 0.01, 0.02))

			# 4 хищных жёлто-красных глаза сверху
			var eye_offsets := [Vector2(-150, -180), Vector2(-65, -215), Vector2(65, -215), Vector2(150, -180)]
			for eo in eye_offsets:
				var ep: Vector2 = center + eo * zoom
				draw_circle(ep, 26.0 * zoom, Color(1.0, 0.88, 0.15))
				draw_line(ep + Vector2(0, -22) * zoom, ep + Vector2(0, 22) * zoom, Color.BLACK, 6.0)

			# Кольцо острых клыков, смыкающихся к центру
			var fangs := 16
			for i in range(fangs):
				var ang := float(i) * TAU / float(fangs) + _jumpscare_timer * 4.0
				var p_outer := center + Vector2(cos(ang), sin(ang)) * 205.0 * zoom
				var p_left := center + Vector2(cos(ang - 0.14), sin(ang - 0.14)) * 205.0 * zoom
				var p_tip := center + Vector2(cos(ang), sin(ang)) * 78.0 * zoom
				draw_colored_polygon(PackedVector2Array([p_left, p_outer, p_tip]), Color(0.95, 0.90, 0.82))

		"trojan":
			# 3. ТРОЯНСКИЙ КОНЬ В T-POSE: Расколотый пополам деревянный череп коня, из щели которого лезут красные глаза!
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0.08, 0.04, 0.01, 0.88), true)
			var split := minf(115.0, _jumpscare_timer * 180.0)

			# Бездна внутри расколотого коня
			draw_rect(Rect2(center - Vector2(split + 40.0, 240.0), Vector2((split + 40.0) * 2.0, 480.0)), Color(0.02, 0.01, 0.02), true)
			for e in range(9):
				var ex := center.x + sin(float(e) * 2.3 + _jumpscare_timer * 15.0) * split * 0.75
				var ey := center.y - 170.0 + float(e) * 42.0
				draw_circle(Vector2(ex, ey), 16.0, Color(1.0, 0.15, 0.08) if strobe else Color(1.0, 0.65, 0.1))
				draw_circle(Vector2(ex, ey), 5.0, Color.WHITE)

			# Левая и правая половины деревянной морды коня
			var left_jaw := Rect2(center + Vector2(-230.0 - split, -220.0), Vector2(190.0, 440.0))
			var right_jaw := Rect2(center + Vector2(40.0 + split, -220.0), Vector2(190.0, 440.0))
			draw_rect(left_jaw, Color(0.55, 0.34, 0.16), true)
			draw_rect(right_jaw, Color(0.55, 0.34, 0.16), true)
			draw_rect(left_jaw, Color(0.15, 0.08, 0.02), false, 6.0)
			draw_rect(right_jaw, Color(0.15, 0.08, 0.02), false, 6.0)
			draw_circle(left_jaw.position + Vector2(120.0, 110.0), 34.0, Color(1.0, 0.2, 0.05))
			draw_circle(right_jaw.position + Vector2(70.0, 110.0), 34.0, Color(1.0, 0.2, 0.05))

		_:
			# 4. ГАЗ / ПУКАН / ИИ: Кибер-череп в плазменной вспышке
			var bg_col := Color(0.12, 0.38, 0.08, 0.85) if _jumpscare_type == "gas" else Color(0.45, 0.06, 0.02, 0.88)
			draw_rect(Rect2(Vector2.ZERO, vp), bg_col, true)
			draw_circle(center, 185.0 * zoom, Color(0.95, 0.92, 0.85) if strobe else Color(0.15, 0.05, 0.05))
			draw_circle(center + Vector2(-65.0, -35.0) * zoom, 42.0 * zoom, Color(0.95, 0.1, 0.1))
			draw_circle(center + Vector2(65.0, -35.0) * zoom, 42.0 * zoom, Color(0.95, 0.1, 0.1))
			draw_rect(Rect2(center + Vector2(-80.0, 55.0) * zoom, Vector2(160.0, 75.0) * zoom), Color.BLACK, true)

func _draw_stylized_hand(origin: Vector2, is_right: bool) -> void:
	var dir := -1.0 if is_right else 1.0
	var outline_col := Color(0.04, 0.05, 0.07, 1.0)
	var sleeve_col := Color(0.16, 0.21, 0.28, 1.0) * scene_light_tint
	var glove_dark := Color(0.24, 0.28, 0.34, 1.0) * scene_light_tint
	var glove_mid := Color(0.42, 0.47, 0.54, 1.0) * scene_light_tint
	var skin_col := Color(0.76, 0.63, 0.54, 1.0) * scene_light_tint
	var highlight_col := Color(0.88, 0.82, 0.76, 1.0) * scene_light_tint

	var forearm_pts := PackedVector2Array([
		origin + Vector2(-58.0 * dir, 140.0),
		origin + Vector2(52.0 * dir, 140.0),
		origin + Vector2(38.0 * dir, 12.0),
		origin + Vector2(-42.0 * dir, 18.0)
	])
	draw_colored_polygon(forearm_pts, sleeve_col)
	draw_polyline(forearm_pts + PackedVector2Array([forearm_pts[0]]), outline_col, 4.0)

	var palm_pts := PackedVector2Array([
		origin + Vector2(-40.0 * dir, 20.0),
		origin + Vector2(38.0 * dir, 14.0),
		origin + Vector2(46.0 * dir, -44.0),
		origin + Vector2(-34.0 * dir, -52.0)
	])
	draw_colored_polygon(palm_pts, glove_dark)

	var palm_light_pts := PackedVector2Array([
		origin + Vector2(-12.0 * dir, 12.0),
		origin + Vector2(34.0 * dir, 8.0),
		origin + Vector2(38.0 * dir, -38.0),
		origin + Vector2(-8.0 * dir, -42.0)
	])
	draw_colored_polygon(palm_light_pts, glove_mid)
	draw_polyline(palm_pts + PackedVector2Array([palm_pts[0]]), outline_col, 4.0)

	for i in range(4):
		var fx := (-24.0 + float(i) * 16.0) * dir
		var fy := -50.0 - (6.0 if (i == 1 or i == 2) else 0.0)
		var f_rect := Rect2(origin + Vector2(fx - 7.0, fy - 24.0), Vector2(14.0, 26.0))
		draw_rect(f_rect, skin_col, true)
		draw_rect(Rect2(f_rect.position + Vector2(2.0, 2.0), Vector2(5.0, 10.0)), highlight_col, true)
		draw_rect(f_rect, outline_col, false, 3.0)

	var thumb_pts := PackedVector2Array([
		origin + Vector2(32.0 * dir, -12.0),
		origin + Vector2(62.0 * dir, -28.0),
		origin + Vector2(56.0 * dir, -46.0),
		origin + Vector2(28.0 * dir, -34.0)
	])
	draw_colored_polygon(thumb_pts, skin_col)
	draw_polyline(thumb_pts + PackedVector2Array([thumb_pts[0]]), outline_col, 3.5)

func _draw_held_carrot(pos: Vector2) -> void:
	var c_body := PackedVector2Array([
		pos + Vector2(-10.0, 12.0),
		pos + Vector2(12.0, 8.0),
		pos + Vector2(4.0, -38.0)
	])
	draw_colored_polygon(c_body, Color(0.95, 0.45, 0.12) * scene_light_tint)
	draw_polyline(c_body + PackedVector2Array([c_body[0]]), Color(0.05, 0.05, 0.05), 3.0)
	draw_line(pos + Vector2(4.0, -38.0), pos + Vector2(-4.0, -52.0), Color(0.2, 0.8, 0.3) * scene_light_tint, 3.5)
	draw_line(pos + Vector2(4.0, -38.0), pos + Vector2(10.0, -50.0), Color(0.2, 0.8, 0.3) * scene_light_tint, 3.5)

func _draw_held_coffee(pos: Vector2) -> void:
	var rect := Rect2(pos - Vector2(18.0, 22.0), Vector2(36.0, 44.0))
	draw_rect(rect, Color(0.15, 0.72, 0.85) * scene_light_tint, true)
	draw_rect(rect, Color(0.05, 0.05, 0.05), false, 3.5)

func _draw_held_duck(pos: Vector2) -> void:
	draw_circle(pos, 18.0, Color(0.96, 0.82, 0.15) * scene_light_tint)
	draw_circle(pos + Vector2(-8.0, -14.0), 11.0, Color(0.96, 0.82, 0.15) * scene_light_tint)
	draw_rect(Rect2(pos + Vector2(-22.0, -18.0), Vector2(10.0, 6.0)), Color(0.95, 0.42, 0.1), true)

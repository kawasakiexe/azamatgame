extends Node2D
## 2D-риг рук дежурного в стиле White Knuckle
## Отображает 2D-руки на переднем плане с инерцией от поворота камеры,
## покачиванием при ходьбе (WASD) и динамическим освещением от 3D-комнаты.

var sway_offset: Vector2 = Vector2.ZERO
var _target_sway: Vector2 = Vector2.ZERO
var _bob_time: float = 0.0
var _walk_bob_time: float = 0.0
var _is_walking: bool = false

var _action_name: String = ""
var _action_timer: float = 0.0

var scene_light_tint: Color = Color(0.75, 0.85, 0.95, 1.0)

func _ready() -> void:
	GameState.hand_action.connect(_on_hand_action)

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

func _process(delta: float) -> void:
	_bob_time += delta * (3.0 if GameState.running else 1.8)
	_target_sway = _target_sway.lerp(Vector2.ZERO, min(1.0, delta * 8.0))
	sway_offset = sway_offset.lerp(_target_sway, min(1.0, delta * 14.0))

	if _action_timer > 0.0:
		_action_timer = max(0.0, _action_timer - delta)
		if _action_timer <= 0.0:
			_action_name = ""

	_update_scene_lighting_tint()
	queue_redraw()

func _update_scene_lighting_tint() -> void:
	if GameState.in_lobby:
		scene_light_tint = scene_light_tint.lerp(Color(0.95, 0.92, 0.84, 1.0), 0.15)
		return

	if GameState.blackout or GameState.power <= 0.0:
		# В темноте руки еле видны, но у щитка с проводами подсвечиваются аварийным красным светом!
		var dist_to_breaker := GameState.player_pos.distance_to(Vector3(-3.1, 0.0, 3.8))
		if dist_to_breaker < 2.8:
			scene_light_tint = scene_light_tint.lerp(Color(0.85, 0.28, 0.22, 1.0), 0.18)
		else:
			scene_light_tint = scene_light_tint.lerp(Color(0.11, 0.13, 0.18, 1.0), 0.18)
		return

	var base := Color(0.56, 0.70, 0.80, 1.0)
	if GameState.is_seated and GameState.player_looking_at_sector == "DESK":
		base = Color(0.52, 0.88, 0.90, 1.0) # Отсвет мониторов
	elif GameState.player_looking_at_sector == "WINDOW_BACK":
		base = Color(0.38, 0.48, 0.72, 1.0) # Ночной лес за окном

	if GameState.pukan_temp > 70.0 or GameState.dip_puzzle_active:
		var pulse := (sin(_bob_time * 4.5) * 0.5 + 0.5) * 0.35
		base = base.lerp(Color(1.0, 0.36, 0.30, 1.0), pulse)

	scene_light_tint = scene_light_tint.lerp(base, 0.15)

func _draw() -> void:
	# Если открыто полноэкранное окно терминала — руки опущены к клавиатуре/пульту
	if GameState.active_screen != "":
		return

	var vp_size := get_viewport_rect().size
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

extends Node
## Главный контроллер сцены и экранных терминалов (MainController)
## Связывает 3D-комнату, 2D-руки, PS1/White Knuckle шейдер дизеринга
## и открываемые в комнате экраны (Терминал задач/смен, Терминал CCTV/дверей,
## Щиток проводов, Торговый автомат ништяков и Секретный сейф).

const POST_SHADER := preload("res://shaders/psx_dither_post.gdshader")
const ServerRoomScript := preload("res://scripts/world/server_room_3d.gd")
const HandsRigScript := preload("res://scripts/visuals/hands_rig_2d.gd")

var server_room: Node3D
var hands_rig: Node2D
var post_rect: ColorRect
var post_mat: ShaderMaterial

# Базовый HUD комнаты
var hud_layer: CanvasLayer
var top_stats_label: Label
var mode_hint_label: Label
var hover_label: Label
var log_label: RichTextLabel
var phone_banner: PanelContainer
var phone_label: Label

# Открываемые экраны 3D-объектов
var main_term_modal: PanelContainer
var main_term_content: VBoxContainer

var cctv_term_modal: PanelContainer
var cctv_info_label: Label
var btn_lock_left: Button
var btn_lock_right: Button
var btn_cooler: Button

var wires_modal: PanelContainer
var wires_box_vbox: VBoxContainer

var shop_modal: PanelContainer
var shop_vbox: VBoxContainer

var safe_modal: PanelContainer
var safe_code_input: String = ""
var safe_display_label: Label

var end_modal: PanelContainer
var end_title_label: Label
var end_desc_label: Label

func _ready() -> void:
	# 1. 3D-сцена загородной серверной
	server_room = ServerRoomScript.new()
	server_room.name = "ServerRoom3D"
	add_child(server_room)

	# 2. 2D-руки на переднем плане (под пост-процессинг шейдером!)
	var hands_layer := CanvasLayer.new()
	hands_layer.layer = 1
	add_child(hands_layer)

	hands_rig = HandsRigScript.new()
	hands_rig.name = "HandsRig2D"
	hands_layer.add_child(hands_rig)

	server_room.camera_rotated.connect(hands_rig.add_camera_sway)
	server_room.walking_updated.connect(hands_rig.set_walking_state)
	server_room.hover_changed.connect(_on_hover_changed)

	# 3. Пост-процессинг шейдер (White Knuckle Bayer Dithering + PS1)
	var post_layer := CanvasLayer.new()
	post_layer.layer = 2
	add_child(post_layer)

	post_rect = ColorRect.new()
	post_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_mat = ShaderMaterial.new()
	post_mat.shader = POST_SHADER
	post_rect.material = post_mat
	post_layer.add_child(post_rect)

	# 4. Интерфейс терминалов и тонкий статус-бар
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 3
	add_child(hud_layer)
	_build_hud()

	GameState.ui_updated.connect(_refresh_ui)
	GameState.screen_opened.connect(_on_screen_opened)
	GameState.shift_started.connect(_on_shift_started)
	GameState.lobby_entered.connect(_on_lobby_entered)
	GameState.jumpscare_triggered.connect(_on_jumpscare_triggered)
	GameState.victory_triggered.connect(_on_victory_triggered)

	_refresh_ui()

func _process(_delta: float) -> void:
	if post_mat:
		var max_stare := 4.5 if GameState.active_buffs["mirrorGlasses"] else 1.8
		var glitch := clampf(GameState.distortion_stare_timer / max_stare, 0.0, 1.0)
		post_mat.set_shader_parameter("distortion_glitch", glitch)

		var heat := 0.0 if GameState.in_lobby else clampf((GameState.pukan_temp - 55.0) / 45.0, 0.0, 1.0)
		post_mat.set_shader_parameter("heat_tint", heat)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var ke := event as InputEventKey

	if ke.keycode == KEY_F11:
		var mode := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		return

	# Пункт 2: Выход с кресла нажатием на ПРОБЕЛ (ни одна головоломка не использует пробел!)
	if ke.keycode == KEY_SPACE:
		if GameState.is_seated:
			GameState.stand_up_from_chair()
			get_viewport().set_input_as_handled()
		return

	if ke.keycode == KEY_ESCAPE:
		if GameState.active_screen != "":
			GameState.close_interactive_screen()
			get_viewport().set_input_as_handled()
		return

	# Тумблеры ядра SW1-4 доступны с цифровых клавиш 1-4 только когда сидишь в кресле
	if GameState.is_seated and not GameState.in_lobby:
		match ke.keycode:
			KEY_1: GameState.toggle_dip(0)
			KEY_2: GameState.toggle_dip(1)
			KEY_3: GameState.toggle_dip(2)
			KEY_4: GameState.toggle_dip(3)

func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	return sb

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(root)

	# --- ВЕРХНЯЯ ПАНЕЛЬ СТАТУСА ---
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 10
	top_bar.offset_top = 8
	top_bar.offset_right = -10
	top_bar.offset_bottom = 66
	top_bar.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.05, 0.08, 0.88), Color(0.20, 0.34, 0.48)))
	root.add_child(top_bar)

	var top_vbox := VBoxContainer.new()
	top_vbox.add_theme_constant_override("separation", 2)
	top_bar.add_child(top_vbox)

	var top_hbox := HBoxContainer.new()
	top_vbox.add_child(top_hbox)

	top_stats_label = Label.new()
	top_stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_stats_label.add_theme_font_size_override("font_size", 13)
	top_hbox.add_child(top_stats_label)

	var btn_lobby := Button.new()
	btn_lobby.text = "☀️ В ДНЕВНОЕ ЛОББИ"
	btn_lobby.focus_mode = Control.FOCUS_NONE
	btn_lobby.pressed.connect(func(): GameState.return_to_lobby())
	top_hbox.add_child(btn_lobby)

	mode_hint_label = Label.new()
	mode_hint_label.add_theme_font_size_override("font_size", 12)
	mode_hint_label.add_theme_color_override("font_color", Color(0.65, 0.88, 0.98))
	top_vbox.add_child(mode_hint_label)

	# --- ЗВОНОК ТИМЛИДА (PHONE GUY) ---
	phone_banner = PanelContainer.new()
	phone_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	phone_banner.offset_left = 10
	phone_banner.offset_top = 72
	phone_banner.offset_right = -10
	phone_banner.offset_bottom = 132
	phone_banner.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.08, 0.22, 0.92), Color(0.42, 0.46, 0.92)))
	phone_banner.visible = false
	root.add_child(phone_banner)

	var phone_hbox := HBoxContainer.new()
	phone_banner.add_child(phone_hbox)
	phone_label = Label.new()
	phone_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phone_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phone_label.add_theme_font_size_override("font_size", 12)
	phone_hbox.add_child(phone_label)
	var phone_close := Button.new()
	phone_close.text = "Послать нахер [X]"
	phone_close.focus_mode = Control.FOCUS_NONE
	phone_close.pressed.connect(func(): phone_banner.visible = false)
	phone_hbox.add_child(phone_close)

	# --- ПРИЦЕЛ В ЦЕНТРЕ ЭКРАНА И ПОДСКАЗКА 3D-ОБЪЕКТА ---
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -10
	crosshair.offset_top = -12
	crosshair.offset_right = 10
	crosshair.offset_bottom = 12
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.65))
	root.add_child(crosshair)

	hover_label = Label.new()
	hover_label.set_anchors_preset(Control.PRESET_CENTER)
	hover_label.offset_left = -320
	hover_label.offset_top = 18
	hover_label.offset_right = 320
	hover_label.offset_bottom = 52
	hover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_label.add_theme_color_override("font_color", Color(0.28, 0.96, 0.98))
	hover_label.add_theme_font_size_override("font_size", 14)
	root.add_child(hover_label)

	# --- КОМПАКТНЫЙ ЖУРНАЛ СОБЫТИЙ ВНИЗУ ---
	var log_panel := PanelContainer.new()
	log_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	log_panel.offset_left = 12
	log_panel.offset_top = -94
	log_panel.offset_right = -12
	log_panel.offset_bottom = -8
	log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.05, 0.08, 0.80), Color(0.18, 0.28, 0.38)))
	root.add_child(log_panel)

	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.scroll_active = false
	log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_panel.add_child(log_label)

	# --- МОДАЛЬНЫЕ ЭКРАНЫ 3D-ТЕРМИНАЛОВ И ОБЪЕКТОВ ---
	_build_main_terminal_modal(root)
	_build_cctv_terminal_modal(root)
	_build_wires_box_modal(root)
	_build_shop_vending_modal(root)
	_build_lobby_safe_modal(root)
	_build_end_modal(root)

func _add_btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

# =============================================================================
# 1. ЭКРАН ГЛАВНОГО ТЕРМИНАЛА (Днём — Выбор смены; Ночью — 5 разных головоломок!)
# =============================================================================
func _build_main_terminal_modal(root: Control) -> void:
	main_term_modal = PanelContainer.new()
	main_term_modal.set_anchors_preset(Control.PRESET_CENTER)
	main_term_modal.offset_left = -360
	main_term_modal.offset_top = -220
	main_term_modal.offset_right = 360
	main_term_modal.offset_bottom = 195
	main_term_modal.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.07, 0.11, 0.96), Color(0.15, 0.88, 0.95)))
	main_term_modal.visible = false
	root.add_child(main_term_modal)

	main_term_content = VBoxContainer.new()
	main_term_content.add_theme_constant_override("separation", 8)
	main_term_modal.add_child(main_term_content)

func _populate_main_terminal() -> void:
	for c in main_term_content.get_children():
		c.queue_free()

	var header := HBoxContainer.new()
	main_term_content.add_child(header)
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.25, 0.95, 0.98))
	header.add_child(title)

	_add_btn(header, "Отойти от экрана [ESC]", func(): GameState.close_interactive_screen())
	_add_btn(header, "🪑 Встать с кресла [ПРОБЕЛ]", func(): GameState.stand_up_from_chair())

	if GameState.in_lobby:
		title.text = "🖥️ ТЕРМИНАЛ ДЕЖУРНОГО — ВЫБОР НОЧНОЙ СМЕНЫ"
		var sub := Label.new()
		sub.text = "Цель каждой ночи — дожить до 06:00 AM. Заработанные на уровнях монеты (🪙 %d/3) можно потратить в автомате ништяков у левой стены!" % GameState.coins
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.add_theme_font_size_override("font_size", 12)
		main_term_content.add_child(sub)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		main_term_content.add_child(grid)

		for i in range(1, 7):
			var lvl := i
			var cfg: Dictionary = GameState.SHIFT_CONFIGS[i]
			var unlocked := (i <= GameState.max_unlocked_level)
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.disabled = not unlocked
			b.text = "%s СМЕНА #%d\n%s\n🧩 Монета: %s" % [
				"🔓" if unlocked else "🔒", i, cfg["subtitle"], cfg["puzzle_name"]
			]
			b.pressed.connect(func(): GameState.start_shift_from_lobby(lvl))
			grid.add_child(b)
		return

	# НОЧНОЙ РЕЖИМ: Уникальная головоломка смены на +1 одноразовую монету!
	var cfg: Dictionary = GameState.SHIFT_CONFIGS.get(GameState.current_level, GameState.SHIFT_CONFIGS[1])
	title.text = "🧩 %s (+1🪙 Монета)" % String(cfg["puzzle_name"])

	var status_lbl := Label.new()
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if GameState.puzzle_solved_this_shift:
		status_lbl.text = "✅ ГОЛОВОЛОМКА ЭТОЙ НОЧИ РЕШЕНА! МОНЕТА В КАРМАНЕ (%d/3)!" % GameState.coins
		status_lbl.add_theme_color_override("font_color", Color(0.25, 0.95, 0.55))
	else:
		status_lbl.text = "Реши задачу, чтобы получить одноразовую монету для дневного магазина ништяков!"
	main_term_content.add_child(status_lbl)

	var ptype := GameState.get_current_puzzle_type()
	var center_box := VBoxContainer.new()
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_term_content.add_child(center_box)

	match ptype:
		"PIPES":
			var desc := Label.new()
			desc.text = "Кликай по трубам, чтобы соединить непрерывную трассу от ВХОДА [0,0] (слева вверху) до ПРОДА [2,2] (справа внизу):"
			desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			desc.add_theme_font_size_override("font_size", 12)
			center_box.add_child(desc)

			var pgrid := GridContainer.new()
			pgrid.columns = 3
			pgrid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			center_box.add_child(pgrid)
			var elbow_chars := ["┗", "┏", "┓", "┛"]
			for i in range(GameState.pipe_grid.size()):
				var idx := i
				var tile: Dictionary = GameState.pipe_grid[i]
				var r: int = int(tile["rot"]) % 4
				var ch := "╋"
				if tile["type"] == "straight":
					ch = "┃" if (r % 2 == 0) else "━"
				elif tile["type"] == "elbow":
					ch = elbow_chars[r]
				var b := Button.new()
				b.focus_mode = Control.FOCUS_NONE
				b.custom_minimum_size = Vector2(72, 56)
				b.text = ch
				b.add_theme_font_size_override("font_size", 24)
				b.pressed.connect(func():
					GameState.rotate_pipe_tile(idx)
					_populate_main_terminal()
				)
				pgrid.add_child(b)

		"CLUSTER_MATH":
			var cur_sum := 0
			for i in range(4):
				cur_sum += GameState.cluster_sliders[i] * GameState.cluster_weights[i]
			var info := Label.new()
			info.text = "Выстави множители 4 воркеров так, чтобы сумма ровно равнялась %d МГц!\nТекущая частота кластера: %d МГц" % [GameState.cluster_target_mhz, cur_sum]
			info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center_box.add_child(info)

			var hbox := HBoxContainer.new()
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.add_theme_constant_override("separation", 12)
			center_box.add_child(hbox)
			for i in range(4):
				var idx := i
				_add_btn(hbox, "Воркер #%d (%d МГц) × %d" % [i + 1, GameState.cluster_weights[i], GameState.cluster_sliders[i]], func():
					GameState.adjust_cluster_slider(idx)
					_populate_main_terminal()
				)

		"LIGHTS_OUT":
			var info := Label.new()
			info.text = "Клик по сектору переключает его и соседние по кресту. Зажги все 9 секторов в [ONLINE 1]:"
			info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center_box.add_child(info)

			var lgrid := GridContainer.new()
			lgrid.columns = 3
			lgrid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			center_box.add_child(lgrid)
			for i in range(9):
				var idx := i
				var val: int = GameState.lights_grid[i]
				var b := Button.new()
				b.focus_mode = Control.FOCUS_NONE
				b.custom_minimum_size = Vector2(74, 54)
				b.text = "🟢 [1]" if val == 1 else "⚫ [0]"
				b.pressed.connect(func():
					GameState.toggle_lights_out_cell(idx)
					_populate_main_terminal()
				)
				lgrid.add_child(b)

		"PACKET_ORDER":
			var sorted_n := GameState.packet_numbers.duplicate()
			sorted_n.sort()
			var info := Label.new()
			info.text = "Пропихни SQL-пакеты строго по возрастанию номера порта! (Прогресс: %d / 6)" % GameState.packet_next_idx
			info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center_box.add_child(info)

			var phbox := HBoxContainer.new()
			phbox.alignment = BoxContainer.ALIGNMENT_CENTER
			center_box.add_child(phbox)
			for n in GameState.packet_numbers:
				var port_val: int = n
				var already_done: bool = sorted_n.find(port_val) < GameState.packet_next_idx
				var b := Button.new()
				b.focus_mode = Control.FOCUS_NONE
				b.disabled = already_done
				b.custom_minimum_size = Vector2(88, 52)
				b.text = ("✅ " if already_done else "📦 ") + str(port_val)
				b.pressed.connect(func():
					GameState.click_packet_number(port_val)
					_populate_main_terminal()
				)
				phbox.add_child(b)

		"WAVE_SYNC":
			var info := Label.new()
			info.text = "Синхронизируй синусоиду ядра с эталоном!\nЭталон: [Частота: %d | Фаза: %d | Амплитуда: %d]" % [
				GameState.wave_target[0], GameState.wave_target[1], GameState.wave_target[2]
			]
			info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center_box.add_child(info)

			var whbox := HBoxContainer.new()
			whbox.alignment = BoxContainer.ALIGNMENT_CENTER
			whbox.add_theme_constant_override("separation", 12)
			center_box.add_child(whbox)
			var names := ["Частота", "Фаза", "Амплитуда"]
			for i in range(3):
				var idx := i
				_add_btn(whbox, "%s: %d (Менять)" % [names[i], GameState.wave_player[i]], func():
					GameState.adjust_wave_param(idx)
					_populate_main_terminal()
				)

# =============================================================================
# 2. ТЕРМИНАЛ БЕЗОПАСНОСТИ (Камеры CCTV, Блокировка ОДНОЙ двери, Вентиляция)
# =============================================================================
func _build_cctv_terminal_modal(root: Control) -> void:
	cctv_term_modal = PanelContainer.new()
	cctv_term_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	cctv_term_modal.offset_left = 24
	cctv_term_modal.offset_top = 74
	cctv_term_modal.offset_right = -24
	cctv_term_modal.offset_bottom = -102
	cctv_term_modal.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.06, 0.08, 0.55), Color(0.18, 0.90, 0.65)))
	cctv_term_modal.visible = false
	root.add_child(cctv_term_modal)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_END
	cctv_term_modal.add_child(vbox)

	cctv_info_label = Label.new()
	cctv_info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cctv_info_label.add_theme_color_override("font_color", Color(0.35, 0.98, 0.68))
	cctv_info_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(cctv_info_label)

	# Кнопки переключения камер CAM01-CAM06
	var cam_row := HBoxContainer.new()
	cam_row.add_theme_constant_override("separation", 8)
	vbox.add_child(cam_row)
	var cam_titles := {
		"CAM01": "CAM01: Периметр",
		"CAM02": "CAM02: Левый шлюз 22",
		"CAM03": "CAM03: Тоннель Коня",
		"CAM04": "CAM04: Правый шлюз 5432",
		"CAM05": "CAM05: Дальний тоннель",
		"CAM06": "CAM06: Вент-шахта"
	}
	for cid in cam_titles.keys():
		var cam_id: String = cid
		_add_btn(cam_row, cam_titles[cid], func():
			GameState.current_cam = cam_id
			ProceduralAudio.play_switch(true)
			_refresh_ui()
		)

	# Кнопки управления шлюзами и вентиляцией (только 1 дверь одновременно!)
	var ctrl_row := HBoxContainer.new()
	ctrl_row.add_theme_constant_override("separation", 10)
	vbox.add_child(ctrl_row)

	btn_lock_left = _add_btn(ctrl_row, "🔒 ЛЕВАЯ ДВЕРЬ (Порт 22)", func(): GameState.toggle_door_lock("left"))
	btn_lock_right = _add_btn(ctrl_row, "🔒 ПРАВАЯ ДВЕРЬ (Порт 5432)", func(): GameState.toggle_door_lock("right"))
	_add_btn(ctrl_row, "💨 ПРОДУТЬ ВЕНТИЛЯЦИЮ ПАРОМ", func(): GameState.purge_vents_with_steam())
	btn_cooler = _add_btn(ctrl_row, "❄️ ОБДУВ КРЕСЛА", func(): GameState.toggle_seat_cooler())
	_add_btn(ctrl_row, "Отойти от экрана [ESC]", func(): GameState.close_interactive_screen())
	_add_btn(ctrl_row, "🪑 Встать с кресла [ПРОБЕЛ]", func(): GameState.stand_up_from_chair())

# =============================================================================
# 3. ЭЛЕКТРОЩИТОК С ПРОВОДАМИ (У задней стены во время блэкаута)
# =============================================================================
func _build_wires_box_modal(root: Control) -> void:
	wires_modal = PanelContainer.new()
	wires_modal.set_anchors_preset(Control.PRESET_CENTER)
	wires_modal.offset_left = -280
	wires_modal.offset_top = -190
	wires_modal.offset_right = 280
	wires_modal.offset_bottom = 190
	wires_modal.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.05, 0.04, 0.96), Color(0.96, 0.52, 0.16)))
	wires_modal.visible = false
	root.add_child(wires_modal)

	wires_box_vbox = VBoxContainer.new()
	wires_box_vbox.add_theme_constant_override("separation", 10)
	wires_modal.add_child(wires_box_vbox)

func _populate_wires_box() -> void:
	for c in wires_box_vbox.get_children():
		c.queue_free()

	var title := Label.new()
	title.text = "🔌 ЭЛЕКТРОЩИТОК: СКРУТИ ОБОРВАННЫЕ ПРОВОДА ПО ЦВЕТАМ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.98, 0.72, 0.25))
	wires_box_vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Соедини все 4 линии питания, а затем дёрни красный рычаг справа от щитка!" if not GameState.wires_fixed else "✅ ВСЕ ПРОВОДА СОЕДИНЕНЫ! Закрой щиток и дёрни КРАСНЫЙ РЫЧАГ рядом!"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wires_box_vbox.add_child(sub)

	var wire_names := ["🔴 КРАСНАЯ ФАЗА (220V)", "🔵 СИНИЙ НОЛЬ (GND)", "🟡 ЖЁЛТАЯ ЗЕМЛЯ (PE)", "🟢 ЗЕЛЁНАЯ ШИНА ЦОД"]
	for i in range(4):
		var idx := i
		var connected: bool = GameState.wire_connections[i]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = connected
		b.text = ("%s — ✅ СКРУЧЕНО" % wire_names[i]) if connected else ("%s — ⚡ НАЖМИ, ЧТОБЫ СКРУТИТЬ КОНТАКТЫ" % wire_names[i])
		b.pressed.connect(func():
			GameState.connect_wire_pair(idx)
			_populate_wires_box()
		)
		wires_box_vbox.add_child(b)

	_add_btn(wires_box_vbox, "Закрыть дверцу щитка [ESC]", func(): GameState.close_interactive_screen())

# =============================================================================
# 4. АВТОМАТ «ЛАРЁК НИШТЯКОВ» (Днём в комнате)
# =============================================================================
func _build_shop_vending_modal(root: Control) -> void:
	shop_modal = PanelContainer.new()
	shop_modal.set_anchors_preset(Control.PRESET_CENTER)
	shop_modal.offset_left = -310
	shop_modal.offset_top = -205
	shop_modal.offset_right = 310
	shop_modal.offset_bottom = 205
	shop_modal.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.04, 0.10, 0.96), Color(0.98, 0.74, 0.18)))
	shop_modal.visible = false
	root.add_child(shop_modal)

	shop_vbox = VBoxContainer.new()
	shop_vbox.add_theme_constant_override("separation", 8)
	shop_modal.add_child(shop_vbox)

func _populate_shop_vending() -> void:
	for c in shop_vbox.get_children():
		c.queue_free()

	var title := Label.new()
	title.text = "🛒 ТОРГОВЫЙ АВТОМАТ «ЛАРЁК НИШТЯКОВ» (Монеты: 🪙 %d / 3)" % GameState.coins
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.98, 0.82, 0.25))
	shop_vbox.add_child(title)

	var items := [
		{"key": "antiTrojanOats", "title": "🥕 Анти-Троянский Овёс (1🪙) — Конь стартует на +40м дальше и едет медленнее"},
		{"key": "titaniumFuse", "title": "⚡ Титановый Жучок в щиток (1🪙) — Полный иммунитет к выбиванию пробок"},
		{"key": "mirrorGlasses", "title": "🕶️ Сварочные Очки Похуизма (1🪙) — Можно смотреть на Исказителя до 4.5 сек"},
		{"key": "asbestosSeat", "title": "🛡️ Асбестовая Поджопная Прокладка (1🪙) — Пукан греется на 40% медленнее"},
		{"key": "bugRepellent", "title": "🪰 Дихлофос «Смерть Головастикам» (1🪙) — Багогрыз не вылезет пол-ночи"}
	]
	for it in items:
		var k: String = it["key"]
		var bought: bool = GameState.active_buffs.get(k, false)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = bought or GameState.coins < 1
		b.text = ("✅ АКТИВНО: " if bought else "КУПИТЬ: ") + String(it["title"])
		b.pressed.connect(func():
			GameState.buy_buff(k)
			_populate_shop_vending()
		)
		shop_vbox.add_child(b)

	_add_btn(shop_vbox, "Отойти от автомата [ESC]", func(): GameState.close_interactive_screen())

# =============================================================================
# 5. СЕКРЕТНЫЙ КОДОВЫЙ СЕЙФ СЕНЬОРА (Дневная головоломка с уликами по комнате)
# =============================================================================
func _build_lobby_safe_modal(root: Control) -> void:
	safe_modal = PanelContainer.new()
	safe_modal.set_anchors_preset(Control.PRESET_CENTER)
	safe_modal.offset_left = -240
	safe_modal.offset_top = -185
	safe_modal.offset_right = 240
	safe_modal.offset_bottom = 185
	safe_modal.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.08, 0.06, 0.96), Color(0.25, 0.92, 0.55)))
	safe_modal.visible = false
	root.add_child(safe_modal)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	safe_modal.add_child(vbox)

	var title := Label.new()
	title.text = "🔐 ЗАНАЧКА СЕНЬОРА (ВВЕДИ 4-ЗНАЧНЫЙ PIN)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "Подсказка: ищи 3 жёлтых стикера по комнате (на окне, на стойке и в шкафчике AZAMAT SASI)!"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hint)

	safe_display_label = Label.new()
	safe_display_label.text = "[ _ _ _ _ ]"
	safe_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	safe_display_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(safe_display_label)

	var numpad := GridContainer.new()
	numpad.columns = 5
	numpad.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(numpad)
	for d in range(10):
		var digit_str := str(d)
		_add_btn(numpad, digit_str, func():
			if safe_code_input.length() < 4:
				safe_code_input += digit_str
				ProceduralAudio.play_key_click()
				safe_display_label.text = "[ %s ]" % safe_code_input
		)

	var act_row := HBoxContainer.new()
	act_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(act_row)
	_add_btn(act_row, "Стереть", func():
		safe_code_input = ""
		safe_display_label.text = "[ _ _ _ _ ]"
	)
	_add_btn(act_row, "🔓 ОТКРЫТЬ СЕЙФ", func():
		if GameState.try_unlock_lobby_safe(safe_code_input):
			GameState.close_interactive_screen()
		else:
			safe_code_input = ""
			safe_display_label.text = "[ ERR! ]"
	)
	_add_btn(act_row, "Отойти [ESC]", func(): GameState.close_interactive_screen())

func _build_end_modal(root: Control) -> void:
	end_modal = PanelContainer.new()
	end_modal.set_anchors_preset(Control.PRESET_CENTER)
	end_modal.offset_left = -310
	end_modal.offset_top = -140
	end_modal.offset_right = 310
	end_modal.offset_bottom = 140
	end_modal.add_theme_stylebox_override("panel", _make_panel_style(Color(0.09, 0.03, 0.05, 0.96), Color(0.95, 0.25, 0.25)))
	end_modal.visible = false
	root.add_child(end_modal)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	end_modal.add_child(vbox)

	end_title_label = Label.new()
	end_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(end_title_label)

	end_desc_label = Label.new()
	end_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(end_desc_label)

	_add_btn(vbox, "☀️ ВЕРНУТЬСЯ В ДНЕВНОЕ ЛОББИ", func():
		end_modal.visible = false
		GameState.return_to_lobby()
	)

func _on_screen_opened(scr_id: String) -> void:
	main_term_modal.visible = (scr_id == "MAIN_TERM")
	cctv_term_modal.visible = (scr_id == "CCTV_TERM")
	wires_modal.visible = (scr_id == "WIRES_BOX")
	shop_modal.visible = (scr_id == "SHOP_VENDING")
	safe_modal.visible = (scr_id == "LOBBY_SAFE")

	if scr_id == "MAIN_TERM":
		_populate_main_terminal()
	elif scr_id == "WIRES_BOX":
		_populate_wires_box()
	elif scr_id == "SHOP_VENDING":
		_populate_shop_vending()
	elif scr_id == "LOBBY_SAFE":
		safe_code_input = ""
		safe_display_label.text = "[ _ _ _ _ ]"

func _refresh_ui() -> void:
	if GameState.in_lobby:
		top_stats_label.text = "☀️ ДНЕВНОЕ ЛОББИ (Загородный Офис)   |   🪙 Монеты: %d / %d   |   🕊️ Безопасный режим: ищи пасхалки, закупайся в автомате или садись в кресло!" % [
			GameState.coins, GameState.max_coins
		]
	else:
		var cfg: Dictionary = GameState.SHIFT_CONFIGS.get(GameState.current_level, GameState.SHIFT_CONFIGS[1])
		var tr_str := ("🐴 Троян: %dм (🥕%d)" % [int(GameState.trojan_distance), GameState.carrots_count]) if bool(cfg["trojan_enabled"]) else "🐴 Троян: Спит"
		var dip_str := ("⚠️ SW:[%d%d%d%d] (%.0fc)" % [GameState.target_dip[0], GameState.target_dip[1], GameState.target_dip[2], GameState.target_dip[3], GameState.dip_timer]) if GameState.dip_puzzle_active else ("SW:[%d%d%d%d]" % [GameState.dip_switches[0], GameState.dip_switches[1], GameState.dip_switches[2], GameState.dip_switches[3]])
		top_stats_label.text = "🕒 %s (Смена #%d)  |  🔋 ИБП: %d%%  |  🔥 Пукан: %d°C  |  💀 Взломы: %d/5  |  🧪 Газ: %d%%  |  %s  |  %s  |  🪙 %d/3" % [
			GameState.get_formatted_clock(),
			GameState.current_level,
			int(ceil(GameState.power)),
			int(round(GameState.pukan_temp)),
			GameState.hack_count,
			int(round(GameState.gas_pressure)),
			tr_str,
			dip_str,
			GameState.coins
		]

	if GameState.is_seated:
		mode_hint_label.text = "🪑 ПОСТ УПРАВЛЕНИЯ (В КРЕСЛЕ) • Зажми ЛКМ для 360° обзора • Кликай по мониторам и тумблерам на столе • [ПРОБЕЛ] — Встать с кресла"
	else:
		mode_hint_label.text = "🚶 НА НОГАХ (ХОДЬБА ПО КОМНАТЕ) • [W,A,S,D] — Передвижение • Зажми ЛКМ — Поворот головы • Кликни по КРЕСЛУ или МОНИТОРАМ, чтобы сесть за пост!"

	if cctv_term_modal.visible:
		var l_status := "ЗАКРЫТА 🔒" if GameState.gate_left else "ОТКРЫТА 🔓"
		var r_status := "ЗАКРЫТА 🔒" if GameState.gate_right else "ОТКРЫТА 🔓"
		btn_lock_left.text = "Левая дверь (Порт 22): " + l_status
		btn_lock_right.text = "Правая дверь (Порт 5432): " + r_status
		btn_cooler.text = "❄️ Обдув кресла: " + ("ВКЛ" if GameState.seat_cooler else "ВЫКЛ")

		cctv_info_label.text = "● REC [%s] — СИСТЕМА БЕЗОПАСНОСТИ (⚠️ Можно держать закрытой только 1 дверь одновременно!)\n👁️ Исказитель / Архитектор: %s\n🩸 Вентиляционная шахта (CAM06): %s\n🐴 Центральный тоннель (CAM03/05): %dм до кабинета" % [
			GameState.current_cam,
			GameState.distortion_pos if GameState.distortion_active else "Вне радаров",
			("ТРЕВОГА: СТАДИЯ %d!" % GameState.burgundy_stage) if GameState.burgundy_stage > 0 else "Чисто",
			int(round(GameState.trojan_distance))
		]

	var lines: Array[String] = []
	for e in GameState.event_log:
		var col := "#67e8f9"
		if e["level"] == "danger": col = "#f87171"
		elif e["level"] == "warn": col = "#fcd34d"
		elif e["level"] == "ok": col = "#34d399"
		lines.append("[color=%s][%s] %s[/color]" % [col, e["time"], e["msg"]])
	log_label.text = "\n".join(lines)

func _on_hover_changed(hint: String) -> void:
	hover_label.text = ("🎯 " + hint) if hint != "" else ""

func _on_shift_started(lvl: int) -> void:
	end_modal.visible = false
	var cfg: Dictionary = GameState.SHIFT_CONFIGS.get(lvl, GameState.SHIFT_CONFIGS[1])
	phone_label.text = "📞 " + String(cfg["phone_msg"])
	phone_banner.visible = true
	_refresh_ui()

func _on_lobby_entered() -> void:
	phone_banner.visible = false
	_refresh_ui()

func _on_jumpscare_triggered(_m_type: String, title: String, desc: String) -> void:
	end_title_label.text = "💀 " + title
	end_desc_label.text = desc
	end_modal.visible = true

func _on_victory_triggered(lvl: int) -> void:
	end_title_label.text = "🎉 06:00 AM — СМЕНА #%d ВЫЖИТА!" % lvl
	end_desc_label.text = "Ты дожил до утра и не дал проду сгореть! В дневном лобби открыта следующая смена!"
	end_modal.visible = true

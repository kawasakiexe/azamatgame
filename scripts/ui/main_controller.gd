extends Node
## Главный контроллер сцены (MainController)
## Связывает 3D-сцену серверной, 2D-риг рук в стиле White Knuckle,
## пост-процессинг шейдер (Bayer Dithering + PSX) и весь игровой HUD.

const POST_SHADER := preload("res://shaders/psx_dither_post.gdshader")
const ServerRoomScript := preload("res://scripts/world/server_room_3d.gd")
const HandsRigScript := preload("res://scripts/visuals/hands_rig_2d.gd")

var server_room: Node3D
var hands_rig: Node2D
var post_rect: ColorRect
var post_mat: ShaderMaterial

# UI-элементы
var hud_layer: CanvasLayer
var top_stats_label: Label
var dip_status_label: Label
var log_label: RichTextLabel
var hover_label: Label
var phone_banner: PanelContainer
var phone_label: Label

var lobby_panel: PanelContainer
var lobby_coins_label: Label
var lobby_levels_grid: GridContainer
var lobby_shop_vbox: VBoxContainer
var inspect_return_btn: Button

var cctv_panel: PanelContainer
var cctv_info_label: Label
var puzzle_panel: PanelContainer
var puzzle_grid_box: GridContainer
var puzzle_status_label: Label
var end_modal: PanelContainer
var end_title_label: Label
var end_desc_label: Label

func _ready() -> void:
	# 1. 3D-мир серверной
	server_room = ServerRoomScript.new()
	server_room.name = "ServerRoom3D"
	add_child(server_room)

	# 2. 2D-слой рук на переднем плане (рендерится ДО пост-процессинг шейдера,
	# чтобы руки тоже проходили через PS1 Bayer Dithering и квантование палитры!)
	var hands_layer := CanvasLayer.new()
	hands_layer.layer = 1
	add_child(hands_layer)

	hands_rig = HandsRigScript.new()
	hands_rig.name = "HandsRig2D"
	hands_layer.add_child(hands_rig)

	server_room.camera_rotated.connect(hands_rig.add_camera_sway)
	server_room.hover_changed.connect(_on_hover_changed)

	# 3. Полноэкранный пост-процессинг шейдер (White Knuckle / PS1 Bayer Dithering)
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

	# 4. Чёткий тактический HUD и модалки поверх шейдера
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 3
	add_child(hud_layer)
	_build_hud()

	GameState.ui_updated.connect(_refresh_ui)
	GameState.shift_started.connect(_on_shift_started)
	GameState.lobby_entered.connect(_on_lobby_entered)
	GameState.jumpscare_triggered.connect(_on_jumpscare_triggered)
	GameState.victory_triggered.connect(_on_victory_triggered)

	_refresh_lobby_lists()
	_refresh_ui()

func _process(_delta: float) -> void:
	if post_mat:
		var max_stare := 4.5 if GameState.active_buffs["mirrorGlasses"] else 1.8
		var glitch := clampf(GameState.distortion_stare_timer / max_stare, 0.0, 1.0)
		post_mat.set_shader_parameter("distortion_glitch", glitch)

		var heat := clampf((GameState.pukan_temp - 55.0) / 45.0, 0.0, 1.0)
		post_mat.set_shader_parameter("heat_tint", heat)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var ke := event as InputEventKey

	if ke.keycode == KEY_F11:
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return

	if GameState.in_lobby:
		if ke.keycode == KEY_ESCAPE and GameState.lobby_inspect_mode:
			_set_lobby_inspect(false)
		return

	match ke.keycode:
		KEY_SPACE: GameState.write_patch_chunk()
		KEY_TAB: GameState.toggle_cctv()
		KEY_P: _toggle_puzzle_modal()
		KEY_Q: GameState.toggle_switch("gateLeft")
		KEY_W: GameState.toggle_switch("gateCenter")
		KEY_E: GameState.toggle_switch("gateRight")
		KEY_A: GameState.ping_port("left")
		KEY_D: GameState.ping_port("right")
		KEY_V: GameState.purge_vents_with_steam()
		KEY_C: GameState.toggle_switch("seatCooler")
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
	top_bar.offset_left = 12
	top_bar.offset_top = 10
	top_bar.offset_right = -12
	top_bar.offset_bottom = 68
	top_bar.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.06, 0.09, 0.90), Color(0.20, 0.32, 0.45)))
	root.add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 14)
	top_bar.add_child(top_hbox)

	top_stats_label = Label.new()
	top_stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_stats_label.add_theme_font_size_override("font_size", 14)
	top_hbox.add_child(top_stats_label)

	var btn_puzzle := Button.new()
	btn_puzzle.text = "🧩 ПАЙПЛАЙН [P] (+1🪙)"
	btn_puzzle.pressed.connect(_toggle_puzzle_modal)
	top_hbox.add_child(btn_puzzle)

	var btn_cctv := Button.new()
	btn_cctv.text = "📹 КАМЕРЫ [TAB]"
	btn_cctv.pressed.connect(func(): GameState.toggle_cctv())
	top_hbox.add_child(btn_cctv)

	var btn_lobby := Button.new()
	btn_lobby.text = "☀️ В ЛОББИ"
	btn_lobby.pressed.connect(func(): GameState.return_to_lobby())
	top_hbox.add_child(btn_lobby)

	# --- БАННЕР PHONE GUY ---
	phone_banner = PanelContainer.new()
	phone_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	phone_banner.offset_left = 12
	phone_banner.offset_top = 74
	phone_banner.offset_right = -12
	phone_banner.offset_bottom = 124
	phone_banner.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.08, 0.22, 0.92), Color(0.38, 0.42, 0.88)))
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
	phone_close.text = "Сбросить"
	phone_close.pressed.connect(func(): phone_banner.visible = false)
	phone_hbox.add_child(phone_close)

	# --- ЦЕНТРАЛЬНЫЙ ПРИЦЕЛ И ПОДСКАЗКА 3D-ВЗАИМОДЕЙСТВИЯ ---
	hover_label = Label.new()
	hover_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hover_label.offset_left = -260
	hover_label.offset_top = 132
	hover_label.offset_right = 260
	hover_label.offset_bottom = 166
	hover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_label.add_theme_color_override("font_color", Color(0.25, 0.92, 0.98))
	hover_label.add_theme_font_size_override("font_size", 15)
	root.add_child(hover_label)

	# --- НИЖНЯЯ ТАКТИЧЕСКАЯ ПАНЕЛЬ ---
	var bottom_bar := PanelContainer.new()
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_left = 12
	bottom_bar.offset_top = -126
	bottom_bar.offset_right = -12
	bottom_bar.offset_bottom = -10
	bottom_bar.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.06, 0.09, 0.90), Color(0.20, 0.32, 0.45)))
	root.add_child(bottom_bar)

	var b_hbox := HBoxContainer.new()
	b_hbox.add_theme_constant_override("separation", 14)
	bottom_bar.add_child(b_hbox)

	# Кнопки быстрых действий
	var actions_grid := GridContainer.new()
	actions_grid.columns = 3
	actions_grid.add_theme_constant_override("h_separation", 6)
	actions_grid.add_theme_constant_override("v_separation", 6)
	b_hbox.add_child(actions_grid)

	_add_action_btn(actions_grid, "⌨️ Хотфикс [SPACE]", func(): GameState.write_patch_chunk())
	_add_action_btn(actions_grid, "🥕 Кинуть морковь", func(): GameState.throw_carrot_at_trojan())
	_add_action_btn(actions_grid, "💨 Пар в вент. [V]", func(): GameState.purge_vents_with_steam())
	_add_action_btn(actions_grid, "🔒 Шлюз 22 [Q]", func(): GameState.toggle_switch("gateLeft"))
	_add_action_btn(actions_grid, "🔒 Центр [W]", func(): GameState.toggle_switch("gateCenter"))
	_add_action_btn(actions_grid, "🔒 Шлюз 5432 [E]", func(): GameState.toggle_switch("gateRight"))
	_add_action_btn(actions_grid, "❄️ Обдув кресла [C]", func(): GameState.toggle_switch("seatCooler"))
	_add_action_btn(actions_grid, "⛽ Дизель (+15%)", func(): GameState.crank_generator())
	_add_action_btn(actions_grid, "🖨️ Печать моркови", func(): GameState.start_printing_carrot())

	# Блок тумблеров SW1-4
	var dip_vbox := VBoxContainer.new()
	b_hbox.add_child(dip_vbox)
	dip_status_label = Label.new()
	dip_status_label.add_theme_font_size_override("font_size", 13)
	dip_vbox.add_child(dip_status_label)

	var dip_hbox := HBoxContainer.new()
	dip_vbox.add_child(dip_hbox)
	for i in range(4):
		var idx := i
		_add_action_btn(dip_hbox, "SW%d [%d]" % [i + 1, i + 1], func(): GameState.toggle_dip(idx))

	# Лог событий
	log_label = RichTextLabel.new()
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.bbcode_enabled = true
	log_label.scroll_active = false
	b_hbox.add_child(log_label)

	# --- ДНЕВНОЕ ЛОББИ ОВЕРЛЕЙ ---
	_build_lobby_overlay(root)

	# --- МОДАЛКИ: КАМЕРЫ CCTV, ПАЙПЛАЙН И КОНЕЦ СМЕНЫ ---
	_build_cctv_overlay(root)
	_build_puzzle_overlay(root)
	_build_end_modal(root)

func _add_action_btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _build_lobby_overlay(root: Control) -> void:
	lobby_panel = PanelContainer.new()
	lobby_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	lobby_panel.offset_left = 48
	lobby_panel.offset_top = 76
	lobby_panel.offset_right = -48
	lobby_panel.offset_bottom = -134
	lobby_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.05, 0.08, 0.92), Color(0.95, 0.68, 0.18)))
	root.add_child(lobby_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	lobby_panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "☀️ ДНЕВНОЕ ЛОББИ СЕРВЕРНОЙ (Поют птицы • Угрозы отключены)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.98, 0.84, 0.32))
	header.add_child(title)

	lobby_coins_label = Label.new()
	lobby_coins_label.add_theme_font_size_override("font_size", 16)
	header.add_child(lobby_coins_label)

	var inspect_btn := Button.new()
	inspect_btn.text = "👁️ Осмотреть 3D-комнату и 2D-руки"
	inspect_btn.pressed.connect(func(): _set_lobby_inspect(true))
	header.add_child(inspect_btn)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	vbox.add_child(split)

	lobby_levels_grid = GridContainer.new()
	lobby_levels_grid.columns = 2
	lobby_levels_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lobby_levels_grid.add_theme_constant_override("h_separation", 8)
	lobby_levels_grid.add_theme_constant_override("v_separation", 8)
	split.add_child(lobby_levels_grid)

	lobby_shop_vbox = VBoxContainer.new()
	lobby_shop_vbox.custom_minimum_size = Vector2(360, 0)
	lobby_shop_vbox.add_theme_constant_override("separation", 6)
	split.add_child(lobby_shop_vbox)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	vbox.add_child(footer)
	_add_action_btn(footer, "🚪 Открыть шкафчик (AZAMAT SASI)", func(): GameState.toggle_cabinet())
	_add_action_btn(footer, "🦆 Крякнуть уточкой", func(): GameState.click_rubber_duck())
	_add_action_btn(footer, "☕ Выпить кофе", func(): GameState.drink_coffee())

	var hint_lbl := Label.new()
	hint_lbl.text = "Зажми ЛКМ/ПКМ для 360° обзора • F11 — Полный экран"
	hint_lbl.add_theme_font_size_override("font_size", 12)
	footer.add_child(hint_lbl)

	inspect_return_btn = Button.new()
	inspect_return_btn.text = "📋 ВЕРНУТЬСЯ К ПЛАНШЕТУ ДНЕВНОГО ЛОББИ [ESC]"
	inspect_return_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	inspect_return_btn.offset_left = -360
	inspect_return_btn.offset_top = 80
	inspect_return_btn.offset_right = -20
	inspect_return_btn.offset_bottom = 118
	inspect_return_btn.visible = false
	inspect_return_btn.pressed.connect(func(): _set_lobby_inspect(false))
	root.add_child(inspect_return_btn)

func _build_cctv_overlay(root: Control) -> void:
	cctv_panel = PanelContainer.new()
	cctv_panel.set_anchors_preset(Control.PRESET_CENTER)
	cctv_panel.offset_left = -380
	cctv_panel.offset_top = -210
	cctv_panel.offset_right = 380
	cctv_panel.offset_bottom = 170
	cctv_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.05, 0.08, 0.78), Color(0.15, 0.85, 0.95)))
	cctv_panel.visible = false
	root.add_child(cctv_panel)

	var vbox := VBoxContainer.new()
	cctv_panel.add_child(vbox)

	cctv_info_label = Label.new()
	cctv_info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cctv_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(cctv_info_label)

	var cam_btns := HBoxContainer.new()
	vbox.add_child(cam_btns)
	for i in range(1, 7):
		var cid := "CAM0%d" % i
		_add_action_btn(cam_btns, cid, func():
			GameState.current_cam = cid
			ProceduralAudio.play_switch(true)
			_refresh_ui()
		)
	_add_action_btn(cam_btns, "🥕 Бросить морковь", func(): GameState.throw_carrot_at_trojan())
	_add_action_btn(cam_btns, "▼ Закрыть [TAB]", func(): GameState.toggle_cctv())

func _build_puzzle_overlay(root: Control) -> void:
	puzzle_panel = PanelContainer.new()
	puzzle_panel.set_anchors_preset(Control.PRESET_CENTER)
	puzzle_panel.offset_left = -230
	puzzle_panel.offset_top = -190
	puzzle_panel.offset_right = 230
	puzzle_panel.offset_bottom = 190
	puzzle_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.07, 0.12, 0.96), Color(0.22, 0.88, 0.95)))
	puzzle_panel.visible = false
	root.add_child(puzzle_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	puzzle_panel.add_child(vbox)

	var title := Label.new()
	title.text = "🧩 CI/CD PIPELINE MAZE (+1🪙)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	puzzle_status_label = Label.new()
	puzzle_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	puzzle_status_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(puzzle_status_label)

	puzzle_grid_box = GridContainer.new()
	puzzle_grid_box.columns = 3
	puzzle_grid_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(puzzle_grid_box)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btns)
	_add_action_btn(btns, "🚀 ЗАПУСТИТЬ DEPLOY (+1🪙)", func():
		GameState.complete_pipeline_puzzle()
		_refresh_puzzle_grid()
	)
	_add_action_btn(btns, "Закрыть [P]", func(): _toggle_puzzle_modal())

func _build_end_modal(root: Control) -> void:
	end_modal = PanelContainer.new()
	end_modal.set_anchors_preset(Control.PRESET_CENTER)
	end_modal.offset_left = -280
	end_modal.offset_top = -130
	end_modal.offset_right = 280
	end_modal.offset_bottom = 130
	end_modal.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.03, 0.05, 0.96), Color(0.95, 0.25, 0.25)))
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

	_add_action_btn(vbox, "☀️ ВЕРНУТЬСЯ В ДНЕВНОЕ ЛОББИ", func():
		end_modal.visible = false
		GameState.return_to_lobby()
	)

func _set_lobby_inspect(inspect: bool) -> void:
	GameState.lobby_inspect_mode = inspect
	lobby_panel.visible = GameState.in_lobby and not inspect
	inspect_return_btn.visible = GameState.in_lobby and inspect

func _toggle_puzzle_modal() -> void:
	if GameState.in_lobby or GameState.game_over:
		return
	GameState.puzzle_modal_open = not GameState.puzzle_modal_open
	puzzle_panel.visible = GameState.puzzle_modal_open
	if GameState.puzzle_modal_open:
		_refresh_puzzle_grid()

func _refresh_puzzle_grid() -> void:
	for c in puzzle_grid_box.get_children():
		c.queue_free()
	var symbols := ["┗", "┏", "┓", "┛"]
	for i in range(GameState.pipe_grid.size()):
		var idx := i
		var tile: Dictionary = GameState.pipe_grid[i]
		var rot: int = int(tile["rot"])
		var b := Button.new()
		b.custom_minimum_size = Vector2(64, 52)
		b.text = "╋" if tile["type"] == "cross" else ("━" if (tile["type"] == "straight" and rot % 2 == 1) else ("┃" if tile["type"] == "straight" else symbols[rot % 4]))
		b.pressed.connect(func():
			GameState.rotate_pipe_tile(idx)
			_refresh_puzzle_grid()
		)
		puzzle_grid_box.add_child(b)

	puzzle_status_label.text = "✅ БИЛД НА ПРОДЕ! +1🪙 ПОЛУЧЕНА!" if GameState.puzzle_solved_this_shift else "Поверни трубы кликом и нажми ЗАПУСТИТЬ DEPLOY"

func _refresh_lobby_lists() -> void:
	for c in lobby_levels_grid.get_children():
		c.queue_free()
	for i in range(1, 7):
		var lvl := i
		var cfg: Dictionary = GameState.SHIFT_CONFIGS[i]
		var unlocked := (i <= GameState.max_unlocked_level)
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not unlocked
		b.text = "%s СМЕНА #%d\n%s" % ["🔓" if unlocked else "🔒", i, cfg["subtitle"]]
		b.pressed.connect(func(): GameState.start_shift_from_lobby(lvl))
		lobby_levels_grid.add_child(b)

	for c in lobby_shop_vbox.get_children():
		c.queue_free()
	var shop_items := [
		{"key": "antiTrojanOats", "title": "🥕 Анти-Троянский Овёс (1🪙)"},
		{"key": "titaniumFuse", "title": "⚡ Титановый Предохранитель (1🪙)"},
		{"key": "mirrorGlasses", "title": "🕶️ Зеркальные Очки (1🪙)"},
		{"key": "asbestosSeat", "title": "🛡️ Асбестовая Подушка (1🪙)"},
		{"key": "bugRepellent", "title": "🪰 Репеллент от Багов (1🪙)"}
	]
	for item in shop_items:
		var k: String = item["key"]
		var bought: bool = GameState.active_buffs.get(k, false)
		var b := Button.new()
		b.disabled = bought or GameState.coins < 1
		b.text = ("✅ " if bought else "🛒 ") + String(item["title"])
		b.pressed.connect(func():
			GameState.buy_buff(k)
			_refresh_lobby_lists()
		)
		lobby_shop_vbox.add_child(b)

func _refresh_ui() -> void:
	top_stats_label.text = "🕒 %s (Смена #%d)   |   🔋 ИБП: %d%%   |   🔥 Пукан: %d°C   |   🛠️ Хотфикс: %d%%   |   💀 Взломы: %d/5   |   🧪 Газ: %d%%   |   🐴 Троян: %dм (🥕%d)" % [
		GameState.get_formatted_clock(),
		GameState.current_level,
		int(ceil(GameState.power)),
		int(round(GameState.pukan_temp)),
		int(floor(GameState.patch_progress)),
		GameState.hack_count,
		int(round(GameState.gas_pressure)),
		int(round(GameState.trojan_distance)),
		GameState.carrots_count
	]

	if GameState.dip_puzzle_active:
		dip_status_label.text = "⚠️ ЦЕЛЬ SW: [%d %d %d %d] (%.1fc)" % [
			GameState.target_dip[0], GameState.target_dip[1], GameState.target_dip[2], GameState.target_dip[3], GameState.dip_timer
		]
	else:
		dip_status_label.text = "ЯДРО SW1-4: [%d %d %d %d] (ОК)" % [
			GameState.dip_switches[0], GameState.dip_switches[1], GameState.dip_switches[2], GameState.dip_switches[3]
		]

	var lines: Array[String] = []
	for e in GameState.event_log:
		var col := "#67e8f9"
		if e["level"] == "danger": col = "#f87171"
		elif e["level"] == "warn": col = "#fcd34d"
		elif e["level"] == "ok": col = "#34d399"
		lines.append("[color=%s][%s] %s[/color]" % [col, e["time"], e["msg"]])
	log_label.text = "\n".join(lines)

	lobby_coins_label.text = "🪙 Монеты: %d / %d" % [GameState.coins, GameState.max_coins]
	lobby_panel.visible = GameState.in_lobby and not GameState.lobby_inspect_mode
	inspect_return_btn.visible = GameState.in_lobby and GameState.lobby_inspect_mode

	cctv_panel.visible = GameState.cctv_open
	if GameState.cctv_open:
		cctv_info_label.text = "● REC [%s] — Сектор видеонаблюдения ЦОД\n👁️ Исказитель: %s\n🐴 Троянский конь (T-Pose): %dм до кабинета\n🩸 Бордовый Душегуб (вентиляция): стадия %d" % [
			GameState.current_cam,
			GameState.distortion_pos if GameState.distortion_active else "Чисто",
			int(round(GameState.trojan_distance)),
			GameState.burgundy_stage
		]

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
	_refresh_lobby_lists()
	_refresh_ui()

func _on_jumpscare_triggered(_m_type: String, title: String, desc: String) -> void:
	end_title_label.text = "💀 " + title
	end_desc_label.text = desc
	end_modal.visible = true

func _on_victory_triggered(lvl: int) -> void:
	end_title_label.text = "🎉 06:00 AM — СМЕНА #%d ПРОЙДЕНА!" % lvl
	end_desc_label.text = "Продакшен выжил до утра! Следующая смена разблокирована в Дневном Лобби!"
	end_modal.visible = true

extends CanvasLayer

var hp_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var currency_label: Label
var kill_label: Label
var round_label: Label
var timer_label: Label
var game_over_panel: Panel
var victory_panel: Panel
var level_intro_panel: Panel
var level_intro_label: Label
var stat_labels: Dictionary = {}

var boss_hp_bar: ProgressBar
var boss_container: VBoxContainer


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.xp_gained.connect(_on_xp_changed)
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.currency_collected.connect(_on_currency_changed)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.game_won.connect(_on_game_won)
	EventBus.boss_round_started.connect(_on_boss_round_started)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.round_ended.connect(_on_round_ended)
	EventBus.round_timer_tick.connect(_on_timer_tick)
	EventBus.level_changed.connect(_on_level_changed)
	EventBus.mutation_activated.connect(func(_id: String) -> void: _update_stats())
	EventBus.stats_changed.connect(_update_stats)


# ── Construir toda la UI ──────────────────────────────────────
func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ── Esquina superior izquierda: HP + XP ──
	var left_margin := MarginContainer.new()
	left_margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	left_margin.add_theme_constant_override("margin_left", 16)
	left_margin.add_theme_constant_override("margin_top", 16)
	left_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_margin.add_child(vbox)

	hp_bar = _make_bar(Color(0.85, 0.15, 0.15), Color(0.25, 0.05, 0.05, 0.8))
	var hp_row := _make_bar_row("♥ HP", hp_bar)
	vbox.add_child(hp_row)

	xp_bar = _make_bar(Color(0.2, 0.7, 1.0), Color(0.05, 0.15, 0.25, 0.8))
	var xp_row := _make_bar_row("★ XP", xp_bar)
	vbox.add_child(xp_row)

	# ── Centro superior: Timer de ronda ──
	var top_center := MarginContainer.new()
	top_center.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top_center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top_center.add_theme_constant_override("margin_top", 12)
	top_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_center)

	var timer_vbox := VBoxContainer.new()
	timer_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_center.add_child(timer_vbox)

	round_label = Label.new()
	round_label.text = "Ronda 1"
	round_label.add_theme_font_size_override("font_size", 16)
	round_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_vbox.add_child(round_label)

	timer_label = Label.new()
	timer_label.text = "1:00"
	timer_label.add_theme_font_size_override("font_size", 28)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_vbox.add_child(timer_label)

	boss_container = VBoxContainer.new()
	boss_container.alignment = BoxContainer.ALIGNMENT_CENTER
	boss_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_container.visible = false
	timer_vbox.add_child(boss_container)
	
	boss_hp_bar = _make_bar(Color(0.9, 0.2, 0.5), Color(0.2, 0.05, 0.1, 0.8))
	boss_hp_bar.custom_minimum_size = Vector2(400, 24)
	boss_container.add_child(boss_hp_bar)

	# ── Esquina superior derecha: Nivel, ADN, Kills, Stats ──
	var right_margin := MarginContainer.new()
	right_margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right_margin.add_theme_constant_override("margin_right", 16)
	right_margin.add_theme_constant_override("margin_top", 16)
	right_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(right_margin)

	var rvbox := VBoxContainer.new()
	rvbox.alignment = BoxContainer.ALIGNMENT_END
	rvbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_margin.add_child(rvbox)

	level_label = _make_label("Nv. 1", 22, Color(1.0, 0.9, 0.3))
	rvbox.add_child(level_label)

	currency_label = _make_label("🧬 0", 18, Color(0.4, 1.0, 0.6))
	rvbox.add_child(currency_label)

	kill_label = _make_label("💀 0", 16, Color(0.8, 0.8, 0.8))
	rvbox.add_child(kill_label)

	# Separador + panel de stats
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	rvbox.add_child(sep)

	_build_stats_panel(rvbox)

	# ── Game Over (oculto) ──
	game_over_panel = Panel.new()
	game_over_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var go_style = StyleBoxFlat.new()
	go_style.bg_color = Color(0.1, 0.0, 0.0, 0.8)
	game_over_panel.add_theme_stylebox_override("panel", go_style)
	game_over_panel.visible = false
	game_over_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(game_over_panel)
	
	var go_vbox = VBoxContainer.new()
	go_vbox.set_anchors_preset(Control.PRESET_CENTER)
	go_vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	go_vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	go_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	go_vbox.add_theme_constant_override("separation", 30)
	game_over_panel.add_child(go_vbox)
	
	var go_title = Label.new()
	go_title.text = "GAME OVER"
	go_title.add_theme_font_size_override("font_size", 72)
	go_title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(go_title)
	
	var go_btn_hbox = HBoxContainer.new()
	go_btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	go_btn_hbox.add_theme_constant_override("separation", 20)
	go_vbox.add_child(go_btn_hbox)
	
	var go_restart_btn = Button.new()
	go_restart_btn.text = "Reiniciar"
	go_restart_btn.custom_minimum_size = Vector2(150, 50)
	go_restart_btn.pressed.connect(func(): get_tree().paused = false; GameManager.reset(); get_tree().reload_current_scene())
	go_btn_hbox.add_child(go_restart_btn)
	
	var go_exit_btn = Button.new()
	go_exit_btn.text = "Salir"
	go_exit_btn.custom_minimum_size = Vector2(150, 50)
	go_exit_btn.pressed.connect(func(): get_tree().quit())
	go_btn_hbox.add_child(go_exit_btn)

	# ── Victoria (oculto) ──
	victory_panel = Panel.new()
	victory_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vic_style = StyleBoxFlat.new()
	vic_style.bg_color = Color(0, 0, 0, 0.9)
	victory_panel.add_theme_stylebox_override("panel", vic_style)
	victory_panel.visible = false
	victory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(victory_panel)
	
	var vic_vbox = VBoxContainer.new()
	vic_vbox.set_anchors_preset(Control.PRESET_CENTER)
	vic_vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vic_vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vic_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vic_vbox.add_theme_constant_override("separation", 30)
	victory_panel.add_child(vic_vbox)
	
	var vic_title = Label.new()
	vic_title.text = "¡VICTORIA!"
	vic_title.add_theme_font_size_override("font_size", 72)
	vic_title.add_theme_color_override("font_color", Color(1, 0.84, 0.0))
	vic_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vic_vbox.add_child(vic_title)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vic_vbox.add_child(btn_hbox)
	
	var restart_btn = Button.new()
	restart_btn.text = "Reiniciar"
	restart_btn.custom_minimum_size = Vector2(150, 50)
	restart_btn.pressed.connect(func(): get_tree().paused = false; GameManager.reset(); get_tree().reload_current_scene())
	btn_hbox.add_child(restart_btn)
	
	var exit_btn = Button.new()
	exit_btn.text = "Salir"
	exit_btn.custom_minimum_size = Vector2(150, 50)
	exit_btn.pressed.connect(func(): get_tree().quit())
	btn_hbox.add_child(exit_btn)

	# ── Nivel Intro (Fade-out) ──
	level_intro_panel = Panel.new()
	level_intro_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var intro_style := StyleBoxFlat.new()
	intro_style.bg_color = Color(0, 0, 0, 0.5)
	level_intro_panel.add_theme_stylebox_override("panel", intro_style)
	level_intro_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_intro_panel.modulate.a = 0.0 # Oculto por defecto
	root.add_child(level_intro_panel)
	
	level_intro_label = Label.new()
	level_intro_label.set_anchors_preset(Control.PRESET_CENTER)
	level_intro_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	level_intro_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	level_intro_label.add_theme_font_size_override("font_size", 52)
	level_intro_label.add_theme_color_override("font_color", Color.WHITE)
	level_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_intro_panel.add_child(level_intro_label)


# ── Helpers ────────────────────────────────────────────────────
func _make_bar(fill_color: Color, bg_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(200, 20)
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = bg_color
	bg_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill_style)
	return bar


func _make_bar_row(label_text: String, bar: ProgressBar) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.custom_minimum_size.x = 50
	row.add_child(lbl)
	row.add_child(bar)
	return row


func _make_label(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return lbl


# ── Callbacks ──────────────────────────────────────────────────
func _on_health_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current


func _on_xp_changed(_amount: int) -> void:
	xp_bar.max_value = GameManager.xp_to_next_level
	xp_bar.value = GameManager.player_xp


func _on_level_up(new_level: int) -> void:
	level_label.text = "Nv. %d" % new_level
	xp_bar.max_value = GameManager.xp_to_next_level
	xp_bar.value = GameManager.player_xp
	level_label.modulate = Color(1.0, 1.0, 0.5)
	var tw := create_tween()
	tw.tween_property(level_label, "modulate", Color.WHITE, 0.5)
	_update_stats()


func _on_currency_changed(_amount: int) -> void:
	currency_label.text = "🧬 %d" % GameManager.total_currency


func _on_enemy_killed(_pos: Vector2, _xp: int) -> void:
	kill_label.text = "💀 %d" % GameManager.total_kills


func _on_timer_tick(seconds_left: int) -> void:
	var mins := seconds_left / 60
	var secs := seconds_left % 60
	timer_label.text = "%d:%02d" % [mins, secs]
	# Rojo cuando queda poco
	if seconds_left <= 10:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)
		
	var level_name: String = GameManager.LEVELS[GameManager.current_level_index]
	var round_num: int = GameManager.current_round_in_level
	if round_num == 5:
		timer_label.text = ""
		round_label.text = "%s - %s" % [level_name, GameManager.BOSS_NAMES[GameManager.current_level_index]]
	else:
		round_label.text = "%s - Ronda %d" % [level_name, round_num]


func _on_player_died() -> void:
	game_over_panel.visible = true
	var tw = create_tween()
	game_over_panel.modulate.a = 0.0
	tw.tween_property(game_over_panel, "modulate:a", 1.0, 1.0)


func _on_game_won() -> void:
	victory_panel.visible = true
	var tw = create_tween()
	victory_panel.modulate.a = 0.0
	tw.tween_property(victory_panel, "modulate:a", 1.0, 1.0)


func _on_boss_round_started(boss_name: String) -> void:
	level_intro_label.text = boss_name
	level_intro_panel.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(level_intro_panel, "modulate:a", 0.0, 2.0)

func _on_boss_spawned(max_hp: float) -> void:
	boss_container.visible = true
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = max_hp

func _on_boss_health_changed(current: float, maximum: float) -> void:
	boss_hp_bar.max_value = maximum
	boss_hp_bar.value = current

func _on_boss_defeated() -> void:
	boss_container.visible = false

func _on_round_ended(_wave: int) -> void:
	boss_container.visible = false


func _on_level_changed(level_index: int, level_name: String) -> void:
	level_intro_label.text = level_name.to_upper()
	level_intro_panel.modulate.a = 1.0
	
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(level_intro_panel, "modulate:a", 0.0, 2.0)


# ── Panel de estadísticas ──────────────────────────────────────
func _build_stats_panel(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.8)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var stats_vbox := VBoxContainer.new()
	panel.add_child(stats_vbox)

	var title := Label.new()
	title.text = "ESTADÍSTICAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	stats_vbox.add_child(title)

	var sep2 := HSeparator.new()
	stats_vbox.add_child(sep2)

	var stats_info: Array = [
		["max_hp",       "❤️ HP Máx",     Color(1.0, 0.5, 0.5)],
		["attack",       "⚔️ Ataque",     Color(1.0, 0.7, 0.3)],
		["defense",      "🛡️ Defensa",    Color(0.5, 0.7, 1.0)],
		["attack_speed", "⚡ Vel.Ataque",  Color(1.0, 1.0, 0.4)],
		["move_speed",   "🏃 Vel.Movim.", Color(0.4, 1.0, 0.6)],
		["life_steal",   "🩸 Robo vida",  Color(0.9, 0.3, 0.3)],
		["luck",         "🍀 Suerte",     Color(0.3, 1.0, 0.5)],
	]
	for info in stats_info:
		var stat_name: String = info[0]
		var display_name: String = info[1]
		var color: Color = info[2]
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", color)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stat_labels[stat_name] = {"label": lbl, "display_name": display_name}
		stats_vbox.add_child(lbl)
	_update_stats()


func _update_stats() -> void:
	for stat_name in stat_labels:
		var info: Dictionary = stat_labels[stat_name]
		var val: float = GameManager.get_stat(stat_name)
		var lbl: Label = info.label
		if stat_name == "life_steal":
			lbl.text = "%s: %d%%" % [info.display_name, int(val * 100)]
		elif stat_name == "attack_speed":
			lbl.text = "%s: %.2f" % [info.display_name, val]
		else:
			lbl.text = "%s: %d" % [info.display_name, int(val)]

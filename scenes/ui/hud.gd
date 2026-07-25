extends CanvasLayer

var hp_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var currency_label: Label
var kill_label: Label
var game_over_label: Label
var stat_labels: Dictionary = {}  # stat_name -> Label


func _ready() -> void:
	layer = 10
	_build_ui()
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.xp_collected.connect(_on_xp_changed)
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.currency_collected.connect(_on_currency_changed)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.mutation_activated.connect(func(_id: String) -> void: _update_stats())


# ── Construir toda la UI ──
func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# HP y XP
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

	# barra HP
	hp_bar = _make_bar(Color(0.85, 0.15, 0.15), Color(0.25, 0.05, 0.05, 0.8))
	var hp_row := _make_bar_row("♥ HP", hp_bar)
	vbox.add_child(hp_row)

	# barra XP
	xp_bar = _make_bar(Color(0.2, 0.7, 1.0), Color(0.05, 0.15, 0.25, 0.8))
	var xp_row := _make_bar_row("★ XP", xp_bar)
	vbox.add_child(xp_row)

	# Lvl, dinero y nº kills
	var right_margin := MarginContainer.new()
	right_margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN  # <--- ESTO EVITA QUE SALGA FUERA DE LA PANTALLA
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

	# Separador
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	rvbox.add_child(sep)

	# Panel de estadísticas
	_build_stats_panel(rvbox)

	# ── Game Over (oculto) ──
	game_over_label = Label.new()
	game_over_label.text = "GAME OVER"
	game_over_label.add_theme_font_size_override("font_size", 64)
	game_over_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.set_anchors_preset(Control.PRESET_CENTER)
	game_over_label.visible = false
	root.add_child(game_over_label)


# Metodos auxiliares
func _make_bar(fill_color: Color, bg_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(200, 20)
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = bg_color
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
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


func _on_currency_changed(_amount: int) -> void:
	currency_label.text = "🧬 %d" % GameManager.total_currency


func _on_enemy_killed(_pos: Vector2, _xp: int) -> void:
	kill_label.text = "💀 %d" % GameManager.total_kills


func _on_player_died() -> void:
	game_over_label.visible = true


func _build_stats_panel(parent: VBoxContainer) -> void:
	# Añadimos un fondo oscuro para que resalte mucho más
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

	var sep := HSeparator.new()
	stats_vbox.add_child(sep)

	var stats_info: Array = [
		["max_hp",       "❤️ HP Máx",     Color(1.0, 0.5, 0.5)],
		["attack",       "⚔️ Ataque",     Color(1.0, 0.7, 0.3)],
		["defense",      "🛡️ Defensa",    Color(0.5, 0.7, 1.0)],
		["attack_speed", "⚡ Vel.Ataque",  Color(1.0, 1.0, 0.4)],
		["move_speed",   "🏃 Vel.Movim.", Color(0.4, 1.0, 0.6)],
		["life_steal",   "🩸 Robo vida",  Color(0.9, 0.3, 0.3)],
		["crit_chance",  "💥 Prob.Crit.", Color(1.0, 0.6, 0.1)],
		["luck",         "🍀 Suerte",     Color(0.3, 1.0, 0.5)],
	]
	for info in stats_info:
		var stat_name: String = info[0]
		var display_name: String = info[1]
		var color: Color = info[2]
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 16) # Letra más grande
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
		# Porcentajes para crit y life steal
		if stat_name in ["crit_chance", "life_steal"]:
			lbl.text = "%s: %d%%" % [info.display_name, int(val * 100)]
		else:
			lbl.text = "%s: %d" % [info.display_name, int(val)]

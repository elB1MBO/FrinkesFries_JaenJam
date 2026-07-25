extends CanvasLayer

var hp_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var currency_label: Label
var kill_label: Label
var game_over_label: Label


func _ready() -> void:
	layer = 10
	_build_ui()
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.xp_collected.connect(_on_xp_changed)
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.currency_collected.connect(_on_currency_changed)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_died.connect(_on_player_died)


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

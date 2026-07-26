extends CanvasLayer
## Pantalla de subida de nivel — elige una estadística a mejorar.

var _root: Control
var _overlay: ColorRect
var _title: Label
var _subtitle: Label
var _cards_container: HBoxContainer
var _current_choices: Array = []

const STAT_UPGRADES: Array = [
	{"stat": "max_hp",       "display": "+10 HP Máx",         "flat": 10.0,  "percent": 0.0,  "color": Color(1.0, 0.5, 0.5)},
	{"stat": "attack",       "display": "+3 Ataque",          "flat": 3.0,   "percent": 0.0,  "color": Color(1.0, 0.7, 0.3)},
	{"stat": "defense",      "display": "+2 Defensa",         "flat": 2.0,   "percent": 0.0,  "color": Color(0.5, 0.7, 1.0)},
	{"stat": "attack_speed", "display": "+10% Vel. Ataque",   "flat": 0.0,   "percent": 0.10, "color": Color(1.0, 1.0, 0.4)},
	{"stat": "move_speed",   "display": "+5% Vel. Movim.",    "flat": 0.0,   "percent": 0.05, "color": Color(0.4, 1.0, 0.6)},
	{"stat": "luck",         "display": "+5 Suerte",          "flat": 5.0,   "percent": 0.0,  "color": Color(0.3, 1.0, 0.5)},
]


func _ready() -> void:
	_build_ui()
	_hide_screen()
	EventBus.player_leveled_up.connect(_on_player_leveled_up)


# ── Construcción de la UI ──────────────────────────────────────
func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.05, 0.8)
	_root.add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	_title = Label.new()
	_title.text = "¡NIVEL 2!"
	_title.add_theme_font_size_override("font_size", 52)
	_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title)

	_subtitle = Label.new()
	_subtitle.text = "Elige una mejora"
	_subtitle.add_theme_font_size_override("font_size", 18)
	_subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_subtitle)

	_cards_container = HBoxContainer.new()
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", 24)
	_cards_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_cards_container)


func _show_screen() -> void:
	_root.visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP

func _hide_screen() -> void:
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ── Al subir de nivel ──────────────────────────────────────────
func _on_player_leveled_up(new_level: int) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_title.text = "¡NIVEL %d!" % new_level

	# Elegir 3 stats aleatorias (sin repetir)
	var pool := STAT_UPGRADES.duplicate()
	pool.shuffle()
	_current_choices = pool.slice(0, mini(3, pool.size()))

	_build_cards()
	_show_screen()
	get_tree().paused = true


# ── Generar cartas de stats ────────────────────────────────────
func _build_cards() -> void:
	for child in _cards_container.get_children():
		child.queue_free()

	for upgrade in _current_choices:
		var card := _create_stat_card(upgrade)
		_cards_container.add_child(card)


func _create_stat_card(upgrade: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 220)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.16, 0.95)
	style.border_color = upgrade.color
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# Icono (cuadrado de color)
	var icon_c := CenterContainer.new()
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.color = upgrade.color
	icon_c.add_child(icon)
	vbox.add_child(icon_c)

	# Texto de la mejora
	var name_lbl := Label.new()
	name_lbl.text = upgrade.display
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", upgrade.color)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.custom_minimum_size.x = 160
	vbox.add_child(name_lbl)

	# Valor actual
	var current_val := GameManager.get_stat(upgrade.stat)
	var current_lbl := Label.new()
	if upgrade.stat == "life_steal":
		current_lbl.text = "Actual: %d%%" % int(current_val * 100)
	else:
		current_lbl.text = "Actual: %d" % int(current_val)
	current_lbl.add_theme_font_size_override("font_size", 14)
	current_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	current_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(current_lbl)

	# Interacción
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_card_input.bind(upgrade, style))

	var base_color: Color = upgrade.color
	panel.mouse_entered.connect(func() -> void:
		style.border_color = base_color.lightened(0.4)
		style.set_border_width_all(4)
	)
	panel.mouse_exited.connect(func() -> void:
		style.border_color = base_color
		style.set_border_width_all(3)
	)

	return panel


func _on_card_input(event: InputEvent, upgrade: Dictionary, _style: StyleBoxFlat) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_stat(upgrade)


func _select_stat(upgrade: Dictionary) -> void:
	var source := "levelup_%d_%s" % [GameManager.player_level, upgrade.stat]
	GameManager.add_modifier(upgrade.stat, source, upgrade.get("flat", 0.0), upgrade.get("percent", 0.0))
	_hide_screen()
	get_tree().paused = false

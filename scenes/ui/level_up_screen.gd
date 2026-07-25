extends CanvasLayer
## Pantalla de selección de mutaciones al subir de nivel.
## Pausa el juego y muestra 3 cartas con mutaciones aleatorias.

var _root: Control
var _overlay: ColorRect
var _title: Label
var _subtitle: Label
var _cards_container: HBoxContainer
var _current_choices: Array = []


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

	# Fondo oscuro
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.05, 0.8)
	_root.add_child(_overlay)

	# Contenedor centrado
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	# Título
	_title = Label.new()
	_title.text = "¡MUTACIÓN!"
	_title.add_theme_font_size_override("font_size", 52)
	_title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title)

	# Subtítulo
	_subtitle = Label.new()
	_subtitle.text = "Elige una mejora para tu virus"
	_subtitle.add_theme_font_size_override("font_size", 18)
	_subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_subtitle)

	# Contenedor de cartas
	_cards_container = HBoxContainer.new()
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", 24)
	_cards_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_cards_container)


# ── Mostrar / Ocultar ─────────────────────────────────────────
func _show_screen() -> void:
	_root.visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP

func _hide_screen() -> void:
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ── Al subir de nivel ──────────────────────────────────────────
func _on_player_leveled_up(_new_level: int) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	# Filtrar mutaciones ya adquiridas
	var pool: Array = []
	for id in MutationDefs.MUTATIONS.keys():
		if id not in GameManager.active_mutations:
			pool.append(id)

	if pool.is_empty():
		return

	pool.shuffle()
	_current_choices = pool.slice(0, mini(3, pool.size()))
	_build_cards()
	_show_screen()
	get_tree().paused = true


# ── Generar cartas ─────────────────────────────────────────────
func _build_cards() -> void:
	for child in _cards_container.get_children():
		child.queue_free()

	for mutation_id in _current_choices:
		var data: Dictionary = MutationDefs.MUTATIONS[mutation_id]
		var card := _create_card(mutation_id, data)
		_cards_container.add_child(card)


func _create_card(mutation_id: String, data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 300)

	# Estilo base
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.16, 0.95)
	style.border_color = data.color
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)

	# Contenido
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Icono placeholder (círculo de color)
	var icon_container := CenterContainer.new()
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(50, 50)
	icon.color = data.color
	icon_container.add_child(icon)
	vbox.add_child(icon_container)

	# Nombre
	var name_lbl := Label.new()
	name_lbl.text = data.name
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", data.color)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_lbl)

	# Rareza
	var rarity_lbl := Label.new()
	rarity_lbl.text = MutationDefs.get_rarity_name(data.rarity)
	rarity_lbl.add_theme_font_size_override("font_size", 13)
	rarity_lbl.add_theme_color_override("font_color", MutationDefs.get_rarity_color(data.rarity))
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_lbl)

	# Descripción
	var desc_lbl := Label.new()
	desc_lbl.text = data.description
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.custom_minimum_size.x = 190
	vbox.add_child(desc_lbl)

	# Interacción — click en toda la carta
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_card_input.bind(mutation_id, panel, style))

	# Hover — brillo en el borde
	var base_border_color: Color = data.color
	panel.mouse_entered.connect(func() -> void:
		style.border_color = base_border_color.lightened(0.4)
		style.set_border_width_all(4)
	)
	panel.mouse_exited.connect(func() -> void:
		style.border_color = base_border_color
		style.set_border_width_all(3)
	)

	return panel


# ── Selección ──────────────────────────────────────────────────
func _on_card_input(event: InputEvent, mutation_id: String, _panel: PanelContainer, _style: StyleBoxFlat) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_mutation(mutation_id)


func _select_mutation(mutation_id: String) -> void:
	GameManager.activate_mutation(mutation_id)
	_hide_screen()
	get_tree().paused = false

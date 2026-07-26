extends CanvasLayer
## Tienda de mutaciones estilo Balatro — aparece al final de cada ronda.

var _root: Control
var _title: Label
var _subtitle: Label
var _currency_label: Label
var _cards_container: HBoxContainer
var _reroll_btn: Button
var _continue_btn: Button
var _current_offers: Array = []


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_hide_screen()
	EventBus.round_ended.connect(_on_round_ended)


# ── UI ─────────────────────────────────────────────────────────
func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# Fondo
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.0, 0.06, 0.85)
	_root.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var main_vbox := VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 20)
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(main_vbox)

	# Título
	_title = Label.new()
	_title.text = "TIENDA DE MUTACIONES"
	_title.add_theme_font_size_override("font_size", 42)
	_title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_title)

	# Subtítulo
	_subtitle = Label.new()
	_subtitle.add_theme_font_size_override("font_size", 18)
	_subtitle.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_subtitle)

	# ADN disponible
	_currency_label = Label.new()
	_currency_label.add_theme_font_size_override("font_size", 24)
	_currency_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	_currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_currency_label)

	# Cartas de mutaciones
	_cards_container = HBoxContainer.new()
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", 20)
	_cards_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(_cards_container)

	# Botones inferiores
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 30)
	main_vbox.add_child(btn_row)

	_reroll_btn = _make_button("🔄 Re-roll (10 ADN)", Color(0.8, 0.6, 0.2))
	_reroll_btn.pressed.connect(_on_reroll)
	btn_row.add_child(_reroll_btn)

	_continue_btn = _make_button("Continuar →", Color(0.3, 0.8, 0.4))
	_continue_btn.pressed.connect(_on_continue)
	btn_row.add_child(_continue_btn)


func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(180, 45)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = color.darkened(0.6)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 16)
	return btn


func _show_screen() -> void:
	_root.visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP

func _hide_screen() -> void:
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ── Apertura de tienda ─────────────────────────────────────────
func _on_round_ended(round_number: int) -> void:
	_subtitle.text = "Ronda %d completada" % round_number
	GameManager.reset_reroll_cost()
	_update_currency()
	_roll_offers()
	_show_screen()
	get_tree().paused = true


func _update_currency() -> void:
	_currency_label.text = "🧬 %d ADN" % GameManager.total_currency
	_reroll_btn.text = "🔄 Re-roll (%d ADN)" % GameManager.reroll_cost
	# Deshabilitar re-roll si no hay pasta
	_reroll_btn.disabled = GameManager.total_currency < GameManager.reroll_cost


func _roll_offers() -> void:
	# Filtrar mutaciones ya adquiridas
	var pool: Array = []
	for id in MutationDefs.MUTATIONS.keys():
		if id not in GameManager.active_mutations:
			pool.append(id)

	pool.shuffle()
	_current_offers = pool.slice(0, mini(3, pool.size()))
	_build_cards()


func _build_cards() -> void:
	for child in _cards_container.get_children():
		child.queue_free()

	if _current_offers.is_empty():
		var lbl := Label.new()
		lbl.text = "¡Todas las mutaciones adquiridas!"
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_cards_container.add_child(lbl)
		return

	for mutation_id in _current_offers:
		var data: Dictionary = MutationDefs.MUTATIONS[mutation_id]
		var card := _create_shop_card(mutation_id, data)
		_cards_container.add_child(card)


func _create_shop_card(mutation_id: String, data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 310)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.16, 0.95)
	style.border_color = data.color
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Icono
	var icon_c := CenterContainer.new()
	if data.has("icon_path") and ResourceLoader.exists(data.icon_path):
		var icon := TextureRect.new()
		icon.texture = load(data.icon_path)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(45, 45)
		icon_c.add_child(icon)
	else:
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(45, 45)
		icon.color = data.color
		icon_c.add_child(icon)
	vbox.add_child(icon_c)

	# Nombre
	var name_lbl := Label.new()
	name_lbl.text = data.name
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.add_theme_color_override("font_color", data.color)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_lbl)

	# Rareza (Reemplazado por Flavor Text)
	var flavor_lbl := Label.new()
	flavor_lbl.text = data.get("flavor", "\"Lorem ipsum dolor sit amet...\"")
	flavor_lbl.add_theme_font_size_override("font_size", 12)
	flavor_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.8))
	flavor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	flavor_lbl.custom_minimum_size.x = 180
	vbox.add_child(flavor_lbl)

	# Descripción
	var desc_lbl := Label.new()
	desc_lbl.text = data.description
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.custom_minimum_size.x = 180
	vbox.add_child(desc_lbl)

	# Precio
	var price: int = data.get("price", 50)
	var price_lbl := Label.new()
	price_lbl.text = "🧬 %d ADN" % price
	price_lbl.add_theme_font_size_override("font_size", 18)
	var can_afford := GameManager.total_currency >= price
	price_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5) if can_afford else Color(0.6, 0.3, 0.3))
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(price_lbl)

	# Interacción
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_shop_card_input.bind(mutation_id, price, panel, style))

	var base_color: Color = data.color
	panel.mouse_entered.connect(func() -> void:
		style.border_color = base_color.lightened(0.4)
		style.set_border_width_all(4)
	)
	panel.mouse_exited.connect(func() -> void:
		style.border_color = base_color
		style.set_border_width_all(3)
	)

	return panel


# ── Acciones ───────────────────────────────────────────────────
func _on_shop_card_input(event: InputEvent, mutation_id: String, price: int, panel: PanelContainer, _style: StyleBoxFlat) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if GameManager.spend_currency(price):
			GameManager.activate_mutation(mutation_id)
			# Quitar carta comprada con animación
			panel.modulate = Color(0.5, 1.0, 0.5, 0.5)
			var tw := create_tween()
			tw.tween_property(panel, "modulate:a", 0.0, 0.3)
			tw.tween_callback(func() -> void:
				_current_offers.erase(mutation_id)
				_build_cards()
			)
			_update_currency()


func _on_reroll() -> void:
	if GameManager.spend_currency(GameManager.reroll_cost):
		GameManager.increment_reroll_cost()
		_roll_offers()
		_update_currency()


func _on_continue() -> void:
	_hide_screen()
	get_tree().paused = false
	EventBus.shop_closed.emit()

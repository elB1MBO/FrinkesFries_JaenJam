extends Control

@onready var options_panel: ColorRect = $OptionsPanel
@onready var music_slider: HSlider = $OptionsPanel/VBox/MusicSlider
@onready var sfx_slider: HSlider = $OptionsPanel/VBox/SFXSlider

func _ready() -> void:
	$VBoxContainer/BtnPlay.pressed.connect(_on_play_pressed)
	$VBoxContainer/BtnOptions.pressed.connect(_on_options_pressed)
	$VBoxContainer/BtnQuit.pressed.connect(_on_quit_pressed)
	$OptionsPanel/VBox/BtnCloseOptions.pressed.connect(_on_close_options_pressed)
	
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	# Asegurarnos de que existan los buses (si no, usamos Master por ahora)
	_setup_buses()

func _setup_buses() -> void:
	# Inicializar los sliders con los valores actuales (por defecto a mitad de volumen)
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	
	if music_bus != -1:
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus))
	if sfx_bus != -1:
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus))

func _on_options_pressed() -> void:
	options_panel.visible = true

func _on_close_options_pressed() -> void:
	options_panel.visible = false

func _on_music_changed(value: float) -> void:
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
	else:
		# Fallback a Master si Music no existe aún
		AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_sfx_changed(value: float) -> void:
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/intro_screen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

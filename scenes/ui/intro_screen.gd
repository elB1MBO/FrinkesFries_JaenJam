extends Control

@onready var label: Label = $Label

var phrases = [
	"La vacuna me ha dolido un poco...",
	"Pero bueno, no creo que me ponga muy enferma,\nhe ido a unos médicos de confianza...",
	"¿Verdad?"
]

var current_phrase_index = 0
var _is_skipping = false

func _ready() -> void:
	label.modulate.a = 0.0
	_play_next_phrase()

func _input(event: InputEvent) -> void:
	if _is_skipping: return
	if event is InputEventMouseButton and event.pressed:
		_finish_intro()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
		_finish_intro()

func _play_next_phrase() -> void:
	if current_phrase_index >= phrases.size():
		_finish_intro()
		return
		
	label.text = phrases[current_phrase_index]
	
	var tw = create_tween()
	# Fade in
	tw.tween_property(label, "modulate:a", 1.0, 1.5)
	# Wait
	var read_time = 3.5
	if current_phrase_index == 2: read_time = 2.0
	tw.tween_interval(read_time)
	# Fade out
	tw.tween_property(label, "modulate:a", 0.0, 1.5)
	
	tw.finished.connect(func():
		current_phrase_index += 1
		_play_next_phrase()
	)

func _finish_intro() -> void:
	if _is_skipping: return
	_is_skipping = true
	
	# En caso de que GameManager se haya quedado en Game Over, lo limpiamos
	if GameManager.current_state == GameManager.GameState.GAME_OVER:
		GameManager.current_state = GameManager.GameState.MENU
		
	# Limpiar variables en GameManager para una nueva partida
	GameManager.player_level = 1
	GameManager.player_xp = 0
	GameManager.total_currency = 0
	GameManager.current_wave = 0
	GameManager.current_level_index = 0
	GameManager.active_mutations.clear()
	GameManager.reset_reroll_cost()
	
	# Asegurarnos de que el timescale esté a 1
	Engine.time_scale = 1.0
	get_tree().paused = false
	
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

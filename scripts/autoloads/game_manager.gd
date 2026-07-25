extends Node
## Estado global del juego: XP, niveles, moneda, game over.

enum GameState { PLAYING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.PLAYING
var current_wave: int = 1
var total_kills: int = 0
var total_currency: int = 0
var player_level: int = 1
var player_xp: int = 0
var xp_to_next_level: int = 10


func _ready() -> void:
	_setup_input_actions()
	EventBus.xp_collected.connect(_on_xp_collected)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.currency_collected.connect(_on_currency_collected)
	EventBus.player_died.connect(_on_player_died)


func reset() -> void:
	current_state = GameState.PLAYING
	current_wave = 1
	total_kills = 0
	total_currency = 0
	player_level = 1
	player_xp = 0
	xp_to_next_level = 10


# ── XP y Level Up ──
func _on_xp_collected(amount: int) -> void:
	player_xp += amount
	while player_xp >= xp_to_next_level:
		player_xp -= xp_to_next_level
		player_level += 1
		xp_to_next_level = _calc_xp_threshold(player_level)
		EventBus.player_leveled_up.emit(player_level)


func _calc_xp_threshold(level: int) -> int:
	# 10, 15, 20, 25 … escala suave
	return 10 + (level - 1) * 5


# ── Kills y dinero ──
func _on_enemy_killed(_pos: Vector2, _xp: int) -> void:
	total_kills += 1


func _on_currency_collected(amount: int) -> void:
	total_currency += amount


# ── Game Over ──
func _on_player_died() -> void:
	current_state = GameState.GAME_OVER
	get_tree().paused = true


# ── Input Map (se puede hacer en el project.godot, pero si funciona asi lo podemos dejar) ──
func _setup_input_actions() -> void:
	_add_action("move_left",  [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_up",    [KEY_W, KEY_UP])
	_add_action("move_down",  [KEY_S, KEY_DOWN])


func _add_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		for key in keys:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action_name, ev)

extends Node
## Estado global del juego: stats, XP, niveles, moneda, mutaciones.

enum GameState { PLAYING, PAUSED, GAME_OVER }

# ── Estado de partida ──────────────────────────────────────────
var current_state: GameState = GameState.PLAYING
var current_wave: int = 1
var total_kills: int = 0
var total_currency: int = 0
var player_level: int = 1
var player_xp: int = 0
var xp_to_next_level: int = 10

# Arena
const ARENA_HALF_SIZE: float = 600.0

# ── Stats base del jugador ─────────────────────────────────────
var base_stats: Dictionary = {
	"max_hp": 100.0,
	"attack": 10.0,
	"defense": 2.0,
	"attack_speed": 2.5,
	"move_speed": 200.0,
	"life_steal": 0.0,
	"crit_chance": 0.0,
	"luck": 0.0,
}

# Modificadores apilables: stat_name -> Array[{source, flat, percent}]
var _modifiers: Dictionary = {}

# ── Mutaciones activas ─────────────────────────────────────────
var active_mutations: Array = []


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
	_modifiers.clear()
	active_mutations.clear()


# ── Sistema de Stats ───────────────────────────────────────────
func get_stat(stat_name: String) -> float:
	var base: float = base_stats.get(stat_name, 0.0)
	var flat_total := 0.0
	var pct_total := 0.0
	for mod in _modifiers.get(stat_name, []):
		flat_total += mod.get("flat", 0.0)
		pct_total += mod.get("percent", 0.0)
	return (base + flat_total) * (1.0 + pct_total)


func add_modifier(stat_name: String, source: String, flat: float = 0.0, percent: float = 0.0) -> void:
	if stat_name not in _modifiers:
		_modifiers[stat_name] = []
	_modifiers[stat_name].append({"source": source, "flat": flat, "percent": percent})


func remove_modifiers_by_source(source: String) -> void:
	for stat_name in _modifiers:
		_modifiers[stat_name] = _modifiers[stat_name].filter(
			func(m: Dictionary) -> bool: return m.get("source", "") != source
		)


# ── Mutaciones ─────────────────────────────────────────────────
func activate_mutation(mutation_id: String) -> void:
	if mutation_id in active_mutations:
		return
	active_mutations.append(mutation_id)

	# Aplicar modificadores de stats pasivos
	match mutation_id:
		"reinforced_membrane":
			add_modifier("max_hp", "reinforced_membrane", 0.0, 0.25)

	EventBus.mutation_activated.emit(mutation_id)


func has_mutation(mutation_id: String) -> bool:
	return mutation_id in active_mutations


# ── XP & Level Up ──────────────────────────────────────────────
func _on_xp_collected(amount: int) -> void:
	player_xp += amount
	while player_xp >= xp_to_next_level:
		player_xp -= xp_to_next_level
		player_level += 1
		xp_to_next_level = _calc_xp_threshold(player_level)
		EventBus.player_leveled_up.emit(player_level)


func _calc_xp_threshold(level: int) -> int:
	# Coste x3: 30, 45, 67, 101, 151, 227...
	return int(floor(30.0 * pow(1.5, level - 1)))


# ── Kills & Currency ───────────────────────────────────────────
func _on_enemy_killed(_pos: Vector2, _xp: int) -> void:
	total_kills += 1


func _on_currency_collected(amount: int) -> void:
	total_currency += amount


# ── Game Over ──────────────────────────────────────────────────
func _on_player_died() -> void:
	current_state = GameState.GAME_OVER
	get_tree().paused = true


# ── Input Map ──────────────────────────────────────────────────
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

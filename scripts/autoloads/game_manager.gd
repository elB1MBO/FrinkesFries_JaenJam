extends Node
## Estado global del juego: stats, XP, niveles, moneda, mutaciones, rondas.

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, SHOPPING, VICTORY }

# ── Estado de partida ──────────────────────────────────────────
var current_state: GameState = GameState.PLAYING
var current_wave: int = 1

const LEVELS: Array = ["Pulmones", "Cerebro", "Corazón"]
const BOSS_NAMES: Array = ["John Rapamune", "Levetiracetam", "Corazón, Señor del Poder y de la Amistad"]
var current_level_index: int = 0
var current_round_in_level: int = 1

var total_kills: int = 0
var total_currency: int = 0
var player_level: int = 1
var player_xp: int = 0
var xp_to_next_level: int = 30

# Arena
const ARENA_HALF_SIZE: float = 600.0

# Tienda
var reroll_cost: int = 25
var _reroll_base: int = 25
var _reroll_increment: int = 25

# ── Stats base del jugador ─────────────────────────────────────
var base_stats: Dictionary = {
	"max_hp": 100.0,
	"attack": 10.0,
	"defense": 1.0,
	"attack_speed": 2.0,
	"move_speed": 200.0,
	"life_steal": 0.0,
	"luck": 0.0,
}

# Modificadores apilables: stat_name -> Array[{source, flat, percent}]
var _modifiers: Dictionary = {}

# ── Mutaciones activas ─────────────────────────────────────────
var active_mutations: Array = []


func _ready() -> void:
	_setup_input_actions()
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.currency_collected.connect(_on_currency_collected)
	EventBus.player_died.connect(_on_player_died)


func reset() -> void:
	current_state = GameState.PLAYING
	current_wave = 1
	current_level_index = 0
	current_round_in_level = 1
	total_kills = 0
	total_currency = 0
	player_level = 1
	player_xp = 0
	xp_to_next_level = 30
	reroll_cost = _reroll_base
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
	EventBus.stats_changed.emit()


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

	match mutation_id:
		"creatina_illo":
			add_modifier("max_hp", mutation_id, 0.0, 0.25)
		"proteina_wey":
			add_modifier("attack", mutation_id, 15.0, 0.0)
		"cellular_vampirism":
			add_modifier("life_steal", mutation_id, 0.05, 0.0)
		"opportunistic_infection":
			add_modifier("luck", mutation_id, 20.0, 0.0)
		"reinforced_membrane":
			add_modifier("max_hp", "reinforced_membrane", 0.0, 0.25)
		"minor_health":
			add_modifier("max_hp", mutation_id, 0.0, 0.05)
		"minor_attack":
			add_modifier("attack", mutation_id, 0.0, 0.05)
		"minor_speed":
			add_modifier("move_speed", mutation_id, 0.0, 0.10)
		"minor_atk_speed":
			add_modifier("attack_speed", mutation_id, 0.0, 0.10)
		"minor_defense":
			add_modifier("defense", mutation_id, 1.0, 0.0)

	EventBus.mutation_activated.emit(mutation_id)


func has_mutation(mutation_id: String) -> bool:
	return mutation_id in active_mutations


# ── Moneda (ADN) ───────────────────────────────────────────────
func spend_currency(amount: int) -> bool:
	if total_currency >= amount:
		total_currency -= amount
		return true
	return false


func reset_reroll_cost() -> void:
	reroll_cost = _reroll_base


func increment_reroll_cost() -> void:
	reroll_cost += _reroll_increment


# ── XP & Level Up (automática al matar) ───────────────────────
func _on_xp_gained(amount: int) -> void:
	if has_mutation("proteina_wey"):
		amount = int(amount * 1.5)
	
	player_xp += amount
	while player_xp >= xp_to_next_level:
		player_xp -= xp_to_next_level
		player_level += 1
		xp_to_next_level = _calc_xp_threshold(player_level)
		EventBus.player_leveled_up.emit(player_level)


func _calc_xp_threshold(level: int) -> int:
	return int(floor(30.0 * pow(2, level - 1)))


# ── Kills & Currency ───────────────────────────────────────────
func _on_enemy_killed(_pos: Vector2, _xp: int) -> void:
	total_kills += 1


func _on_currency_collected(amount: int) -> void:
	var luck := get_stat("luck")
	if luck > 0.0 and randf() < (luck / 100.0):
		amount *= 2
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

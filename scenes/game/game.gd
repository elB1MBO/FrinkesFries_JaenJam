extends Node2D

var arena_half_size: float = GameManager.ARENA_HALF_SIZE

# Escenas de enemigos
var base_enemy_scene: PackedScene = preload("res://scenes/enemies/base_enemy.tscn")
var macrophage_scene: PackedScene = preload("res://scenes/enemies/macrophage.tscn")
var lymphocyte_scene: PackedScene = preload("res://scenes/enemies/lymphocyte_b.tscn")
var red_blood_cell_scene: PackedScene = preload("res://scenes/enemies/red_blood_cell.tscn")

# Dificultad
var enemies_per_spawn: int = 2
var _difficulty_step: int = 0

# Ronda
var round_duration: float = 60.0
var _round_timer: float = 60.0
var _last_tick: int = -1

@onready var player: CharacterBody2D = $Player
@onready var spawn_timer: Timer = $EnemySpawnTimer
@onready var enemies_node: Node2D = $Enemies
@onready var projectiles_node: Node2D = $Projectiles
@onready var pickups_node: Node2D = $Pickups


func _ready() -> void:
	spawn_timer.wait_time = 1.8
	spawn_timer.timeout.connect(_on_spawn_timer)
	spawn_timer.start()
	RenderingServer.set_default_clear_color(Color(0.06, 0.06, 0.12))
	EventBus.shop_closed.connect(_on_shop_closed)
	_round_timer = round_duration


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	# Timer de ronda
	_round_timer -= delta
	var secs_left := int(ceil(maxf(0.0, _round_timer)))
	if secs_left != _last_tick:
		_last_tick = secs_left
		EventBus.round_timer_tick.emit(secs_left)

	if _round_timer <= 0.0:
		_end_round()
		return

	queue_redraw()


# ── Spawn de enemigos ──────────────────────────────────────────
func _on_spawn_timer() -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	for i in enemies_per_spawn:
		_spawn_enemy()


func _pick_enemy_scene() -> PackedScene:
	var roll := randf()
	var wave := GameManager.current_wave
	# Piñata: 8% (siempre presente, es neutral)
	if roll < 0.08:
		return red_blood_cell_scene
	# Macrófago: empieza en ola 2, crece hasta 18%
	var macro_chance := 0.0 if wave < 2 else minf(0.18, 0.08 + wave * 0.02)
	if roll < 0.08 + macro_chance:
		return macrophage_scene
	# Linfocito B: empieza en ola 2, crece hasta 18%
	var lympho_chance := 0.0 if wave < 2 else minf(0.18, 0.08 + wave * 0.02)
	if roll < 0.08 + macro_chance + lympho_chance:
		return lymphocyte_scene
	# Resto: enemigo base
	return base_enemy_scene


func _spawn_enemy() -> void:
	var scene := _pick_enemy_scene()
	var enemy = scene.instantiate()
	enemy.global_position = _random_spawn_pos()
	# Escalado de dificultad
	enemy.max_hp += _difficulty_step * 5.0
	if enemy.has_method("_physics_process"):
		if "speed" in enemy:
			enemy.speed += _difficulty_step * 3.0
	if "xp_reward" in enemy:
		enemy.xp_reward += _difficulty_step
	if "dna_drop_max" in enemy:
		enemy.dna_drop_max += _difficulty_step
	enemies_node.add_child(enemy)


func _random_spawn_pos() -> Vector2:
	var angle := randf() * TAU
	var dist := randf_range(450.0, 650.0)
	var pos := player.global_position + Vector2.from_angle(angle) * dist
	pos.x = clampf(pos.x, -arena_half_size, arena_half_size)
	pos.y = clampf(pos.y, -arena_half_size, arena_half_size)
	return pos


# ── Fin de ronda ───────────────────────────────────────────────
func _end_round() -> void:
	GameManager.current_state = GameManager.GameState.SHOPPING
	spawn_timer.stop()

	# Limpiar arena
	for enemy in enemies_node.get_children():
		enemy.queue_free()
	for proj in projectiles_node.get_children():
		proj.queue_free()

	EventBus.round_ended.emit(GameManager.current_wave)


func _on_shop_closed() -> void:
	GameManager.current_wave += 1
	GameManager.current_state = GameManager.GameState.PLAYING
	_difficulty_step += 1
	_increase_difficulty()
	_round_timer = round_duration
	_last_tick = -1
	spawn_timer.start()


func _increase_difficulty() -> void:
	enemies_per_spawn = mini(enemies_per_spawn + 1, 20)
	spawn_timer.wait_time = maxf(spawn_timer.wait_time - 0.15, 0.4)


# ── Dibujar borde del mapa ─────────────────────────────────────
func _draw() -> void:
	var rect := Rect2(
		Vector2(-arena_half_size, -arena_half_size),
		Vector2(arena_half_size * 2, arena_half_size * 2)
	)
	draw_rect(rect, Color(0.3, 0.1, 0.1, 0.4), false, 3.0)
	draw_rect(rect, Color(0.08, 0.08, 0.15, 0.3), true)

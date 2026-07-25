extends Node2D

var arena_half_size: float = GameManager.ARENA_HALF_SIZE

# Escenas de enemigos
var base_enemy_scene: PackedScene = preload("res://scenes/enemies/base_enemy.tscn")
var macrophage_scene: PackedScene = preload("res://scenes/enemies/macrophage.tscn")
var lymphocyte_scene: PackedScene = preload("res://scenes/enemies/lymphocyte_b.tscn")
var lymphocyte_t_scene: PackedScene = preload("res://scenes/enemies/lymphocyte_t.tscn")
var red_blood_cell_scene: PackedScene = preload("res://scenes/enemies/red_blood_cell.tscn")
var boss_jhon_rapamune_scene: PackedScene = preload("res://scenes/enemies/boss_jhon_rapamune.tscn")

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
@onready var background: Sprite2D = $Background

var bg_pulmones: Texture2D = preload("res://assets/sprites/tileMaps/tilePulmones.png")
var bg_cerebro: Texture2D = preload("res://assets/sprites/tileMaps/tileCerebro.png")
var bg_corazon: Texture2D = preload("res://assets/sprites/tileMaps/tileCorazon.png")


func _ready() -> void:
	spawn_timer.wait_time = 1.8
	spawn_timer.timeout.connect(_on_spawn_timer)
	spawn_timer.start()
	_update_level_aesthetics()
	EventBus.shop_closed.connect(_on_shop_closed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	_round_timer = round_duration
	# Emitir señal de nivel inicial para HUD
	call_deferred("_emit_initial_level")


func _emit_initial_level() -> void:
	EventBus.level_changed.emit(GameManager.current_level_index, GameManager.LEVELS[GameManager.current_level_index])


func _update_level_aesthetics() -> void:
	match GameManager.current_level_index:
		0: # Pulmones
			RenderingServer.set_default_clear_color(Color(0.12, 0.05, 0.06))
			if background: background.texture = bg_pulmones
		1: # Cerebro
			RenderingServer.set_default_clear_color(Color(0.06, 0.04, 0.15))
			if background: background.texture = bg_cerebro
		2: # Corazón
			RenderingServer.set_default_clear_color(Color(0.15, 0.02, 0.02))
			if background: background.texture = bg_corazon
		_:
			RenderingServer.set_default_clear_color(Color(0.06, 0.06, 0.12))
			if background: background.texture = null


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	# Timer de ronda
	if GameManager.current_round_in_level != 5:
		_round_timer -= delta
		var secs_left := int(ceil(maxf(0.0, _round_timer)))
		if secs_left != _last_tick:
			_last_tick = secs_left
			EventBus.round_timer_tick.emit(secs_left)

		if _round_timer <= 0.0:
			_end_round()
			return

	queue_redraw()


# ── Cheats de Desarrollo ───────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			if GameManager.current_state == GameManager.GameState.PLAYING:
				_end_round()


# ── Spawn de enemigos ──────────────────────────────────────────
func _on_spawn_timer() -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	for i in enemies_per_spawn:
		_spawn_enemy()


func _spawn_boss() -> void:
	var boss: Node2D
	# Nivel 0 = Pulmones -> John Rapamune
	if GameManager.current_level_index == 0:
		var spawn_pos := Vector2(0, -arena_half_size + 100.0) # Centro superior
		boss = ObjectPool.acquire(boss_jhon_rapamune_scene, enemies_node, spawn_pos)
		
		# Ajustar estadísticas según dificultad
		boss.max_hp += _difficulty_step * 250.0
		boss.current_hp = boss.max_hp
	else:
		# Fallback para los otros niveles por ahora (macrófago gigante)
		var spawn_pos := Vector2(0, -arena_half_size + 100.0)
		boss = ObjectPool.acquire(macrophage_scene, enemies_node, spawn_pos)
		boss.set_meta("is_boss", true)
		boss.scale = Vector2(2.5, 2.5)
		boss.max_hp = 150.0 + 1500.0 + (_difficulty_step * 200.0)
		boss.current_hp = boss.max_hp
		if "speed" in boss: boss.speed = 40.0 * 0.8
		if "xp_reward" in boss: boss.xp_reward = 15 + 500
		if "dna_drop_max" in boss: boss.dna_drop_max = 10 + 200


func _pick_enemy_scene() -> PackedScene:
	var roll := randf()
	var wave := GameManager.current_wave
	# Piñata: 2% (siempre presente, es neutral)
	if roll < 0.02:
		return red_blood_cell_scene
	
	var current_prob := 0.02
	# Macrófago: empieza en ola 2, crece hasta 15%
	var macro_chance := 0.0 if wave < 2 else minf(0.15, 0.05 + wave * 0.02)
	current_prob += macro_chance
	if roll < current_prob:
		return macrophage_scene
		
	# Linfocito B: empieza en ola 2, crece hasta 15%
	var lympho_b_chance := 0.0 if wave < 2 else minf(0.15, 0.05 + wave * 0.02)
	current_prob += lympho_b_chance
	if roll < current_prob:
		return lymphocyte_scene
		
	# Linfocito T: empieza en ola 3, crece hasta 15%
	var lympho_t_chance := 0.0 if wave < 3 else minf(0.15, 0.05 + wave * 0.02)
	current_prob += lympho_t_chance
	if roll < current_prob:
		return lymphocyte_t_scene
		
	# Resto: enemigo base
	return base_enemy_scene


func _spawn_enemy() -> void:
	var scene := _pick_enemy_scene()
	var enemy = ObjectPool.acquire(scene, enemies_node, _random_spawn_pos())
	# Escalado de dificultad
	enemy.max_hp += _difficulty_step * 2.0
	if enemy.has_method("_physics_process"):
		if "speed" in enemy:
			enemy.speed += _difficulty_step * 1.5
	if "xp_reward" in enemy:
		enemy.xp_reward += int(_difficulty_step * 0.5)
	if "dna_drop_max" in enemy:
		enemy.dna_drop_max += int(_difficulty_step * 0.5)
	# add_child is handled by ObjectPool
	pass


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
		if enemy.process_mode != Node.PROCESS_MODE_DISABLED:
			ObjectPool.release(enemy)
	for proj in projectiles_node.get_children():
		if proj.process_mode != Node.PROCESS_MODE_DISABLED:
			ObjectPool.release(proj)
	for pickup in pickups_node.get_children():
		if pickup.process_mode != Node.PROCESS_MODE_DISABLED:
			ObjectPool.release(pickup)

	EventBus.round_ended.emit(GameManager.current_wave)


func _on_shop_closed() -> void:
	GameManager.current_wave += 1
	GameManager.current_round_in_level += 1
	
	if GameManager.current_round_in_level > 5:
		if GameManager.current_level_index == GameManager.LEVELS.size() - 1:
			# Victoria
			GameManager.current_state = GameManager.GameState.VICTORY
			get_tree().paused = true
			EventBus.game_won.emit()
			return
		else:
			# Avanzar de nivel
			GameManager.current_round_in_level = 1
			GameManager.current_level_index += 1
			_update_level_aesthetics()
			EventBus.level_changed.emit(GameManager.current_level_index, GameManager.LEVELS[GameManager.current_level_index])
		
	GameManager.current_state = GameManager.GameState.PLAYING
	_difficulty_step += 1
	_increase_difficulty()
	_round_timer = round_duration
	_last_tick = -1
	
	if GameManager.current_round_in_level == 5:
		# Ronda de Boss: Detener el timer y generar el jefe
		spawn_timer.stop()
		EventBus.boss_round_started.emit(GameManager.BOSS_NAMES[GameManager.current_level_index])
		EventBus.round_timer_tick.emit(0) # Forzar actualización del HUD
		_spawn_boss()
	else:
		spawn_timer.start()


func _increase_difficulty() -> void:
	if _difficulty_step % 2 == 0:
		enemies_per_spawn = mini(enemies_per_spawn + 1, 15)
	spawn_timer.wait_time = maxf(spawn_timer.wait_time - 0.1, 0.6)


func _on_boss_defeated() -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		call_deferred("_end_round")


# ── Dibujar borde del mapa ─────────────────────────────────────
func _draw() -> void:
	var rect := Rect2(
		Vector2(-arena_half_size, -arena_half_size),
		Vector2(arena_half_size * 2, arena_half_size * 2)
	)
	var border_color := Color(0.3, 0.1, 0.1, 0.4)
	var inner_color := Color(0.08, 0.08, 0.15, 0.3)
	
	match GameManager.current_level_index:
		0: # Pulmones
			border_color = Color(0.4, 0.15, 0.2, 0.4)
			inner_color = Color(0.15, 0.06, 0.08, 0.3)
		1: # Cerebro
			border_color = Color(0.2, 0.1, 0.5, 0.4)
			inner_color = Color(0.08, 0.05, 0.2, 0.3)
		2: # Corazón
			border_color = Color(0.6, 0.05, 0.05, 0.4)
			inner_color = Color(0.2, 0.02, 0.02, 0.3)
			
	draw_rect(rect, border_color, false, 3.0)
	draw_rect(rect, inner_color, true)

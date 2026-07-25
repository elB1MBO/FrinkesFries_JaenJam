extends Node2D

@export var arena_half_size: float = 1500.0

var enemy_scene: PackedScene = preload("res://scenes/enemies/base_enemy.tscn")

# Dificultad
var enemies_per_spawn: int = 2
var difficulty_interval: float = 30.0   # TODO: he puesto 30 como base, podemos ajustarla mas tarde (?)
var _difficulty_step: int = 0
var _elapsed: float = 0.0

@onready var player: CharacterBody2D = $Player
@onready var spawn_timer: Timer = $EnemySpawnTimer
@onready var enemies_node: Node2D = $Enemies
@onready var projectiles_node: Node2D = $Projectiles
@onready var pickups_node: Node2D = $Pickups


func _ready() -> void:
	spawn_timer.wait_time = 1.8
	spawn_timer.timeout.connect(_on_spawn_timer)
	spawn_timer.start()
	# TODO: Dejo un fondo oscuro basico, luego tendremos que ir cambiando este fondo en función del órgano en el que estemos
	RenderingServer.set_default_clear_color(Color(0.06, 0.06, 0.12))


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_elapsed += delta
	var step := int(_elapsed / difficulty_interval)
	if step > _difficulty_step:
		_difficulty_step = step
		_increase_difficulty()

	queue_redraw()


# ── Spawn de enemigos ──
func _on_spawn_timer() -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	for i in enemies_per_spawn:
		_spawn_enemy()


func _spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	enemy.global_position = _random_spawn_pos()
	# Escalar stats con la dificultad
	enemy.max_hp += _difficulty_step * 5.0
	enemy.speed += _difficulty_step * 5.0
	enemy.xp_value += _difficulty_step
	enemies_node.add_child(enemy)


func _random_spawn_pos() -> Vector2:
	# TODO: Ahora mismo spawnean siempre fuera de la pantalla, pero dentro del mapa. Lo dejamos así? o que spawneen dentro tmb?
	var angle := randf() * TAU
	var dist := randf_range(450.0, 650.0)
	var pos := player.global_position + Vector2.from_angle(angle) * dist
	pos.x = clampf(pos.x, -arena_half_size, arena_half_size)
	pos.y = clampf(pos.y, -arena_half_size, arena_half_size)
	return pos


# ── Escalado de dificultad ──
func _increase_difficulty() -> void:
	enemies_per_spawn = mini(enemies_per_spawn + 1, 20)
	spawn_timer.wait_time = maxf(spawn_timer.wait_time - 0.15, 0.4)


# ── Dibujar borde del mapa ── 
	# TODO: Cada mapa va a ser igual, cambiando solo estéticamente?
func _draw() -> void:
	var rect := Rect2(
		Vector2(-arena_half_size, -arena_half_size),
		Vector2(arena_half_size * 2, arena_half_size * 2)
	)
	draw_rect(rect, Color(0.3, 0.1, 0.1, 0.4), false, 3.0)
	draw_rect(rect, Color(0.08, 0.08, 0.15, 0.3), true)

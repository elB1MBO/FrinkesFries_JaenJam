extends CharacterBody2D
## Linfocito B (Tirador) — persigue hasta cierto rango, luego dispara anticuerpos.

@export var max_hp: float = 20.0
@export var speed: float = 70.0
@export var xp_reward: int = 8
@export var dna_drop_min: int = 2
@export var dna_drop_max: int = 4
@export var attack_range: float = 300.0
@export var shoot_interval: float = 2.0
@export var projectile_damage: float = 12.0

var current_hp: float
var player: Node2D = null
var _in_range: bool = false

var dna_scene: PackedScene = preload("res://scenes/pickups/dna_fragment.tscn")
var projectile_scene: PackedScene = preload("res://scenes/projectiles/enemy_projectile.tscn")

@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp
	player = get_tree().get_first_node_in_group("player")
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot_timer)


func _physics_process(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		return

	var dist := global_position.distance_to(player.global_position)
	var dir := (player.global_position - global_position).normalized()

	if dist > attack_range:
		# Perseguir
		_in_range = false
		velocity = dir * speed
		shoot_timer.stop()
	else:
		# En rango — detenerse y disparar
		velocity = Vector2.ZERO
		if not _in_range:
			_in_range = true
			shoot_timer.start()

	move_and_slide()


func _on_shoot_timer() -> void:
	if not player or not is_instance_valid(player):
		return
	var dir := (player.global_position - global_position).normalized()
	var proj = projectile_scene.instantiate()
	proj.global_position = global_position
	proj.direction = dir
	proj.damage = projectile_damage
	get_tree().current_scene.get_node("Projectiles").call_deferred("add_child", proj)


func take_damage(amount: float) -> void:
	current_hp -= amount
	modulate = Color(2.0, 2.0, 2.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
	if current_hp <= 0.0:
		_die()


func _die() -> void:
	EventBus.xp_gained.emit(xp_reward)
	EventBus.enemy_killed.emit(global_position, xp_reward)
	_spawn_dna()
	queue_free()


func _spawn_dna() -> void:
	var total := randi_range(dna_drop_min, dna_drop_max)
	var frag = dna_scene.instantiate()
	frag.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	frag.dna_value = total
	get_tree().current_scene.get_node("Pickups").call_deferred("add_child", frag)


# ── Visual: Linfocito B (redondo, azulado, con anticuerpos) ───
func _draw() -> void:
	# Cuerpo
	draw_circle(Vector2.ZERO, 12.0, Color(0.35, 0.5, 0.85))
	draw_circle(Vector2.ZERO, 9.0, Color(0.4, 0.55, 0.9))
	# Núcleo grande (típico de linfocitos)
	draw_circle(Vector2(-1, 1), 7.0, Color(0.25, 0.3, 0.7))
	# Anticuerpos en superficie (puntitos Y)
	for i in 6:
		var angle := i * TAU / 6.0
		var pos := Vector2.from_angle(angle) * 11.0
		draw_circle(pos, 2.0, Color(0.95, 0.85, 0.3))
	# Indicador de rango (sutil)
	if _in_range:
		draw_arc(Vector2.ZERO, 14.0, 0, TAU, 16, Color(1.0, 0.3, 0.3, 0.4), 1.5)

extends CharacterBody2D
## Linfocito B (Tirador) — persigue hasta cierto rango, luego dispara anticuerpos.

@export var max_hp: float = 20.0
@export var speed: float = 70.0
@export var xp_reward: int = 8
@export var dna_drop_min: int = 6
@export var dna_drop_max: int = 10
@export var attack_range: float = 300.0
@export var shoot_interval: float = 2.0
@export var projectile_damage: float = 12.0

var current_hp: float
var player: Node2D = null
var _in_range: bool = false
var _is_dead: bool = false

var dna_scene: PackedScene = preload("res://scenes/pickups/dna_fragment.tscn")
var projectile_scene: PackedScene = preload("res://scenes/projectiles/enemy_projectile.tscn")
var _shoot_sfx: AudioStreamPlayer2D

@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot_timer)
	
	_shoot_sfx = AudioStreamPlayer2D.new()
	_shoot_sfx.stream = preload("res://assets/audio/disparo_sutil_linfocito_b.mp3")
	_shoot_sfx.volume_db = 0.0
	add_child(_shoot_sfx)
	
	_on_acquire()

func _on_acquire() -> void:
	current_hp = max_hp
	_is_dead = false
	modulate = Color.WHITE
	_in_range = false
	if shoot_timer:
		shoot_timer.stop()


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
	var proj_parent = get_tree().current_scene.get_node("Projectiles")
	_shoot_sfx.play()
	var proj = ObjectPool.acquire(projectile_scene, proj_parent, global_position)
	proj.direction = dir
	proj.damage = projectile_damage


func take_damage(amount: float) -> void:
	if _is_dead: return
	current_hp -= amount
	modulate = Color(2.0, 2.0, 2.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
	if current_hp <= 0.0:
		_is_dead = true
		_die()

func _die() -> void:
	EventBus.xp_gained.emit(xp_reward)
	EventBus.enemy_killed.emit(global_position, xp_reward)
	_spawn_dna()
	ObjectPool.call_deferred("release", self)

func _spawn_dna() -> void:
	var total := randi_range(dna_drop_min, dna_drop_max)
	var pickups = get_tree().current_scene.get_node("Pickups")
	var pos = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	var frag = ObjectPool.acquire(dna_scene, pickups, pos)
	frag.dna_value = total

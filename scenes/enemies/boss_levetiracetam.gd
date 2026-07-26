extends CharacterBody2D
## Levetiracetam (Jefe Cerebro)
## - Disparo normal: círculos azules (reducen Atk Spd 50%)
## - Especial: onda cada 10s (7.5s bajo 25%)
## - Fase: bajo 50%, proyectil normal +25% de tamaño

@export var max_hp: float = 2000.0
@export var speed: float = 30.0
@export var damage: float = 40.0
@export var xp_reward: int = 500
@export var dna_drop_min: int = 200
@export var dna_drop_max: int = 250

var current_hp: float
var player: Node2D = null
var _stun_timer: float = 0.0
var _is_dead: bool = false
var _projectile_scale: float = 1.0

var dna_scene: PackedScene = preload("res://scenes/pickups/dna_fragment.tscn")
var projectile_scene: PackedScene = preload("res://scenes/projectiles/boss_levetiracetam_projectile.tscn")
var wave_scene: PackedScene = preload("res://scenes/projectiles/boss_levetiracetam_wave.tscn")

@onready var shoot_timer: Timer = $ShootTimer
@onready var special_timer: Timer = $SpecialTimer
var _wave_sfx: AudioStreamPlayer2D
var _shoot_sfx: AudioStreamPlayer2D

func _ready() -> void:
	add_to_group("enemies")
	set_meta("is_boss", true)
	player = get_tree().get_first_node_in_group("player")
	shoot_timer.timeout.connect(_on_shoot)
	special_timer.timeout.connect(_on_special_attack)
	
	_wave_sfx = AudioStreamPlayer2D.new()
	_wave_sfx.stream = preload("res://assets/audio/onda_expansiva_boss_cerebro.mp3")
	_wave_sfx.volume_db = 0.0
	add_child(_wave_sfx)
	
	_shoot_sfx = AudioStreamPlayer2D.new()
	_shoot_sfx.stream = preload("res://assets/audio/lanzamiento_neurona_boss_cerebro.mp3")
	_shoot_sfx.volume_db = -24.0
	add_child(_shoot_sfx)
	
	_on_acquire()


func _on_acquire() -> void:
	current_hp = max_hp
	modulate = Color.WHITE
	_stun_timer = 0.0
	_is_dead = false
	_projectile_scale = 1.0
	if shoot_timer: shoot_timer.start()
	if special_timer: 
		special_timer.wait_time = 10.0
		special_timer.start()
	EventBus.boss_spawned.emit(max_hp)
	EventBus.boss_health_changed.emit(current_hp, max_hp)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if _stun_timer > 0.0:
		_stun_timer -= delta
		return
		
	# Lógica de fases
	var hp_percent = current_hp / max_hp
	
	if hp_percent <= 0.25:
		special_timer.wait_time = 7.5
		_projectile_scale = 1.25
	elif hp_percent <= 0.50:
		special_timer.wait_time = 10.0
		_projectile_scale = 1.25
	else:
		special_timer.wait_time = 10.0
		_projectile_scale = 1.0
		
	if not player or not is_instance_valid(player):
		return
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(damage, global_position)
			_stun_timer = 0.4


func _on_shoot() -> void:
	if _is_dead or not player or not is_instance_valid(player): return
	var dir := (player.global_position - global_position).normalized()
	var proj_parent = get_tree().current_scene.get_node("Projectiles")
	
	_shoot_sfx.play()
	
	# Disparo de múltiples círculos azules en abanico
	var base_angle := dir.angle()
	for i in range(-1, 2):
		var angle = base_angle + (i * PI / 8.0)
		var proj = ObjectPool.acquire(projectile_scene, proj_parent, global_position)
		proj.direction = Vector2.from_angle(angle)
		if "scale_mult" in proj:
			proj.scale_mult = _projectile_scale


func _on_special_attack() -> void:
	if _is_dead or not player or not is_instance_valid(player): return
	var dir := (player.global_position - global_position).normalized()
	var proj_parent = get_tree().current_scene.get_node("Projectiles")
	
	_wave_sfx.play()
	
	var wave = ObjectPool.acquire(wave_scene, proj_parent, global_position)
	wave.direction = dir


func take_damage(amount: float) -> void:
	if _is_dead: return
	current_hp -= amount
	EventBus.boss_health_changed.emit(current_hp, max_hp)
	
	modulate = Color(2.0, 2.0, 2.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
	if current_hp <= 0.0:
		_die()


func _die() -> void:
	_is_dead = true
	shoot_timer.stop()
	special_timer.stop()
	
	EventBus.xp_gained.emit(xp_reward)
	EventBus.enemy_killed.emit(global_position, xp_reward)
	_spawn_dna()
	
	ObjectPool.call_deferred("release", self)
	EventBus.boss_defeated.emit()


func _spawn_dna() -> void:
	var total := randi_range(dna_drop_min, dna_drop_max)
	var num_frags := randi_range(15, 25)
	var pickups = get_tree().current_scene.get_node("Pickups")
	for i in num_frags:
		var pos = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		var frag = ObjectPool.acquire(dna_scene, pickups, pos)
		@warning_ignore("integer_division")
		frag.dna_value = maxi(1, total / num_frags)

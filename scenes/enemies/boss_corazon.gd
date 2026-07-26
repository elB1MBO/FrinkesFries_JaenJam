extends CharacterBody2D

var max_hp: float = 3000.0
var current_hp: float = 3000.0
var speed: float = 40.0
var damage: float = 20.0
var xp_reward: int = 2000

var player: Node2D
var _is_dead := false

@onready var shoot_timer: Timer = $ShootTimer
@onready var crush_timer: Timer = $CrushTimer
@onready var homing_timer: Timer = $HomingTimer
@onready var sprite: Sprite2D = $Sprite2D

var projectile_scene = preload("res://scenes/enemies/boss_corazon_projectile.tscn")
var crush_scene = preload("res://scenes/enemies/boss_corazon_crush.tscn")
var homing_scene = preload("res://scenes/enemies/boss_corazon_homing.tscn")

func _ready() -> void:
	add_to_group("enemies")
	set_meta("is_boss", true)
	player = get_tree().get_first_node_in_group("player")
	shoot_timer.timeout.connect(_on_shoot)
	crush_timer.timeout.connect(_on_crush_attack)
	homing_timer.timeout.connect(_on_spawn_homing)
	
	# Escalar vida según el nivel
	var scaling = pow(1.5, GameManager.current_level_index)
	max_hp *= scaling
	current_hp = max_hp
	damage *= scaling
	
	crush_timer.start(4.0)
	shoot_timer.start(2.5)
	homing_timer.start(3.0)
	
	EventBus.boss_spawned.emit(max_hp)
	EventBus.boss_health_changed.emit(current_hp, max_hp)

func _physics_process(delta: float) -> void:
	if _is_dead or not is_instance_valid(player):
		return
		
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
	
	# Comprobar daño cuerpo a cuerpo al jugador
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(damage, global_position)

func _on_shoot() -> void:
	if _is_dead or not is_instance_valid(player): return
	
	var is_phase_2 = current_hp <= (max_hp * 0.5)
	
	for i in range(3):
		var proj = projectile_scene.instantiate()
		var p_dir = (player.global_position - global_position).normalized().rotated(deg_to_rad(-15 + (i * 15)))
		proj.direction = p_dir
		
		if is_phase_2:
			proj.scale = Vector2(1.2, 1.2)
			proj.speed *= 1.2
			proj.damage *= 1.2
			
		proj.boss_ref = self
		proj.global_position = global_position
		get_parent().add_child(proj)

func _on_crush_attack() -> void:
	if _is_dead or not is_instance_valid(player): return
	
	if current_hp <= (max_hp * 0.5):
		_spawn_crush()
		get_tree().create_timer(0.2, false).timeout.connect(_spawn_crush)
		get_tree().create_timer(0.4, false).timeout.connect(_spawn_crush)
	else:
		_spawn_crush()
	
	if current_hp <= (max_hp * 0.25):
		crush_timer.start(2.0)
	else:
		crush_timer.start(4.0)

func _spawn_homing() -> void:
	if _is_dead or not is_instance_valid(player): return
	var homing = homing_scene.instantiate()
	homing.global_position = global_position
	get_parent().add_child(homing)

func _spawn_crush() -> void:
	if _is_dead or not is_instance_valid(player): return
	var crush = crush_scene.instantiate()
	crush.global_position = player.global_position
	get_parent().add_child(crush)

func take_damage(amount: float) -> void:
	if _is_dead: return
	current_hp -= amount
	EventBus.boss_health_changed.emit(current_hp, max_hp)
	
	var tw = create_tween()
	sprite.modulate = Color(10, 10, 10)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		_die()

func heal(amount: float) -> void:
	if _is_dead or current_hp >= max_hp: return
	current_hp = minf(current_hp + amount, max_hp)
	EventBus.boss_health_changed.emit(current_hp, max_hp)
	
	var tw = create_tween()
	sprite.modulate = Color(0, 2, 0) # Verde brillante
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func _die() -> void:
	_is_dead = true
	EventBus.boss_defeated.emit()
	EventBus.enemy_died.emit(global_position, xp_reward)
	GameManager.add_currency(500) # Gran recompensa
	queue_free()

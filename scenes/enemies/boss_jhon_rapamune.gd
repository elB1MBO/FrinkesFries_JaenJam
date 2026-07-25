extends CharacterBody2D
## John Rapamune (Jefe Pulmones)

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
var _current_slow_amount: float = 0.25

var dna_scene: PackedScene = preload("res://scenes/pickups/dna_fragment.tscn")
var minion_scene: PackedScene = preload("res://scenes/enemies/jhon_rapamune_minion.tscn")
var projectile_scene: PackedScene = preload("res://scenes/projectiles/boss_projectile.tscn")

@onready var shoot_timer: Timer = $ShootTimer
@onready var minion_timer: Timer = $MinionTimer


func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	shoot_timer.timeout.connect(_on_shoot)
	minion_timer.timeout.connect(_on_spawn_minions)
	_on_acquire()

func _on_acquire() -> void:
	current_hp = max_hp
	modulate = Color.WHITE
	_stun_timer = 0.0
	_is_dead = false
	if shoot_timer: shoot_timer.start()
	if minion_timer: minion_timer.start()
	EventBus.boss_spawned.emit(max_hp)
	EventBus.boss_health_changed.emit(current_hp, max_hp)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if _stun_timer > 0.0:
		_stun_timer -= delta
		return
		
	# Lógica de fases según la vida
	var hp_percent = current_hp / max_hp
	if hp_percent <= 0.25:
		shoot_timer.wait_time = 0.85
		_current_slow_amount = 0.50
	elif hp_percent <= 0.50:
		shoot_timer.wait_time = 0.85
		_current_slow_amount = 0.25
	else:
		shoot_timer.wait_time = 1.0
		_current_slow_amount = 0.25
		
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
	
	# Patrón tipo "Corazón de Isaac": Anillo de 8 proyectiles, con uno apuntando directo al jugador
	var base_angle := dir.angle()
	
	for i in 8:
		var angle = base_angle + (i * TAU / 8.0)
		var proj = ObjectPool.acquire(projectile_scene, proj_parent, global_position)
		proj.direction = Vector2.from_angle(angle)
		proj.damage = 25.0
		if "slow_amount" in proj:
			proj.slow_amount = _current_slow_amount


func _on_spawn_minions() -> void:
	if _is_dead: return
	var enemies_node = get_tree().current_scene.get_node("Enemies")
	for i in 5:
		var angle := i * TAU / 5.0
		var spawn_pos = global_position + Vector2.from_angle(angle) * 80.0
		var minion = ObjectPool.acquire(minion_scene, enemies_node, spawn_pos)
		# Darle un pequeño boost inicial para que se separe
		if minion and minion.has_method("_physics_process"):
			minion.velocity = Vector2.from_angle(angle) * 200.0


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
	minion_timer.stop()
	
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

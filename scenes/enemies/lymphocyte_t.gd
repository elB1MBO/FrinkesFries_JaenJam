extends CharacterBody2D
## Linfocito T (Melee agresivo) — rápido, resistente, da más XP y ADN.

@export var max_hp: float = 60.0
@export var speed: float = 160.0
@export var damage: float = 15.0
@export var xp_reward: int = 12
@export var dna_drop_min: int = 10
@export var dna_drop_max: int = 16

var current_hp: float
var player: Node2D = null
var _in_range: bool = false
var _is_dead: bool = false
var _stun_timer: float = 0.0

var dna_scene: PackedScene = preload("res://scenes/pickups/dna_fragment.tscn")


func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	_on_acquire()

func _on_acquire() -> void:
	current_hp = max_hp
	_is_dead = false
	modulate = Color.WHITE
	_stun_timer = 0.0
	_is_dead = false


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if _stun_timer > 0.0:
		_stun_timer -= delta
		return

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
	_is_dead = true
	EventBus.xp_gained.emit(xp_reward)
	EventBus.enemy_killed.emit(global_position, xp_reward)
	_spawn_dna()
	ObjectPool.call_deferred("release", self)

func _spawn_dna() -> void:
	var total := randi_range(dna_drop_min, dna_drop_max)
	var pickups = get_tree().current_scene.get_node("Pickups")
	var frag = ObjectPool.acquire(dna_scene, pickups, global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10)))
	frag.dna_value = total

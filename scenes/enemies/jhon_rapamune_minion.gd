extends CharacterBody2D
## Súbdito de John Rapamune — rápido, débil, ataca a melee. No suelta nada.

@export var max_hp: float = 10.0
@export var speed: float = 160.0
@export var damage: float = 8.0
@export var xp_reward: int = 0
@export var dna_drop_min: int = 0
@export var dna_drop_max: int = 0

var current_hp: float
var player: Node2D = null
var _is_dead: bool = false


func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	_on_acquire()

func _on_acquire() -> void:
	current_hp = max_hp
	modulate = Color.WHITE
	_is_dead = false


func _physics_process(delta: float) -> void:
	if _is_dead:
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
			_die() # Explota al contacto


func take_damage(amount: float) -> void:
	if _is_dead:
		return
	current_hp -= amount
	modulate = Color(2.0, 2.0, 2.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
	if current_hp <= 0.0:
		_die()


func _die() -> void:
	_is_dead = true
	# No da XP, pero sí cuenta como baja si queremos
	# EventBus.enemy_killed.emit(global_position, xp_reward)
	ObjectPool.call_deferred("release", self)

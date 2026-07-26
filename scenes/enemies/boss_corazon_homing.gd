extends CharacterBody2D

var max_hp: float = 80.0
var current_hp: float = 80.0
var speed: float = 140.0
var damage: float = 30.0

var player: Node2D
var _is_dead := false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemies") # Para que los disparos del jugador lo dañen
	player = get_tree().get_first_node_in_group("player")
	
	var multiplier = pow(1.5, GameManager.current_level_index)
	max_hp *= multiplier
	current_hp = max_hp
	damage *= multiplier
	speed *= (1.0 + (GameManager.current_level_index * 0.1))

func _physics_process(delta: float) -> void:
	if _is_dead or not is_instance_valid(player): return
	
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
	
	# Impacto con el jugador
	for i in get_slide_collision_count():
		var col = get_slide_collision(i).get_collider()
		if col and col.is_in_group("player") and col.has_method("take_damage"):
			col.take_damage(damage, global_position)
			_die(false)

func take_damage(amount: float) -> void:
	if _is_dead: return
	current_hp -= amount
	
	var tw = create_tween()
	sprite.modulate = Color(10, 10, 10)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		_die(true)

func _die(_killed_by_player: bool) -> void:
	_is_dead = true
	queue_free()

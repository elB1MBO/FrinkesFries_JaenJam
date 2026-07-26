extends Area2D

var direction := Vector2.ZERO
var speed := 250.0
var damage := 20.0
var max_lifetime := 4.0

var boss_ref: Node2D = null

var _lifetime := 0.0

func _ready() -> void:
	collision_layer = 8   # Enemy projectiles
	collision_mask = 1    # Player
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		if is_instance_valid(boss_ref) and boss_ref.has_method("heal"):
			boss_ref.heal(damage)
		queue_free()

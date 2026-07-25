extends Area2D

var xp_value: int = 3
var magnet_speed: float = 350.0
var magnet_radius: float = 120.0
var is_magnetized: bool = false
var player: Node2D = null

var _float_offset: float = 0.0

func _ready() -> void:
	collision_layer = 8   # Layer 4: pickups
	collision_mask = 1    # Mask 1: player
	
	set_deferred("monitoring", true)
	set_deferred("monitorable", false)
	
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")
	_float_offset = randf() * TAU  # aleatorio para que no siempre sea del mismo color


func _physics_process(delta: float) -> void:
	_float_offset += delta * 3.0

	if not player or not is_instance_valid(player):
		return

	var dist := global_position.distance_to(player.global_position)
	if dist < magnet_radius:
		is_magnetized = true

	if is_magnetized:
		var dir := (player.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta
		magnet_speed += delta * 400.0

	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		EventBus.xp_collected.emit(xp_value)
		queue_free()


func _draw() -> void:
	var pulse := 0.8 + sin(_float_offset) * 0.2
	draw_circle(Vector2.ZERO, 7.0 * pulse, Color(0.3, 0.5, 1.0, 0.3))
	draw_circle(Vector2.ZERO, 4.0 * pulse, Color(0.4, 0.65, 1.0, 0.85))
	draw_circle(Vector2.ZERO, 2.0, Color(0.7, 0.85, 1.0))

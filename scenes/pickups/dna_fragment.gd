extends Area2D
## Fragmento de ADN — pickup de moneda. Efecto magnético hacia el jugador.

var dna_value: int = 1
var magnet_speed: float = 350.0
var magnet_radius: float = 120.0
var is_magnetized: bool = false
var player: Node2D = null
var _is_dead: bool = false

var _float_offset: float = 0.0


func _ready() -> void:
	collision_layer = 8   # Layer 4: pickups
	collision_mask = 1    # Mask 1: player
	set_deferred("monitoring", true)
	set_deferred("monitorable", false)
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")
	_on_acquire()

func _on_acquire() -> void:
	is_magnetized = false
	magnet_speed = 350.0
	_is_dead = false
	_float_offset = randf() * TAU


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
	if _is_dead: return
	_is_dead = true
	if body.is_in_group("player"):
		EventBus.currency_collected.emit(dna_value)
		ObjectPool.call_deferred("release", self)


func _draw() -> void:
	var pulse := 0.8 + sin(_float_offset) * 0.2
	var s := 6.0 * pulse

	# Doble hélice de ADN
	for i in 5:
		var t := i / 4.0
		var y_pos := lerpf(-s, s, t)
		var x_off := sin(t * TAU + _float_offset) * 4.0
		# Hebra izquierda
		draw_circle(Vector2(-x_off, y_pos), 2.0, Color(0.2, 0.9, 0.4, 0.9))
		# Hebra derecha
		draw_circle(Vector2(x_off, y_pos), 2.0, Color(0.2, 0.7, 0.9, 0.9))
		# Puente entre hebras
		if i % 2 == 0:
			draw_line(Vector2(-x_off, y_pos), Vector2(x_off, y_pos), Color(0.5, 1.0, 0.6, 0.5), 1.0)

	# Brillo central
	draw_circle(Vector2.ZERO, 2.5 * pulse, Color(0.4, 1.0, 0.6, 0.6))

extends Area2D
## Célula orbital — gira alrededor del jugador dañando enemigos al contacto.

var orbit_radius: float = 60.0
var orbit_speed: float = 2.5
var damage: float = 15.0
var _angle: float = 0.0


func _ready() -> void:
	collision_layer = 4   # Proyectiles
	collision_mask = 2    # Enemigos
	set_deferred("monitoring", true)
	set_deferred("monitorable", false)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_angle += orbit_speed * delta
	position = Vector2.from_angle(_angle) * orbit_radius
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)


func _draw() -> void:
	# Célula mona con membrana
	draw_circle(Vector2.ZERO, 9.0, Color(0.9, 0.55, 0.7, 0.85))
	draw_circle(Vector2(2, -1), 4.0, Color(0.7, 0.3, 0.5))
	draw_arc(Vector2.ZERO, 10.0, 0, TAU, 24, Color(0.95, 0.7, 0.8), 1.5)

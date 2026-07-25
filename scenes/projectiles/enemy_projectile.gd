extends Area2D
## Proyectil enemigo (anticuerpo) — disparado por el Linfocito B.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 220.0
var damage: float = 12.0
var ttl: float = 3.5


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1   # Detecta al jugador
	set_deferred("monitoring", true)
	set_deferred("monitorable", false)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(ttl).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	queue_free()


func _draw() -> void:
	# Anticuerpo en forma de Y
	draw_line(Vector2(0, 5), Vector2(0, -2), Color(0.95, 0.8, 0.2), 2.5)
	draw_line(Vector2(0, -2), Vector2(-5, -7), Color(0.95, 0.8, 0.2), 2.5)
	draw_line(Vector2(0, -2), Vector2(5, -7), Color(0.95, 0.8, 0.2), 2.5)
	draw_circle(Vector2(-5, -7), 2.5, Color(1.0, 0.9, 0.3))
	draw_circle(Vector2(5, -7), 2.5, Color(1.0, 0.9, 0.3))
	draw_circle(Vector2(0, 5), 2.0, Color(0.9, 0.75, 0.15))

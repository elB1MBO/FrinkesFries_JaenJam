extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: float = 10.0
var ttl: float = 2.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(ttl).timeout.connect(queue_free) # autodestruye


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

# Proyectil básico (un moco verde xd)
func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(0.4, 1.0, 0.4, 0.9))
	draw_circle(Vector2.ZERO, 2.0, Color(0.8, 1.0, 0.8))

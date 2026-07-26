extends Area2D
## Proyectil de Levetiracetam: Daño leve pero reduce a la mitad la velocidad de ataque.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var damage: float = 15.0
var ttl: float = 5.0
var scale_mult: float = 1.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1   # Detecta al jugador
	set_deferred("monitoring", true)
	set_deferred("monitorable", false)
	body_entered.connect(_on_body_entered)
	_on_acquire()


var _current_ttl: float = 0.0

func _on_acquire() -> void:
	scale = Vector2(scale_mult, scale_mult)
	_current_ttl = ttl


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	_current_ttl -= delta
	if _current_ttl <= 0.0:
		ObjectPool.call_deferred("release", self)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if body.has_method("apply_attack_slow"):
			body.apply_attack_slow(0.5, 3.0) # 50% slow for 3 seconds
	ObjectPool.call_deferred("release", self)

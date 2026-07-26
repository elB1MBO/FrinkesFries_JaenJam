extends Area2D
## Onda de Levetiracetam: Una línea curva (onda) que viaja hacia el jugador.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 225.0
var damage: float = 35.0
var ttl: float = 3.5


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	set_deferred("monitoring", true)
	set_deferred("monitorable", false)
	body_entered.connect(_on_body_entered)
	_on_acquire()


var _current_ttl: float = 0.0

func _on_acquire() -> void:
	_current_ttl = ttl


func _physics_process(delta: float) -> void:
	# Actualizar la rotación aquí garantiza que apunte bien, 
	# ya que la dirección se asigna después de instanciarse.
	rotation = direction.angle()
	
	position += direction * speed * delta
	
	_current_ttl -= delta
	if _current_ttl <= 0.0:
		ObjectPool.call_deferred("release", self)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
	ObjectPool.call_deferred("release", self)


func _draw() -> void:
	# Dibujar onda escalada x3
	var center = Vector2(-60, 0)
	var radius = 75.0
	draw_arc(center, radius, -PI/3.0, PI/3.0, 32, Color(0.2, 0.4, 0.8), 18.0)
	draw_arc(center, radius, -PI/3.0, PI/3.0, 32, Color(0.5, 0.8, 1.0), 6.0)

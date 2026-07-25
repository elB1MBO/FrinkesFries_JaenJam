extends Area2D
## Proyectil del Boss — Anillo hueco, lento, daño alto.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 130.0
var damage: float = 25.0
var slow_amount: float = 0.25
var ttl: float = 6.0
var _is_dead: bool = false

var _life_timer: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1   # Detecta al jugador
	set_deferred("monitoring", true)
	set_deferred("monitorable", false)
	body_entered.connect(_on_body_entered)
	_on_acquire()

func _on_acquire() -> void:
	_life_timer = 0.0
	_is_dead = false


func _physics_process(delta: float) -> void:
	_life_timer += delta
	if _life_timer >= ttl:
		ObjectPool.call_deferred("release", self)
		return
	position += direction * speed * delta
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if _is_dead: return
	_is_dead = true
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		if body.has_method("apply_slow"):
			body.apply_slow(slow_amount, 2.0)
	ObjectPool.call_deferred("release", self)


func _draw() -> void:
	# Dibuja los enlaces (líneas moradas)
	draw_line(Vector2(0, 0), Vector2(-15, 0), Color(0.6, 0.2, 0.6), 4.0)
	draw_line(Vector2(-15, 0), Vector2(-30, 0), Color(0.6, 0.2, 0.6), 4.0)
	
	# Dibuja los "átomos" (rosa con centro cyan)
	# Átomo principal (frente)
	draw_circle(Vector2(0, 0), 8.0, Color(0.9, 0.5, 0.8))
	draw_circle(Vector2(0, 0), 4.0, Color(0.4, 0.9, 0.9))
	
	# Átomo secundario
	draw_circle(Vector2(-15, 0), 6.0, Color(0.9, 0.5, 0.8))
	draw_circle(Vector2(-15, 0), 3.0, Color(0.4, 0.9, 0.9))
	
	# Átomo terciario (cola)
	draw_circle(Vector2(-30, 0), 4.0, Color(0.9, 0.5, 0.8))
	draw_circle(Vector2(-30, 0), 2.0, Color(0.4, 0.9, 0.9))

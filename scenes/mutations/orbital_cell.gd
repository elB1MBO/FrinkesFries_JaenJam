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


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		
		# Knockback visual
		if not body.has_meta("is_boss"):
			var tw := body.create_tween()
			var kb_dir := (body.global_position - global_position).normalized()
			var kb_pos := body.position + kb_dir * 15.0
			tw.tween_property(body, "position", kb_pos, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			body.set_meta("kb_tween", tw)

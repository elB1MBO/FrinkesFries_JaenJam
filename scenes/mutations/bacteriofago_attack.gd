extends Area2D

var damage: float = 20.0
var shadow_alpha: float = 0.0
var warning_time: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Detect enemies
	body_entered.connect(_on_body_entered)
	
	collision.set_deferred("disabled", true)
	sprite.visible = false
	sprite.scale = Vector2(0.1, 0.1)
	sprite.position.y = -400.0 # Caída desde más alto
	
	# Animar sombra verde
	var tw = create_tween()
	tw.tween_property(self, "shadow_alpha", 0.5, warning_time).set_trans(Tween.TRANS_SINE)
	
	get_tree().create_timer(warning_time, false).timeout.connect(_drop_bacteriofago)

var _has_dropped := false

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _has_dropped: return
	if shadow_alpha > 0.0:
		# Dibujar sombra (radio = 60)
		draw_circle(Vector2.ZERO, 60.0, Color(0.1, 0.2, 0.1, shadow_alpha))
		draw_arc(Vector2.ZERO, 60.0, 0, TAU, 32, Color(0.3, 0.8, 0.3, shadow_alpha), 2.0)

func _drop_bacteriofago() -> void:
	_has_dropped = true
	sprite.visible = true
	shadow_alpha = 0.0 # Ocultar sombra al caer
	queue_redraw()
	
	# Animación de caída y escala
	var tw = create_tween()
	tw.tween_property(sprite, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.25)
	
	tw.finished.connect(func():
		# Activar hitbox temporalmente
		collision.set_deferred("disabled", false)
		get_tree().create_timer(0.1, false).timeout.connect(func(): collision.set_deferred("disabled", true))
		
		# Animación de impacto y desaparición lenta
		var tw2 = create_tween()
		tw2.tween_property(sprite, "scale", Vector2(2.0, 1.0), 0.1)
		tw2.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.1)
		
		# Mantenerlo en pantalla 0.6 segundos antes de empezar a desvanecer
		tw2.tween_interval(0.6)
		
		# Desvanecimiento mucho más lento (0.8 segundos)
		tw2.tween_property(sprite, "modulate:a", 0.0, 0.8)
		tw2.finished.connect(queue_free)
	)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)

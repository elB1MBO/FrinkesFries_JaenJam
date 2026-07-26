extends Area2D

var damage := 40.0
var warning_time := 2.0
var radius := 60.0

var shadow_alpha := 0.0
var rainbow_alpha := 0.0
var rainbow_width := 0.0

@onready var collision: CollisionShape2D = $CollisionShape2D
var _sfx: AudioStreamPlayer2D

var rainbow_colors = [
	Color(1, 0, 0),       # Red
	Color(1, 0.5, 0),     # Orange
	Color(1, 1, 0),       # Yellow
	Color(0, 1, 0),       # Green
	Color(0, 0, 1),       # Blue
	Color(0.29, 0, 0.51), # Indigo
	Color(0.56, 0, 1)     # Violet
]

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	
	_sfx = AudioStreamPlayer2D.new()
	_sfx.stream = preload("res://assets/audio/rayo_magico_arcoiris_boss.mp3")
	_sfx.volume_db = 0.0
	add_child(_sfx)
	
	collision.set_deferred("disabled", true)
	
	# Animar el circulo de advertencia
	var tw = create_tween()
	tw.tween_property(self, "shadow_alpha", 0.6, warning_time).set_trans(Tween.TRANS_SINE)
	
	get_tree().create_timer(warning_time, false).timeout.connect(_drop_lightning)

func _process(_delta: float) -> void:
	# Forzar dibujado continuo de la sombra y del arcoiris
	queue_redraw()

func _draw() -> void:
	if shadow_alpha > 0.0:
		draw_circle(Vector2.ZERO, radius, Color(0.2, 0.0, 0.0, shadow_alpha))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.2, 0.2, shadow_alpha), 2.0)
		
	if rainbow_alpha > 0.0:
		var stripe_w = rainbow_width / rainbow_colors.size()
		var start_x = -rainbow_width / 2.0
		var h = 800.0 # Alto infinito hacia arriba
		for i in range(rainbow_colors.size()):
			var c = rainbow_colors[i]
			c.a = rainbow_alpha
			var rect = Rect2(start_x + (i * stripe_w), -h, stripe_w, h)
			draw_rect(rect, c)

func _drop_lightning() -> void:
	_sfx.play()
	# El rayo impacta instantáneamente
	collision.set_deferred("disabled", false)
	shadow_alpha = 0.0 # Ocultar la sombra de aviso al impactar
	rainbow_alpha = 1.0
	
	# Flash impact animation
	var tw = create_tween()
	rainbow_width = 80.0
	tw.tween_property(self, "rainbow_width", 10.0, 0.4).set_trans(Tween.TRANS_BOUNCE)
	tw.parallel().tween_property(self, "rainbow_alpha", 0.0, 0.5)
	
	tw.finished.connect(func():
		queue_free()
	)
	
	# Desactivar colisión tras el impacto inicial (un solo golpe)
	get_tree().create_timer(0.1, false).timeout.connect(func(): collision.set_deferred("disabled", true))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)

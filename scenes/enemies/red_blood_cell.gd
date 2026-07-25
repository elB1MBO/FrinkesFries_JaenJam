extends CharacterBody2D
## Glóbulo Rojo (Piñata) — neutral, rebota por el mapa, suelta botín masivo.

@export var max_hp: float = 15.0
@export var speed: float = 120.0
@export var xp_reward: int = 3
@export var dna_drop_min: int = 10
@export var dna_drop_max: int = 20

var current_hp: float
var direction: Vector2

var dna_scene: PackedScene = preload("res://scenes/pickups/dna_fragment.tscn")


func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp
	# Dirección inicial aleatoria
	direction = Vector2.from_angle(randf() * TAU).normalized()
	# No colisiona con el jugador (no hace daño por contacto)
	collision_layer = 2
	collision_mask = 0


func _physics_process(_delta: float) -> void:
	velocity = direction * speed
	move_and_slide()

	# Rebote en los bordes de la arena
	var limit := GameManager.ARENA_HALF_SIZE
	if global_position.x <= -limit or global_position.x >= limit:
		direction.x = -direction.x
		global_position.x = clampf(global_position.x, -limit + 1, limit - 1)
	if global_position.y <= -limit or global_position.y >= limit:
		direction.y = -direction.y
		global_position.y = clampf(global_position.y, -limit + 1, limit - 1)


func take_damage(amount: float) -> void:
	current_hp -= amount
	modulate = Color(2.0, 1.0, 1.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
	if current_hp <= 0.0:
		_die()


func _die() -> void:
	EventBus.xp_gained.emit(xp_reward)
	EventBus.enemy_killed.emit(global_position, xp_reward)
	_spawn_dna()
	queue_free()


func _spawn_dna() -> void:
	# Botín masivo — varios fragmentos
	var total := randi_range(dna_drop_min, dna_drop_max)
	var num_frags := randi_range(3, 5)
	for i in num_frags:
		var frag = dna_scene.instantiate()
		frag.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		@warning_ignore("integer_division")
		frag.dna_value = maxi(1, total / num_frags)
		get_tree().current_scene.get_node("Pickups").call_deferred("add_child", frag)


# ── Visual: Glóbulo Rojo (disco bicóncavo, rojo) ──────────────
func _draw() -> void:
	# Disco exterior
	draw_circle(Vector2.ZERO, 14.0, Color(0.85, 0.18, 0.15))
	# Zona más oscura central (forma bicóncava)
	draw_circle(Vector2.ZERO, 7.0, Color(0.7, 0.12, 0.1))
	# Brillo para dar volumen
	draw_circle(Vector2(-4, -4), 5.0, Color(0.95, 0.35, 0.3, 0.5))
	draw_circle(Vector2(3, 3), 3.0, Color(0.95, 0.3, 0.25, 0.3))

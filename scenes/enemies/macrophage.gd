extends CharacterBody2D
## Macrófago (Tanque) — lento, mucha vida, daño masivo.

@export var max_hp: float = 150.0
@export var speed: float = 40.0
@export var damage: float = 25.0
@export var xp_reward: int = 15
@export var dna_drop_min: int = 3
@export var dna_drop_max: int = 5

var current_hp: float
var player: Node2D = null

var dna_scene: PackedScene = preload("res://scenes/pickups/dna_fragment.tscn")


func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp
	player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(damage)


func take_damage(amount: float) -> void:
	current_hp -= amount
	modulate = Color(2.0, 2.0, 2.0)
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
	# Suelta varios fragmentos por ser gordo
	var total := randi_range(dna_drop_min, dna_drop_max)
	var num_frags := randi_range(1, 3)
	for i in num_frags:
		var frag = dna_scene.instantiate()
		frag.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
		@warning_ignore("integer_division")
		frag.dna_value = maxi(1, total / num_frags)
		get_tree().current_scene.get_node("Pickups").call_deferred("add_child", frag)


# ── Visual: Macrófago (ameboide grande y morado) ──────────────
func _draw() -> void:
	# Cuerpo principal — ameboide irregular
	draw_circle(Vector2.ZERO, 22.0, Color(0.55, 0.3, 0.55))
	# Pseudópodos
	draw_circle(Vector2(-14, -10), 10.0, Color(0.6, 0.35, 0.58))
	draw_circle(Vector2(12, -12), 9.0, Color(0.58, 0.32, 0.56))
	draw_circle(Vector2(16, 8), 10.0, Color(0.6, 0.35, 0.58))
	draw_circle(Vector2(-10, 14), 9.0, Color(0.58, 0.32, 0.56))
	draw_circle(Vector2(0, -16), 8.0, Color(0.6, 0.35, 0.58))
	# Núcleo
	draw_circle(Vector2(-2, 2), 8.0, Color(0.4, 0.15, 0.45))
	draw_circle(Vector2(2, -1), 5.0, Color(0.35, 0.1, 0.4))
	# Vacuolas (burbujas internas)
	draw_circle(Vector2(8, -3), 4.0, Color(0.7, 0.5, 0.7, 0.5))
	draw_circle(Vector2(-7, -5), 3.0, Color(0.7, 0.5, 0.7, 0.5))

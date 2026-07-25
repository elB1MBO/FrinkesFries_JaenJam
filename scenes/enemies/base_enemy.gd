extends CharacterBody2D

@export var max_hp: float = 30.0
@export var speed: float = 80.0
@export var damage: float = 8.0
@export var xp_reward: int = 5    # XP directa al morir
@export var dna_drop_min: int = 1
@export var dna_drop_max: int = 3

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
	# XP directa al jugador (sin recoger)
	EventBus.xp_gained.emit(xp_reward)
	EventBus.enemy_killed.emit(global_position, xp_reward)
	_spawn_dna()
	queue_free()


func _spawn_dna() -> void:
	var dna_amount := randi_range(dna_drop_min, dna_drop_max)
	var frag = dna_scene.instantiate()
	frag.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	frag.dna_value = dna_amount
	get_tree().current_scene.get_node("Pickups").call_deferred("add_child", frag)


# ── Glóbulo blanco ──
func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(0.88, 0.88, 0.96))
	draw_circle(Vector2(4, -2), 8.0, Color(0.92, 0.90, 1.0))
	draw_circle(Vector2(-5, 3), 7.0, Color(0.85, 0.85, 0.95))
	draw_circle(Vector2(2, 1), 5.0, Color(0.55, 0.45, 0.75))

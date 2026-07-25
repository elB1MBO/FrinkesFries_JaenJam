extends CharacterBody2D

# ── Stats base ─────────────────────────────────────────────────
@export var max_hp: float = 100.0
@export var attack: float = 10.0
@export var defense: float = 2.0
@export var attack_speed: float = 2.5
@export var move_speed: float = 200.0
@export var attack_range: float = 350.0

var current_hp: float

var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")

@onready var attack_timer: Timer = $AttackTimer
@onready var damage_cooldown: Timer = $DamageCooldown


func _ready() -> void:
	add_to_group("player")
	current_hp = max_hp
	attack_timer.wait_time = 1.0 / attack_speed
	attack_timer.start()
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	EventBus.player_health_changed.emit(current_hp, max_hp)


func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * move_speed
	move_and_slide()


# ── Auto-disparo ───────────────────────────────────────────────
func _on_attack_timer_timeout() -> void:
	var nearest := _find_nearest_enemy()
	if nearest:
		_shoot_at(nearest.global_position)


func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null
	var best_dist: float = attack_range
	for enemy in enemies:
		var d := global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best


func _shoot_at(target_pos: Vector2) -> void:
	var proj = projectile_scene.instantiate()
	proj.global_position = global_position
	proj.direction = (target_pos - global_position).normalized()
	proj.damage = attack
	get_tree().current_scene.get_node("Projectiles").add_child(proj)


# ── Recibir daño ──
func take_damage(amount: float) -> void:
	if not damage_cooldown.is_stopped():
		return
	damage_cooldown.start()

	var actual := maxf(1.0, amount - defense)
	current_hp -= actual
	EventBus.player_health_changed.emit(current_hp, max_hp)

	modulate = Color.RED
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.2)

	if current_hp <= 0.0:
		EventBus.player_died.emit()


# ── Virus (de momento simple xd) ──
func _draw() -> void:
	# Cuerpo
	draw_circle(Vector2.ZERO, 16.0, Color(0.18, 0.78, 0.22))
	# Pinchos
	for i in 8:
		var angle := i * TAU / 8.0
		var from := Vector2.from_angle(angle) * 14.0
		var to := Vector2.from_angle(angle) * 22.0
		draw_line(from, to, Color(0.1, 0.55, 0.12), 3.0)
	# Ojos
	draw_circle(Vector2(-5, -4), 4.0, Color.WHITE)
	draw_circle(Vector2(5, -4), 4.0, Color.WHITE)
	draw_circle(Vector2(-4, -5), 2.0, Color.BLACK)
	draw_circle(Vector2(6, -5), 2.0, Color.BLACK)
	# Sonrisa
	draw_arc(Vector2(0, 2), 6.0, 0.2, PI - 0.2, 12, Color(0.08, 0.4, 0.1), 2.0)

extends CharacterBody2D
## Virus protagonista — se mueve con WASD/flechas, dispara automáticamente
## al enemigo más cercano. Lee stats de GameManager. Gestiona mutaciones.

var current_hp: float

var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")
var orbital_cell_scene: PackedScene = preload("res://scenes/mutations/orbital_cell.tscn")

@onready var attack_timer: Timer = $AttackTimer
@onready var damage_cooldown: Timer = $DamageCooldown

# Estado de mutaciones
var _regen_timer: float = 0.0
var _toxic_timer: float = 0.0
var _toxic_range: float = 80.0
var _toxic_damage: float = 5.0

var _knockback_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	current_hp = GameManager.get_stat("max_hp")
	_update_attack_speed()
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	EventBus.player_health_changed.emit(current_hp, GameManager.get_stat("max_hp"))
	EventBus.mutation_activated.connect(_on_mutation_activated)


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_velocity := input_dir * GameManager.get_stat("move_speed")
	
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, 15.0 * delta)
	velocity = target_velocity + _knockback_velocity
	
	move_and_slide()
	# Limitar al borde de la arena
	var limit := GameManager.ARENA_HALF_SIZE
	global_position.x = clampf(global_position.x, -limit, limit)
	global_position.y = clampf(global_position.y, -limit, limit)


func _process(delta: float) -> void:
	_process_regen(delta)
	_process_toxic_aura(delta)


# ── Auto-disparo ───────────────────────────────────────────────
func _update_attack_speed() -> void:
	attack_timer.wait_time = 1.0 / GameManager.get_stat("attack_speed")


func _on_attack_timer_timeout() -> void:
	_update_attack_speed()
	var nearest := _find_nearest_enemy()
	if nearest:
		_shoot_at(nearest.global_position)


func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null
	var best_dist: float = 350.0  # rango de ataque
	for enemy in enemies:
		if enemy.process_mode == Node.PROCESS_MODE_DISABLED:
			continue
		if enemy.get("current_hp") != null and enemy.current_hp <= 0.0:
			continue
			
		var d := global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best


func _shoot_at(target_pos: Vector2) -> void:
	var proj_parent = get_tree().current_scene.get_node("Projectiles")
	var proj = ObjectPool.acquire(projectile_scene, proj_parent, global_position)
	proj.direction = (target_pos - global_position).normalized()
	proj.damage = GameManager.get_stat("attack")


# ── Recibir daño ───────────────────────────────────────────────
func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO) -> void:
	if not damage_cooldown.is_stopped():
		return
		
	# I-frames (breve ventana de invulnerabilidad)
	damage_cooldown.wait_time = 0.15
	damage_cooldown.start()
	
	# Knockback — only from nearby sources to avoid pool ghost hits
	if source_pos != Vector2.ZERO:
		var dist_to_source := global_position.distance_to(source_pos)
		if dist_to_source < 200.0 and dist_to_source > 0.01:
			var dir := (global_position - source_pos).normalized()
			_knockback_velocity = dir * 600.0

	var defense := GameManager.get_stat("defense")
	var actual := maxf(1.0, amount - defense)
	current_hp -= actual
	EventBus.player_health_changed.emit(current_hp, GameManager.get_stat("max_hp"))

	# Flash rojo
	modulate = Color.RED
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.2)

	# Mutación: Pinchos Reactivos
	if GameManager.has_mutation("reactive_spikes"):
		call_deferred("_trigger_reactive_spikes")

	if current_hp <= 0.0:
		EventBus.player_died.emit()


# ── Curación ───────────────────────────────────────────────────
func heal(amount: float) -> void:
	var max_hp := GameManager.get_stat("max_hp")
	current_hp = minf(current_hp + amount, max_hp)
	EventBus.player_health_changed.emit(current_hp, max_hp)


# ── Mutaciones: aplicación ─────────────────────────────────────
func _on_mutation_activated(mutation_id: String) -> void:
	match mutation_id:
		"orbital_cell":
			var cell = orbital_cell_scene.instantiate()
			add_child(cell)
		"reinforced_membrane":
			# Curar el bonus de HP al adquirirlo
			var bonus_hp := GameManager.get_stat("max_hp") - current_hp
			if bonus_hp > 0:
				heal(bonus_hp * 0.25)
		"toxic_capside":
			pass  # Se procesa en _process_toxic_aura
		"reactive_spikes":
			pass  # Se dispara en take_damage
		"split_shot":
			pass  # Se gestiona en projectile.gd


# ── Mutaciones: efectos por tick ───────────────────────────────
func _process_regen(delta: float) -> void:
	if not GameManager.has_mutation("reinforced_membrane"):
		return
	_regen_timer += delta
	if _regen_timer >= 1.0:
		_regen_timer -= 1.0
		heal(1.0)


func _process_toxic_aura(delta: float) -> void:
	if not GameManager.has_mutation("toxic_capside"):
		return
	_toxic_timer += delta
	if _toxic_timer < 1.0:
		return
	_toxic_timer -= 1.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.process_mode == Node.PROCESS_MODE_DISABLED:
			continue
		if enemy.get("current_hp") != null and enemy.current_hp <= 0.0:
			continue
		if global_position.distance_to(enemy.global_position) < _toxic_range:
			if enemy.has_method("take_damage"):
				enemy.take_damage(_toxic_damage)


func _trigger_reactive_spikes() -> void:
	var atk := GameManager.get_stat("attack") * 0.5
	var proj_parent = get_tree().current_scene.get_node("Projectiles")
	for i in 8:
		var proj = ObjectPool.acquire(projectile_scene, proj_parent, global_position)
		proj.direction = Vector2.from_angle(i * TAU / 8.0)
		proj.damage = atk
		proj.speed = 350.0


# ── Dibujo placeholder ────────────────────────────────────────
func _draw() -> void:
	# Aura tóxica visible
	if GameManager.has_mutation("toxic_capside"):
		draw_arc(Vector2.ZERO, _toxic_range, 0, TAU, 32, Color(0.6, 0.15, 0.9, 0.2), 2.0)
		draw_circle(Vector2.ZERO, _toxic_range, Color(0.5, 0.1, 0.8, 0.05))

	# Cuerpo del virus
	draw_circle(Vector2.ZERO, 16.0, Color(0.18, 0.78, 0.22))
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

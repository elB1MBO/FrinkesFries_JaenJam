extends CharacterBody2D
## Virus protagonista — se mueve con WASD/flechas, dispara automáticamente
## al enemigo más cercano. Lee stats de GameManager. Gestiona mutaciones.

var current_hp: float

var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")
var orbital_cell_scene: PackedScene = preload("res://scenes/mutations/orbital_cell.tscn")
var bacteriofago_attack_scene: PackedScene = preload("res://scenes/mutations/bacteriofago_attack.tscn")

@onready var attack_timer: Timer = $AttackTimer
@onready var damage_cooldown: Timer = $DamageCooldown
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer
@onready var bacteriofago_timer: Timer = $BacteriofagoTimer

var anim_frame_toggle: int = 0

# Estado de mutaciones
var _regen_timer: float = 0.0
var _shoot_sfx: AudioStreamPlayer


var _slow_amount: float = 0.0
var _slow_timer: float = 0.0

var _atk_slow_amount: float = 0.0
var _atk_slow_timer: float = 0.0

var _knockback_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	current_hp = GameManager.get_stat("max_hp")
	_update_attack_speed()
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	anim_timer.timeout.connect(_on_anim_timer_timeout)
	bacteriofago_timer.timeout.connect(_on_spawn_bacteriofago)
	EventBus.player_health_changed.emit(current_hp, GameManager.get_stat("max_hp"))
	EventBus.mutation_activated.connect(_on_mutation_activated)
	
	_shoot_sfx = AudioStreamPlayer.new()
	_shoot_sfx.stream = preload("res://assets/audio/disparo_virus.mp3")
	_shoot_sfx.volume_db = -26.0
	_shoot_sfx.max_polyphony = 5
	add_child(_shoot_sfx)
	
	_update_sprite_state()


func _physics_process(delta: float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_amount = 0.0
			
	if _atk_slow_timer > 0.0:
		_atk_slow_timer -= delta
		if _atk_slow_timer <= 0.0:
			_atk_slow_amount = 0.0
			_update_attack_speed()

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_velocity := input_dir * GameManager.get_stat("move_speed") * (1.0 - _slow_amount)
	
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, 15.0 * delta)
	velocity = target_velocity + _knockback_velocity
	
	move_and_slide()
	# Limitar al borde de la arena
	var limit := GameManager.ARENA_HALF_SIZE
	global_position.x = clampf(global_position.x, -limit, limit)
	global_position.y = clampf(global_position.y, -limit, limit)


func _process(delta: float) -> void:
	_process_regen(delta)


# ── Auto-disparo ───────────────────────────────────────────────
func _update_attack_speed() -> void:
	var base_spd = GameManager.get_stat("attack_speed")
	var final_spd = base_spd * (1.0 - _atk_slow_amount)
	# Prevenir división por cero si final_spd llega a 0
	if final_spd <= 0.0: final_spd = 0.1
	attack_timer.wait_time = 1.0 / final_spd


func apply_attack_slow(amount: float, duration: float) -> void:
	_atk_slow_amount = maxf(_atk_slow_amount, amount)
	_atk_slow_timer = maxf(_atk_slow_timer, duration)
	_update_attack_speed()


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
	_shoot_sfx.play()
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
	EventBus.player_damaged.emit()
	EventBus.player_health_changed.emit(current_hp, GameManager.get_stat("max_hp"))
	_update_sprite_state()

	# Flash rojo
	sprite.modulate = Color.RED
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)

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
	_update_sprite_state()


func apply_slow(amount: float, duration: float) -> void:
	_slow_amount = maxf(_slow_amount, amount)
	_slow_timer = duration


# ── Mutaciones: aplicación ─────────────────────────────────────
func _on_mutation_activated(mutation_id: String) -> void:
	match mutation_id:
		"bacteriofago":
			if bacteriofago_timer.is_stopped():
				bacteriofago_timer.start(6.0)
		"creatina_illo":
			var tw := create_tween()
			tw.tween_property(self, "scale", scale * 1.1, 0.5)
		"orbital_cell":
			var cell = orbital_cell_scene.instantiate()
			add_child(cell)
		"reinforced_membrane":
			# Curar el bonus de HP al adquirirlo
			var bonus_hp := GameManager.get_stat("max_hp") - current_hp
			if bonus_hp > 0:
				heal(bonus_hp * 0.25)

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





func _on_spawn_bacteriofago() -> void:
	var nearest := _find_nearest_enemy()
	if not nearest: return
	
	var atk = bacteriofago_attack_scene.instantiate()
	atk.global_position = nearest.global_position
	atk.damage = GameManager.get_stat("attack") * 2.0
	get_parent().add_child(atk)

func _trigger_reactive_spikes() -> void:
	var atk := GameManager.get_stat("attack") * 0.5
	var proj_parent = get_tree().current_scene.get_node("Projectiles")
	for i in 8:
		var proj = ObjectPool.acquire(projectile_scene, proj_parent, global_position)
		proj.direction = Vector2.from_angle(i * TAU / 8.0)
		proj.damage = atk
		proj.speed = 350.0

# ── Animación y estado visual ──────────────────────────────────
func _on_anim_timer_timeout() -> void:
	anim_frame_toggle = 1 - anim_frame_toggle
	_update_sprite_state()

func _update_sprite_state() -> void:
	var mutation_count := GameManager.active_mutations.size()
	var row := clampi(mutation_count, 0, 4)
		
	sprite.frame = row * 2 + anim_frame_toggle


# ── Dibujo de Mutaciones ──────────────────────────────────────
func _draw() -> void:
	pass

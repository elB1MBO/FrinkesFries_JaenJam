extends Area2D
## Proyectil del jugador — vuela en línea recta, daña al primer enemigo,
## soporta crit, life steal y división celular (split shot).

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: float = 10.0
var ttl: float = 2.0
var is_split: bool = false  # Evita división infinita


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	set_deferred("monitoring", true)
	set_deferred("monitorable", false)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(ttl).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var final_damage := damage

		# Crítico
		var crit_chance := GameManager.get_stat("crit_chance")
		if crit_chance > 0.0 and randf() < crit_chance:
			final_damage *= 2.0

		body.take_damage(final_damage)

		# Life steal
		var life_steal := GameManager.get_stat("life_steal")
		if life_steal > 0.0:
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("heal"):
				player.heal(final_damage * life_steal)

		# Split shot
		if not is_split and GameManager.has_mutation("split_shot"):
			_do_split()

	queue_free()


func _do_split() -> void:
	var scene := load("res://scenes/projectiles/projectile.tscn") as PackedScene
	for angle_offset in [-0.4, 0.4]:
		var proj = scene.instantiate()
		proj.global_position = global_position
		proj.direction = direction.rotated(angle_offset)
		proj.damage = damage * 0.6
		proj.speed = speed * 0.85
		proj.is_split = true
		get_tree().current_scene.get_node("Projectiles").call_deferred("add_child", proj)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(0.4, 1.0, 0.4, 0.9))
	draw_circle(Vector2.ZERO, 2.0, Color(0.8, 1.0, 0.8))

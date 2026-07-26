extends Node
## Signal bus global — las señales se emiten y conectan desde otros scripts.

# Combate
@warning_ignore("unused_signal")
signal enemy_killed(enemy_position: Vector2, xp_value: int)
@warning_ignore("unused_signal")
signal player_damaged()
@warning_ignore("unused_signal")
signal player_health_changed(current_hp: float, max_hp: float)
@warning_ignore("unused_signal")
signal player_died()

# Progresión — XP automática al matar
@warning_ignore("unused_signal")
signal xp_gained(amount: int)
@warning_ignore("unused_signal")
signal player_leveled_up(new_level: int)

# Moneda (ADN)
@warning_ignore("unused_signal")
signal currency_collected(amount: int)

# Mutaciones / Stats
@warning_ignore("unused_signal")
signal mutation_activated(mutation_id: String)
@warning_ignore("unused_signal")
signal stats_changed()

# Rondas y Niveles
@warning_ignore("unused_signal")
signal round_timer_tick(seconds_left: int)
@warning_ignore("unused_signal")
signal round_ended(round_number: int)
@warning_ignore("unused_signal")
signal shop_closed()
@warning_ignore("unused_signal")
signal level_changed(level_index: int, level_name: String)
@warning_ignore("unused_signal")
signal game_won()
@warning_ignore("unused_signal")
signal boss_round_started(boss_name: String)
@warning_ignore("unused_signal")
signal boss_spawned(max_hp: float)
@warning_ignore("unused_signal")
signal boss_health_changed(current_hp: float, max_hp: float)
@warning_ignore("unused_signal")
signal boss_defeated()
@warning_ignore("unused_signal")
signal boss_defeated_acknowledged()

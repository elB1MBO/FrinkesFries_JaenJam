extends Node

# Combate
@warning_ignore("unused_signal")
signal enemy_killed(enemy_position: Vector2, xp_value: int)
@warning_ignore("unused_signal")
signal player_health_changed(current_hp: float, max_hp: float)
@warning_ignore("unused_signal")
signal player_died()

# Progresión
@warning_ignore("unused_signal")
signal xp_collected(amount: int)
@warning_ignore("unused_signal")
signal player_leveled_up(new_level: int)
@warning_ignore("unused_signal")
signal currency_collected(amount: int)

# Rondas (Fase 3)
@warning_ignore("unused_signal")
signal wave_completed(wave_number: int)

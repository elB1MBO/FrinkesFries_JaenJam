extends Node

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var death_sfx_player: AudioStreamPlayer = $DeathSFXPlayer
@onready var click_player: AudioStreamPlayer = $ClickPlayer
@onready var dna_player: AudioStreamPlayer = $DNAPlayer
@onready var damage_player: AudioStreamPlayer = $DamagePlayer
@onready var defeat_player: AudioStreamPlayer = $DefeatPlayer
@onready var victory_player: AudioStreamPlayer = $VictoryPlayer
@onready var boss_death_player: AudioStreamPlayer = $BossDeathPlayer

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.level_changed.connect(_on_level_changed)
	EventBus.currency_collected.connect(_on_currency_collected)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.game_won.connect(_on_game_won)
	EventBus.boss_defeated.connect(_on_boss_defeated)

func _on_boss_defeated() -> void:
	boss_death_player.play()

func _on_player_died() -> void:
	bgm_player.stop()
	defeat_player.play()

func _on_game_won() -> void:
	bgm_player.stop()
	victory_player.play()

func _on_player_damaged() -> void:
	damage_player.play()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_player.play()

func _on_currency_collected(_amount: int) -> void:
	dna_player.play()

func _on_enemy_killed(_pos: Vector2, _xp: int) -> void:
	# El max_polyphony del nodo y el bajo volumen evitarán la saturación
	# El parámetro (0.83) hace que empiece a sonar desde el segundo 0.83
	death_sfx_player.play(0.83)

func _on_level_changed(level_idx: int, _level_name: String) -> void:
	_play_music(level_idx)

func _play_music(level_idx: int) -> void:
	# Por ahora solo tenemos la de pulmones
	var stream: AudioStream = null
	if level_idx == 0:
		stream = preload("res://assets/audio/melodia_pulmones.mp3")
	elif level_idx == 1:
		stream = preload("res://assets/audio/melodia_cerebro.mp3")
	elif level_idx == 2:
		stream = preload("res://assets/audio/melodia_corazon.mp3")
		
	if stream != null:
		# Forzar que el MP3 haga loop por si no estaba configurado así en la importación
		if stream is AudioStreamMP3:
			stream.loop = true
			
		if bgm_player.stream != stream:
			bgm_player.stream = stream
			bgm_player.play()
		elif not bgm_player.playing:
			bgm_player.play()

func play_menu_music() -> void:
	var stream = preload("res://assets/audio/melodia_menu.mp3")
	if stream != null:
		if stream is AudioStreamMP3:
			stream.loop = true
		if bgm_player.stream != stream:
			bgm_player.stream = stream
			bgm_player.play()
		elif not bgm_player.playing:
			bgm_player.play()

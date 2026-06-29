extends CharacterBody2D

@export var max_health: int = 100
var health: int = 100
@export var gravity: float = 980.0

# --- SHOOTING ---
@export var shoot_range: float = 600.0
@export var shoot_cooldown: float = 1.0
@export var bullet_damage: int = 15
var shoot_timer: float = 1.5
var is_shooting: bool = false

# --- DODGE / JUMP ---
@export var jump_velocity: float = -700.0
@export var dodge_push_x: float = 160.0   # horizontal push away from player during jump
@export var dodge_cooldown: float = 3.0
var dodge_timer: float = 0.0
var is_dodging: bool = false
var dodge_can_land: bool = false           # prevents landing on the same frame the jump starts
var dodge_land_delay: float = 0.0
var jump_tween: Tween
var shoot_tween: Tween
var hurt_tween: Tween
var walk_tween: Tween
var idle_hframes: int = 6
var is_walking: bool = false

# --- CROUCH / STATE MACHINE ---
enum EnemyState { ADVANCE, CROUCH, STAND }
var _tact_state: EnemyState = EnemyState.ADVANCE
var _state_timer: Timer
var _col_node: CollisionShape2D
var _col_shape: CapsuleShape2D
var is_hurting: bool = false
@export var advance_speed: float = 80.0

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var health_bar: ProgressBar
var approach_area: Area2D
var tutorial_label: Label
var dead_texture: Texture2D
var hurt_texture: Texture2D
var idle_texture: Texture2D
var shot_texture: Texture2D
var jump_texture: Texture2D
var walk_texture: Texture2D

var is_dead := false

var enemy_bullet_script = preload("res://SCRIPTS/ProiettileNemico.gd")
@export var drop_item_scene: PackedScene = preload("res://scenes/vest_pickup.tscn")
@export var raider_index: int = 1
@export var death_tutorial_text: String = "I nemici eliminati possono rilasciare oggetti che ti aiuteranno in battaglia"
@export var use_random_loot: bool = false

var _audio_shoot: AudioStreamPlayer

func _ready() -> void:
	health = max_health
	add_to_group("enemies")

	var base_path = "res://assets/Raider_" + str(raider_index) + "/"
	var idle_path = base_path + "Idle.png"
	if ResourceLoader.exists(idle_path):
		sprite.texture = load(idle_path)

	idle_texture = sprite.texture
	idle_hframes = _hframes(idle_texture)
	sprite.hframes = idle_hframes

	hurt_texture = load(base_path + "Hurt.png")
	dead_texture = load(base_path + "Dead.png")

	var shot_path = base_path + "Shot.png"
	if not ResourceLoader.exists(shot_path):
		shot_path = base_path + "Shot_1.png"
	shot_texture = load(shot_path)

	jump_texture = load(base_path + "Jump.png")
	var walk_path = base_path + "Walk.png"
	if ResourceLoader.exists(walk_path):
		walk_texture = load(walk_path)

	_create_ui()
	_create_tutorials()

	if anim.has_animation("idle"):
		anim.play("idle")

	_col_node = $CollisionShape2D
	_col_shape = _col_node.shape as CapsuleShape2D

	_state_timer = Timer.new()
	_state_timer.one_shot = true
	add_child(_state_timer)
	_state_timer.timeout.connect(_on_state_timer_timeout)
	_state_timer.start(randf_range(2.0, 4.0))

	_audio_shoot = AudioStreamPlayer.new()
	_audio_shoot.stream = load("res://assets/Audio/sfx/shooting.wav")
	_audio_shoot.volume_db = -10.0
	add_child(_audio_shoot)

func _hframes(tex: Texture2D) -> int:
	if tex == null:
		return 1
	var h = tex.get_height()
	return max(1, int(tex.get_width() / h)) if h > 0 else 1

func _create_ui() -> void:
	health_bar = ProgressBar.new()
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	health_bar.modulate = Color(1, 0, 0)
	health_bar.position = Vector2(-25, -60)
	health_bar.size = Vector2(50, 8)
	health_bar.visible = false

	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(1.0, 0.0, 0.0)
	health_bar.add_theme_stylebox_override("background", sb_bg)
	health_bar.add_theme_stylebox_override("fill", sb_fg)

	add_child(health_bar)

func _create_tutorials() -> void:
	approach_area = Area2D.new()
	var coll = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 250.0
	coll.shape = shape
	approach_area.add_child(coll)
	add_child(approach_area)

	approach_area.body_entered.connect(_on_approach_entered)
	approach_area.body_exited.connect(_on_approach_exited)

	tutorial_label = Label.new()
	tutorial_label.position = Vector2(-150, -100)
	tutorial_label.custom_minimum_size = Vector2(300, 0)
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.modulate.a = 0.0

	var settings = LabelSettings.new()
	settings.font_size = 10
	tutorial_label.label_settings = settings

	add_child(tutorial_label)

func _on_approach_entered(body: Node2D) -> void:
	if is_dead: return
	if body.is_in_group("player") and death_tutorial_text != "":
		_show_tutorial("Attenzione, nemico in vista, eliminalo!")

func _on_approach_exited(body: Node2D) -> void:
	if is_dead: return
	if body.is_in_group("player"):
		_hide_tutorial()

var current_tween: Tween

func _show_tutorial(text: String) -> void:
	tutorial_label.text = text
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(tutorial_label, "modulate:a", 1.0, 0.3)

func _hide_tutorial() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(tutorial_label, "modulate:a", 0.0, 0.3)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_dead:
		move_and_slide()
		return

	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		move_and_slide()
		return

	var player = players[0]

	# Always face the player (runs even during jump/shoot)
	sprite.flip_h = player.global_position.x < global_position.x

	shoot_timer -= delta

	velocity.x = 0

	var dist = abs(global_position.x - player.global_position.x)

	match _tact_state:
		EnemyState.CROUCH:
			if shoot_timer <= 0.0 and not is_shooting and dist <= shoot_range:
				_shoot(player)
		_:
			if shoot_timer <= 0.0 and not is_shooting and dist <= shoot_range:
				_shoot(player)
			# Avanza verso il giocatore anche mentre spara
			if _tact_state == EnemyState.ADVANCE and dist > 150.0 and not is_hurting:
				velocity.x = sign(player.global_position.x - global_position.x) * advance_speed

	# Animazione di camminata: attiva solo quando non ci sono animazioni prioritarie
	if not is_shooting and not is_hurting:
		if velocity.x != 0.0 and not is_walking:
			_play_walk()
		elif velocity.x == 0.0 and is_walking:
			_stop_walk()

	move_and_slide()

# --- STATE MACHINE ---
func _on_state_timer_timeout() -> void:
	match _tact_state:
		EnemyState.ADVANCE:
			_start_crouch()
		EnemyState.CROUCH:
			_start_stand()
		EnemyState.STAND:
			_start_advance()

func _start_advance() -> void:
	_tact_state = EnemyState.ADVANCE
	_state_timer.start(randf_range(2.0, 4.0))

func _start_crouch() -> void:
	if is_dead or is_hurting:
		_start_advance()
		return
	_tact_state = EnemyState.CROUCH
	_stop_walk()
	_state_timer.start(randf_range(1.5, 2.5))

func _start_stand() -> void:
	_tact_state = EnemyState.STAND
	_state_timer.start(0.3)

func _enter_crouch_visuals() -> void:
	_col_node.position.y = 48.0
	_col_shape.height = 32.0

func _exit_crouch_visuals() -> void:
	_col_node.position.y = 32.0
	_col_shape.height = 64.0

# True when the player's shoot animation is active and they are facing this enemy.
func _is_player_shooting_at_me(player: Node2D) -> bool:
	var ps = player.get_node_or_null("AnimatedSprite2D")
	if ps == null or ps.animation != "spara":
		return false
	var dir_to_me = global_position.x - player.global_position.x
	var facing_right = not ps.flip_h
	return (dir_to_me > 50.0 and facing_right) or (dir_to_me < -50.0 and not facing_right)

# --- SHOOT ---
func _shoot(player: Node2D) -> void:
	shoot_timer = shoot_cooldown
	_play_shoot()
	_audio_shoot.play()

	var dir_x = sign(player.global_position.x - global_position.x)
	if dir_x == 0:
		dir_x = 1

	var bullet = Area2D.new()
	bullet.set_script(enemy_bullet_script)
	bullet.velocity  = Vector2(dir_x * 900.0, 0)
	bullet.danno     = bullet_damage
	bullet.global_position = global_position + Vector2(dir_x * 160, 80)
	if dir_x < 0:
		bullet.scale.x = -1
	get_parent().add_child(bullet)

func _kill_sprite_tweens() -> void:
	if shoot_tween and shoot_tween.is_valid():
		shoot_tween.kill()
		shoot_tween = null
	if hurt_tween and hurt_tween.is_valid():
		hurt_tween.kill()
		hurt_tween = null
	if jump_tween and jump_tween.is_valid():
		jump_tween.kill()
		jump_tween = null
	if walk_tween and walk_tween.is_valid():
		walk_tween.kill()
		walk_tween = null
	is_walking = false

func _play_shoot() -> void:
	is_shooting = true
	anim.stop()
	sprite.texture = shot_texture
	var frames = _hframes(shot_texture)
	sprite.hframes = frames
	sprite.frame   = 0

	_kill_sprite_tweens()
	shoot_tween = create_tween()
	shoot_tween.tween_property(sprite, "frame", frames - 1, 0.5)
	shoot_tween.tween_callback(func():
		is_shooting = false
		if not is_dead:
			sprite.texture = idle_texture
			sprite.hframes = idle_hframes
			sprite.frame   = 0
			anim.play("idle")
	)

# --- JUMP DODGE ---
func _start_dodge(player: Node2D) -> void:
	is_dodging       = true
	dodge_timer      = dodge_cooldown
	dodge_can_land   = false
	dodge_land_delay = 0.3   # seconds before we start checking for floor again

	# Jump up + push away from the player
	velocity.y = jump_velocity
	var dir_away = sign(global_position.x - player.global_position.x)
	if dir_away == 0:
		dir_away = 1
	velocity.x = dir_away * dodge_push_x

	_kill_sprite_tweens()
	_play_jump()

func _play_jump() -> void:
	anim.stop()
	sprite.texture = jump_texture
	var frames = _hframes(jump_texture)
	sprite.hframes = frames
	sprite.frame   = 0

	jump_tween = create_tween().set_loops()
	jump_tween.tween_property(sprite, "frame", frames - 1, 0.55)
	jump_tween.tween_callback(func(): sprite.frame = 0)

func _play_walk() -> void:
	if walk_texture == null:
		return
	is_walking = true
	if walk_tween and walk_tween.is_valid():
		walk_tween.kill()
	anim.stop()
	sprite.texture = walk_texture
	var frames = _hframes(walk_texture)
	sprite.hframes = frames
	sprite.frame = 0
	walk_tween = create_tween().set_loops()
	walk_tween.tween_property(sprite, "frame", frames - 1, 0.5)
	walk_tween.tween_callback(func(): sprite.frame = 0)

func _stop_walk() -> void:
	is_walking = false
	if walk_tween and walk_tween.is_valid():
		walk_tween.kill()
		walk_tween = null
	sprite.texture = idle_texture
	sprite.hframes = idle_hframes
	sprite.frame = 0
	anim.play("idle")

func _end_dodge() -> void:
	is_dodging = false
	velocity.x  = 0.0
	_kill_sprite_tweens()
	if not is_dead:
		sprite.texture = idle_texture
		sprite.hframes = idle_hframes
		sprite.frame   = 0
		anim.play("idle")

# --- DAMAGE / DEATH (unchanged) ---
func take_damage(amount: int) -> void:
	if is_dead or amount <= 0: return

	health -= amount
	health_bar.value   = health
	health_bar.visible = true

	if health <= 0:
		die()
	else:
		_play_hurt()

func _play_hurt() -> void:
	is_hurting = true
	is_shooting = false
	_exit_crouch_visuals()
	_kill_sprite_tweens()
	anim.stop()
	sprite.texture = hurt_texture
	var frames = _hframes(hurt_texture)
	sprite.hframes = frames
	sprite.frame   = 0

	hurt_tween = create_tween()
	hurt_tween.tween_property(sprite, "frame", frames - 1, 0.4)
	hurt_tween.tween_callback(func():
		is_hurting = false
		if not is_dead:
			sprite.texture = idle_texture
			sprite.hframes = idle_hframes
			sprite.frame   = 0
			anim.play("idle")
	)

func die() -> void:
	is_dead     = true
	is_shooting = false
	is_dodging  = false
	is_hurting  = false
	_kill_sprite_tweens()
	_state_timer.stop()
	_exit_crouch_visuals()

	set_physics_process(false)

	if use_random_loot:
		_drop_random_loot()
	elif drop_item_scene:
		var drop = drop_item_scene.instantiate()
		drop.global_position = global_position + Vector2(0, 110)
		get_parent().call_deferred("add_child", drop)
	$CollisionShape2D.set_deferred("disabled", true)
	health_bar.visible = false

	anim.stop()
	sprite.texture = dead_texture
	var frames = _hframes(dead_texture)
	sprite.hframes = frames
	sprite.frame   = 0

	var death_tween = create_tween()
	death_tween.tween_property(sprite, "frame", frames - 1, 0.6)

	if death_tutorial_text != "":
		_show_tutorial(death_tutorial_text)

	await get_tree().create_timer(4.0).timeout
	if death_tutorial_text != "":
		_hide_tutorial()

	var fade = create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, 1.0)
	await fade.finished
	queue_free()

func _drop_random_loot() -> void:
	var roll = randf()
	var drop_pos = global_position + Vector2(0, 110)

	if roll < 0.4:
		# 40% — Niente
		return
	elif roll < 0.6:
		# 20% — Munizioni
		var loot_script = load("res://SCRIPTS/loot_pickup.gd")
		var pickup = Area2D.new()
		pickup.set_script(loot_script)
		pickup.tipo = "munizioni"
		pickup.scale = Vector2(3.2, 3.2)
		pickup.position = drop_pos
		get_parent().call_deferred("add_child", pickup)
	elif roll < 0.75:
		# 15% — Medikit
		var medikit = load("res://scenes/medikit_pickup.tscn").instantiate()
		medikit.position = drop_pos
		get_parent().call_deferred("add_child", medikit)
	elif roll < 0.9:
		# 15% — Granata
		var loot_script = load("res://SCRIPTS/loot_pickup.gd")
		var pickup = Area2D.new()
		pickup.set_script(loot_script)
		pickup.tipo = "granata"
		pickup.scale = Vector2(3.2, 3.2)
		pickup.position = drop_pos
		get_parent().call_deferred("add_child", pickup)
	else:
		# 10% — Giubbotto antiproiettile
		var vest = load("res://scenes/vest_pickup.tscn").instantiate()
		vest.position = drop_pos
		get_parent().call_deferred("add_child", vest)

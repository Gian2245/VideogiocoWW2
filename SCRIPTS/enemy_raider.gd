extends CharacterBody2D

@export var max_health: int = 100
var health: int = 100
@export var gravity: float = 980.0

# --- SHOOTING ---
@export var shoot_range: float = 600.0
@export var shoot_cooldown: float = 2.5
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

var is_dead := false

var enemy_bullet_script = preload("res://SCRIPTS/ProiettileNemico.gd")
var vest_scene = preload("res://scenes/vest_pickup.tscn")

var _audio_shoot: AudioStreamPlayer

func _ready() -> void:
	health = max_health
	add_to_group("enemies")

	idle_texture = sprite.texture
	hurt_texture = load("res://assets/Raider_1/Hurt.png")
	dead_texture = load("res://assets/Raider_1/Dead.png")
	shot_texture  = load("res://assets/Raider_1/Shot.png")
	jump_texture  = load("res://assets/Raider_1/Jump.png")

	_create_ui()
	_create_tutorials()

	if anim.has_animation("idle"):
		anim.play("idle")

	_audio_shoot = AudioStreamPlayer.new()
	_audio_shoot.stream = load("res://assets/Audio/sfx/shooting.wav")
	_audio_shoot.volume_db = -10.0
	add_child(_audio_shoot)

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
	if body.is_in_group("player"):
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
	dodge_timer  -= delta

	# --- JUMP DODGE: wait to leave the ground, then land when floor is reached again ---
	if is_dodging:
		if not dodge_can_land:
			dodge_land_delay -= delta
			if dodge_land_delay <= 0.0:
				dodge_can_land = true
		elif is_on_floor():
			_end_dodge()
		move_and_slide()
		return

	velocity.x = 0

	# Dodge has priority; can't start while shooting animation is playing
	if dodge_timer <= 0.0 and not is_shooting and _is_player_shooting_at_me(player):
		_start_dodge(player)
	elif shoot_timer <= 0.0 and not is_shooting:
		var dist = abs(global_position.x - player.global_position.x)
		if dist <= shoot_range:
			_shoot(player)

	move_and_slide()

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

func _play_shoot() -> void:
	is_shooting = true
	anim.stop()
	sprite.texture = shot_texture
	var img = shot_texture.get_image()
	var frames = 1
	if img != null:
		frames = int(img.get_size().x / img.get_size().y)
	sprite.hframes = frames
	sprite.frame   = 0

	var tween = create_tween()
	tween.tween_property(sprite, "frame", frames - 1, 0.5)
	tween.tween_callback(func():
		is_shooting = false
		if not is_dead:
			sprite.texture = idle_texture
			sprite.hframes = 6
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

	_play_jump()

func _play_jump() -> void:
	anim.stop()
	sprite.texture = jump_texture
	var img = jump_texture.get_image()
	var frames = 1
	if img != null:
		frames = int(img.get_size().x / img.get_size().y)
	sprite.hframes = frames
	sprite.frame   = 0

	if jump_tween and jump_tween.is_valid():
		jump_tween.kill()
	# Loop the jump frames for the entire air time
	jump_tween = create_tween().set_loops()
	jump_tween.tween_property(sprite, "frame", frames - 1, 0.55)
	jump_tween.tween_callback(func(): sprite.frame = 0)

func _end_dodge() -> void:
	is_dodging = false
	velocity.x  = 0.0
	if jump_tween and jump_tween.is_valid():
		jump_tween.kill()
		jump_tween = null
	if not is_dead:
		sprite.texture = idle_texture
		sprite.hframes = 6
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
	is_shooting = false   # being hit interrupts the shoot animation
	if jump_tween and jump_tween.is_valid():
		jump_tween.kill()
		jump_tween = null
	anim.stop()
	sprite.texture = hurt_texture
	var img = hurt_texture.get_image()
	var frames = 1
	if img != null:
		frames = int(img.get_size().x / img.get_size().y)
	sprite.hframes = frames
	sprite.frame   = 0

	var tween = create_tween()
	tween.tween_property(sprite, "frame", frames - 1, 0.4)
	tween.tween_callback(func():
		if not is_dead:
			sprite.texture = idle_texture
			sprite.hframes = 6
			sprite.frame   = 0
			anim.play("idle")
	)

func die() -> void:
	is_dead     = true
	is_shooting = false
	is_dodging  = false
	if jump_tween and jump_tween.is_valid():
		jump_tween.kill()
		jump_tween = null

	set_physics_process(false)

	if vest_scene:
		var vest = vest_scene.instantiate()
		vest.global_position = global_position + Vector2(0, 110)
		get_parent().call_deferred("add_child", vest)
	$CollisionShape2D.set_deferred("disabled", true)
	health_bar.visible = false

	anim.stop()
	sprite.texture = dead_texture
	var img = dead_texture.get_image()
	var frames = 1
	if img != null:
		frames = int(img.get_size().x / img.get_size().y)
	sprite.hframes = frames
	sprite.frame   = 0

	var tween = create_tween()
	tween.tween_property(sprite, "frame", frames - 1, 0.6)

	_show_tutorial("I nemici eliminati possono rilasciare oggetti che ti aiuteranno in battaglia")

	await get_tree().create_timer(4.0).timeout
	_hide_tutorial()

	var fade = create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, 1.0)
	await fade.finished
	queue_free()

extends CharacterBody2D

@export var max_health: int = 100
var health: int = 100
@export var gravity: float = 980.0

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var health_bar: ProgressBar
var approach_area: Area2D
var tutorial_label: Label
var dead_texture: Texture2D
var hurt_texture: Texture2D
var idle_texture: Texture2D

var is_dead := false

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	
	idle_texture = sprite.texture
	hurt_texture = load("res://assets/Raider_1/Hurt.png")
	dead_texture = load("res://assets/Raider_1/Dead.png")
	
	_create_ui()
	_create_tutorials()
	
	if anim.has_animation("idle"):
		anim.play("idle")

func _create_ui() -> void:
	health_bar = ProgressBar.new()
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	health_bar.modulate = Color(1, 0, 0)
	health_bar.position = Vector2(-25, -60)
	health_bar.size = Vector2(50, 8)
	health_bar.visible = false
	
	# Stile rosso
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(1.0, 0.0, 0.0)
	health_bar.add_theme_stylebox_override("background", sb_bg)
	health_bar.add_theme_stylebox_override("fill", sb_fg)
	
	add_child(health_bar)

func _create_tutorials() -> void:
	# Approach Tutorial
	approach_area = Area2D.new()
	var coll = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 250.0
	coll.shape = shape
	approach_area.add_child(coll)
	add_child(approach_area)
	
	approach_area.body_entered.connect(_on_approach_entered)
	approach_area.body_exited.connect(_on_approach_exited)
	
	# Common Label for tutorials
	tutorial_label = Label.new()
	tutorial_label.position = Vector2(-150, -100)
	tutorial_label.custom_minimum_size = Vector2(300, 0)
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.modulate.a = 0.0
	
	# Imposta un font più piccolo
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
		
	if not is_dead:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var player = players[0]
			# Assumendo che lo sprite originale guardi a destra,
			# lo specchiamo se il giocatore è alla sua sinistra.
			sprite.flip_h = player.global_position.x < global_position.x
			
	move_and_slide()

func take_damage(amount: int) -> void:
	if is_dead or amount <= 0: return
	
	health -= amount
	health_bar.value = health
	health_bar.visible = true
	
	if health <= 0:
		die()
	else:
		_play_hurt()

func _play_hurt() -> void:
	anim.stop()
	sprite.texture = hurt_texture
	var img = hurt_texture.get_image()
	var frames = 1
	if img != null:
		frames = int(img.get_size().x / img.get_size().y)
	sprite.hframes = frames
	sprite.frame = 0
	
	var tween = create_tween()
	tween.tween_property(sprite, "frame", frames - 1, 0.4)
	tween.tween_callback(func():
		if not is_dead:
			sprite.texture = idle_texture
			sprite.hframes = 6
			anim.play("idle")
	)

func die() -> void:
	is_dead = true
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	health_bar.visible = false
	
	anim.stop()
	sprite.texture = dead_texture
	var img = dead_texture.get_image()
	var frames = 1
	if img != null:
		frames = int(img.get_size().x / img.get_size().y)
	sprite.hframes = frames
	sprite.frame = 0
	
	var tween = create_tween()
	tween.tween_property(sprite, "frame", frames - 1, 0.6)
	
	_show_tutorial("I nemici eliminati possono rilasciare oggetti che ti aiuteranno in battaglia")
	
	# Attendi 4 secondi prima di nascondere il testo
	await get_tree().create_timer(4.0).timeout
	_hide_tutorial()
	
	# Dissolvenza del cadavere e rimozione
	var fade = create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, 1.0)
	await fade.finished
	queue_free()

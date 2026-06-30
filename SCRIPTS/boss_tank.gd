extends CharacterBody2D

@export var max_hp: int = 500
var current_hp: int

@export var move_speed: float = 35.0
@export var shoot_interval: float = 3.5
@export var shoot_range: float = 1500.0

var is_dead: bool = false
var _player: Node2D

var projectile_scene: PackedScene = preload("res://scenes/boss_projectile.tscn")
var flash_scene: PackedScene = preload("res://scenes/effect_flash.tscn")

@onready var sprite = $Sprite2D
@onready var cannon = $CannonMarker
@onready var shoot_timer = $ShootTimer

var health_bar: ProgressBar

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	add_to_group("boss")
	
	_player = get_tree().get_first_node_in_group("player")
	
	_create_ui()
	
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot)
	shoot_timer.start()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if not is_on_floor():
		velocity.y += 980 * delta
		
	# Il boss si gira verso il giocatore
	if _player:
		var dir = sign(_player.global_position.x - global_position.x)
		if dir == 0: dir = -1
		
		# Assumendo che l'immagine di base punti verso SINISTRA:
		# Se il giocatore è a destra (dir = 1), lo riflettiamo.
		sprite.flip_h = (dir > 0)
		
		# Il cannone mantiene la sua distanza dal centro, invertendosi a destra o sinistra
		cannon.position.x = abs(cannon.position.x) * dir
		
		# Muove leggermente in avanti (verso il giocatore)
		velocity.x = dir * move_speed
	else:
		velocity.x = -move_speed
	
	move_and_slide()

func _on_shoot() -> void:
	if is_dead:
		return
		
	# CONTROLLO DISTANZA: Se il giocatore esiste ed è più lontano del shoot_range, annulla lo sparo
	if _player and global_position.distance_to(_player.global_position) > shoot_range:
		return
		
	# Crea il proiettile
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		var level_root = get_tree().current_scene # Lo mettiamo nel livello, non nello spawner!
		
		# REGOLA D'ORO: Aggiungi all'albero PRIMA di impostare la global_position
		level_root.add_child(proj) 
		proj.global_position = cannon.global_position
		
		if _player:
			var dir = sign(_player.global_position.x - global_position.x)
			if dir == 0: dir = -1
			proj.direction = Vector2(dir, 0)
			
			if flash_scene:
				var flash = flash_scene.instantiate()
				level_root.add_child(flash) # Prima aggiungi
				flash.global_position = cannon.global_position # Poi posizioni
				if dir > 0:
					flash.scale.x = -1 # Ribalta il flash se spara a destra
				
		else:
			proj.direction = Vector2.LEFT
			if flash_scene:
				var flash = flash_scene.instantiate()
				level_root.add_child(flash) # Prima aggiungi
				flash.global_position = cannon.global_position # Poi posizioni
				
		

func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	current_hp -= amount
	health_bar.value = current_hp
	health_bar.visible = true
	
	# Effetto visivo danno
	modulate = Color(1, 0.5, 0.5)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	if current_hp <= 0:
		die()

func die() -> void:
	is_dead = true
	shoot_timer.stop()
	modulate = Color(0.3, 0.3, 0.3)
	
	# Crea esplosioni sul carro armato
	for i in range(9):
		var exp_scene = load("res://scenes/effect_explosion.tscn")
		if exp_scene:
			var exp = exp_scene.instantiate()
			exp.global_position = global_position + Vector2(randf_range(-100, 100), randf_range(-50, 50))
			get_parent().add_child(exp)
			
	# Aspetta 1 secondo esatto prima di eseguire il codice successivo
	await get_tree().create_timer(0.5).timeout
	
	visible = false
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
		
	await get_tree().create_timer(1.5).timeout
	
	var win_scene_script = load("res://SCRIPTS/win_screen_3.gd")
	if win_scene_script:
		var win_node = CanvasLayer.new()
		win_node.set_script(win_scene_script)
		get_tree().current_scene.add_child(win_node)
		win_node.call("mostra")
		
	# Fai sparire definitivamente il boss dal livello
	queue_free()

func _create_ui() -> void:
	health_bar = ProgressBar.new()
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_bar.show_percentage = false
	health_bar.position = Vector2(-75, -200) # Posizionata sopra il carro
	health_bar.size = Vector2(150, 12)
	health_bar.visible = true
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(1.0, 0.0, 0.0)
	health_bar.add_theme_stylebox_override("background", sb_bg)
	health_bar.add_theme_stylebox_override("fill", sb_fg)
	
	add_child(health_bar)

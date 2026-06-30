extends Area2D

@export var speed: float = 800.0
@export var damage: int = 50

var direction: Vector2 = Vector2.LEFT

var explosion_scene: PackedScene = preload("res://scenes/effect_explosion.tscn")

func _ready() -> void:
	# Distruggi il proiettile dopo 5 secondi se non colpisce nulla
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(queue_free)
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_spawn_explosion()
		queue_free()
	elif body is StaticBody2D: # Pavimento o ostacoli
		_spawn_explosion()
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		_spawn_explosion()
		queue_free()

func _spawn_explosion() -> void:
	if explosion_scene:
		var exp = explosion_scene.instantiate()
		exp.global_position = global_position
		# Aggiungi l'esplosione al padre per non farla distruggere assieme al proiettile
		get_parent().add_child(exp)

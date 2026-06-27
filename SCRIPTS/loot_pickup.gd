extends Area2D

var tipo: String = "munizioni"
var time_passed: float = 0.0
var base_y: float = 0.0
var initialized: bool = false

func _ready() -> void:
	var coll = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	coll.shape = shape
	add_child(coll)
	_crea_visuale()
	connect("body_entered", _on_body_entered)

func _crea_visuale() -> void:
	var sprite = Sprite2D.new()
	if tipo == "munizioni":
		sprite.texture = load("res://assets/Blocchi/ammo-pickup.png")
		sprite.scale = Vector2(0.179, 0.179)
	else:
		sprite.texture = load("res://assets/Blocchi/grenade-pickup.png")
		sprite.scale = Vector2(0.202, 0.202)
	add_child(sprite)

func _process(delta: float) -> void:
	if not initialized:
		base_y = position.y
		initialized = true
	time_passed += delta
	position.y = base_y + sin(time_passed * 3.5) * 6.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if tipo == "munizioni" and body.has_method("raccogli_munizioni"):
			body.raccogli_munizioni()
		elif tipo == "granata" and body.has_method("raccogli_granata"):
			body.raccogli_granata()
		queue_free()

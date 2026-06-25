extends Area2D

var velocity = Vector2.ZERO
var danno = 20

func _ready() -> void:
	# Creiamo la grafica del proiettile
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-20, -3), Vector2(20, -3), Vector2(20, 3), Vector2(-20, 3)])
	poly.color = Color(1.0, 0.8, 0.1, 1.0) # Giallo-Arancio luminoso
	add_child(poly)
	
	# Effetto scia (glow)
	var glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([Vector2(-30, -6), Vector2(25, -6), Vector2(25, 6), Vector2(-30, 6)])
	glow.color = Color(1.0, 0.5, 0.0, 0.3)
	add_child(glow)

	# Collisione
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 6)
	shape.shape = rect
	add_child(shape)
	
	body_entered.connect(_on_body_entered)
	
	# Autodistruzione dopo 2 secondi per evitare di accumulare proiettili fuori schermo
	get_tree().create_timer(2.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
		
	if body.is_in_group("enemies") or body.is_in_group("breakable"):
		if body.has_method("take_damage") and body.get("is_dead") != true:
			body.take_damage(danno)
		queue_free()
	elif body is StaticBody2D: # Pavimento o casse non breakable
		queue_free()

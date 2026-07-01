extends Area2D

var velocity = Vector2.ZERO
var danno = 15

func _ready() -> void:
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-20, -3), Vector2(20, -3), Vector2(20, 3), Vector2(-20, 3)])
	poly.color = Color(1.0, 0.15, 0.1, 1.0)
	add_child(poly)

	var glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([Vector2(-28, -5), Vector2(28, -5), Vector2(28, 5), Vector2(-28, 5)])
	glow.color = Color(0.9, 0.0, 0.0, 0.3)
	add_child(glow)

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 6)
	shape.shape = rect
	add_child(shape)

	body_entered.connect(_on_body_entered)
	get_tree().create_timer(2.5).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		return
	if body.is_in_group("player"):
		# Se il giocatore sta schivando: segnala il colpo sfiorato (per ricompensa adrenalina)
		# e non applica danno (l'invincibilità è gestita da take_damage)
		if body.has_method("segnala_colpo_in_arrivo"):
			body.segnala_colpo_in_arrivo()
		if body.has_method("take_damage"):
			body.take_damage(danno)
		queue_free()
	elif body is StaticBody2D:
		queue_free()

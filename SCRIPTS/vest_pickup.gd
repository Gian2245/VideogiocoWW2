extends Area2D

var time_passed: float = 0.0
var base_y: float = 0.0
var initialized := false

func _ready() -> void:
	connect("body_entered", _on_body_entered)

func _process(delta: float) -> void:
	if not initialized:
		base_y = position.y
		initialized = true
		
	time_passed += delta
	# Lieve oscillazione rotatoria
	rotation = sin(time_passed * 2.5) * 0.15
	# Movimento fluttuante su e giù
	position.y = base_y + sin(time_passed * 4.0) * 10.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("raccogli_giubbotto"):
			body.raccogli_giubbotto()
			queue_free()

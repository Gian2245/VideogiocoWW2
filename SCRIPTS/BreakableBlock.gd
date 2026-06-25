extends StaticBody2D

@export var texture_to_use: Texture2D

var hits: int = 0

func _ready() -> void:
	if texture_to_use:
		$Sprite2D.texture = texture_to_use

func take_damage(amount: int) -> void:
	hits += 1
	
	# Animazione per indicare il danno (lampeggia di rosso)
	var tween = create_tween()
	$Sprite2D.modulate = Color(1, 0, 0, 1)
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1), 0.2)
	
	if hits >= 2:
		queue_free()

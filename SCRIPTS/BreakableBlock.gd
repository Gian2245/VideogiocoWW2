extends StaticBody2D

@export var texture_to_use: Texture2D

var hp: int = 20

func _ready() -> void:
	if texture_to_use:
		$Sprite2D.texture = texture_to_use
		var new_shape = $CollisionShape2D.shape.duplicate()
		var tex_path = texture_to_use.resource_path.get_file()
		if tex_path == "blocco3.png":
			new_shape.size = Vector2(213, 234)
			$CollisionShape2D.position = Vector2(-4.5, 5.5)
		elif tex_path == "blocco4.png":
			new_shape.size = Vector2(192, 235)
			$CollisionShape2D.position = Vector2(-4, 3)
		elif tex_path == "blocco5.png":
			new_shape.size = Vector2(195, 235)
			$CollisionShape2D.position = Vector2(-43, 17.5)
		else:
			new_shape.size = texture_to_use.get_size()
		$CollisionShape2D.shape = new_shape

func take_damage(amount: int) -> void:
	hp -= amount
	
	if hp <= 0:
		queue_free()
	else:
		# Animazione per indicare il danno (lampeggia di rosso)
		var tween = create_tween()
		$Sprite2D.modulate = Color(1, 0, 0, 1)
		tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1), 0.2)

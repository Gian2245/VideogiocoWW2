extends StaticBody2D

@export var texture_to_use: Texture2D

# Exactly 2 melee hits to break — damage amount is ignored, each call = 1 hit.
var hp: int = 2

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

func take_damage(_amount: int) -> void:
	hp -= 1

	if hp <= 0:
		_break()
	else:
		_hit_feedback()

func _hit_feedback() -> void:
	# Red flash
	$Sprite2D.modulate = Color(1.0, 0.0, 0.0, 1.0)
	var flash = create_tween()
	flash.tween_property($Sprite2D, "modulate", Color(0.72, 0.52, 0.52, 1.0), 0.25)

	# Upward bounce to indicate impact
	var bounce = create_tween()
	bounce.tween_property($Sprite2D, "position:y", -12.0, 0.08).set_ease(Tween.EASE_OUT)
	bounce.tween_property($Sprite2D, "position:y",   0.0, 0.12).set_ease(Tween.EASE_IN)

func _break() -> void:
	# Disable collision immediately so the player isn't stuck
	$CollisionShape2D.set_deferred("disabled", true)

	# Quick scale-down then remove
	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2.ZERO, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)

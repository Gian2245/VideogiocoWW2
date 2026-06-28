extends StaticBody2D

# Cassa di rifornimento — Livello 2
# Si rompe con 2 colpi (melee o arma da fuoco).
# Droppa un oggetto casuale (20% ciascuno) oppure niente (20%).

var hp: int = 2

func _ready() -> void:
	add_to_group("breakable")

	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var textures = [
		"res://assets/Blocchi/blocco3.png",
		"res://assets/Blocchi/blocco4.png",
		"res://assets/Blocchi/blocco5.png"
	]
	sprite.texture = load(textures.pick_random())
	add_child(sprite)

	var coll = CollisionShape2D.new()
	coll.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(200, 230)
	coll.shape = shape
	add_child(coll)

func take_damage(_amount: int) -> void:
	hp -= 1
	if hp <= 0:
		_break()
	else:
		_hit_feedback()

func _hit_feedback() -> void:
	$Sprite2D.modulate = Color(1.0, 0.0, 0.0, 1.0)
	var flash = create_tween()
	flash.tween_property($Sprite2D, "modulate", Color(0.72, 0.52, 0.52, 1.0), 0.25)

	var bounce = create_tween()
	bounce.tween_property($Sprite2D, "position:y", -12.0, 0.08).set_ease(Tween.EASE_OUT)
	bounce.tween_property($Sprite2D, "position:y", 0.0, 0.12).set_ease(Tween.EASE_IN)

func _break() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	_drop_loot()

	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2.ZERO, 0.15) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)

func _drop_loot() -> void:
	var roll = randf()
	var drop_pos = global_position + Vector2(0, -80)

	if roll < 0.2:
		# 20% — Niente
		return
	elif roll < 0.4:
		# 20% — Munizioni
		var loot_script = load("res://SCRIPTS/loot_pickup.gd")
		var pickup = Area2D.new()
		pickup.set_script(loot_script)
		pickup.tipo = "munizioni"
		pickup.scale = Vector2(3.2, 3.2)
		pickup.position = drop_pos
		get_parent().call_deferred("add_child", pickup)
	elif roll < 0.6:
		# 20% — Medikit
		var medikit = load("res://scenes/medikit_pickup.tscn").instantiate()
		medikit.position = drop_pos
		get_parent().call_deferred("add_child", medikit)
	elif roll < 0.8:
		# 20% — Granata
		var loot_script = load("res://SCRIPTS/loot_pickup.gd")
		var pickup = Area2D.new()
		pickup.set_script(loot_script)
		pickup.tipo = "granata"
		pickup.scale = Vector2(3.2, 3.2)
		pickup.position = drop_pos
		get_parent().call_deferred("add_child", pickup)
	else:
		# 20% — Giubbotto antiproiettile
		var vest = load("res://scenes/vest_pickup.tscn").instantiate()
		vest.position = drop_pos
		get_parent().call_deferred("add_child", vest)

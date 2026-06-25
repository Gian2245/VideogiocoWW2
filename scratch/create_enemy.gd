extends SceneTree

func _init():
	var root = CharacterBody2D.new()
	root.name = "EnemyRaider1"
	
	var script = load("res://SCRIPTS/enemy_raider.gd")
	root.set_script(script)
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = load("res://assets/Raider_1/Idle.png")
	sprite.hframes = 6
	root.add_child(sprite)
	sprite.owner = root
	
	var coll = CollisionShape2D.new()
	coll.name = "CollisionShape2D"
	var shape = CapsuleShape2D.new()
	shape.radius = 16.0
	shape.height = 64.0
	coll.shape = shape
	coll.position = Vector2(0, 16)
	root.add_child(coll)
	coll.owner = root
	
	var anim = AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	
	var lib = AnimationLibrary.new()
	var idle_anim = Animation.new()
	idle_anim.length = 0.6
	idle_anim.loop_mode = Animation.LOOP_LINEAR
	var track = idle_anim.add_track(Animation.TYPE_VALUE)
	idle_anim.track_set_path(track, "Sprite2D:frame")
	for i in range(6):
		idle_anim.track_insert_key(track, i * 0.1, i)
	idle_anim.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
	
	lib.add_animation("idle", idle_anim)
	anim.add_animation_library("", lib)
	anim.autoplay = "idle"
	
	root.add_child(anim)
	anim.owner = root
	
	var pack = PackedScene.new()
	pack.pack(root)
	ResourceSaver.save(pack, "res://scenes/enemy_raider_1.tscn")
	
	print("Enemy created successfully.")
	quit()

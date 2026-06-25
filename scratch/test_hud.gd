extends SceneTree

func _init():
	var packed_scene = load("res://scenes/HUD.tscn")
	if not packed_scene:
		print("Failed to load HUD.tscn")
		quit()
		return
		
	var hud = packed_scene.instantiate()
	if not hud:
		print("Failed to instantiate HUD")
		quit()
		return
		
	print("HUD instantiated successfully.")
	print("Has ArmorRoot: ", hud.has_node("ArmorRoot"))
	if hud.has_node("ArmorRoot"):
		var armor_root = hud.get_node("ArmorRoot")
		print("ArmorRoot children: ", armor_root.get_children())
	
	print("Has %ArmorValue: ", hud.get_node_or_null("%ArmorValue") != null)
	print("Has %ArmorSegments: ", hud.get_node_or_null("%ArmorSegments") != null)
	
	quit()

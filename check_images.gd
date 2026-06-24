extends SceneTree

func _init():
	var images = [
		"res://assets/Raider_1/Idle.png",
		"res://assets/Raider_1/Hurt.png",
		"res://assets/Raider_1/Dead.png"
	]
	
	for path in images:
		var img = Image.load_from_file(path.replace("res://", "c:/EsameVideogiochi/VideogiocoWW2/"))
		if img != null:
			var size = img.get_size()
			var frames = size.x / size.y
			print(path, " - Size: ", size, " - Estimated frames (x/y): ", frames)
		else:
			print("Could not load ", path)
			
	quit()

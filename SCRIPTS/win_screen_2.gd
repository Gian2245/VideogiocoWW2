extends CanvasLayer

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("win_screen")
	visible = false
	_build_ui()

func _build_ui() -> void:
	var overlay = ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1280, 720)
	overlay.color = Color(0.0, 0.0, 0.0, 0.88)
	add_child(overlay)

	var title = Label.new()
	title.text = "Preparati per lo scontro finale"
	title.position = Vector2(0, 185)
	title.size = Vector2(1280, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ts = LabelSettings.new()
	ts.font_size = 62
	ts.font_color = Color(0.95, 0.82, 0.10)
	ts.outline_size = 6
	ts.outline_color = Color(0.0, 0.0, 0.0)
	title.label_settings = ts
	add_child(title)

	var subtitle = Label.new()
	subtitle.text = ""
	subtitle.position = Vector2(0, 318)
	subtitle.size = Vector2(1280, 60)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ss = LabelSettings.new()
	ss.font_size = 28
	ss.font_color = Color(0.85, 0.85, 0.85)
	ss.outline_size = 3
	ss.outline_color = Color(0.0, 0.0, 0.0)
	subtitle.label_settings = ss
	add_child(subtitle)

	# --- Pulsante "Prossimo Livello" (centrato a destra) ---
	var btn = Button.new()
	btn.text = "Prossimo Livello  →"
	btn.position = Vector2(660, 430)
	btn.size = Vector2(280, 56)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(_on_prossimo_livello)
	add_child(btn)

	# --- Pulsante "Rigioca Livello" (centrato a sinistra) ---
	var btn_replay = Button.new()
	btn_replay.text = "↺  Rigioca Livello"
	btn_replay.position = Vector2(340, 430)
	btn_replay.size = Vector2(280, 56)
	btn_replay.add_theme_font_size_override("font_size", 22)
	btn_replay.pressed.connect(_on_rigioca_livello)
	add_child(btn_replay)

	var coming_soon = Label.new()
	coming_soon.name = "ComingSoon"
	coming_soon.text = "Prossimo livello in arrivo..."
	coming_soon.position = Vector2(0, 510)
	coming_soon.size = Vector2(1280, 50)
	coming_soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coming_soon.visible = false
	var cs = LabelSettings.new()
	cs.font_size = 20
	cs.font_color = Color(0.55, 0.55, 0.55)
	cs.outline_size = 2
	cs.outline_color = Color.BLACK
	coming_soon.label_settings = cs
	add_child(coming_soon)

func mostra() -> void:
	visible = true
	get_tree().paused = true

func _on_prossimo_livello() -> void:
	if ResourceLoader.exists("res://scenes/boss_scene.tscn"):
		# Salva l'inventario del giocatore prima di cambiare livello
		var player = get_tree().get_first_node_in_group("player")
		if player:
			PlayerData.salva_da_player(player)
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/boss_scene.tscn")
	else:
		if has_node("ComingSoon"):
			$ComingSoon.visible = true

func _on_rigioca_livello() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game2.tscn")

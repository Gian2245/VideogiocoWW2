extends CanvasLayer

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_over_screen")
	visible = false
	_build_ui()

func _build_ui() -> void:
	var overlay = ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1280, 720)
	overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	add_child(overlay)

	var title = Label.new()
	title.text = "GAME OVER"
	title.position = Vector2(0, 230)
	title.size = Vector2(1280, 130)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ts = LabelSettings.new()
	ts.font_size = 84
	ts.font_color = Color(0.92, 0.10, 0.08)
	ts.outline_size = 6
	ts.outline_color = Color(0.0, 0.0, 0.0)
	title.label_settings = ts
	add_child(title)

	var btn = Button.new()
	btn.text = "Riprova"
	btn.position = Vector2(530, 400)
	btn.size = Vector2(220, 56)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_on_restart)
	add_child(btn)

func mostra() -> void:
	visible = true
	get_tree().paused = true

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

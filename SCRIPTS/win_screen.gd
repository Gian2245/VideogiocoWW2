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
	overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	add_child(overlay)

	var title = Label.new()
	title.text = "MISSIONE COMPLETATA"
	title.position = Vector2(0, 210)
	title.size = Vector2(1280, 130)
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
	subtitle.text = "Ottimo lavoro, soldato!"
	subtitle.position = Vector2(0, 340)
	subtitle.size = Vector2(1280, 60)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ss = LabelSettings.new()
	ss.font_size = 28
	ss.font_color = Color(0.85, 0.85, 0.85)
	ss.outline_size = 3
	ss.outline_color = Color(0.0, 0.0, 0.0)
	subtitle.label_settings = ss
	add_child(subtitle)

	var btn = Button.new()
	btn.text = "Rigioca"
	btn.position = Vector2(530, 430)
	btn.size = Vector2(220, 56)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_on_rigioca)
	add_child(btn)

func mostra() -> void:
	visible = true
	get_tree().paused = true

func _on_rigioca() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

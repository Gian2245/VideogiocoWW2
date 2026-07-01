extends Control

# ============================================================
# Schermata di selezione livello, raggiungibile dal menu principale
# tramite il pulsante "LIVELLI".
# ============================================================

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

const LIVELLI := [
	{"nome": "Livello 1 — Sbarco", "scena": "res://scenes/game1.tscn"},
	{"nome": "Livello 2 — Avanzata", "scena": "res://scenes/game2.tscn"},
	{"nome": "Scontro Finale", "scena": "res://scenes/boss_scene.tscn"},
]

func _ready() -> void:
	var overlay = ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1280, 720)
	overlay.color = Color(0.05, 0.05, 0.08, 0.95)
	add_child(overlay)

	var title = Label.new()
	title.text = "SELEZIONA LIVELLO"
	title.position = Vector2(0, 90)
	title.size = Vector2(1280, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts = LabelSettings.new()
	ts.font_size = 48
	ts.font_color = Color(0.95, 0.82, 0.10)
	ts.outline_size = 6
	ts.outline_color = Color(0.0, 0.0, 0.0)
	title.label_settings = ts
	add_child(title)

	var start_y = 260
	for livello in LIVELLI:
		var btn = Button.new()
		btn.text = livello["nome"]
		btn.position = Vector2(440, start_y)
		btn.size = Vector2(400, 60)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_livello_pressed.bind(livello["scena"]))
		add_child(btn)
		start_y += 80

	var btn_indietro = Button.new()
	btn_indietro.text = "←  Indietro"
	btn_indietro.position = Vector2(40, 630)
	btn_indietro.size = Vector2(160, 50)
	btn_indietro.add_theme_font_size_override("font_size", 20)
	btn_indietro.pressed.connect(_on_indietro_pressed)
	add_child(btn_indietro)

func _on_livello_pressed(scena: String) -> void:
	PlayerData.reset()
	get_tree().change_scene_to_file(scena)

func _on_indietro_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

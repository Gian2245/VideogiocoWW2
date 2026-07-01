extends CanvasLayer

# Soglie medaglie Livello 1 (in secondi)
const SOGLIA_ORO := 35.0      # entro 35"
const SOGLIA_ARGENTO := 50.0  # entro 50"
const SOGLIA_BRONZO := 90.0   # entro 1'30"

var _medaglia_label: Label
var _tempo_label: Label

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
	title.text = "Bene, sei pronto!"
	title.position = Vector2(0, 135)
	title.size = Vector2(1280, 110)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ts = LabelSettings.new()
	ts.font_size = 62
	ts.font_color = Color(0.95, 0.82, 0.10)
	ts.outline_size = 6
	ts.outline_color = Color(0.0, 0.0, 0.0)
	title.label_settings = ts
	add_child(title)

	# --- Medaglia (riempita in mostra()) ---
	_medaglia_label = Label.new()
	_medaglia_label.position = Vector2(0, 268)
	_medaglia_label.size = Vector2(1280, 54)
	_medaglia_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ms = LabelSettings.new()
	ms.font_size = 34
	ms.outline_size = 5
	ms.outline_color = Color.BLACK
	_medaglia_label.label_settings = ms
	add_child(_medaglia_label)

	_tempo_label = Label.new()
	_tempo_label.position = Vector2(0, 330)
	_tempo_label.size = Vector2(1280, 28)
	_tempo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tl = LabelSettings.new()
	tl.font_size = 18
	tl.font_color = Color(0.85, 0.85, 0.85)
	tl.outline_size = 2
	tl.outline_color = Color.BLACK
	_tempo_label.label_settings = tl
	add_child(_tempo_label)

	var subtitle = Label.new()
	subtitle.text = "Ora incomincia la vera sfida"
	subtitle.position = Vector2(0, 372)
	subtitle.size = Vector2(1280, 50)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ss = LabelSettings.new()
	ss.font_size = 26
	ss.font_color = Color(0.85, 0.85, 0.85)
	ss.outline_size = 3
	ss.outline_color = Color(0.0, 0.0, 0.0)
	subtitle.label_settings = ss
	add_child(subtitle)

	# --- Pulsante "Prossimo Livello" (centrato a destra) ---
	var btn = Button.new()
	btn.text = "Prossimo Livello  →"
	btn.position = Vector2(660, 440)
	btn.size = Vector2(280, 56)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(_on_prossimo_livello)
	add_child(btn)

	# --- Pulsante "Rigioca Tutorial" (centrato a sinistra) ---
	var btn_replay = Button.new()
	btn_replay.text = "↺  Rigioca Tutorial"
	btn_replay.position = Vector2(340, 440)
	btn_replay.size = Vector2(280, 56)
	btn_replay.add_theme_font_size_override("font_size", 22)
	btn_replay.pressed.connect(_on_rigioca_tutorial)
	add_child(btn_replay)

	var coming_soon = Label.new()
	coming_soon.name = "ComingSoon"
	coming_soon.text = "Prossimo livello in arrivo..."
	coming_soon.position = Vector2(0, 516)
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
	# Ferma il cronometro del livello e leggi il tempo finale
	var secondi := 0.0
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("ferma_timer"):
		hud.ferma_timer()
		secondi = hud.get_tempo_trascorso()
	var medaglia := _calcola_medaglia(secondi)
	Progress.completa_livello(0, medaglia)
	_mostra_risultato(secondi, medaglia)
	get_tree().paused = true

func _mostra_risultato(secondi: float, medaglia: int) -> void:
	var testo := ""
	var colore := Color(0.7, 0.7, 0.7)
	match medaglia:
		3:
			testo = "🥇  MEDAGLIA D'ORO"
			colore = Color(1.0, 0.84, 0.0)
		2:
			testo = "🥈  MEDAGLIA D'ARGENTO"
			colore = Color(0.85, 0.85, 0.9)
		1:
			testo = "🥉  MEDAGLIA DI BRONZO"
			colore = Color(0.85, 0.55, 0.25)
		_:
			testo = "Nessuna medaglia"
			colore = Color(0.7, 0.7, 0.7)

	_medaglia_label.text = testo
	_medaglia_label.label_settings.font_color = colore
	_tempo_label.text = "Tempo: " + _format_tempo(secondi)

func _calcola_medaglia(secondi: float) -> int:
	if secondi <= SOGLIA_ORO:
		return 3
	elif secondi <= SOGLIA_ARGENTO:
		return 2
	elif secondi <= SOGLIA_BRONZO:
		return 1
	return 0

func _format_tempo(secondi: float) -> String:
	var totale := int(secondi)
	return "%02d:%02d" % [totale / 60, totale % 60]

func _on_prossimo_livello() -> void:
	if ResourceLoader.exists("res://scenes/game2.tscn"):
		# Salva l'inventario del giocatore prima di cambiare livello
		var player = get_tree().get_first_node_in_group("player")
		if player:
			PlayerData.salva_da_player(player)
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/game2.tscn")
	else:
		if has_node("ComingSoon"):
			$ComingSoon.visible = true

func _on_rigioca_tutorial() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game1.tscn")

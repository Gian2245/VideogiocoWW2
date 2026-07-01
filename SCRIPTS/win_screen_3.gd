extends CanvasLayer

# Soglie medaglie Livello Boss (in secondi)
const SOGLIA_ORO := 45.0      
const SOGLIA_ARGENTO := 75.0  
const SOGLIA_BRONZO := 120.0   

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
	title.text = "ESECUZIONE ESEMPLARE, SOLDATO!"
	title.position = Vector2(0, 60)
	title.size = Vector2(1280, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ts = LabelSettings.new()
	ts.font_size = 56
	ts.font_color = Color(0.95, 0.82, 0.10) # Giallo oro
	ts.outline_size = 6
	ts.outline_color = Color(0.0, 0.0, 0.0)
	title.label_settings = ts
	add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Hai distrutto il Panzer e messo in sicurezza l'area. La missione è un successo."
	subtitle.position = Vector2(0, 140)
	subtitle.size = Vector2(1280, 40)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ss = LabelSettings.new()
	ss.font_size = 24
	ss.font_color = Color(0.85, 0.85, 0.85)
	ss.outline_size = 3
	ss.outline_color = Color(0.0, 0.0, 0.0)
	subtitle.label_settings = ss
	add_child(subtitle)

	# --- Medaglia e Tempo ---
	_medaglia_label = Label.new()
	_medaglia_label.position = Vector2(0, 200)
	_medaglia_label.size = Vector2(1280, 40)
	_medaglia_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ms = LabelSettings.new()
	ms.font_size = 30
	ms.outline_size = 5
	ms.outline_color = Color.BLACK
	_medaglia_label.label_settings = ms
	add_child(_medaglia_label)

	_tempo_label = Label.new()
	_tempo_label.position = Vector2(0, 240)
	_tempo_label.size = Vector2(1280, 28)
	_tempo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tl = LabelSettings.new()
	tl.font_size = 18
	tl.font_color = Color(0.85, 0.85, 0.85)
	tl.outline_size = 2
	tl.outline_color = Color.BLACK
	_tempo_label.label_settings = tl
	add_child(_tempo_label)

	# --- Testo Promo ---
	var promo = Label.new()
	promo.text = "Ma non abbassare la guardia: la vera guerra è appena iniziata e questa era solo la demo!\nIl fronte ha bisogno delle tue abilità. Nel gioco completo ti aspetta l'inferno in terra:\nsblocca un arsenale di nuove armi devastanti, sopravvivi a ondate implacabili di nemici\ne preparati ad affrontare scontri e boss fight sempre più brutali ed estremi.\n\nHai il fegato per tornare in trincea?"
	promo.position = Vector2(100, 280)
	promo.size = Vector2(1080, 280)
	promo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	promo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	promo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ps = LabelSettings.new()
	ps.font_size = 20
	ps.font_color = Color(1.0, 1.0, 1.0)
	ps.outline_size = 3
	ps.outline_color = Color.BLACK
	ps.line_spacing = 6.0
	promo.label_settings = ps
	add_child(promo)

	# --- Pulsante "Esci dal Gioco" (centrato in basso) ---
	var btn_exit = Button.new()
	btn_exit.text = "✖  Esci dal Gioco"
	btn_exit.position = Vector2(500, 580)
	btn_exit.size = Vector2(280, 56)
	btn_exit.add_theme_font_size_override("font_size", 22)
	btn_exit.pressed.connect(_on_esci)
	add_child(btn_exit)

func mostra() -> void:
	visible = true
	# Ferma il cronometro del livello e leggi il tempo finale
	var secondi := 0.0
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("ferma_timer"):
		hud.ferma_timer()
		secondi = hud.get_tempo_trascorso()
	var medaglia := _calcola_medaglia(secondi)
	Progress.completa_livello(2, medaglia)
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

func _on_esci() -> void:
	get_tree().quit()

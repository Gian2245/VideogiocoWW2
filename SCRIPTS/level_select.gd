extends Control

# ============================================================
# Schermata di selezione livello, raggiungibile dal menu principale
# tramite il pulsante "LIVELLI".
#
# Ogni livello è mostrato come una scheda con numero, nome,
# descrizione ed eventuale tag "BOSS". Una scheda è bloccata finché
# il livello precedente non viene completato (vedi autoload
# "Progress" in SCRIPTS/progress_data.gd) e mostra la medaglia
# migliore ottenuta (oro / argento / bronzo / nessuna).
# ============================================================

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const PIXEL_FONT: Font = preload("res://assets/Fonts/PressStart2P-Regular.ttf")
const BACKGROUND_TEX: Texture2D = preload("res://assets/Lone Commando - Main Menu.png")

const CARD_SIZE := Vector2(317, 258)
const CARD_START_X := 124
const CARD_GAP := 37
const CARD_Y := 200

const COLOR_GOLD := Color(0.95, 0.75, 0.25)
const COLOR_BOSS := Color(0.92, 0.42, 0.18)
const COLOR_BORDER_IDLE := Color(0.32, 0.34, 0.4)

const NOMI_MEDAGLIE := ["Nessuna medaglia", "🥉 Bronzo", "🥈 Argento", "🥇 Oro"]
const COLORI_MEDAGLIE := [
	Color(0.65, 0.65, 0.65),
	Color(0.85, 0.55, 0.25),
	Color(0.85, 0.85, 0.9),
	Color(1.0, 0.84, 0.0),
]

const LIVELLI := [
	{
		"nome": "SBARCO",
		"desc": "Infiltrazione al campo\nmilitare",
		"scena": "res://scenes/game1.tscn",
		"boss": false,
		"colore": Color(0.14, 0.19, 0.28),
	},
	{
		"nome": "AVANZATA",
		"desc": "Oltre le linee nemiche",
		"scena": "res://scenes/game2.tscn",
		"boss": false,
		"colore": Color(0.13, 0.2, 0.16),
	},
	{
		"nome": "SCONTRO FINALE",
		"desc": "Assalto finale alla\nroccaforte",
		"scena": "res://scenes/boss_scene.tscn",
		"boss": true,
		"colore": Color(0.3, 0.15, 0.1),
	},
]

var _cards: Array = []
var _selected_index: int = 0

func _ready() -> void:
	_build_background()
	_build_header()

	var x := CARD_START_X
	for i in range(LIVELLI.size()):
		_cards.append(_build_card(i, LIVELLI[i], Vector2(x, CARD_Y)))
		x += int(CARD_SIZE.x) + CARD_GAP

	_build_back_button()
	_aggiorna_schede()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		_seleziona((_selected_index + 1) % _cards.size())
	elif event.is_action_pressed("ui_left"):
		_seleziona((_selected_index - 1 + _cards.size()) % _cards.size())
	elif event.is_action_pressed("ui_accept"):
		_conferma_selezione(_selected_index)
	elif event.is_action_pressed("ui_cancel"):
		_on_indietro_pressed()

# --- Costruzione UI ---

func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = BACKGROUND_TEX
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	var overlay := ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.01, 0.01, 0.03, 0.88)
	add_child(overlay)

func _build_header() -> void:
	var title := Label.new()
	title.text = "LIVELLI"
	title.position = Vector2(0, 40)
	title.size = Vector2(1280, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := LabelSettings.new()
	ts.font = PIXEL_FONT
	ts.font_size = 44
	ts.font_color = Color(0.95, 0.82, 0.10)
	ts.outline_size = 6
	ts.outline_color = Color(0.0, 0.0, 0.0)
	title.label_settings = ts
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "SELEZIONA LA MISSIONE"
	subtitle.position = Vector2(0, 118)
	subtitle.size = Vector2(1280, 26)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ss := LabelSettings.new()
	ss.font = PIXEL_FONT
	ss.font_size = 13
	ss.font_color = Color(0.85, 0.85, 0.85)
	ss.outline_size = 3
	ss.outline_color = Color(0.0, 0.0, 0.0)
	subtitle.label_settings = ss
	add_child(subtitle)

func _build_back_button() -> void:
	var btn := Button.new()
	btn.text = "←  INDIETRO"
	btn.position = Vector2(30, 26)
	btn.size = Vector2(200, 36)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", PIXEL_FONT)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.85, 0.89, 0.95))
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
	btn.pressed.connect(_on_indietro_pressed)
	add_child(btn)

func _build_card(indice: int, dati: Dictionary, pos: Vector2) -> Dictionary:
	var root := Control.new()
	root.position = pos
	root.size = CARD_SIZE
	add_child(root)

	var panel := Panel.new()
	panel.size = CARD_SIZE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.92)
	style.set_border_width_all(2)
	style.border_color = COLOR_BORDER_IDLE
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var thumb_h := CARD_SIZE.y * 0.6
	var thumb := ColorRect.new()
	thumb.position = Vector2(2, 2)
	thumb.size = Vector2(CARD_SIZE.x - 4, thumb_h - 2)
	thumb.color = dati.get("colore", Color(0.15, 0.15, 0.2))
	root.add_child(thumb)

	var badge := Panel.new()
	badge.position = Vector2(12, 12)
	badge.size = Vector2(50, 38)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	badge_style.set_corner_radius_all(3)
	badge.add_theme_stylebox_override("panel", badge_style)
	root.add_child(badge)

	var numero := Label.new()
	numero.text = "%02d" % (indice + 1)
	numero.size = badge.size
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ns := LabelSettings.new()
	ns.font = PIXEL_FONT
	ns.font_size = 16
	ns.font_color = Color.WHITE
	numero.label_settings = ns
	badge.add_child(numero)

	if dati.get("boss", false):
		var tag := Panel.new()
		tag.position = Vector2(CARD_SIZE.x - 68, thumb_h - 30)
		tag.size = Vector2(56, 24)
		var tag_style := StyleBoxFlat.new()
		tag_style.bg_color = COLOR_BOSS
		tag_style.set_corner_radius_all(3)
		tag.add_theme_stylebox_override("panel", tag_style)
		root.add_child(tag)

		var tag_label := Label.new()
		tag_label.text = "BOSS"
		tag_label.size = tag.size
		tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var tls := LabelSettings.new()
		tls.font = PIXEL_FONT
		tls.font_size = 10
		tls.font_color = Color.WHITE
		tag_label.label_settings = tls
		tag.add_child(tag_label)

	var medaglia_label := Label.new()
	medaglia_label.position = Vector2(0, thumb_h - 26)
	medaglia_label.size = Vector2(CARD_SIZE.x - 10, 22)
	medaglia_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var mls := LabelSettings.new()
	mls.font = PIXEL_FONT
	mls.font_size = 11
	mls.outline_size = 3
	mls.outline_color = Color.BLACK
	medaglia_label.label_settings = mls
	root.add_child(medaglia_label)

	var titolo := Label.new()
	titolo.text = dati["nome"]
	titolo.position = Vector2(14, thumb_h + 6)
	titolo.size = Vector2(CARD_SIZE.x - 28, 26)
	titolo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var tis := LabelSettings.new()
	tis.font = PIXEL_FONT
	tis.font_size = 14
	tis.font_color = Color(0.9, 0.92, 0.95)
	tis.outline_size = 2
	tis.outline_color = Color.BLACK
	titolo.label_settings = tis
	root.add_child(titolo)

	var desc := Label.new()
	desc.text = dati["desc"]
	desc.position = Vector2(14, thumb_h + 34)
	desc.size = Vector2(CARD_SIZE.x - 28, 44)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ds := LabelSettings.new()
	ds.font = PIXEL_FONT
	ds.font_size = 9
	ds.font_color = Color(0.75, 0.77, 0.8)
	desc.label_settings = ds
	root.add_child(desc)

	var btn := Button.new()
	btn.flat = true
	btn.size = CARD_SIZE
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_style := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("disabled", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.pressed.connect(_conferma_selezione.bind(indice))
	btn.mouse_entered.connect(_seleziona.bind(indice))
	root.add_child(btn)

	var lock_overlay := ColorRect.new()
	lock_overlay.size = CARD_SIZE
	lock_overlay.color = Color(0.0, 0.0, 0.0, 0.85)
	lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_overlay.visible = false
	root.add_child(lock_overlay)

	var lock_label := Label.new()
	lock_label.text = "🔒  BLOCCATO"
	lock_label.size = CARD_SIZE
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var lls := LabelSettings.new()
	lls.font = PIXEL_FONT
	lls.font_size = 13
	lls.font_color = Color(0.85, 0.85, 0.85)
	lls.outline_size = 3
	lls.outline_color = Color.BLACK
	lock_label.label_settings = lls
	lock_overlay.add_child(lock_label)

	return {
		"boss": dati.get("boss", false),
		"scena": dati["scena"],
		"style": style,
		"btn": btn,
		"medaglia_label": medaglia_label,
		"lock_overlay": lock_overlay,
	}

# --- Selezione / stato ---

func _seleziona(indice: int) -> void:
	_selected_index = indice
	_aggiorna_schede()

func _aggiorna_schede() -> void:
	for i in range(_cards.size()):
		var card: Dictionary = _cards[i]
		var sbloccato: bool = Progress.is_sbloccato(i)

		card["lock_overlay"].visible = not sbloccato
		card["btn"].disabled = not sbloccato

		var medaglia: int = Progress.get_medaglia(i)
		card["medaglia_label"].text = NOMI_MEDAGLIE[medaglia] if sbloccato else ""
		card["medaglia_label"].label_settings.font_color = COLORI_MEDAGLIE[medaglia]

		var is_selected := (i == _selected_index)
		var colore_bordo: Color = COLOR_BORDER_IDLE
		if is_selected:
			colore_bordo = COLOR_BOSS if card["boss"] else COLOR_GOLD
		card["style"].border_color = colore_bordo
		card["style"].set_border_width_all(3 if is_selected else 2)

func _conferma_selezione(indice: int) -> void:
	_seleziona(indice)
	if not Progress.is_sbloccato(indice):
		return
	PlayerData.reset()
	get_tree().change_scene_to_file(_cards[indice]["scena"])

func _on_indietro_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

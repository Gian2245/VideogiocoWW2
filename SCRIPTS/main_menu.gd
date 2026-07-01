extends Control

# ============================================================
# Menu Principale — prima schermata mostrata all'avvio del gioco.
# Lo sfondo (assets/Lone Commando - Main Menu.png) contiene già il
# titolo e le voci di menu disegnate nell'illustrazione: qui creiamo
# solo pulsanti invisibili sovrapposti al testo per gestire click e
# selezione (con le frecce laterali come indicatore).
#
# Navigabile sia col mouse (hover/click) sia con tastiera/pad
# (frecce su/giù + Invio o Spazio per confermare).
# ============================================================

const LEVEL_SELECT_SCENE := "res://scenes/LevelSelect.tscn"
const LEVEL1_SCENE := "res://scenes/game1.tscn"

const PIXEL_FONT: Font = preload("res://assets/Fonts/PressStart2P-Regular.ttf")

const COLOR_GOLD := Color(0.95, 0.75, 0.25)
const COLOR_LIGHT := Color(0.85, 0.89, 0.95)

@onready var _background: TextureRect = $Background

var _items: Array = []   # ogni voce: { btn, arrow_left, arrow_right, base_color, callback }
var _selected_index: int = 0

func _ready() -> void:
	# Le voci di menu sono già disegnate nello sfondo: qui posizioniamo solo
	# le aree cliccabili (invisibili) sopra il testo di ciascuna voce.
	# Centri forniti dall'utente (in pixel, canvas 1280x720):
	# GIOCA (629,417) — LIVELLI (627,473) — ESCI (625,539)
	_add_menu_button("", Rect2(489, 396, 280, 42), COLOR_GOLD, _on_gioca_pressed)
	_add_menu_button("", Rect2(477, 452, 300, 42), COLOR_LIGHT, _on_livelli_pressed)
	_add_menu_button("", Rect2(535, 518, 180, 42), COLOR_LIGHT, _on_esci_pressed)

	_select_item(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_select_item((_selected_index + 1) % _items.size())
	elif event.is_action_pressed("ui_up"):
		_select_item((_selected_index - 1 + _items.size()) % _items.size())
	elif event.is_action_pressed("ui_accept"):
		_items[_selected_index]["callback"].call()

func _select_item(index: int) -> void:
	_selected_index = index
	for i in range(_items.size()):
		var item = _items[i]
		var is_selected = (i == index)
		item["btn"].scale = Vector2(1.06, 1.06) if is_selected else Vector2.ONE
		item["arrow_left"].visible = is_selected
		item["arrow_right"].visible = is_selected

func _add_menu_button(text: String, rect: Rect2, color: Color, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.position = rect.position
	btn.size = rect.size
	btn.pivot_offset = rect.size / 2.0
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

	btn.add_theme_font_override("font", PIXEL_FONT)
	btn.add_theme_font_size_override("font_size", 30)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
	btn.add_theme_color_override("font_pressed_color", color.darkened(0.2))
	btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	btn.add_theme_constant_override("outline_size", 8)

	var arrow_left = _make_arrow_label("<", rect, true)
	var arrow_right = _make_arrow_label(">", rect, false)
	arrow_left.visible = false
	arrow_right.visible = false
	add_child(arrow_left)
	add_child(arrow_right)

	var index = _items.size()
	btn.pressed.connect(callback)
	btn.mouse_entered.connect(func(): _select_item(index))
	add_child(btn)

	_items.append({
		"btn": btn,
		"arrow_left": arrow_left,
		"arrow_right": arrow_right,
		"callback": callback,
	})

func _make_arrow_label(glyph: String, rect: Rect2, on_left: bool) -> Label:
	var label = Label.new()
	label.text = glyph
	label.size = Vector2(60, rect.size.y)
	var offset = -70.0 if on_left else rect.size.x + 10.0
	label.position = Vector2(rect.position.x + offset, rect.position.y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var settings = LabelSettings.new()
	settings.font = PIXEL_FONT
	settings.font_size = 26
	settings.font_color = COLOR_GOLD
	settings.outline_size = 6
	settings.outline_color = Color(0.0, 0.0, 0.0)
	label.label_settings = settings
	return label

func _on_gioca_pressed() -> void:
	PlayerData.reset()
	get_tree().change_scene_to_file(LEVEL1_SCENE)

func _on_livelli_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)

func _on_esci_pressed() -> void:
	get_tree().quit()

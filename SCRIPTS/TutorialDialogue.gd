extends CanvasLayer

## Finestra di dialogo modale dell'istruttore: mette il gioco in pausa e mostra
## uno o più messaggi nella cornice dedicata. SPAZIO avanza al messaggio
## successivo; sull'ultimo messaggio chiude il dialogo e sblocca il gioco.
## Riutilizzabile da qualunque script tramite il gruppo "tutorial_dialogue":
##   get_tree().get_first_node_in_group("tutorial_dialogue").mostra_sequenza([...])

signal dialogo_chiuso

const PIXEL_FONT: Font = preload("res://assets/Fonts/PressStart2P-Regular.ttf")

@onready var _root: Control = %DialogueRoot
@onready var _label: Label = %DialogueLabel
@onready var _spazio_blink: TextureRect = %SpazioBlink

var _messaggi: Array = []
var _indice := 0
var _attivo := false
var _blink_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("tutorial_dialogue")
	_root.visible = false
	_label.add_theme_font_override("font", PIXEL_FONT)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func mostra_sequenza(messaggi: Array) -> void:
	if messaggi.is_empty() or _attivo:
		return
	_messaggi = messaggi
	_indice = 0
	_attivo = true
	_root.visible = true
	get_tree().paused = true
	_mostra_riga_corrente()
	_avvia_blink()

func mostra_messaggio(testo: String) -> void:
	mostra_sequenza([testo])

func _mostra_riga_corrente() -> void:
	_label.text = str(_messaggi[_indice])

func _unhandled_input(event: InputEvent) -> void:
	if not _attivo:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		# Consuma subito lo stato "premuto" di ui_accept: altrimenti, appena il gioco
		# si sblocca, il player potrebbe leggere lo stesso tasto SPAZIO come salto.
		Input.action_release("ui_accept")
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("sopprimi_prossimo_salto"):
			player.sopprimi_prossimo_salto()
		_avanza()

func _avanza() -> void:
	_indice += 1
	if _indice >= _messaggi.size():
		_chiudi()
	else:
		_mostra_riga_corrente()

func _chiudi() -> void:
	_attivo = false
	_root.visible = false
	get_tree().paused = false
	_ferma_blink()
	dialogo_chiuso.emit()

func _avvia_blink() -> void:
	_ferma_blink()
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(_spazio_blink, "modulate", Color(1.8, 1.7, 1.15, 1.0), 0.45).set_trans(Tween.TRANS_SINE)
	_blink_tween.tween_property(_spazio_blink, "modulate", Color(1, 1, 1, 1), 0.45).set_trans(Tween.TRANS_SINE)

func _ferma_blink() -> void:
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	_spazio_blink.modulate = Color(1, 1, 1, 1)

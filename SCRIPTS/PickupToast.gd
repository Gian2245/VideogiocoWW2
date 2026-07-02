extends Control

## Toast riutilizzabile per notificare la raccolta di oggetti (munizioni, granate, medikit, armi...).
## Chiamare mostra_pickup() da qualsiasi script: i messaggi ravvicinati si accodano
## ed escono in sequenza, senza mai sovrapporsi.

const PIXEL_FONT: Font = preload("res://assets/Fonts/PressStart2P-Regular.ttf")

@export var durata_visibile_default: float = 1.8
@export var durata_fade_in: float = 0.2
@export var durata_fade_out: float = 0.35

@onready var _label: Label = %ToastLabel

var _coda: Array = []
var _in_riproduzione := false
var _tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	_label.add_theme_font_override("font", PIXEL_FONT)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func mostra_pickup(testo: String, durata: float = -1.0) -> void:
	_coda.append({
		"testo": testo,
		"durata": durata if durata > 0.0 else durata_visibile_default,
	})
	if not _in_riproduzione:
		_avanza_coda()

func _avanza_coda() -> void:
	if _coda.is_empty():
		_in_riproduzione = false
		return
	_in_riproduzione = true
	var voce: Dictionary = _coda.pop_front()
	_label.text = voce["testo"]

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, durata_fade_in)
	_tween.tween_interval(voce["durata"])
	_tween.tween_property(self, "modulate:a", 0.0, durata_fade_out)
	_tween.finished.connect(_avanza_coda, CONNECT_ONE_SHOT)

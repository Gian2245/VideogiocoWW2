extends Node

# ============================================================
# Singleton Autoload — Colonna sonora di sottofondo
# Persiste tra i livelli e suona in loop continuo e senza stacchi.
# Registrato come autoload "Musica" in project.godot
# ============================================================

const THEME_PATH := "res://assets/Audio/music/theme.wav"

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.stream = load(THEME_PATH)
	add_child(_player)

	# NOTA: il loop "vero" e senza stacchi è abilitato nell'import del .wav
	# (edit/loop_mode=1). NON forziamo loop_mode a runtime: se il sample è ancora
	# importato senza loop, un loop_end non valido produrrebbe un loop di durata 0
	# (= silenzio). Ci affidiamo all'import + alla rete di sicurezza qui sotto, che
	# riavvia il tema appena finisce: così si sente in ogni caso.
	if not _player.finished.is_connected(_riavvia):
		_player.finished.connect(_riavvia)

	_player.play()

func _riavvia() -> void:
	if _player:
		_player.play()

func avvia() -> void:
	if _player and not _player.playing:
		_player.play()

func ferma() -> void:
	if _player:
		_player.stop()

func imposta_volume_db(db: float) -> void:
	if _player:
		_player.volume_db = db

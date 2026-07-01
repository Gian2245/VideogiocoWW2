extends Node

# Script della boss_scene: sostituisce la musica con il tema boss fight
# e la ripristina quando si esce dalla scena.

const BOSS_MUSIC_PATH := "res://assets/Audio/sfx/tema livello boss fight.mp3"

func _ready() -> void:
	# Sostituisce la musica di sottofondo con il tema della boss fight
	if Musica:
		Musica.cambia_traccia(BOSS_MUSIC_PATH)

func _notification(what: int) -> void:
	# Quando la scena viene rimossa dall'albero, ripristina la musica originale
	if what == NOTIFICATION_PREDELETE:
		if Musica:
			Musica.ripristina()

extends Area2D

@export var fade_duration: float = 0.3
@export_multiline var tutorial_text: String = "Premi X per sparare"

@onready var label: Label = $Label

var current_tween: Tween

func _ready() -> void:
	label.text = tutorial_text
	# Assicurati che il testo sia invisibile all'inizio
	label.modulate.a = 0.0
	
	# Colleghiamo i segnali via codice
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_fade_label(1.0) # Dissolvenza in entrata

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_fade_label(0.0) # Dissolvenza in uscita

func _fade_label(target_alpha: float) -> void:
	# Se c'è un'animazione in corso, fermala
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	# Crea un nuovo Tween per l'animazione
	current_tween = create_tween()
	
	# Anima il canale Alpha della proprietà Modulate
	current_tween.tween_property(label, "modulate:a", target_alpha, fade_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

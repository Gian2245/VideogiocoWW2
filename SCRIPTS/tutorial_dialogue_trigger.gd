extends Area2D

## Trigger una tantum: al primo passaggio del giocatore apre TutorialDialogue
## con la sequenza di messaggi indicata, poi si disattiva (non si ripete
## se il giocatore torna indietro e rientra nella zona).

@export var messaggi: Array[String] = ["Testo di esempio"]

var _gia_attivato := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _gia_attivato or not body.is_in_group("player"):
		return
	var dialogo := get_tree().get_first_node_in_group("tutorial_dialogue")
	if dialogo and dialogo.has_method("mostra_sequenza"):
		_gia_attivato = true
		dialogo.mostra_sequenza(messaggi)

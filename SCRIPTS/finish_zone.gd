extends Area2D

var _triggered: bool = false

func _process(_delta: float) -> void:
	if _triggered:
		return

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]

	# Prima condizione: il giocatore deve aver superato la FinishZone
	if player.global_position.x < global_position.x:
		return

	# Seconda condizione: tutti i nemici devono essere morti
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get("is_dead") == false:
			return

	# Entrambe le condizioni soddisfatte → vittoria
	_triggered = true
	var win = get_tree().get_first_node_in_group("win_screen")
	if win and win.has_method("mostra") and not win.visible:
		win.mostra()

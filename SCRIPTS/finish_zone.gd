extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Il giocatore deve aver eliminato tutti i nemici prima di vincere
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get("is_dead") == false:
			return

	var win = get_tree().get_first_node_in_group("win_screen")
	if win and win.has_method("mostra") and not win.visible:
		await get_tree().create_timer(3.0).timeout
		win.mostra()

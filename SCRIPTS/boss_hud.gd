extends CanvasLayer

@onready var hp_bar = $ProgressBar
var boss_node: Node2D

func _ready() -> void:
	# Cerca il boss nell'albero delle scene
	boss_node = get_tree().get_first_node_in_group("boss")
	if boss_node:
		hp_bar.max_value = boss_node.max_hp
		hp_bar.value = boss_node.current_hp

func _process(delta: float) -> void:
	if boss_node:
		if boss_node.is_dead:
			visible = false
		else:
			hp_bar.value = boss_node.current_hp

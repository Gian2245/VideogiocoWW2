extends Node

# ============================================================
# Game2 Spawner — Sequenza fissa di sezioni.
# Alterna tratti di sole casse da spaccare con "orde" di nemici,
# invece del vecchio pattern piatto "1 cassa, 1 nemico" scalato
# con la distanza. L'ultima sezione (5 casse) prepara la boss fight:
# al suo completamento la FinishZone viene spostata subito dopo,
# così il livello finisce lì.
# ============================================================

const SEZIONI := [
	{"tipo": "crate", "quantita": 4},
	{"tipo": "wave", "nemici": ["raider", "raider", "raider"]},
	{"tipo": "crate", "quantita": 3},
	{"tipo": "wave", "nemici": ["runner", "runner", "sniper", "sniper"]},
	{"tipo": "crate", "quantita": 3},
	{"tipo": "wave", "nemici": ["runner", "runner", "raider", "raider"]},
	{"tipo": "crate", "quantita": 3},
	{"tipo": "wave", "nemici": ["runner", "raider", "raider", "sniper", "sniper"]},
	{"tipo": "crate", "quantita": 5},
]

var _player: Node2D
var _next_spawn_x: float = 1500.0
var _section_index: int = 0
var _finished_spawning: bool = false

var _enemy_scene: PackedScene = preload("res://scenes/enemy_raider_1.tscn")
var _sniper_scene: PackedScene = preload("res://scenes/enemy_sniper.tscn")
var _runner_scene: PackedScene = preload("res://scenes/enemy_runner.tscn")
var _crate_script = preload("res://SCRIPTS/supply_crate.gd")

func _ready() -> void:
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_next_spawn_x = _player.global_position.x + 1500.0

func _process(_delta: float) -> void:
	if _finished_spawning or _player == null:
		return
	if _player.get("is_dead") == true:
		return

	if _player.global_position.x >= _next_spawn_x:
		var base_x = _player.global_position.x
		var sezione = SEZIONI[_section_index]

		var last_offset: float
		if sezione["tipo"] == "crate":
			last_offset = _spawn_crates_section(base_x, sezione["quantita"])
		else:
			last_offset = _spawn_wave(base_x, sezione["nemici"])

		_section_index += 1
		if _section_index >= SEZIONI.size():
			_finished_spawning = true
			_posiziona_finish_zone(base_x + last_offset + 900.0)
		else:
			_next_spawn_x = base_x + last_offset + 500.0

func _spawn_crates_section(base_x: float, count: int) -> float:
	var spacing = 350.0
	var last_offset = 0.0
	for i in range(count):
		last_offset = 900.0 + i * spacing + randf_range(-40.0, 40.0)
		var crate = StaticBody2D.new()
		crate.set_script(_crate_script)
		crate.position = Vector2(base_x + last_offset, 800)
		crate.scale = Vector2(0.6, 0.6)
		get_parent().add_child(crate)
	return last_offset

func _spawn_wave(base_x: float, composizione: Array) -> float:
	# I runner vanno sempre nello slot più vicino al giocatore, così nessun
	# altro nemico gli blocca la corsa verso di noi.
	var tipi: Array = composizione.duplicate()
	tipi.sort_custom(func(a, b): return a == "runner" and b != "runner")

	var last_offset = 0.0
	for i in range(tipi.size()):
		last_offset = randf_range(1200.0, 1600.0) + i * randf_range(300.0, 500.0)
		var spawn_x = base_x + last_offset

		var enemy
		match tipi[i]:
			"sniper":
				enemy = _sniper_scene.instantiate()
			"runner":
				enemy = _runner_scene.instantiate()
			_:
				enemy = _enemy_scene.instantiate()
				enemy.raider_index = [1, 2].pick_random()
		enemy.position = Vector2(spawn_x, 696)
		enemy.scale = Vector2(3.2, 3.2)
		enemy.use_random_loot = true
		enemy.drop_item_scene = null
		enemy.death_tutorial_text = ""
		get_parent().add_child(enemy)
	return last_offset

func _posiziona_finish_zone(finish_x: float) -> void:
	var finish_zone = get_parent().get_node_or_null("FinishZone")
	if finish_zone:
		finish_zone.global_position.x = finish_x

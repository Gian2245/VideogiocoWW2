extends Node

# ============================================================
# Game2 Spawner — Spawning basato sulla DISTANZA percorsa
# X = 0     → 15000 : 1 nemico per spawn
# X = 15000 → 25000 : 2 nemici per spawn
# X = 25000 → 30000 : 3 nemici per spawn
# X = 30000+        : stop spawning, FinishZone gestisce la vittoria
# Spawn ogni 1500px, piazzati 1200-1600px avanti (fuori schermo).
# ============================================================

@export var spawn_distance: float = 1500.0
@export var spawn_stop_x: float = 30000.0
@export var crate_spawn_every: int = 2

var _player: Node2D
var _next_spawn_x: float = 1500.0
var _spawn_count: int = 0
var _finished_spawning: bool = false

var _enemy_scene: PackedScene = preload("res://scenes/enemy_raider_1.tscn")
var _sniper_scene: PackedScene = preload("res://scenes/enemy_sniper.tscn")
var _runner_scene: PackedScene = preload("res://scenes/enemy_runner.tscn")

@export var sniper_chance: float = 0.25  # probabilità che un nemico spawnato sia un cecchino
@export var runner_chance: float = 0.25  # probabilità che un nemico spawnato sia un runner

func _ready() -> void:
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_next_spawn_x = _player.global_position.x + spawn_distance

func _process(_delta: float) -> void:
	if _finished_spawning or _player == null:
		return
	if _player.get("is_dead") == true:
		return

	if _player.global_position.x >= spawn_stop_x:
		_finished_spawning = true
		return

	if _player.global_position.x >= _next_spawn_x:
		_try_spawn()
		_next_spawn_x += spawn_distance

func _get_enemy_count() -> int:
	var px = _player.global_position.x
	if px >= 25000.0:
		return 3
	elif px >= 15000.0:
		return 2
	else:
		return 1

func _try_spawn() -> void:
	var count = _get_enemy_count()
	var first_enemy_x := 0.0

	for i in range(count):
		# Ogni nemico è piazzato a distanza crescente per non sovrapporsi
		var offset = randf_range(1200.0, 1600.0) + i * randf_range(300.0, 500.0)
		var spawn_x = _player.global_position.x + offset

		var enemy
		var roll = randf()
		if roll < sniper_chance:
			enemy = _sniper_scene.instantiate()
		elif roll < sniper_chance + runner_chance:
			enemy = _runner_scene.instantiate()
		else:
			enemy = _enemy_scene.instantiate()
			enemy.raider_index = [1, 2].pick_random()
		enemy.position = Vector2(spawn_x, 696)
		enemy.scale = Vector2(3.2, 3.2)
		enemy.use_random_loot = true
		enemy.drop_item_scene = null
		enemy.death_tutorial_text = ""
		get_parent().add_child(enemy)

		if i == 0:
			first_enemy_x = spawn_x

	_spawn_count += 1

	if _spawn_count % crate_spawn_every == 0:
		_spawn_crates(first_enemy_x)

func _spawn_crates(enemy_x: float) -> void:
	var crate_script = load("res://SCRIPTS/supply_crate.gd")

	for i in range(2):
		var crate_x: float
		if i == 0:
			crate_x = _player.global_position.x + randf_range(1000.0, 1150.0)
		else:
			crate_x = enemy_x + randf_range(200.0, 500.0)

		if abs(crate_x - enemy_x) < 400.0:
			crate_x = enemy_x + 450.0 + randf_range(0.0, 100.0)

		var crate = StaticBody2D.new()
		crate.set_script(crate_script)
		crate.position = Vector2(crate_x, 800)
		crate.scale = Vector2(0.6, 0.6)
		get_parent().add_child(crate)

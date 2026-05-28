extends TextureRect

@export var player_path: NodePath = ^"../palyer"
@export_range(0.1, 2.0, 0.05) var scroll_factor := 1.0
@export var second_texture: Texture2D = preload("res://assets/ChatGPT Image 28 mag 2026, 13_46_16.png")
@export_range(0.05, 2.0, 0.05) var transition_duration := 0.45

var _player: Node2D
var _second_tile: TextureRect
var _segment_width := 0.0
var _base_x := 0.0
var _player_start_x := 0.0
var _using_second_background := false

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node2D
	if _player == null:
		push_warning("Sfondo: player non trovato. Controlla player_path.")
		set_process(false)
		return

	_segment_width = size.x
	_base_x = position.x
	_player_start_x = _player.global_position.x
	z_index = -100

	_second_tile = duplicate() as TextureRect
	_second_tile.name = "SfondoLoop"
	_second_tile.script = null
	_second_tile.texture = second_texture
	_second_tile.z_index = z_index
	_second_tile.position = position + Vector2(_segment_width, 0.0)
	get_parent().add_child.call_deferred(_second_tile)

func _process(_delta: float) -> void:
	if _player == null or _segment_width <= 0.0:
		return

	var traveled := (_player.global_position.x - _player_start_x) * scroll_factor

	if not _using_second_background:
		var initial_offset := clampf(traveled, 0.0, _segment_width)
		position.x = _base_x - initial_offset
		if is_instance_valid(_second_tile):
			_second_tile.position.x = position.x + _segment_width

		if traveled >= _segment_width:
			_switch_to_second_background()
		return

	var wrapped_offset := fposmod(maxf(traveled, 0.0), _segment_width)
	position.x = _base_x - wrapped_offset
	if is_instance_valid(_second_tile):
		_second_tile.position.x = position.x + _segment_width

func _switch_to_second_background() -> void:
	var old_texture := texture
	_using_second_background = true
	_player_start_x = _player.global_position.x
	texture = second_texture
	position.x = _base_x
	if is_instance_valid(_second_tile):
		_second_tile.texture = second_texture
		_second_tile.position.x = position.x + _segment_width
	_start_crossfade(old_texture)

func _start_crossfade(old_texture: Texture2D) -> void:
	if old_texture == null:
		return
	var fade_overlay := TextureRect.new()
	fade_overlay.texture = old_texture
	fade_overlay.position = position
	fade_overlay.size = size
	fade_overlay.scale = scale
	fade_overlay.rotation = rotation
	fade_overlay.pivot_offset = pivot_offset
	fade_overlay.flip_h = flip_h
	fade_overlay.flip_v = flip_v
	fade_overlay.stretch_mode = stretch_mode
	fade_overlay.modulate = Color(1, 1, 1, 1)
	fade_overlay.z_index = z_index + 1
	get_parent().add_child(fade_overlay)

	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, transition_duration)
	tween.tween_callback(fade_overlay.queue_free)

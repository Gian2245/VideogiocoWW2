extends Area2D

var time_passed: float = 0.0
var base_y: float = 0.0
var initialized := false
var player_in_range: Node2D = null

func _ready() -> void:
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	
	_crea_visuale_arma()
	_crea_label()

func _crea_visuale_arma() -> void:
	# Corpo principale della pistola
	var corpo = Polygon2D.new()
	corpo.polygon = PackedVector2Array([
		Vector2(-14, -5), Vector2(10, -5),
		Vector2(10, 5),  Vector2(-14, 5)
	])
	corpo.color = Color(0.25, 0.22, 0.18)  # Marrone scuro metallo
	add_child(corpo)

	# Canna (proiettile)
	var canna = Polygon2D.new()
	canna.polygon = PackedVector2Array([
		Vector2(10, -3), Vector2(20, -3),
		Vector2(20, 2),  Vector2(10, 2)
	])
	canna.color = Color(0.18, 0.16, 0.13)  # Più scuro
	add_child(canna)

	# Impugnatura (grip)
	var grip = Polygon2D.new()
	grip.polygon = PackedVector2Array([
		Vector2(-8, 5),  Vector2(-2, 5),
		Vector2(-2, 14), Vector2(-8, 14)
	])
	grip.color = Color(0.35, 0.24, 0.14)  # Legno
	add_child(grip)

	# Grilletto
	var grilletto = Polygon2D.new()
	grilletto.polygon = PackedVector2Array([
		Vector2(-1, 5), Vector2(1, 5),
		Vector2(0, 10)
	])
	grilletto.color = Color(0.15, 0.13, 0.10)
	add_child(grilletto)

	# Luce / highlight metallo
	var luce = Polygon2D.new()
	luce.polygon = PackedVector2Array([
		Vector2(-14, -5), Vector2(10, -5),
		Vector2(10, -3),  Vector2(-14, -3)
	])
	luce.color = Color(0.55, 0.52, 0.45, 0.6)
	add_child(luce)

	# Cerchio glow attorno all'arma (effetto pickup luminoso)
	var glow = Polygon2D.new()
	var punti: PackedVector2Array = []
	var raggio = 18.0
	for i in range(24):
		var angolo = i * (TAU / 24.0)
		punti.append(Vector2(cos(angolo) * raggio + 2, sin(angolo) * raggio))
	glow.polygon = punti
	glow.color = Color(1.0, 0.85, 0.2, 0.18)  # Giallo gold semi-trasparente
	glow.z_index = -1
	add_child(glow)
	
	# Anima il glow con un tween ciclico
	var glow_tween = create_tween().set_loops()
	glow_tween.tween_property(glow, "modulate:a", 0.3, 0.6)
	glow_tween.tween_property(glow, "modulate:a", 1.0, 0.6)

func _crea_label() -> void:
	var l = Label.new()
	l.name = "Label"
	l.text = "Premi E per raccogliere l'arma"
	l.position = Vector2(-75, -32)
	l.custom_minimum_size = Vector2(150, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var settings = LabelSettings.new()
	settings.font_size = 8
	settings.outline_size = 3
	settings.outline_color = Color.BLACK
	l.label_settings = settings
	l.modulate.a = 0.0
	add_child(l)

func _process(delta: float) -> void:
	if not initialized:
		base_y = position.y
		initialized = true
		
	time_passed += delta
	# Lieve oscillazione rotatoria
	rotation = sin(time_passed * 2.5) * 0.12
	# Movimento fluttuante su e giù
	position.y = base_y + sin(time_passed * 3.5) * 8.0

	# Controlla l'input di interazione
	if player_in_range != null:
		if Input.is_key_pressed(KEY_E):
			_collect()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = body
		_show_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		_hide_prompt()

func _show_prompt() -> void:
	if has_node("Label"):
		var tween = create_tween()
		tween.tween_property($Label, "modulate:a", 1.0, 0.2)

func _hide_prompt() -> void:
	if has_node("Label"):
		var tween = create_tween()
		tween.tween_property($Label, "modulate:a", 0.0, 0.2)

func _collect() -> void:
	set_process(false)
	if player_in_range != null and player_in_range.has_method("raccogli_arma"):
		player_in_range.raccogli_arma(2)
	queue_free()

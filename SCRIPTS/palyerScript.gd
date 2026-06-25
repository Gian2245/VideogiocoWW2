extends CharacterBody2D

# --- VARIABILI DI MOVIMENTO CONFIGURABILI ---
@export var WALK_SPEED = 300.0
@export var RUN_SPEED = 550.0
@export var JUMP_VELOCITY = -750.0
@export var munizioni_massime := 8
@export var max_health := 100
@export var max_armor := 50
@export var granate := 2
@export var distanza_esplosione := 110.0
@export var scala_esplosione := Vector2(2.4, 2.4)
@export var nome_arma := "AR11"
@export var modalita_sparo := "Semi-Auto"

var velocità_attuale = WALK_SPEED
var munizioni_attuali := 0
var health := 100
var armor := 0

# --- VARIABILI PER IL DOPPIO TOCCO (DASH/RUN) ---
var tempo_ultimo_tocco_destra = 0.0
var tempo_ultimo_tocco_sinistra = 0.0
const SOGLIA_DOPPIO_TOCCO = 0.25
var sta_correndo = false
var carica_granata: float = 0.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D
@onready var explosion_fx: AnimatedSprite2D = $ExplosionFX
@onready var player_camera: Camera2D = $Camera2D
@export var camera_offset := Vector2(0, -64)
@export var camera_zoom := Vector2(0.68, 0.68)

var sta_attaccando = false
var _hud: Node
var max_cam_x := -INF

func _ready() -> void:
	munizioni_attuali = munizioni_massime
	health = max_health
	animated_sprite.animation_finished.connect(_on_animation_finished)
	explosion_fx.animation_finished.connect(_on_esplosione_finita)
	explosion_fx.scale = scala_esplosione
	player_camera.zoom = camera_zoom
	player_camera.enabled = true
	player_camera.position_smoothing_enabled = false
	player_camera.global_position = global_position + camera_offset
	max_cam_x = player_camera.global_position.x
	_hud = get_tree().get_first_node_in_group("hud")
	if _hud:
		_hud.imposta_arma(nome_arma)
		_hud.imposta_modalita_sparo(modalita_sparo)
		_hud.imposta_granate(granate)
	_aggiorna_hud_munizioni()
	_aggiorna_hud_salute()
	_aggiorna_hud_armatura()

func _physics_process(delta: float) -> void:
	tempo_ultimo_tocco_destra += delta
	tempo_ultimo_tocco_sinistra += delta

	if not is_on_floor():
		velocity.y += gravity * delta

	if sta_attaccando:
		if animated_sprite.animation == "granata" and Input.is_action_pressed("granata"):
			carica_granata += delta
		velocity.x = 0
		move_and_slide()
		return

	if Input.is_action_just_pressed("ui_right"):
		if tempo_ultimo_tocco_destra < SOGLIA_DOPPIO_TOCCO:
			sta_correndo = true
		tempo_ultimo_tocco_destra = 0.0

	if Input.is_action_just_pressed("ui_left"):
		if tempo_ultimo_tocco_sinistra < SOGLIA_DOPPIO_TOCCO:
			sta_correndo = true
		tempo_ultimo_tocco_sinistra = 0.0

	# Z = attacco | X = sparo | R = ricarica | G = granata
	if Input.is_key_pressed(KEY_Z):
		_inizia_attacco()
		return
	elif Input.is_action_pressed("spara") and munizioni_attuali > 0:
		_inizia_sparo()
		return
	elif Input.is_action_just_pressed("ricarica"):
		if munizioni_attuali < munizioni_massime:
			_inizia_ricarica()
		return
	elif Input.is_action_just_pressed("granata"):
		if granate > 0:
			_inizia_granata()
		return

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocità_attuale = RUN_SPEED if sta_correndo else WALK_SPEED
		velocity.x = direction * velocità_attuale
		animated_sprite.flip_h = direction < 0
	else:
		sta_correndo = false
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)

	_gestisci_animazioni(direction)
	move_and_slide()
	
	# La telecamera avanza solo verso destra
	var target_cam_x = global_position.x + camera_offset.x
	if target_cam_x > max_cam_x:
		max_cam_x = target_cam_x
		
	player_camera.global_position.x = max_cam_x
	player_camera.global_position.y = global_position.y + camera_offset.y
	
	# Impedisce al giocatore di uscire dallo schermo a sinistra
	var left_edge = player_camera.global_position.x - (get_viewport_rect().size.x / 2.0) / player_camera.zoom.x
	if global_position.x < left_edge + 30:
		global_position.x = left_edge + 30

func _inizia_attacco() -> void:
	sta_attaccando = true
	animated_sprite.play("attack")
	
	# Applica danno melee (35) ai nemici molto vicini davanti
	var direction_x = -1.0 if animated_sprite.flip_h else 1.0
	_applica_danno_frontale(35, 250.0, 150.0, direction_x, true)

func _inizia_sparo() -> void:
	sta_attaccando = true
	munizioni_attuali -= 1
	_aggiorna_hud_munizioni()
	animated_sprite.play("spara")
	
	var direction_x = -1.0 if animated_sprite.flip_h else 1.0
	
	var bullet_script = preload("res://SCRIPTS/Proiettile.gd")
	var bullet = Area2D.new()
	bullet.set_script(bullet_script)
	bullet.velocity = Vector2(direction_x * 1600.0, 0)
	bullet.danno = 20
	bullet.global_position = global_position + Vector2(direction_x * 160, 85)
	
	if direction_x < 0:
		bullet.scale.x = -1
		
	get_parent().add_child(bullet)

func _inizia_ricarica() -> void:
	sta_attaccando = true
	animated_sprite.play("ricarica")

func _inizia_granata() -> void:
	sta_attaccando = true
	carica_granata = 0.0
	granate -= 1
	if _hud:
		_hud.imposta_granate(granate)
	animated_sprite.play("granata")
func _lancia_esplosione() -> void:
	var verso := -1.0 if animated_sprite.flip_h else 1.0
	
	# Creiamo una granata visiva un po' più grande
	var granata = Polygon2D.new()
	granata.polygon = PackedVector2Array([Vector2(-8,-8), Vector2(8,-8), Vector2(8,8), Vector2(-8,8)])
	granata.color = Color(0.15, 0.15, 0.1) # Grigio scuro
	get_parent().add_child(granata)
	
	# Punto di partenza: circa la mano del giocatore
	var start_pos = global_position + Vector2(40 * verso, -50)
	granata.global_position = start_pos
	
	# Punto di arrivo: i piedi sul pavimento. Il pavimento reale è a Y + 240 pixel per via dello scale 3.2x
	var floor_y = global_position.y + 240.0
	
	# Calcola distanza in base alla carica: 0s -> cade vicino, 0.5s -> lancio lontano
	var power = min(carica_granata / 0.5, 1.0)
	var distanza = 50.0 + power * 550.0
	var end_pos = Vector2(global_position.x + (distanza * verso), floor_y) 
	
	# Altezza del picco della parabola
	var peak_y = start_pos.y - 180.0
	
	# Animazione (Traiettoria a Parabola)
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(granata, "global_position:x", end_pos.x, 0.7)
	
	var tween_y = create_tween()
	tween_y.tween_property(granata, "global_position:y", peak_y, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween_y.tween_property(granata, "global_position:y", end_pos.y, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD).set_delay(0.35)
	
	var tween_rot = create_tween()
	tween_rot.tween_property(granata, "rotation", deg_to_rad(360 * 2 * verso), 0.7)
	
	tween_y.finished.connect(func():
		granata.queue_free()
		_esplodi(end_pos)
	)
	
	sta_attaccando = false
	animated_sprite.play("fermo")

func _esplodi(pos_esplosione: Vector2) -> void:
	# Solleviamo visivamente l'esplosione dal pavimento per farla aderire meglio al suolo
	explosion_fx.global_position = pos_esplosione - Vector2(0, 153)
	explosion_fx.flip_h = animated_sprite.flip_h
	explosion_fx.visible = true
	explosion_fx.play("esplosione")
	
	# Applica danno esplosione (Raggio di 200 pixel)
	_applica_danno_esplosione(pos_esplosione, 200.0, 100)

func _on_esplosione_finita() -> void:
	explosion_fx.visible = false

func _applica_danno_frontale(danno: int, max_dist_x: float, max_dist_y: float, dir_x: float, is_melee: bool = false) -> void:
	var bersagli = get_tree().get_nodes_in_group("enemies")
	bersagli += get_tree().get_nodes_in_group("breakable")
	
	var bersagli_validi = []
	for b in bersagli:
		if not b.has_method("take_damage") or b.get("is_dead") == true:
			continue
		
		var diff = b.global_position - global_position
		if sign(diff.x) == sign(dir_x) or diff.x == 0:
			if abs(diff.x) <= max_dist_x and abs(diff.y) <= max_dist_y:
				bersagli_validi.append({"nodo": b, "dist": abs(diff.x)})
				
	bersagli_validi.sort_custom(func(a, b): return a.dist < b.dist)
	
	for bersaglio in bersagli_validi:
		var b = bersaglio.nodo
		b.take_damage(danno)
		if not is_melee and b.is_in_group("breakable"):
			break # Il proiettile si ferma sulla prima cassa colpita

func _applica_danno_esplosione(centro: Vector2, raggio: float, max_danno: int) -> void:
	var nemici = get_tree().get_nodes_in_group("enemies")
	nemici += get_tree().get_nodes_in_group("breakable")
	for nemico in nemici:
		if not nemico.has_method("take_damage") or nemico.get("is_dead") == true:
			continue
			
		var pos_target = nemico.global_position
		if nemico.is_in_group("enemies"):
			# Offset per i nemici rispetto ai piedi
			pos_target += Vector2(0, 240.0)
			
		var dist = centro.distance_to(pos_target)
		
		if dist <= raggio:
			if dist < 60.0:
				nemico.take_damage(max_danno * 5) # Elimina subito
			else:
				var danno_scalato = int(max_danno * (1.0 - (dist / raggio)))
				nemico.take_damage(max(10, danno_scalato))

func _gestisci_animazioni(direction: float) -> void:
	if not is_on_floor():
		return
	if direction != 0:
		animated_sprite.play("run" if sta_correndo else "walk")
	else:
		animated_sprite.play("fermo")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "ricarica":
		munizioni_attuali = munizioni_massime
		_aggiorna_hud_munizioni()
	elif animated_sprite.animation == "spara":
		if Input.is_action_pressed("spara") and munizioni_attuali > 0:
			_inizia_sparo()
			return
	elif animated_sprite.animation == "granata":
		_lancia_esplosione()
		return
	if animated_sprite.animation in ["attack", "spara", "ricarica"]:
		sta_attaccando = false
		animated_sprite.play("fermo")

func _aggiorna_hud_munizioni() -> void:
	if _hud == null:
		return
	_hud.aggiorna_munizioni(munizioni_attuali, munizioni_massime, munizioni_massime)

func _aggiorna_hud_salute() -> void:
	if _hud == null:
		return
	_hud.aggiorna_salute(health, max_health)

func _aggiorna_hud_armatura() -> void:
	if _hud == null:
		return
	if _hud.has_method("aggiorna_armatura"):
		_hud.aggiorna_armatura(armor, max_armor)

func raccogli_giubbotto() -> void:
	armor = max_armor
	_aggiorna_hud_armatura()

func take_damage(amount: int) -> void:
	if amount <= 0:
		return
		
	if armor > 0:
		if armor >= amount:
			armor -= amount
			amount = 0
		else:
			amount -= armor
			armor = 0
		_aggiorna_hud_armatura()
		
	if amount > 0:
		health = max(health - amount, 0)
		_aggiorna_hud_salute()

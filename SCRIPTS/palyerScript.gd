extends CharacterBody2D

# --- VARIABILI DI MOVIMENTO CONFIGURABILI ---
@export var WALK_SPEED = 210.0
@export var RUN_SPEED = 450.0
@export var JUMP_VELOCITY = -500.0
@export var munizioni_massime := 8
@export var max_health := 100
@export var granate := 2
@export var distanza_esplosione := 110.0
@export var scala_esplosione := Vector2(2.4, 2.4)
@export var nome_arma := "AR11"
@export var modalita_sparo := "Semi-Auto"

var velocità_attuale = WALK_SPEED
var munizioni_attuali := 0
var health := 100

# --- VARIABILI PER IL DOPPIO TOCCO (DASH/RUN) ---
var tempo_ultimo_tocco_destra = 0.0
var tempo_ultimo_tocco_sinistra = 0.0
const SOGLIA_DOPPIO_TOCCO = 0.25
var sta_correndo = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D
@onready var explosion_fx: AnimatedSprite2D = $ExplosionFX
@onready var player_camera: Camera2D = $Camera2D
@export var camera_offset := Vector2(0, -64)
@export var camera_zoom := Vector2(0.68, 0.68)

var sta_attaccando = false
var _hud: Node

func _ready() -> void:
	munizioni_attuali = munizioni_massime
	health = max_health
	animated_sprite.animation_finished.connect(_on_animation_finished)
	explosion_fx.animation_finished.connect(_on_esplosione_finita)
	explosion_fx.scale = scala_esplosione
	player_camera.zoom = camera_zoom
	player_camera.enabled = true
	player_camera.global_position = global_position + camera_offset
	_hud = get_tree().get_first_node_in_group("hud")
	if _hud:
		_hud.imposta_arma(nome_arma)
		_hud.imposta_modalita_sparo(modalita_sparo)
		_hud.imposta_granate(granate)
	_aggiorna_hud_munizioni()
	_aggiorna_hud_salute()

func _physics_process(delta: float) -> void:
	player_camera.global_position = global_position + camera_offset
	tempo_ultimo_tocco_destra += delta
	tempo_ultimo_tocco_sinistra += delta

	if not is_on_floor():
		velocity.y += gravity * delta

	if sta_attaccando:
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

func _inizia_attacco() -> void:
	sta_attaccando = true
	animated_sprite.play("attack")

func _inizia_sparo() -> void:
	sta_attaccando = true
	munizioni_attuali -= 1
	_aggiorna_hud_munizioni()
	animated_sprite.play("spara")

func _inizia_ricarica() -> void:
	sta_attaccando = true
	animated_sprite.play("ricarica")

func _inizia_granata() -> void:
	sta_attaccando = true
	granate -= 1
	if _hud:
		_hud.imposta_granate(granate)
	animated_sprite.play("granata")

func _lancia_esplosione() -> void:
	var verso := -1.0 if animated_sprite.flip_h else 1.0
	explosion_fx.position = Vector2(distanza_esplosione * verso, -16.0)
	explosion_fx.flip_h = animated_sprite.flip_h
	explosion_fx.visible = true
	explosion_fx.play("esplosione")

func _on_esplosione_finita() -> void:
	explosion_fx.visible = false
	sta_attaccando = false
	animated_sprite.play("fermo")

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

func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	health = max(health - amount, 0)
	_aggiorna_hud_salute()

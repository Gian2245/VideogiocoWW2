extends CharacterBody2D

# --- VARIABILI DI MOVIMENTO CONFIGURABILI ---
@export var WALK_SPEED = 210.0     # Velocità quando cammina normalmente
@export var RUN_SPEED = 450.0      # Velocità aumentata per la corsa (doppio tocco)
@export var JUMP_VELOCITY = -500.0 # Forza del salto

# Variabile dinamica che cambierà tra WALK_SPEED e RUN_SPEED
var velocità_attuale = WALK_SPEED

# --- VARIABILI PER IL DOPPIO TOCCO (DASH/RUN) ---
var tempo_ultimo_tocco_destra = 0.0
var tempo_ultimo_tocco_sinistra = 0.0
const SOGLIA_DOPPIO_TOCCO = 0.25 # Tempo massimo in secondi tra i due tocchi
var sta_correndo = false

# Recupera la gravità di sistema
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Riferimento al nodo delle animazioni
@onready var animated_sprite = $AnimatedSprite2D
@onready var player_camera: Camera2D = $Camera2D
@export var camera_offset := Vector2(0, -48)

# Variabile di stato per bloccare il movimento quando attacca o spara
var sta_attaccando = false

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)
	player_camera.global_position = global_position + camera_offset

func _physics_process(delta):
	player_camera.global_position = global_position + camera_offset
	# Aggiorna i timer interni del doppio tocco usando il tempo di gioco
	tempo_ultimo_tocco_destra += delta
	tempo_ultimo_tocco_sinistra += delta

	# 1. GESTIONE DELLA GRAVITÀ
	if not is_on_floor():
		velocity.y += gravity * delta

	# Se il personaggio sta compiendo un'azione d'attacco, si ferma
	if sta_attaccando:
		velocity.x = 0 
		move_and_slide()
		return

	# 2. RILEVAMENTO DOPPIO TOCCO
	if Input.is_action_just_pressed("ui_right"):
		if tempo_ultimo_tocco_destra < SOGLIA_DOPPIO_TOCCO:
			sta_correndo = true
		tempo_ultimo_tocco_destra = 0.0 
		
	if Input.is_action_just_pressed("ui_left"):
		if tempo_ultimo_tocco_sinistra < SOGLIA_DOPPIO_TOCCO:
			sta_correndo = true
		tempo_ultimo_tocco_sinistra = 0.0 

	# 3. GESTIONE ATTACCHI E SPARO (Tasti Z e X)
	if Input.is_key_pressed(KEY_Z):
		sta_attaccando = true
		animated_sprite.play("attack")
		return
	elif Input.is_key_pressed(KEY_X):
		sta_attaccando = true
		animated_sprite.play("spara")
		return

	# 4. GESTIONE DEL SALTO
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 5. GESTIONE DEL MOVIMENTO ORIZZONTALE
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		if sta_correndo:
			velocità_attuale = RUN_SPEED
		else:
			velocità_attuale = WALK_SPEED
			
		velocity.x = direction * velocità_attuale
		
		if direction > 0:
			animated_sprite.flip_h = false 
		else:
			animated_sprite.flip_h = true  
	else:
		# Se rilascia i tasti, si ferma e interrompe la corsa
		sta_correndo = false
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)

	# 6. GESTIONE DELLE ANIMAZIONI BASE
	_gestisci_animazioni(direction)

	# 7. APPLICAZIONE DEL MOVIMENTO
	move_and_slide()

# Gestione di Corsa, Camminata e Fermo
func _gestisci_animazioni(direction):
	if is_on_floor():
		if direction != 0:
			if sta_correndo:
				animated_sprite.play("run")     
			else:
				animated_sprite.play("walk")    
		else:
			animated_sprite.play("fermo")   

func _on_animation_finished():
	if animated_sprite.animation == "attack" or animated_sprite.animation == "spara":
		sta_attaccando = false
		animated_sprite.play("fermo")

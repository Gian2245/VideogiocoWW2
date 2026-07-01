extends CharacterBody2D

# --- VARIABILI DI MOVIMENTO CONFIGURABILI ---
@export var WALK_SPEED = 360.0
@export var RUN_SPEED = 660.0
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

# --- MODALITÀ ADRENALINA ---
const ADRENALINA_MASSIMA := 5.0        # carica necessaria per attivare la barra
const ADRENALINA_DURATA := 5.0         # durata/decadimento in secondi della modalità
const ADRENALINA_MOLT_VELOCITA := 1.4  # quanto si va più veloci
const ADRENALINA_MOLT_DANNO := 2       # danno raddoppiato
const ADRENALINA_GUADAGNO_FUOCO := 1.0 # carica per uccisione con arma da fuoco
const ADRENALINA_GUADAGNO_MELEE := 1.5 # +50% per uccisione corpo a corpo
var adrenalina_carica := 0.0           # carica accumulata (0..ADRENALINA_MASSIMA)
var in_adrenalina := false
var adrenalina_timer := 0.0
var _zoom_tween: Tween

var munizioni_attuali := 0
var health := 100
var armor := 0
var ha_arma_nuova := false
var is_dead := false
var is_crouching: bool = false
var _player_col_node: CollisionShape2D
var _player_col_shape: CapsuleShape2D

var armi_sbloccate: Array = [
	{
		"soldier_index": 1,
		"nome_arma": "AR11",
		"modalita_sparo": "Semi-Auto",
		"munizioni_massime": 8,
		"munizioni_attuali": 8,
		"munizioni_riserva": 24,
		"munizioni_riserva_massime": 24,
		"danno": 35
	}
]
var indice_arma_attuale: int = 0

# --- VARIABILI PER IL DOPPIO TOCCO (DASH/RUN) ---
var tempo_ultimo_tocco_destra = 0.0
var tempo_ultimo_tocco_sinistra = 0.0
const SOGLIA_DOPPIO_TOCCO = 0.25
var sta_correndo = false
var carica_granata: float = 0.0

# --- SCHIVATA ---
const DODGE_DURATA     := 0.4    # secondi di invincibilità (più generosa, più facile schivare)
const DODGE_COOLDOWN   := 0.55   # secondi prima di poter schivare di nuovo (fluido)
const DODGE_DISTANZA   := 130.0  # pixel di spostamento laterale
const DODGE_MOVE_TIME  := 0.15   # secondi per coprire la distanza (fluido, non teletrasporto)
const DODGE_ADR_BONUS  := 0.8    # adrenalina guadagnata per schivata riuscita
var _dodge_timer    := 0.0       # tempo rimasto di schivata attiva (invincibilità)
var _dodge_cooldown := 0.0       # tempo rimasto di cooldown
var is_dodging      := false
var _dodge_dir      := 1.0       # direzione della schivata (+1 destra / -1 sinistra)
var _colpo_in_arrivo_timer := 0.0  # secondi da quando un proiettile nemico ci ha sfiorato

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D
@onready var explosion_fx: AnimatedSprite2D = $ExplosionFX
@onready var player_camera: Camera2D = $Camera2D
@export var camera_offset := Vector2(0, -64)
@export var camera_zoom := Vector2(0.68, 0.68)

var sta_attaccando = false
var _hud: Node
var max_cam_x := -INF

var _tutorial_label: Label
var _tutorial_tween: Tween

var _audio_shoot: AudioStreamPlayer
var _audio_reload: AudioStreamPlayer
var _audio_melee: AudioStreamPlayer
var _audio_explosion: AudioStreamPlayer
var _audio_footstep: AudioStreamPlayer
var _audio_pickup: AudioStreamPlayer
var _audio_adrenalina: AudioStreamPlayer
var _footstep_timer := 0.0
const FOOTSTEP_INTERVAL = 60.0 / 100.0  # 100 BPM

func _create_audio_player(path: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.stream = load(path)
	add_child(p)
	return p

func _ready() -> void:
	if not InputMap.has_action("cambia_arma"):
		InputMap.add_action("cambia_arma")
		var event = InputEventKey.new()
		event.physical_keycode = KEY_Q
		InputMap.action_add_event("cambia_arma", event)

	if not InputMap.has_action("adrenalina"):
		InputMap.add_action("adrenalina")
		var event_adr = InputEventKey.new()
		event_adr.physical_keycode = KEY_H
		InputMap.action_add_event("adrenalina", event_adr)

	if not InputMap.has_action("schivata"):
		InputMap.add_action("schivata")
		var event_dodge = InputEventKey.new()
		event_dodge.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("schivata", event_dodge)

	_tutorial_label = Label.new()
	_tutorial_label.position = Vector2(-200, -160)
	_tutorial_label.custom_minimum_size = Vector2(400, 0)
	_tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_label.modulate.a = 0.0
	
	var settings = LabelSettings.new()
	settings.font_size = 14
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	_tutorial_label.label_settings = settings
	add_child(_tutorial_label)
		
	_player_col_node = $CollisionShape2D
	_player_col_shape = _player_col_node.shape as CapsuleShape2D

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
	if _hud and _hud.has_method("aggiorna_adrenalina"):
		_hud.aggiorna_adrenalina(adrenalina_carica, ADRENALINA_MASSIMA)

	_audio_shoot     = _create_audio_player("res://assets/Audio/sfx/shooting.wav")
	_audio_reload    = _create_audio_player("res://assets/Audio/sfx/reload.wav")
	_audio_melee     = _create_audio_player("res://assets/Audio/sfx/melee-hit.wav")
	_audio_explosion = _create_audio_player("res://assets/Audio/sfx/explotion.wav")
	_audio_footstep  = _create_audio_player("res://assets/Audio/sfx/footstep.wav")
	_audio_pickup    = _create_audio_player("res://assets/Audio/sfx/pick-up-item.wav")
	_audio_adrenalina = _create_audio_player("res://assets/Audio/sfx/attivazione adrenalina.wav")

	# Carica l'inventario salvato dal livello precedente (se presente)
	if PlayerData.has_saved_data:
		PlayerData.carica_su_player(self)
		_aggiorna_hud_munizioni()
		_aggiorna_hud_salute()
		_aggiorna_hud_armatura()
		if _hud:
			_hud.imposta_arma(nome_arma)
			_hud.imposta_modalita_sparo(modalita_sparo)
			_hud.imposta_granate(granate)

func _physics_process(delta: float) -> void:
	tempo_ultimo_tocco_destra += delta
	tempo_ultimo_tocco_sinistra += delta

	_gestisci_adrenalina(delta)
	_aggiorna_schivata(delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_dead:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		move_and_slide()
		return

	if sta_attaccando:
		if animated_sprite.animation == "granata" and Input.is_action_pressed("granata"):
			carica_granata += delta
		_audio_footstep.stop()
		_footstep_timer = 0.0
		velocity.x = 0
		move_and_slide()
		return

	# --- CROUCH ---
	var wants_crouch = Input.is_action_pressed("ui_down") and is_on_floor()
	if wants_crouch and not is_crouching:
		_enter_crouch()
	elif not wants_crouch and is_crouching:
		_exit_crouch()

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
	elif modalita_sparo == "Semi-Auto":
		if Input.is_action_just_pressed("spara") and munizioni_attuali > 0:
			_inizia_sparo()
			return
	else:
		if Input.is_action_pressed("spara") and munizioni_attuali > 0:
			_inizia_sparo()
			return
	
	if Input.is_action_just_pressed("ricarica"):
		if munizioni_attuali < munizioni_massime:
			_inizia_ricarica()
		return
	elif Input.is_action_just_pressed("granata"):
		if granate > 0:
			_inizia_granata()
		return
	elif Input.is_action_just_pressed("cambia_arma"):
		cambia_arma_successiva()
		return

	# SCHIVATA — Shift: solo a terra, non durante la schivata stessa, e col cooldown rispettato
	if Input.is_action_just_pressed("schivata") and is_on_floor() and not is_dodging and _dodge_cooldown <= 0.0 and not is_dead:
		_esegui_schivata()
		return

	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocità_attuale = RUN_SPEED if sta_correndo else WALK_SPEED
		if is_crouching:
			velocità_attuale *= 0.5
		if in_adrenalina:
			velocità_attuale *= ADRENALINA_MOLT_VELOCITA
		velocity.x = direction * velocità_attuale
		animated_sprite.flip_h = direction < 0
	else:
		sta_correndo = false
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)

	_gestisci_animazioni(direction)
	_gestisci_footstep(direction, delta)
	move_and_slide()

	# La telecamera avanza solo verso destra
	var target_cam_x = global_position.x + camera_offset.x
	if target_cam_x > max_cam_x:
		max_cam_x = target_cam_x

	# Blocca avanzamento finché ci sono nemici vivi: nessuno deve uscire a sinistra
	var half_view = (get_viewport_rect().size.x / 2.0) / player_camera.zoom.x
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get("is_dead") == true:
			continue
		var limit = enemy.global_position.x + half_view - 200.0
		if max_cam_x > limit:
			max_cam_x = limit

	player_camera.global_position.x = max_cam_x
	player_camera.global_position.y = global_position.y + camera_offset.y

	# Impedisce al giocatore di uscire dallo schermo a sinistra
	var left_edge = player_camera.global_position.x - half_view
	if global_position.x < left_edge + 30:
		global_position.x = left_edge + 30

func _enter_crouch() -> void:
	is_crouching = true
	_player_col_node.position = Vector2(-8, 41)
	_player_col_shape.height = 46.0

func _exit_crouch() -> void:
	is_crouching = false
	_player_col_node.position = Vector2(-8, 18)
	_player_col_shape.height = 92.0

func _esegui_schivata() -> void:
	# Direzione: quella in cui ci si sta muovendo, altrimenti quella in cui si guarda
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir == 0.0:
		_dodge_dir = -1.0 if animated_sprite.flip_h else 1.0
	else:
		_dodge_dir = dir

	is_dodging      = true
	_dodge_timer    = DODGE_DURATA
	_dodge_cooldown = DODGE_COOLDOWN

	# Se c'era un proiettile in arrivo → schivata perfetta → +adrenalina
	if _colpo_in_arrivo_timer > 0.0:
		_guadagna_adrenalina(DODGE_ADR_BONUS)

	# Feedback visivo: il personaggio diventa semitrasparente durante il dash
	modulate = Color(0.7, 0.85, 1.0, 0.65)

	# Tween che sposta il personaggio di una distanza fissa in modo FLUIDO
	# Usiamo global_position direttamente così non ci sono salti bruschi
	var target_x = global_position.x + _dodge_dir * DODGE_DISTANZA
	var tween = create_tween()
	tween.tween_property(self, "global_position:x", target_x, DODGE_MOVE_TIME)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _aggiorna_schivata(delta: float) -> void:
	if _dodge_cooldown > 0.0:
		_dodge_cooldown -= delta

	if _colpo_in_arrivo_timer > 0.0:
		_colpo_in_arrivo_timer -= delta

	if is_dodging:
		_dodge_timer -= delta
		if _dodge_timer <= 0.0:
			is_dodging = false
			modulate = Color.WHITE  # ripristina opacità normale

# Chiamato dal proiettile nemico quando passa vicino al giocatore (ma non lo colpisce)
# Permette di rilevare se il giocatore ha schivato attivamente
func segnala_colpo_in_arrivo() -> void:
	_colpo_in_arrivo_timer = 0.6

func _guadagna_adrenalina(quantita: float) -> void:
	if is_dead:
		return
	if in_adrenalina:
		adrenalina_timer = minf(adrenalina_timer + quantita, ADRENALINA_DURATA)
	else:
		adrenalina_carica = minf(adrenalina_carica + quantita, ADRENALINA_MASSIMA)
		if _hud and _hud.has_method("aggiorna_adrenalina"):
			_hud.aggiorna_adrenalina(adrenalina_carica, ADRENALINA_MASSIMA)

func _gestisci_footstep(direction: float, delta: float) -> void:
	if is_on_floor() and direction != 0:
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			_audio_footstep.play()
			_footstep_timer = FOOTSTEP_INTERVAL
	else:
		_audio_footstep.stop()
		_footstep_timer = 0.0

func _inizia_attacco() -> void:
	sta_attaccando = true
	animated_sprite.play("attack")
	_audio_melee.play()

	# Applica danno melee (35) ai nemici molto vicini davanti
	var direction_x = -1.0 if animated_sprite.flip_h else 1.0
	_applica_danno_frontale(35 * _mult_danno(), 250.0, 150.0, direction_x, true)

func _inizia_sparo() -> void:
	sta_attaccando = true
	munizioni_attuali -= 1
	_aggiorna_hud_munizioni()
	animated_sprite.play("spara")
	_audio_shoot.play()
	
	var direction_x = -1.0 if animated_sprite.flip_h else 1.0
	
	var bullet_script = preload("res://SCRIPTS/Proiettile.gd")
	var bullet = Area2D.new()
	bullet.set_script(bullet_script)
	bullet.velocity = Vector2(direction_x * 1600.0, 0)
	bullet.danno = armi_sbloccate[indice_arma_attuale]["danno"] * _mult_danno()
	bullet.global_position = global_position + Vector2(direction_x * 160, 85)
	
	if direction_x < 0:
		bullet.scale.x = -1
		
	get_parent().add_child(bullet)

func _inizia_ricarica() -> void:
	sta_attaccando = true
	animated_sprite.play("ricarica")
	_audio_reload.play()

func _inizia_granata() -> void:
	sta_attaccando = true
	carica_granata = 0.0
	granate -= 1
	if _hud:
		_hud.imposta_granate(granate)
	animated_sprite.play("granata")
func _lancia_esplosione() -> void:
	var verso := -1.0 if animated_sprite.flip_h else 1.0
	
	# Creiamo una granata visiva
	var granata = Polygon2D.new()
	granata.polygon = PackedVector2Array([Vector2(-8,-8), Vector2(8,-8), Vector2(8,8), Vector2(-8,8)])
	granata.color = Color(0.15, 0.15, 0.1)
	get_parent().add_child(granata)
	
	# Punto di partenza: circa la mano del giocatore
	var start_pos = global_position + Vector2(40 * verso, -50)
	granata.global_position = start_pos
	
	# --- FISICA REALISTICA ---
	# Potenza: 0.0 (no carica) → 1.0 (carica massima 0.5s)
	var power = clampf(carica_granata / 0.5, 0.0, 1.0)
	
	# Velocità scalare proporzionale alla carica (min 400, max 950 px/s)
	var speed = lerp(400.0, 950.0, power)
	
	# Angolo fisso di 45° per massima gittata naturalistica
	var angle_rad = deg_to_rad(45.0)
	var vx = speed * cos(angle_rad) * verso
	var vy = -speed * sin(angle_rad)  # negativo = verso l'alto

	# Pavimento reale (i nemici sono a questa Y)
	var floor_y = global_position.y + 240.0

	# Tempo di volo REALE con dislivello: risolve 0.5*g*t² + vy*t + (start_y - floor_y) = 0
	# → prende la radice positiva (atterraggio futuro)
	var qa = 0.5 * gravity
	var qb = vy
	var qc = start_pos.y - floor_y
	var discriminant = qb * qb - 4.0 * qa * qc
	var t_volo = (-qb + sqrt(discriminant)) / (2.0 * qa)

	# Posizione finale: X calcolata con velocità costante, Y = pavimento reale
	var end_pos = Vector2(start_pos.x + vx * t_volo, floor_y)

	# Picco della parabola: avviene al tempo t_peak = -vy / gravity
	var t_peak = -vy / gravity
	var peak_y = start_pos.y + vy * t_peak + 0.5 * gravity * t_peak * t_peak
	var t_down = t_volo - t_peak

	# Tween orizzontale (lineare, costante)
	var tween = create_tween()
	tween.tween_property(granata, "global_position:x", end_pos.x, t_volo)

	# Tween verticale: salita fino al picco, poi discesa fino al pavimento
	var tween_y = create_tween()
	tween_y.tween_property(granata, "global_position:y", peak_y, t_peak)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween_y.tween_property(granata, "global_position:y", end_pos.y, t_down)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Rotazione durante il volo
	var tween_rot = create_tween()
	tween_rot.tween_property(granata, "rotation", deg_to_rad(360.0 * 2.5 * verso), t_volo)
	
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
	_audio_explosion.play()
	
	# Applica danno esplosione (Raggio di 200 pixel)
	_applica_danno_esplosione(pos_esplosione, 200.0, 100 * _mult_danno())

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
		if b.is_in_group("enemies"):
			b.take_damage(danno, is_melee)
		else:
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
	if is_dead and animated_sprite.animation == "morta":
		_trigger_game_over()
		return

	if animated_sprite.animation == "hurt":
		sta_attaccando = false
		animated_sprite.play("fermo")
		return

	if animated_sprite.animation == "ricarica":
		# Preleva le munizioni necessarie dalla riserva
		var arma = armi_sbloccate[indice_arma_attuale]
		var mancanti = munizioni_massime - munizioni_attuali
		var da_prelevare = min(mancanti, arma["munizioni_riserva"])
		munizioni_attuali += da_prelevare
		arma["munizioni_riserva"] -= da_prelevare
		arma["munizioni_attuali"] = munizioni_attuali
		_aggiorna_hud_munizioni()
	elif animated_sprite.animation == "spara":
		if modalita_sparo != "Semi-Auto" and Input.is_action_pressed("spara") and munizioni_attuali > 0:
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
	var riserva = armi_sbloccate[indice_arma_attuale]["munizioni_riserva"]
	_hud.aggiorna_munizioni(munizioni_attuali, munizioni_massime, riserva)

func _aggiorna_hud_salute() -> void:
	if _hud == null:
		return
	_hud.aggiorna_salute(health, max_health)

func _aggiorna_hud_armatura() -> void:
	if _hud == null:
		return
	if _hud.has_method("aggiorna_armatura"):
		_hud.aggiorna_armatura(armor, max_armor)

func _trigger_game_over() -> void:
	var go_screen = get_tree().get_first_node_in_group("game_over_screen")
	if go_screen and go_screen.has_method("mostra") and not go_screen.visible:
		go_screen.mostra()

func _mostra_tutorial(testo: String, durata: float = 4.0) -> void:
	_tutorial_label.text = testo
	if _tutorial_tween and _tutorial_tween.is_valid():
		_tutorial_tween.kill()
	_tutorial_tween = create_tween()
	_tutorial_tween.tween_property(_tutorial_label, "modulate:a", 1.0, 0.5)
	_tutorial_tween.tween_interval(durata)
	_tutorial_tween.tween_property(_tutorial_label, "modulate:a", 0.0, 0.5)

func raccogli_giubbotto() -> void:
	armor = max_armor
	_aggiorna_hud_armatura()
	_audio_pickup.play()

func raccogli_munizioni() -> void:
	# Ricarica la riserva dell'arma corrente fino al massimo
	var arma = armi_sbloccate[indice_arma_attuale]
	arma["munizioni_riserva"] = arma["munizioni_riserva_massime"]
	_aggiorna_hud_munizioni()
	_audio_pickup.play()
	_mostra_tutorial("Munizioni per " + arma["nome_arma"] + " trovate!", 2.0)

func raccogli_granata() -> void:
	granate += 1
	if _hud:
		_hud.imposta_granate(granate)
	_audio_pickup.play()
	_mostra_tutorial("Granata trovata!", 2.0)

func raccogli_medikit(quantita: int) -> void:
	health = min(health + quantita, max_health)
	_aggiorna_hud_salute()
	_audio_pickup.play()
	_mostra_tutorial("+" + str(quantita) + " HP", 2.0)

# --- ADRENALINA ---
func _mult_danno() -> int:
	return ADRENALINA_MOLT_DANNO if in_adrenalina else 1

func _gestisci_adrenalina(delta: float) -> void:
	if is_dead:
		return
	if in_adrenalina:
		# Decadimento: la barra (tempo residuo) cala di continuo; le uccisioni la ricaricano
		adrenalina_timer -= delta
		if _hud and _hud.has_method("aggiorna_adrenalina"):
			_hud.aggiorna_adrenalina(maxf(adrenalina_timer, 0.0), ADRENALINA_DURATA, true)
		if adrenalina_timer <= 0.0:
			_disattiva_adrenalina()
	elif Input.is_action_just_pressed("adrenalina") and adrenalina_carica >= ADRENALINA_MASSIMA:
		_attiva_adrenalina()

# Chiamata dai nemici quando muoiono. da_melee = uccisione corpo a corpo (+50%)
func registra_uccisione(da_melee: bool = false) -> void:
	if is_dead:
		return
	var guadagno := ADRENALINA_GUADAGNO_MELEE if da_melee else ADRENALINA_GUADAGNO_FUOCO
	if in_adrenalina:
		# Durante la modalità ogni uccisione "rinnova l'onda" allungando il tempo residuo
		adrenalina_timer = minf(adrenalina_timer + guadagno, ADRENALINA_DURATA)
	else:
		adrenalina_carica = minf(adrenalina_carica + guadagno, ADRENALINA_MASSIMA)
		if _hud and _hud.has_method("aggiorna_adrenalina"):
			_hud.aggiorna_adrenalina(adrenalina_carica, ADRENALINA_MASSIMA)

func _attiva_adrenalina() -> void:
	in_adrenalina = true
	adrenalina_timer = ADRENALINA_DURATA
	adrenalina_carica = 0.0  # consuma la carica

	if _audio_adrenalina:
		_audio_adrenalina.play()

	# Rallentamento momentaneo (time-scale 0.85 per 0.5s reali)
	Engine.time_scale = 0.85
	get_tree().create_timer(0.5, true, false, true).timeout.connect(_ripristina_time_scale)

	# Leggero zoom della telecamera per dare "peso" all'attivazione
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(player_camera, "zoom", camera_zoom * 1.12, 0.25).set_ease(Tween.EASE_OUT)

	if _hud:
		if _hud.has_method("imposta_filtro_adrenalina"):
			_hud.imposta_filtro_adrenalina(true)
		if _hud.has_method("aggiorna_adrenalina"):
			_hud.aggiorna_adrenalina(adrenalina_timer, ADRENALINA_DURATA, true)

func _disattiva_adrenalina() -> void:
	in_adrenalina = false
	adrenalina_timer = 0.0

	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(player_camera, "zoom", camera_zoom, 0.4).set_ease(Tween.EASE_OUT)

	if _hud:
		if _hud.has_method("imposta_filtro_adrenalina"):
			_hud.imposta_filtro_adrenalina(false)
		if _hud.has_method("aggiorna_adrenalina"):
			_hud.aggiorna_adrenalina(adrenalina_carica, ADRENALINA_MASSIMA)

func _ripristina_time_scale() -> void:
	Engine.time_scale = 1.0

func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead:
		return
	# Durante la schivata il giocatore è invincibile
	if is_dodging:
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
		if health <= 0:
			is_dead = true
			sta_attaccando = false
			_exit_crouch()
			if animated_sprite.sprite_frames.has_animation("morta"):
				animated_sprite.play("morta")
			else:
				_trigger_game_over()
		else:
			sta_attaccando = false
			if animated_sprite.sprite_frames.has_animation("hurt"):
				animated_sprite.play("hurt")

func cambia_soldato(indice: int) -> void:
	var folder_nuovo = "res://assets/Soldier_" + str(indice) + "/"
	
	# We duplicate the sprite_frames to avoid editing the original resource on disk
	animated_sprite.sprite_frames = animated_sprite.sprite_frames.duplicate(true)
	
	var anims = animated_sprite.sprite_frames.get_animation_names()
	for anim_name in anims:
		var frame_count = animated_sprite.sprite_frames.get_frame_count(anim_name)
		for f in range(frame_count):
			var tex = animated_sprite.sprite_frames.get_frame_texture(anim_name, f)
			if tex is AtlasTexture:
				var path = tex.atlas.resource_path
				if path.contains("assets/Soldier_"):
					var filename = path.get_file()
					var new_path = folder_nuovo + filename
					if ResourceLoader.exists(new_path):
						var new_atlas = load(new_path)
						tex.atlas = new_atlas

func cambia_arma_successiva() -> void:
	if armi_sbloccate.size() <= 1 or sta_attaccando or is_dead:
		return
	
	armi_sbloccate[indice_arma_attuale]["munizioni_attuali"] = munizioni_attuali
	indice_arma_attuale = (indice_arma_attuale + 1) % armi_sbloccate.size()
	var nuova_arma = armi_sbloccate[indice_arma_attuale]
	
	nome_arma = nuova_arma["nome_arma"]
	modalita_sparo = nuova_arma["modalita_sparo"]
	munizioni_massime = nuova_arma["munizioni_massime"]
	munizioni_attuali = nuova_arma["munizioni_attuali"]
	
	cambia_soldato(nuova_arma["soldier_index"])
	
	if _hud:
		_hud.imposta_arma(nome_arma)
		_hud.imposta_modalita_sparo(modalita_sparo)
	_aggiorna_hud_munizioni()
	_audio_pickup.play()

func raccogli_arma(soldier_index: int) -> void:
	var arma_trovata = false
	for arma in armi_sbloccate:
		if arma["soldier_index"] == soldier_index:
			arma["munizioni_attuali"] = arma["munizioni_massime"]
			arma_trovata = true
			if arma == armi_sbloccate[indice_arma_attuale]:
				munizioni_attuali = munizioni_massime
				_aggiorna_hud_munizioni()
			break
			
	if not arma_trovata:
		armi_sbloccate.append({
			"soldier_index": soldier_index,
			"nome_arma": "STG44" if soldier_index != 1 else "AR11",
			"modalita_sparo": "Automatico" if soldier_index != 1 else "Semi-Auto",
			"munizioni_massime": 15 if soldier_index != 1 else 8,
			"munizioni_attuali": 15 if soldier_index != 1 else 8,
			"munizioni_riserva": 45 if soldier_index != 1 else 24,
			"munizioni_riserva_massime": 45 if soldier_index != 1 else 24,
			"danno": 20 if soldier_index != 1 else 35
		})
		armi_sbloccate[indice_arma_attuale]["munizioni_attuali"] = munizioni_attuali
		indice_arma_attuale = armi_sbloccate.size() - 2
		cambia_arma_successiva()
		_mostra_tutorial("Hai raccolto una nuova arma! Premi [ Q ] per cambiare arma in qualsiasi momento.", 6.0)
	else:
		_audio_pickup.play()

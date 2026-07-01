extends CanvasLayer

const PIXEL_FONT: Font = preload("res://assets/Fonts/PressStart2P-Regular.ttf")

@onready var _weapon_name: Label = %WeaponName
@onready var _ammo_current: Label = %AmmoCurrent
@onready var _ammo_reserve: Label = %AmmoReserve
@onready var _fire_mode: Label = %FireMode
@onready var _bullet_icon: Label = %BulletIcon
@onready var _grenade_icon: TextureRect = $WeaponRoot/Panel/HBox/GrenadeBlock/GrenadeIcon
@onready var _grenade_count: Label = %GrenadeCount
@onready var _grenade_count_2: Label = $WeaponRoot/Panel/HBox/GrenadeBlock/GrenadeCount2

@onready var _health_title: Label = %HealthTitle
@onready var _health_value: Label = %HealthValue
@onready var _health_bar: TextureProgressBar = %HealthBar

@onready var _armor_title: Label = %ArmorTitle
@onready var _armor_value: Label = %ArmorValue
@onready var _armor_bar: TextureProgressBar = %ArmorBar

@onready var _adrenaline_title: Label = %AdrenalineTitle
@onready var _adrenaline_hint: Label = %AdrenalineHint
@onready var _adrenaline_bar: TextureProgressBar = %AdrenalineBar
@onready var _adrenaline_filter: ColorRect = %AdrenalineFilter
var _adrenaline_pulse_tween: Tween
var _adrenaline_filter_tween: Tween

@onready var _timer_label: Label = %TimerLabel
var _tempo_trascorso := 0.0
var _timer_attivo := true

const COLOR_NORMAL := Color(0.95, 0.95, 0.95, 1.0)
const COLOR_DIM := Color(0.72, 0.72, 0.72, 1.0)
const COLOR_EMPTY := Color(0.92, 0.28, 0.22, 1.0)

var _ultimo_ratio_salute := 1.0

func _ready() -> void:
	_grenade_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_grenade_count_2.visible = false  # Nasconde il contatore duplicato
	_applica_font_pixel()

func _applica_font_pixel() -> void:
	var labels: Array[Label] = [
		_health_title, _health_value, _armor_title, _armor_value,
		_adrenaline_title, _adrenaline_hint,
		_weapon_name, _fire_mode, _ammo_current, _ammo_reserve, _bullet_icon, _grenade_count,
	]
	for label in labels:
		label.add_theme_font_override("font", PIXEL_FONT)

func _process(delta: float) -> void:
	if _timer_attivo:
		_tempo_trascorso += delta
		if _timer_label:
			_timer_label.text = _format_tempo(_tempo_trascorso)

# --- CRONOMETRO LIVELLO ---
func get_tempo_trascorso() -> float:
	return _tempo_trascorso

func ferma_timer() -> void:
	_timer_attivo = false

func _format_tempo(secondi: float) -> String:
	var totale := int(secondi)
	return "%02d:%02d" % [totale / 60, totale % 60]

func aggiorna_munizioni(attuali: int, massime: int, riserva: int = -1) -> void:
	_ammo_current.text = str(attuali)
	if riserva >= 0:
		_ammo_reserve.text = str(riserva)
	else:
		_ammo_reserve.text = str(massime)
	_ammo_current.add_theme_color_override("font_color", COLOR_EMPTY if attuali <= 0 else COLOR_NORMAL)
	_ammo_reserve.add_theme_color_override("font_color", COLOR_DIM)

func aggiorna_salute(attuale: int, massimo: int) -> void:
	var ratio := clampf(float(attuale) / float(massimo), 0.0, 1.0) if massimo > 0 else 0.0
	_health_value.text = "%d/%d" % [attuale, massimo]
	_health_bar.max_value = massimo
	_health_bar.value = attuale
	if ratio < _ultimo_ratio_salute:
		_pulse_danno(_health_bar)
	_ultimo_ratio_salute = ratio

func aggiorna_armatura(attuale: int, massimo: int) -> void:
	_armor_value.text = "%d/%d" % [attuale, massimo]
	_armor_bar.max_value = massimo
	_armor_bar.value = attuale

func _pulse_danno(barra: TextureProgressBar) -> void:
	var tween := create_tween()
	tween.tween_property(barra, "modulate", Color(1.4, 0.7, 0.7), 0.08)
	tween.tween_property(barra, "modulate", Color.WHITE, 0.2)

func aggiorna_adrenalina(valore: float, massimo: float, in_modalita: bool = false) -> void:
	if _adrenaline_bar == null:
		return
	_adrenaline_bar.max_value = massimo
	_adrenaline_bar.value = valore
	# Pulsa solo quando la carica è piena e pronta da attivare (fuori dalla modalità)
	var pronta := (not in_modalita) and valore >= massimo
	if pronta and (_adrenaline_pulse_tween == null or not _adrenaline_pulse_tween.is_valid()):
		_adrenaline_pulse_tween = create_tween().set_loops()
		_adrenaline_pulse_tween.tween_property(_adrenaline_bar, "modulate", Color(1.6, 1.6, 1.6), 0.4)
		_adrenaline_pulse_tween.tween_property(_adrenaline_bar, "modulate", Color.WHITE, 0.4)
	elif not pronta and _adrenaline_pulse_tween and _adrenaline_pulse_tween.is_valid():
		_adrenaline_pulse_tween.kill()
	if not pronta:
		# Glow fisso più acceso durante la modalità, normale altrimenti
		_adrenaline_bar.modulate = Color(1.3, 1.3, 1.3) if in_modalita else Color.WHITE

func imposta_filtro_adrenalina(attivo: bool) -> void:
	if _adrenaline_filter == null:
		return
	if _adrenaline_filter_tween and _adrenaline_filter_tween.is_valid():
		_adrenaline_filter_tween.kill()
	if attivo:
		# Filtro verde pulsante su tutto lo schermo durante l'adrenalina
		_adrenaline_filter_tween = create_tween().set_loops()
		_adrenaline_filter_tween.tween_property(_adrenaline_filter, "color:a", 0.22, 0.5)
		_adrenaline_filter_tween.tween_property(_adrenaline_filter, "color:a", 0.10, 0.5)
	else:
		_adrenaline_filter_tween = create_tween()
		_adrenaline_filter_tween.tween_property(_adrenaline_filter, "color:a", 0.0, 0.3)

func imposta_arma(nome: String) -> void:
	_weapon_name.text = nome.to_upper()

func imposta_modalita_sparo(modalita: String) -> void:
	_fire_mode.text = modalita.to_upper()

func imposta_granate(quantita: int) -> void:
	var testo := str(quantita)
	_grenade_count.text = testo
	# _grenade_count_2 è nascosto, non viene aggiornato

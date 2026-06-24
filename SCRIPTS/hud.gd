extends CanvasLayer

@onready var _weapon_name: Label = %WeaponName
@onready var _ammo_current: Label = %AmmoCurrent
@onready var _ammo_reserve: Label = %AmmoReserve
@onready var _fire_mode: Label = %FireMode
@onready var _grenade_icon: TextureRect = $WeaponRoot/Panel/HBox/GrenadeBlock/GrenadeIcon
@onready var _grenade_count: Label = %GrenadeCount
@onready var _grenade_count_2: Label = $WeaponRoot/Panel/HBox/GrenadeBlock/GrenadeCount2
@onready var _health_value: Label = %HealthValue
@onready var _health_glow: Panel = %HealthGlow
@onready var _health_segments: HBoxContainer = %HealthSegments

@onready var _armor_value: Label = %ArmorValue
@onready var _armor_glow: Panel = %ArmorGlow
@onready var _armor_segments: HBoxContainer = %ArmorSegments

const COLOR_NORMAL := Color(0.95, 0.95, 0.95, 1.0)
const COLOR_DIM := Color(0.72, 0.72, 0.72, 1.0)
const COLOR_EMPTY := Color(0.92, 0.28, 0.22, 1.0)
const COLOR_LOW_HEALTH := Color(0.95, 0.55, 0.2, 1.0)

const SEG_ON_GREEN := Color(0.28, 0.52, 0.24, 1.0)
const SEG_BORDER_GREEN := Color(0.55, 0.82, 0.48, 1.0)
const SEG_ON_ORANGE := Color(0.62, 0.38, 0.12, 1.0)
const SEG_BORDER_ORANGE := Color(0.95, 0.62, 0.22, 1.0)
const SEG_ON_RED := Color(0.58, 0.16, 0.14, 1.0)
const SEG_BORDER_RED := Color(0.92, 0.32, 0.26, 1.0)
const SEG_OFF_BG := Color(0.09, 0.1, 0.09, 1.0)
const SEG_OFF_BORDER := Color(0.2, 0.22, 0.2, 1.0)

const SEG_ON_BLUE := Color(0.12, 0.45, 0.75, 1.0)
const SEG_BORDER_BLUE := Color(0.25, 0.65, 0.95, 1.0)

var _segment_panels: Array[Panel] = []
var _style_seg_on := StyleBoxFlat.new()
var _style_seg_off := StyleBoxFlat.new()
var _ultimo_ratio_salute := 1.0

var _segment_panels_armor: Array[Panel] = []
var _style_seg_on_armor := StyleBoxFlat.new()
var _style_seg_off_armor := StyleBoxFlat.new()

func _ready() -> void:
	_grenade_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_setup_segment_styles()
	_setup_armor_styles()
	for child in _health_segments.get_children():
		if child is Panel:
			_segment_panels.append(child)
	for child in _armor_segments.get_children():
		if child is Panel:
			_segment_panels_armor.append(child)

func _setup_segment_styles() -> void:
	_style_seg_on.set_border_width_all(1)
	_style_seg_on.set_corner_radius_all(2)
	_style_seg_off.bg_color = SEG_OFF_BG
	_style_seg_off.border_color = SEG_OFF_BORDER
	_style_seg_off.set_border_width_all(1)
	_style_seg_off.set_corner_radius_all(2)

func _setup_armor_styles() -> void:
	_style_seg_on_armor.set_border_width_all(1)
	_style_seg_on_armor.set_corner_radius_all(2)
	_style_seg_on_armor.bg_color = SEG_ON_BLUE
	_style_seg_on_armor.border_color = SEG_BORDER_BLUE
	
	_style_seg_off_armor.bg_color = SEG_OFF_BG
	_style_seg_off_armor.border_color = SEG_OFF_BORDER
	_style_seg_off_armor.set_border_width_all(1)
	_style_seg_off_armor.set_corner_radius_all(2)

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
	_health_value.text = str(attuale)
	_applica_colori_salute(ratio)
	_aggiorna_segmenti(ratio)
	_aggiorna_glow(ratio)
	if ratio < _ultimo_ratio_salute:
		_pulse_danno()
	_ultimo_ratio_salute = ratio

func _applica_colori_salute(ratio: float) -> void:
	if ratio <= 0.25:
		_health_value.add_theme_color_override("font_color", COLOR_EMPTY)
		_style_seg_on.bg_color = SEG_ON_RED
		_style_seg_on.border_color = SEG_BORDER_RED
	elif ratio <= 0.5:
		_health_value.add_theme_color_override("font_color", COLOR_LOW_HEALTH)
		_style_seg_on.bg_color = SEG_ON_ORANGE
		_style_seg_on.border_color = SEG_BORDER_ORANGE
	else:
		_health_value.add_theme_color_override("font_color", COLOR_NORMAL)
		_style_seg_on.bg_color = SEG_ON_GREEN
		_style_seg_on.border_color = SEG_BORDER_GREEN

func _aggiorna_segmenti(ratio: float) -> void:
	if _segment_panels.is_empty():
		return
	var attivi := int(ceil(ratio * float(_segment_panels.size())))
	for i in _segment_panels.size():
		if i < attivi:
			_segment_panels[i].add_theme_stylebox_override("panel", _style_seg_on)
		else:
			_segment_panels[i].add_theme_stylebox_override("panel", _style_seg_off)

func _aggiorna_glow(ratio: float) -> void:
	_health_glow.modulate.a = clampf(ratio * 0.85 + 0.1, 0.1, 0.85)
	_health_glow.anchor_right = clampf(ratio, 0.02, 1.0)

func _pulse_danno() -> void:
	var tween := create_tween()
	tween.tween_property(_health_segments, "modulate", Color(1.4, 0.7, 0.7), 0.08)
	tween.tween_property(_health_segments, "modulate", Color.WHITE, 0.2)

func aggiorna_armatura(attuale: int, massimo: int) -> void:
	var ratio := clampf(float(attuale) / float(massimo), 0.0, 1.0) if massimo > 0 else 0.0
	_armor_value.text = str(attuale)
	_aggiorna_segmenti_armatura(ratio)
	_aggiorna_glow_armatura(ratio)

func _aggiorna_segmenti_armatura(ratio: float) -> void:
	if _segment_panels_armor.is_empty():
		return
	var attivi := int(ceil(ratio * float(_segment_panels_armor.size())))
	for i in _segment_panels_armor.size():
		if i < attivi:
			_segment_panels_armor[i].add_theme_stylebox_override("panel", _style_seg_on_armor)
		else:
			_segment_panels_armor[i].add_theme_stylebox_override("panel", _style_seg_off_armor)

func _aggiorna_glow_armatura(ratio: float) -> void:
	_armor_glow.modulate = SEG_ON_BLUE
	_armor_glow.modulate.a = clampf(ratio * 0.85 + 0.1, 0.1, 0.85)
	_armor_glow.anchor_right = clampf(ratio, 0.02, 1.0)

func imposta_arma(nome: String) -> void:
	_weapon_name.text = nome.to_upper()

func imposta_modalita_sparo(modalita: String) -> void:
	_fire_mode.text = modalita.to_upper()

func imposta_granate(quantita: int) -> void:
	var testo := str(quantita)
	_grenade_count.text = testo
	_grenade_count_2.text = testo

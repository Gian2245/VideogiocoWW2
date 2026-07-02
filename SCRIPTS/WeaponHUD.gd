extends Control

## Riquadro arma dell'HUD (nome, modalità di fuoco, munizioni, granate), sopra la
## cornice "cornice armi.png". Espone la stessa interfaccia che il vecchio blocco
## interno a hud.gd esponeva, così hud.gd può limitarsi a inoltrare le chiamate.

const PIXEL_FONT: Font = preload("res://assets/Fonts/PressStart2P-Regular.ttf")

const COLOR_NORMAL := Color(0.97, 0.97, 0.95, 1.0)
const COLOR_EMPTY := Color(0.92, 0.28, 0.22, 1.0)

@onready var _weapon_name: Label = %WeaponName
@onready var _fire_mode: Label = %FireMode
@onready var _ammo_current: Label = %AmmoCurrent
@onready var _ammo_reserve: Label = %AmmoReserve
@onready var _grenade_count: Label = %GrenadeCount

func _ready() -> void:
	var labels: Array[Label] = [_weapon_name, _fire_mode, _ammo_current, _ammo_reserve, _grenade_count]
	for label in labels:
		label.add_theme_font_override("font", PIXEL_FONT)

func imposta_arma(nome: String) -> void:
	_weapon_name.text = nome.to_upper()

func imposta_modalita_sparo(modalita: String) -> void:
	_fire_mode.text = modalita.to_upper()

func aggiorna_munizioni(attuali: int, massime: int, riserva: int = -1) -> void:
	_ammo_current.text = str(attuali)
	_ammo_reserve.text = str(riserva) if riserva >= 0 else str(massime)
	_ammo_current.add_theme_color_override("font_color", COLOR_EMPTY if attuali <= 0 else COLOR_NORMAL)

func imposta_granate(quantita: int) -> void:
	_grenade_count.text = str(quantita)

extends Node

# ============================================================
# Singleton Autoload — Persiste l'inventario tra i livelli
# Registrato come autoload "PlayerData" in project.godot
# ============================================================

var has_saved_data: bool = false

# Stato del giocatore
var health: int = 100
var armor: int = 0
var granate: int = 2

# Armi
var armi_sbloccate: Array = []
var indice_arma_attuale: int = 0
var munizioni_attuali: int = 0

func salva_da_player(player: Node) -> void:
	health = player.health
	armor = player.armor
	granate = player.granate
	armi_sbloccate = player.armi_sbloccate.duplicate(true)
	indice_arma_attuale = player.indice_arma_attuale
	munizioni_attuali = player.munizioni_attuali
	has_saved_data = true

func carica_su_player(player: Node) -> void:
	if not has_saved_data:
		return
	player.health = health
	player.armor = armor
	player.granate = granate
	player.armi_sbloccate = armi_sbloccate.duplicate(true)
	player.indice_arma_attuale = indice_arma_attuale
	player.munizioni_attuali = munizioni_attuali
	# Sincronizza le variabili dell'arma corrente
	var arma = player.armi_sbloccate[player.indice_arma_attuale]
	player.nome_arma = arma["nome_arma"]
	player.modalita_sparo = arma["modalita_sparo"]
	player.munizioni_massime = arma["munizioni_massime"]
	# Cambia il soldato visivo se necessario
	player.cambia_soldato(arma["soldier_index"])
	has_saved_data = false

func reset() -> void:
	has_saved_data = false

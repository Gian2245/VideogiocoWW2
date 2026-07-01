extends Node

# ============================================================
# Singleton Autoload — Progressi di gioco persistenti su disco
# (livelli sbloccati e medaglia migliore ottenuta per livello).
# Registrato come autoload "Progress" in project.godot
# ============================================================

const SAVE_PATH := "user://progress.save"
const NUM_LIVELLI := 3

# Medaglie: 0 = nessuna, 1 = bronzo, 2 = argento, 3 = oro
var sbloccati: Array = [true, false, false]
var medaglie: Array = [0, 0, 0]

func _ready() -> void:
	_carica()

func is_sbloccato(indice: int) -> bool:
	if indice < 0 or indice >= sbloccati.size():
		return false
	return sbloccati[indice]

func get_medaglia(indice: int) -> int:
	if indice < 0 or indice >= medaglie.size():
		return 0
	return medaglie[indice]

func completa_livello(indice: int, medaglia: int) -> void:
	if indice < 0 or indice >= NUM_LIVELLI:
		return
	sbloccati[indice] = true
	if medaglia > medaglie[indice]:
		medaglie[indice] = medaglia
	if indice + 1 < NUM_LIVELLI:
		sbloccati[indice + 1] = true
	_salva()

func _salva() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"sbloccati": sbloccati, "medaglie": medaglie}))
	file.close()

func _carica() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var dati = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(dati) != TYPE_DICTIONARY:
		return
	if dati.has("sbloccati"):
		for i in range(min(sbloccati.size(), dati["sbloccati"].size())):
			sbloccati[i] = dati["sbloccati"][i]
	if dati.has("medaglie"):
		for i in range(min(medaglie.size(), dati["medaglie"].size())):
			medaglie[i] = dati["medaglie"][i]

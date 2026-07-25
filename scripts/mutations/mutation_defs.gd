class_name MutationDefs
## Catálogo estático de todas las mutaciones disponibles.

enum Rarity { COMMON, UNCOMMON, RARE }

# ── Datos de cada mutación ─────────────────────────────────────
static var MUTATIONS: Dictionary = {
	"reactive_spikes": {
		"name": "Pinchos Reactivos",
		"description": "Al recibir daño, dispara 8 proyectiles en todas direcciones.",
		"rarity": Rarity.COMMON,
		"color": Color(1.0, 0.4, 0.2),
		"price": 150,
	},
	"orbital_cell": {
		"name": "Célula Orbital",
		"description": "Una célula orbita alrededor y daña a los enemigos que toca.",
		"rarity": Rarity.UNCOMMON,
		"color": Color(0.3, 0.85, 1.0),
		"price": 300,
	},
	"split_shot": {
		"name": "División Celular",
		"description": "Los proyectiles se dividen en 2 al impactar.",
		"rarity": Rarity.UNCOMMON,
		"color": Color(0.6, 1.0, 0.3),
		"price": 300,
	},
	"reinforced_membrane": {
		"name": "Membrana Reforzada",
		"description": "+25% HP máximo. Regenera 1 HP por segundo.",
		"rarity": Rarity.COMMON,
		"color": Color(0.2, 0.9, 0.5),
		"price": 150,
	},
	"toxic_capside": {
		"name": "Cápside Tóxica",
		"description": "Los enemigos cercanos reciben daño pasivo cada segundo.",
		"rarity": Rarity.RARE,
		"color": Color(0.7, 0.2, 1.0),
		"price": 600,
	},
	"minor_health": {
		"name": "HP Menor",
		"description": "+10% Vida Máxima.",
		"rarity": Rarity.COMMON,
		"color": Color(0.9, 0.7, 0.7),
		"price": 50,
	},
	"minor_attack": {
		"name": "Ataque Menor",
		"description": "+10% Daño de Ataque.",
		"rarity": Rarity.COMMON,
		"color": Color(0.9, 0.8, 0.6),
		"price": 50,
	},
	"minor_speed": {
		"name": "Agilidad Menor",
		"description": "+10% Velocidad Movimiento.",
		"rarity": Rarity.COMMON,
		"color": Color(0.6, 0.9, 0.7),
		"price": 50,
	},
	"minor_atk_speed": {
		"name": "Velocidad Menor",
		"description": "+10% Velocidad de Ataque.",
		"rarity": Rarity.COMMON,
		"color": Color(0.9, 0.9, 0.5),
		"price": 50,
	},
	"minor_defense": {
		"name": "Defensa Menor",
		"description": "+1 Defensa base.",
		"rarity": Rarity.COMMON,
		"color": Color(0.6, 0.8, 0.9),
		"price": 50,
	},
}


static func get_rarity_name(rarity: Rarity) -> String:
	match rarity:
		Rarity.COMMON:   return "Común"
		Rarity.UNCOMMON: return "Poco común"
		Rarity.RARE:     return "Raro"
	return ""


static func get_rarity_color(rarity: Rarity) -> Color:
	match rarity:
		Rarity.COMMON:   return Color(0.7, 0.7, 0.7)
		Rarity.UNCOMMON: return Color(0.3, 0.7, 1.0)
		Rarity.RARE:     return Color(0.85, 0.3, 1.0)
	return Color.WHITE

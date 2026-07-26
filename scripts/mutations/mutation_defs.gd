class_name MutationDefs
## Catálogo estático de todas las mutaciones disponibles.

enum Rarity { COMMON, UNCOMMON, RARE }

# ── Datos de cada mutación ─────────────────────────────────────
static var MUTATIONS: Dictionary = {
	"reactive_spikes": {
		"name": "Pinchos Reactivos",
		"description": "Al recibir daño, dispara 8 proyectiles en todas direcciones.",
		"flavor": "\"Verás que te pincho...\"",
		"rarity": Rarity.COMMON,
		"color": Color(1.0, 0.4, 0.2),
		"price": 150,
		"icon_path": "res://assets/sprites/pinchos_reactivos.png",
	},
	"orbital_cell": {
		"name": "Célula Orbital",
		"description": "Una célula orbita alrededor y daña a los enemigos que toca.",
		"flavor": "\"Estás tan gordo que una célula ha entrado en tu órbita... al menos te ayuda\"",
		"rarity": Rarity.UNCOMMON,
		"color": Color(0.3, 0.85, 1.0),
		"price": 300,
		"icon_path": "res://assets/sprites/celula_orbital.png",
	},
	"split_shot": {
		"name": "División Celular",
		"description": "Los proyectiles se dividen en 2 al impactar.",
		"flavor": "\"Fuuusion't\"",
		"rarity": Rarity.UNCOMMON,
		"color": Color(0.6, 1.0, 0.3),
		"price": 300,
		"icon_path": "res://assets/sprites/division_celular.png",
	},
	"reinforced_membrane": {
		"name": "Membrana Reforzada",
		"description": "+25% HP máximo. Regenera 1 HP por segundo.",
		"flavor": "\"Duro como la piedra\"",
		"rarity": Rarity.COMMON,
		"color": Color(0.2, 0.9, 0.5),
		"price": 150,
		"icon_path": "res://assets/sprites/membrana_reforzada.png",
	},
	"creatina_illo": {
		"name": "Creatina ILLO",
		"description": "+25% Vida Máxima, pero incrementa tu tamaño un 10%.",
		"flavor": "\"Illo te vas a poner como el Joan Pradells\"",
		"rarity": Rarity.UNCOMMON,
		"color": Color(0.9, 0.4, 0.2),
		"price": 250,
		"icon_path": "res://assets/sprites/creatina_illo.png",
	},
	"proteina_wey": {
		"name": "Proteína 'Wey'",
		"description": "+10 de Ataque y obtienes x1.5 de Experiencia.",
		"flavor": "\"Para ponerte como el Matón\"",
		"rarity": Rarity.UNCOMMON,
		"color": Color(0.9, 0.8, 0.3),
		"price": 280,
		"icon_path": "res://assets/sprites/proteina.png",
	},
	"cellular_vampirism": {
		"name": "Vampirismo Celular",
		"description": "+5% de Robo de Vida permanente.",
		"flavor": "\"TRAKATRÁ\"",
		"rarity": Rarity.RARE,
		"color": Color(0.9, 0.3, 0.3),
		"price": 500,
		"icon_path": "res://assets/sprites/vampirismo_celular.png",
	},
	"opportunistic_infection": {
		"name": "Infección Oportunista",
		"description": "+20 de Suerte. Cada punto de Suerte es un 1% de probabilidad de que el ADN valga el doble.",
		"flavor": "\"GachapÓn wey\"",
		"rarity": Rarity.RARE,
		"color": Color(0.2, 0.8, 0.6),
		"price": 400,
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
		"icon_path": "res://assets/sprites/ataque.png",
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
		"icon_path": "res://assets/sprites/defensa.png",
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

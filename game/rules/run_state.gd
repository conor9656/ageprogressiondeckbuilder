extends RefCounted
## Persistent Ancient-era run state. Pure data + small helpers — no UI.


var rng: RandomNumberGenerator

var era: int = 1
var settlement_index: int = 0  ## 0 village, 1 town, 2 capital
var kind_order: Array = ["village", "town", "capital"]

var gold: int = 0
var science: int = 0
var culture: int = 0
var faith: int = 0
var sci_level: int = 0
var civ_level: int = 0

var deck_kinds: Array = []  ## Array of kind strings for fights (editions ignored in W3 greybox)
var next_cid: int = 1
var tiers: Dictionary = {"M": 1, "R": 1, "C": 1, "S": 1, "B": 1}
var form_levels: Dictionary = {}

var blueprints: Array = []
var doctrines: Array = []
var policies: Array = []
var blueprint_slots: int = 2
var doctrine_slots: int = 1
var policy_slots: int = 2

var hand_size: int = 8
var base_assaults: int = 4
var base_regroups: int = 3

var builder_charges_max: int = 1
var missionary_charges_max: int = 1

var occupied: Array = []  ## scholar / artisan / temple / trade
var writing: bool = false
var last_troop_upgrade: String = ""
var owned_prog: Dictionary = {}  ## id -> true
var owned_civics: Dictionary = {}

var sci_bonus_pct: float = 0.0
var gold_bonus_pct: float = 0.0
var faith_bonus_pct: float = 0.0
var cul_bonus_pct: float = 0.0
var interest_cap: int = 5
var pack_bonus: int = 0
var unit_cost_flat: int = 0
var reroll_cost: int = 3
var eng_flags: Dictionary = {}
var pro_flags: Dictionary = {}

var log: Array = []
var run_won: bool = false
var run_lost: bool = false


func setup(seed: int = 1) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = seed
	era = 1
	settlement_index = 0
	gold = 0
	science = 0
	culture = 0
	faith = 0
	sci_level = 0
	civ_level = 0
	tiers = {"M": 1, "R": 1, "C": 1, "S": 1, "B": 1}
	form_levels = {}
	blueprints.clear()
	doctrines.clear()
	policies.clear()
	blueprint_slots = 2
	doctrine_slots = 1
	policy_slots = 2
	hand_size = 8
	base_assaults = 4
	base_regroups = 3
	builder_charges_max = 1
	missionary_charges_max = 1
	occupied.clear()
	writing = false
	last_troop_upgrade = ""
	owned_prog.clear()
	owned_civics.clear()
	sci_bonus_pct = 0.0
	gold_bonus_pct = 0.0
	faith_bonus_pct = 0.0
	cul_bonus_pct = 0.0
	interest_cap = 5
	pack_bonus = 0
	unit_cost_flat = 0
	reroll_cost = 3
	eng_flags.clear()
	pro_flags.clear()
	log.clear()
	run_won = false
	run_lost = false
	deck_kinds.clear()
	next_cid = 1
	for _i in 6:
		deck_kinds.append("M")
	for _i in 5:
		deck_kinds.append("R")
	for _i in 3:
		deck_kinds.append("C")
	for _i in 2:
		deck_kinds.append("S")


func current_kind() -> String:
	if settlement_index < 0 or settlement_index >= kind_order.size():
		return ""
	return str(kind_order[settlement_index])


func soft_cap() -> int:
	## E1 = II
	return 2


func income_mult(kind: String) -> float:
	## Ancient only for W3
	return 1.0


func snapshot() -> Dictionary:
	return {
		"gold": gold,
		"science": science,
		"culture": culture,
		"faith": faith,
		"sci_level": sci_level,
		"civ_level": civ_level,
		"tiers": tiers.duplicate(),
		"deck_size": deck_kinds.size(),
		"blueprints": blueprints.duplicate(),
		"doctrines": doctrines.duplicate(),
		"policies": policies.duplicate(),
		"occupied": occupied.duplicate(),
		"settlement_index": settlement_index,
		"hand_size": hand_size,
		"base_assaults": base_assaults,
		"base_regroups": base_regroups,
		"builder_charges_max": builder_charges_max,
		"missionary_charges_max": missionary_charges_max,
		"form_levels": form_levels.duplicate(),
		"pack_bonus": pack_bonus,
		"writing": writing,
	}

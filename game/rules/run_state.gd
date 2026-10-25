extends RefCounted
## Persistent Domination-run state (eras 1–8). Pure data + small helpers — no UI.

const RunTables := preload("res://rules/run_tables.gd")
const CombatTables := preload("res://rules/combat_tables.gd")
const AgesCard := preload("res://rules/card.gd")


var rng: RandomNumberGenerator

var era: int = 1
var settlement_index: int = 0  ## 0 village, 1 town, 2 capital
var kind_order: Array = ["village", "town", "capital"]
var eras_cleared: int = 0  ## Capitals conquered

var gold: int = 0
var science: int = 0
var culture: int = 0
var faith: int = 0
var sci_level: int = 0
var civ_level: int = 0

var deck_cards: Array = []  ## Array of card Dictionaries (AgesCard.to_dict)
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
var builder_scale: float = 1.0  ## Blueprint numeric mult from Builder tier
var missionary_scale: float = 1.0  ## Doctrine payout mult (same table as Builder)

var wonder: String = ""  ## owned Wonder id (one / run) or ""
var shop_wonder_offer: String = ""  ## dedicated Wonder row this visit
var shop_wonder_rerolls_left: int = 1
var skipped_wonders: Dictionary = {}  ## id -> true (rival built it)
var all_units_editions: bool = false  ## Eiffel
var promo_cost_pct: float = 0.0  ## Eiffel −30% etc.

var occupied: Array = []  ## scholar / artisan / temple / trade
var writing: bool = false
var last_troop_upgrade: String = ""
var owned_prog: Dictionary = {}  ## id -> true
var owned_civics: Dictionary = {}

var sci_bonus_pct: float = 0.0
var gold_bonus_pct: float = 0.0
var faith_bonus_pct: float = 0.0
var cul_bonus_pct: float = 0.0
var doctrine_payout_pct: float = 0.0
var victory_gold_pct: float = 0.0
var capital_might_bonus: float = 0.0
var zeal_settlements_left: int = 0
var zeal_might_pct: float = 0.20
var missionary_zeal_gold: int = 15
var missionary_zeal_faith: int = 8
var chichen_mom: int = 0
var interest_cap: int = 5
var pack_bonus: int = 0
var unit_cost_flat: int = 0
var reroll_cost: int = 3
var disband_cost: int = 5
var eng_flags: Dictionary = {}
var pro_flags: Dictionary = {}

## Multi-era growth
var industrial_assault_granted: bool = false
var industrial_toolkit: String = ""
var faith_combat_mom: int = 0
var foundry_bp_mult: float = 1.0

var log: Array = []
var run_won: bool = false
var run_lost: bool = false


func setup(seed: int = 1) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = seed
	era = 1
	settlement_index = 0
	eras_cleared = 0
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
	RunTables.reload()
	CombatTables.ensure_loaded()
	blueprint_slots = RunTables.default_int("blueprint_slots")
	doctrine_slots = RunTables.default_int("doctrine_slots")
	policy_slots = RunTables.default_int("policy_slots")
	hand_size = RunTables.default_int("hand_size")
	base_assaults = RunTables.default_int("base_assaults")
	base_regroups = RunTables.default_int("base_regroups")
	builder_charges_max = RunTables.default_int("builder_charges_max")
	missionary_charges_max = RunTables.default_int("missionary_charges_max")
	builder_scale = RunTables.builder_scale_for_tier(1)
	missionary_scale = RunTables.builder_scale_for_tier(1)
	wonder = ""
	shop_wonder_offer = ""
	shop_wonder_rerolls_left = 1
	skipped_wonders.clear()
	all_units_editions = false
	promo_cost_pct = 0.0
	occupied.clear()
	writing = false
	last_troop_upgrade = ""
	owned_prog.clear()
	owned_civics.clear()
	sci_bonus_pct = 0.0
	gold_bonus_pct = 0.0
	faith_bonus_pct = 0.0
	cul_bonus_pct = 0.0
	doctrine_payout_pct = 0.0
	victory_gold_pct = 0.0
	capital_might_bonus = 0.0
	zeal_settlements_left = 0
	zeal_might_pct = 0.20
	missionary_zeal_gold = 15
	missionary_zeal_faith = 8
	chichen_mom = 0
	interest_cap = RunTables.default_int("interest_cap")
	pack_bonus = 0
	unit_cost_flat = 0
	reroll_cost = RunTables.default_int("reroll_cost")
	disband_cost = RunTables.disband_start_cost()
	eng_flags.clear()
	pro_flags.clear()
	industrial_assault_granted = false
	industrial_toolkit = ""
	faith_combat_mom = 0
	foundry_bp_mult = 1.0
	log.clear()
	run_won = false
	run_lost = false
	deck_cards.clear()
	next_cid = 1
	var starter: Dictionary = RunTables.starting_deck_counts()
	for kind in ["M", "R", "C", "S"]:
		for _i in int(starter.get(kind, 0)):
			add_unit_card(str(kind), "standard")


func add_unit_card(kind: String, edition: String = "standard") -> Dictionary:
	var c: RefCounted = AgesCard.new(kind, next_cid)
	next_cid += 1
	if edition != "" and edition != "standard":
		c.apply_edition(edition)
	else:
		c.edition = "standard"
	var d: Dictionary = c.to_dict()
	deck_cards.append(d)
	return d


func deck_kinds() -> Array:
	var out: Array = []
	for d in deck_cards:
		out.append(str(d.get("kind", "M")))
	return out


func deck_size() -> int:
	return deck_cards.size()


func current_kind() -> String:
	if settlement_index < 0 or settlement_index >= kind_order.size():
		return ""
	return str(kind_order[settlement_index])


func soft_cap() -> int:
	CombatTables.ensure_loaded()
	return CombatTables.soft_cap(era)


func income_mult(kind: String) -> float:
	return RunTables.income_mult(era, kind)


func bar_cost_mult() -> float:
	var m: float = 1.0
	if era >= RunTables.breakthrough_era_min():
		m = 1.0 - RunTables.midgame_bar_discount()
	if bool(eng_flags.get("sci_cost_cut", false)):
		m *= 0.75
	return m


func era_label() -> String:
	return RunTables.era_name(era)


func snapshot() -> Dictionary:
	return {
		"era": era,
		"era_name": era_label(),
		"eras_cleared": eras_cleared,
		"gold": gold,
		"science": science,
		"culture": culture,
		"faith": faith,
		"sci_level": sci_level,
		"civ_level": civ_level,
		"tiers": tiers.duplicate(),
		"deck_size": deck_cards.size(),
		"deck_cards": deck_cards.duplicate(true),
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
		"builder_scale": builder_scale,
		"missionary_scale": missionary_scale,
		"builder_tier": int(tiers.get("B", 1)),
		"wonder": wonder,
		"skipped_wonders": skipped_wonders.keys(),
		"disband_cost": disband_cost,
		"form_levels": form_levels.duplicate(),
		"pack_bonus": pack_bonus,
		"writing": writing,
		"industrial_toolkit": industrial_toolkit,
		"faith_combat_mom": faith_combat_mom,
		"sci_bonus_pct": sci_bonus_pct,
		"gold_bonus_pct": gold_bonus_pct,
		"faith_bonus_pct": faith_bonus_pct,
		"cul_bonus_pct": cul_bonus_pct,
		"eng_flags": eng_flags.duplicate(),
		"pro_flags": pro_flags.duplicate(),
	}

class_name AgesRules
extends RefCounted
## Facade for pure rules. UI (W2+) calls here — never owns combat math.

const CombatTables := preload("res://rules/combat_tables.gd")
const Damage := preload("res://rules/damage.gd")
const Formation := preload("res://rules/formation.gd")
const SettlementFight := preload("res://rules/settlement_fight.gd")
const AncientRun := preload("res://rules/ancient_run.gd")

const VERSION := "0.6.0-w5-canonical-ci"


static func engine_tag() -> String:
	return "ages-rules/%s" % VERSION


static func evaluate_kinds(kinds: Array, opts: Dictionary = {}) -> Dictionary:
	CombatTables.ensure_loaded()
	var tiers: Dictionary = opts.get("tiers", {"M": 1, "R": 1, "C": 1, "S": 1})
	return Damage.evaluate(kinds, tiers, opts)


static func best_formation(kinds: Array, era: int = 1, tiers: Dictionary = {}) -> Dictionary:
	CombatTables.ensure_loaded()
	var combat: Array = []
	var tier_list: Array = []
	var tmap := {"M": 1, "R": 1, "C": 1, "S": 1}
	tmap.merge(tiers, true)
	for k in kinds:
		if k in ["M", "R", "C", "S"]:
			combat.append(k)
			tier_list.append(int(tmap[k]))
	return Formation.best(combat, tier_list, CombatTables.soft_cap(era))


static func new_fight(opts: Dictionary) -> RefCounted:
	var fight = SettlementFight.new()
	fight.setup(opts)
	return fight


static func new_ancient_run(seed: int = 1) -> RefCounted:
	var run = AncientRun.new()
	run.start(seed)
	return run

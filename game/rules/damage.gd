class_name Damage
extends RefCounted
## Core Might × Momentum — main path from sim evaluate_play.

const CombatTables := preload("res://rules/combat_tables.gd")
const Formation := preload("res://rules/formation.gd")


static func evaluate(kinds: Array, tiers_by_kind: Dictionary, opts: Dictionary = {}) -> Dictionary:
	var era: int = int(opts.get("era", 1))
	var sci: int = int(opts.get("sci_level", 0))
	var form_levels: Dictionary = opts.get("form_levels", {})
	var walls: bool = bool(opts.get("walls", false)) and not bool(opts.get("walls_removed", false))
	var garrison: String = str(opts.get("garrison", "militia"))
	var ignore_walls: bool = bool(opts.get("ignore_walls", false))

	var combat_kinds: Array = []
	var tiers: Array = []
	for k in kinds:
		if k in ["M", "R", "C", "S"]:
			combat_kinds.append(k)
			tiers.append(int(tiers_by_kind.get(k, 1)))

	var soft: int = CombatTables.soft_cap(era)
	var form: Dictionary = Formation.best(combat_kinds, tiers, soft)
	var form_id: String = form["form_id"]
	var rank: int = int(form["rank"])
	var scoring: PackedInt32Array = form["scoring"]

	var base: Vector2i = CombatTables.form_base(form_id)
	var base_m := float(base.x)
	var base_o := float(base.y)
	var lv: int = int(form_levels.get(form_id, 0))
	var bonus: Vector2i = CombatTables.form_level_bonus(form_id)
	base_m += bonus.x * lv
	base_o += bonus.y * lv

	var might := base_m
	var mom := base_o

	var has_siege_played := false
	for k in combat_kinds:
		if k == "S":
			has_siege_played = true
			break

	for j in scoring.size():
		var idx: int = scoring[j]
		var kind: String = combat_kinds[idx]
		var tier: int = int(tiers[idx])
		var um := float(CombatTables.unit_might(kind, tier))
		var uo := float(CombatTables.unit_mom(kind, tier))

		if garrison == "pikemen" and kind == "C":
			um = 0.0
		if garrison == "archers" and kind == "M":
			um = um / 2.0
		if garrison == "horsemen" and kind == "R":
			uo = 0.0

		might += um
		mom += uo

	mom *= 1.0 + CombatTables.tech_literacy() * sci

	if era >= 4 and sci > 0:
		might *= 1.0 + CombatTables.age_power() * sci

	var dmg := might * mom
	if walls and not has_siege_played and not ignore_walls:
		dmg *= 0.5

	return {
		"form": form_id,
		"rank": rank,
		"might": might,
		"mom": mom,
		"damage": maxi(0, int(dmg)),
		"scoring": scoring,
	}

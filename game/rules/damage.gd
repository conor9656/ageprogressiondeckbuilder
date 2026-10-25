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
	var faith_combat_mom: int = int(opts.get("faith_combat_mom", 0))
	var card_mods: Array = opts.get("card_mods", [])
	var siege_might: float = float(opts.get("siege_might", 0))
	var next_might: float = float(opts.get("next_might", 0))
	var next_mom: float = float(opts.get("next_mom", 0))
	var next_unit_might_pct: float = float(opts.get("next_unit_might_pct", 0))
	var next_mom_mult: float = float(opts.get("next_mom_mult", 1.0))
	var merc_might: float = float(opts.get("merc_might", 0))
	var war_psalm_mom: float = float(opts.get("war_psalm_mom", 0))
	var chichen_mom: float = float(opts.get("chichen_mom", 0))
	var capital_might_bonus: float = float(opts.get("capital_might_bonus", 0))
	var zeal_might_pct: float = float(opts.get("zeal_might_pct", 0))
	var settlement_kind: String = str(opts.get("settlement_kind", "village"))
	var builder_scale: float = float(opts.get("builder_scale", 1.0))
	var policies: Array = opts.get("policies", [])

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

	var gmods: Dictionary = CombatTables.garrison_mods().get(garrison, {})
	var zero_might: Array = gmods.get("zero_might", [])
	var half_might: Array = gmods.get("half_might", [])
	var zero_mom: Array = gmods.get("zero_mom", [])

	var scored_mods: Array = []

	for j in scoring.size():
		var idx: int = scoring[j]
		var kind: String = combat_kinds[idx]
		var tier: int = int(tiers[idx])
		var mod: Dictionary = {}
		if idx < card_mods.size() and typeof(card_mods[idx]) == TYPE_DICTIONARY:
			mod = card_mods[idx]
		var um := float(CombatTables.unit_might(kind, tier)) + float(mod.get("bonus_might", 0))
		var uo := float(CombatTables.unit_mom(kind, tier)) + float(mod.get("bonus_mom", 0))
		if kind == "S":
			um += siege_might * builder_scale
		## Simple policy class bumps (common policies)
		if kind == "M" and policies.has("agoge"):
			um += 4
		if kind == "R" and policies.has("drill_manual"):
			uo += 1
		if kind == "C" and policies.has("horse_breeding"):
			um += 5
		if kind == "S" and policies.has("sappers"):
			um += 6
		um *= float(mod.get("might_mult", 1.0))

		var plated: bool = bool(mod.get("plated", false))
		if zero_might.has(kind):
			um = 0.0
		if half_might.has(kind):
			um = um / 4.0 if plated else um / 2.0
		if zero_mom.has(kind):
			uo = 0.0

		var mult := 1
		if bool(mod.get("score_twice", false)):
			mult *= 2
		might += um * mult
		mom += uo * mult
		might += float(mod.get("banner_might", 0))
		scored_mods.append(mod)

	if form_id in ["skirmish", "pair"] and policies.has("militia_act"):
		might += 8
	if form_id == "battle_line" and policies.has("line_officers"):
		might += 6
	if policies.has("research_corps"):
		might *= 1.0 + 0.05 * sci

	## Industrial Line Mom (E5+): flat + per form level on line shapes
	if era >= CombatTables.line_era_min() and CombatTables.line_era_forms().has(form_id):
		var form_lv: int = mini(lv, CombatTables.line_era_mom_form_cap())
		mom += float(CombatTables.line_era_flat_mom())
		mom += float(CombatTables.line_era_mom_per_form_lv() * form_lv)

	if faith_combat_mom > 0:
		mom += float(faith_combat_mom)
	if war_psalm_mom > 0:
		mom += war_psalm_mom
	if chichen_mom > 0:
		mom += chichen_mom

	might += next_might + merc_might
	mom += next_mom
	if next_unit_might_pct > 0.0:
		var unit_part: float = might - base_m
		might = base_m + unit_part * (1.0 + next_unit_might_pct)
	mom *= next_mom_mult

	if zeal_might_pct > 0.0:
		might *= 1.0 + zeal_might_pct
	if settlement_kind == "capital" and capital_might_bonus > 0.0:
		might *= 1.0 + capital_might_bonus

	mom *= 1.0 + CombatTables.tech_literacy() * sci

	if era >= CombatTables.age_power_era_min() and sci > 0:
		might *= 1.0 + CombatTables.age_power() * sci

	var dmg := might * mom
	if walls and not has_siege_played and not ignore_walls:
		dmg *= CombatTables.walls_damage_mult()

	return {
		"form": form_id,
		"rank": rank,
		"might": might,
		"mom": mom,
		"damage": maxi(0, int(dmg)),
		"scoring": scoring,
		"scored_mods": scored_mods,
	}

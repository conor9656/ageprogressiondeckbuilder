class_name SettlementFight
extends RefCounted
## Headless Assault / Regroup loop for one settlement.
## UI drives the same methods; AI picks plays for tests/sims.

const AgesCard := preload("res://rules/card.gd")
const AgesRules := preload("res://rules/ages_rules.gd")
const SupportCharges := preload("res://rules/support_charges.gd")
const DeckPiles := preload("res://rules/deck_piles.gd")
const CombatTables := preload("res://rules/combat_tables.gd")
const RunTables := preload("res://rules/run_tables.gd")

var piles: RefCounted
var charges: RefCounted
var rng: RandomNumberGenerator

var hand_size: int = 8
var assaults_left: int = 4
var regroups_left: int = 3
var assaults_used: int = 0

var defence: int = 0
var defence_left: int = 0
var walls: bool = false
var garrison: String = "militia"
var settlement_kind: String = "village"

var era: int = 1
var sci_level: int = 0
var tiers: Dictionary = {"M": 1, "R": 1, "C": 1, "S": 1}
var form_levels: Dictionary = {}
var policies: Array = []

## Equipped modifiers
var blueprints: Array = []
var doctrines: Array = []
var faith_combat_mom: int = 0
var ignore_walls_next: bool = false
var walls_removed: bool = false
var builder_free_slot: bool = false
var missionary_free_slot: bool = false
var builder_scale: float = 1.0
var missionary_scale: float = 1.0
var foundry_bp_mult: float = 1.0
var active_blueprint_index: int = 0
var active_doctrine_index: int = 0
var capital_might_bonus: float = 0.0
var zeal_might_pct: float = 0.0
var chichen_mom: int = 0
var eng_flags: Dictionary = {}

## Fight bursts from Blueprints / Doctrines
var next_might: int = 0
var next_mom: int = 0
var next_unit_might_pct: float = 0.0
var next_mom_mult: float = 1.0
var siege_might: int = 0
var merc_might: int = 0
var war_psalm_mom: int = 0
var spoils_mult: float = 1.0
var blueprints_fired: Dictionary = {}
var doctrines_fired: Array = []
var scored_cids: Dictionary = {}
var scored_sci_pct: float = 0.0
var scored_faith_pct: float = 0.0
var scored_gold: int = 0
var scored_faith: int = 0

var total_damage: int = 0
var log: Array = []
var won: bool = false


func setup(opts: Dictionary) -> void:
	CombatTables.ensure_loaded()
	RunTables.ensure_loaded()
	rng = RandomNumberGenerator.new()
	rng.seed = int(opts.get("seed", 1))
	piles = DeckPiles.new(rng)
	charges = SupportCharges.new()

	hand_size = int(opts.get("hand_size", 8))
	assaults_left = int(opts.get("assaults", 4))
	regroups_left = int(opts.get("regroups", 3))
	assaults_used = 0
	defence = int(opts.get("defence", 100))
	defence_left = defence
	walls = bool(opts.get("walls", false))
	garrison = str(opts.get("garrison", "militia"))
	settlement_kind = str(opts.get("kind", "village"))
	era = int(opts.get("era", 1))
	sci_level = int(opts.get("sci_level", 0))
	tiers = opts.get("tiers", {"M": 1, "R": 1, "C": 1, "S": 1})
	form_levels = opts.get("form_levels", {})
	policies = opts.get("policies", []).duplicate()
	blueprints = opts.get("blueprints", []).duplicate()
	doctrines = opts.get("doctrines", []).duplicate()
	faith_combat_mom = int(opts.get("faith_combat_mom", 0))
	builder_free_slot = bool(opts.get("builder_free_slot", false))
	missionary_free_slot = bool(opts.get("missionary_free_slot", false))
	builder_scale = float(opts.get("builder_scale", 1.0))
	missionary_scale = float(opts.get("missionary_scale", 1.0))
	foundry_bp_mult = float(opts.get("foundry_bp_mult", 1.0))
	active_blueprint_index = int(opts.get("active_blueprint_index", 0))
	active_doctrine_index = int(opts.get("active_doctrine_index", 0))
	capital_might_bonus = float(opts.get("capital_might_bonus", 0.0))
	zeal_might_pct = float(opts.get("zeal_might_pct", 0.0))
	chichen_mom = int(opts.get("chichen_mom", 0))
	eng_flags = opts.get("eng_flags", {}).duplicate()
	ignore_walls_next = false
	walls_removed = false
	next_might = 0
	next_mom = 0
	next_unit_might_pct = 0.0
	next_mom_mult = 1.0
	siege_might = 0
	merc_might = 0
	war_psalm_mom = 0
	spoils_mult = 1.0
	blueprints_fired.clear()
	doctrines_fired.clear()
	scored_cids.clear()
	scored_sci_pct = 0.0
	scored_faith_pct = 0.0
	scored_gold = 0
	scored_faith = 0
	total_damage = 0
	log.clear()
	won = false

	var deck_data: Array = opts.get("deck", _default_deck())
	var cards: Array = []
	var cid := 1
	for entry in deck_data:
		if typeof(entry) == TYPE_DICTIONARY:
			var c: RefCounted = AgesCard.from_dict(entry)
			if int(c.cid) <= 0:
				c.cid = cid
			cid = maxi(cid, int(c.cid) + 1)
			cards.append(c)
		else:
			cards.append(AgesCard.new(str(entry), cid))
			cid += 1
	piles.load_deck(cards)
	piles.refill_hand(hand_size)
	charges.refill()


func _default_deck() -> Array:
	return [
		"M", "M", "M", "M", "M", "M",
		"R", "R", "R", "R", "R",
		"C", "C", "C",
		"S", "S",
	]


func is_over() -> bool:
	return defence_left <= 0 or assaults_left <= 0


func combat_in_hand() -> Array:
	var out: Array = []
	for c in piles.hand:
		if c.is_combat():
			out.append(c)
	return out


func free_builder_slot() -> bool:
	return builder_free_slot or blueprints.has("helping_hand")


func free_missionary_slot() -> bool:
	return missionary_free_slot


func selected_blueprint() -> String:
	if blueprints.is_empty():
		return ""
	var i: int = clampi(active_blueprint_index, 0, blueprints.size() - 1)
	var bp: String = str(blueprints[i])
	if blueprints_fired.has(bp):
		var avail: Array = _unfired_blueprints()
		if avail.is_empty():
			return ""
		return str(avail[0])
	return bp


func selected_doctrine() -> String:
	if doctrines.is_empty():
		return ""
	var i: int = clampi(active_doctrine_index, 0, doctrines.size() - 1)
	var doc: String = str(doctrines[i])
	if doctrines_fired.has(doc):
		var avail: Array = _unfired_doctrines()
		if avail.is_empty():
			return ""
		return str(avail[0])
	return doc


func _unfired_blueprints() -> Array:
	var out: Array = []
	for b in blueprints:
		if not blueprints_fired.has(str(b)):
			out.append(str(b))
	return out


func _unfired_doctrines() -> Array:
	var out: Array = []
	for d in doctrines:
		if not doctrines_fired.has(str(d)):
			out.append(str(d))
	return out


func _bp_scale(name: String) -> float:
	var sc: float = builder_scale * foundry_bp_mult
	if RunTables.wall_blueprints().has(name) and bool(eng_flags.get("wall_bp_bonus", false)):
		sc *= 1.5
	if bool(eng_flags.get("bp_double", false)):
		sc *= 2.0
	return sc


func _eval_opts(play_cards: Array, use_builder: bool, use_missionary: bool, dry: bool = true) -> Dictionary:
	var kinds: Array = []
	var mods: Array = []
	for c in play_cards:
		if c.is_combat():
			kinds.append(c.kind)
			mods.append(c.to_combat_mod())
	var opts_ignore: bool = ignore_walls_next
	var walls_gone: bool = walls_removed
	var nm: int = next_might
	var no: int = next_mom
	var nup: float = next_unit_might_pct
	var nom: float = next_mom_mult
	var sm: int = siege_might
	var mm: int = merc_might
	var wp: int = war_psalm_mom
	if use_builder and not blueprints.is_empty():
		var bp: String = selected_blueprint()
		var effect: String = RunTables.catalog_effect(RunTables.blueprints(), bp)
		var sc: float = _bp_scale(bp)
		match effect:
			"ignore_walls_next":
				opts_ignore = true
			"remove_walls":
				walls_gone = true
			"siege_might":
				sm += int(10 * sc)
			"next_might10":
				nm += int(10 * sc)
			"next_mom2":
				no += int(2 * sc) + 2
			"next_unit_might_50":
				nup = maxf(nup, minf(1.0, 0.5 * sc / maxf(1.0, builder_scale)))
			"next_unit_might_25":
				nup = maxf(nup, 0.25)
			"sci_mom_scale":
				nom = maxf(nom, 1.0 + 0.1 * sci_level)
			_:
				pass
	if use_missionary and not doctrines.is_empty():
		var doc: String = selected_doctrine()
		var deffect: String = RunTables.catalog_effect(RunTables.doctrines(), doc)
		match deffect:
			"merc_might":
				## Gold not available in fight — use a modest greybox stand-in
				mm = maxi(mm, 20)
			"war_psalm":
				wp = maxi(wp, 1)
			_:
				pass
	return AgesRules.evaluate_kinds(kinds, {
		"era": era, "sci_level": sci_level, "tiers": tiers,
		"form_levels": form_levels,
		"walls": walls, "garrison": garrison,
		"walls_removed": walls_gone, "ignore_walls": opts_ignore,
		"faith_combat_mom": faith_combat_mom,
		"card_mods": mods,
		"siege_might": sm, "next_might": nm, "next_mom": no,
		"next_unit_might_pct": nup, "next_mom_mult": nom,
		"merc_might": mm, "war_psalm_mom": wp, "chichen_mom": chichen_mom,
		"capital_might_bonus": capital_might_bonus,
		"zeal_might_pct": zeal_might_pct if zeal_might_pct > 0.0 else 0.0,
		"settlement_kind": settlement_kind,
		"builder_scale": builder_scale,
		"policies": policies,
		"dry": dry,
	})


func evaluate_kinds_now(kinds: Array) -> Dictionary:
	## Back-compat for simple kind arrays (no per-card mods).
	return AgesRules.evaluate_kinds(kinds, {
		"era": era, "sci_level": sci_level, "tiers": tiers,
		"form_levels": form_levels, "walls": walls, "garrison": garrison,
		"walls_removed": walls_removed, "ignore_walls": ignore_walls_next,
		"faith_combat_mom": faith_combat_mom, "chichen_mom": chichen_mom,
		"capital_might_bonus": capital_might_bonus, "zeal_might_pct": zeal_might_pct,
		"settlement_kind": settlement_kind, "builder_scale": builder_scale,
		"siege_might": siege_might, "next_might": next_might, "next_mom": next_mom,
		"next_unit_might_pct": next_unit_might_pct, "next_mom_mult": next_mom_mult,
		"merc_might": merc_might, "war_psalm_mom": war_psalm_mom, "policies": policies,
	})


## --- Player / AI actions -----------------------------------------------------

func do_regroup(discard_cards: Array = []) -> bool:
	if regroups_left <= 0 or is_over():
		return false
	var dump: Array = []
	for c in discard_cards:
		if piles.hand.has(c) and not dump.has(c):
			dump.append(c)
	if dump.is_empty() or dump.size() > 5:
		return false
	piles.discard_from_hand(dump)
	piles.refill_hand(hand_size)
	regroups_left -= 1
	log.append({"op": "regroup", "discarded": dump.size(), "hand": piles.hand.size(), "regroups_left": regroups_left})
	return true


func choose_regroup_discard_ai(max_n: int = 3) -> Array:
	var choice: Dictionary = choose_assault_ai()
	var keep: Dictionary = {}
	for c in choice.get("cards", []):
		keep[c.get_instance_id()] = true
	var dump: Array = []
	for c in piles.hand:
		if keep.has(c.get_instance_id()):
			continue
		dump.append(c)
		if dump.size() >= max_n:
			break
	if dump.is_empty() and not piles.hand.is_empty():
		dump.append(piles.hand[piles.hand.size() - 1])
	return dump


func do_assault(play_cards: Array, use_builder: bool = false, use_missionary: bool = false) -> Dictionary:
	if assaults_left <= 0 or is_over():
		return {"ok": false}
	var combat_n := 0
	for c in play_cards:
		if c.is_combat():
			combat_n += 1
	var free_b: bool = free_builder_slot()
	var free_y: bool = free_missionary_slot()
	if not SupportCharges.attach_ok(combat_n, use_builder, use_missionary, free_b, free_y):
		use_builder = false
		use_missionary = false
		if not SupportCharges.attach_ok(combat_n, false, false, false, false):
			return {"ok": false, "reason": "bad_formation_size"}

	var fired_bp := ""
	var fired_doc := ""
	if use_builder and charges.can_use_builder() and not _unfired_blueprints().is_empty():
		charges.spend_builder()
		fired_bp = _fire_blueprint()
	elif use_builder:
		use_builder = false
	if use_missionary and charges.can_use_missionary() and not _unfired_doctrines().is_empty():
		charges.spend_missionary()
		fired_doc = _fire_doctrine()
	elif use_missionary:
		use_missionary = false

	## Bursts already applied into fight state by _fire_*
	var ev := _eval_opts(play_cards, false, false, false)
	var dmg: int = int(ev["damage"])
	defence_left -= dmg
	total_damage += dmg
	assaults_used += 1
	assaults_left -= 1

	## Accrue on-score edition/promo economy once per card per settlement
	var scoring: PackedInt32Array = ev.get("scoring", PackedInt32Array())
	var combat_play: Array = []
	for c in play_cards:
		if c.is_combat():
			combat_play.append(c)
	for j in scoring.size():
		var idx: int = scoring[j]
		if idx < 0 or idx >= combat_play.size():
			continue
		var card = combat_play[idx]
		var id: int = int(card.cid)
		if scored_cids.has(id):
			continue
		scored_cids[id] = true
		scored_sci_pct += float(card.on_score_sci_pct)
		scored_faith_pct += float(card.on_score_faith_pct)
		scored_gold += int(card.on_score_gold)
		scored_faith += int(card.on_score_faith)

	## Consume one-shot bursts
	ignore_walls_next = false
	next_might = 0
	next_mom = 0
	next_unit_might_pct = 0.0
	next_mom_mult = 1.0

	piles.discard_from_hand(play_cards)
	piles.refill_hand(hand_size)

	var entry := {
		"op": "assault",
		"form": ev["form"],
		"rank": ev["rank"],
		"dmg": dmg,
		"left": maxi(0, defence_left),
		"assaults_left": assaults_left,
		"used_builder": use_builder,
		"used_missionary": use_missionary,
		"blueprint": fired_bp,
		"doctrine": fired_doc,
		"builder_scale": builder_scale,
	}
	log.append(entry)
	if defence_left <= 0:
		won = true
	return {"ok": true, "eval": ev, "entry": entry}


func _fire_blueprint() -> String:
	var bp: String = selected_blueprint()
	if bp == "" or blueprints_fired.has(bp):
		return ""
	blueprints_fired[bp] = true
	var effect: String = RunTables.catalog_effect(RunTables.blueprints(), bp)
	var sc: float = _bp_scale(bp)
	match effect:
		"siege_might":
			siege_might += int(10 * sc)
		"ignore_walls_next":
			ignore_walls_next = true
		"remove_walls":
			walls_removed = true
		"next_might10":
			next_might += int(10 * sc)
		"next_mom2":
			next_mom += int(2 * sc) + 2
		"next_unit_might_50":
			next_unit_might_pct = maxf(next_unit_might_pct, minf(1.0, 0.5 * sc / maxf(1.0, builder_scale)))
		"next_unit_might_25":
			next_unit_might_pct = maxf(next_unit_might_pct, 0.25)
		"plus_regroup":
			regroups_left += 1
		"plus_assault":
			assaults_left += 1
		"draw2":
			piles.refill_hand(hand_size + 2)
		"sci_mom_scale":
			next_mom_mult = maxf(next_mom_mult, 1.0 + 0.1 * sci_level)
		"helping_hand":
			builder_free_slot = true
		_:
			pass
	log.append({"op": "blueprint", "name": bp, "effect": effect, "scale": sc})
	return bp


func _fire_doctrine() -> String:
	var doc: String = selected_doctrine()
	if doc == "" or doctrines_fired.has(doc):
		return ""
	doctrines_fired.append(doc)
	var effect: String = RunTables.catalog_effect(RunTables.doctrines(), doc)
	match effect:
		"merc_might":
			merc_might = maxi(merc_might, 20)
		"war_psalm":
			war_psalm_mom = maxi(war_psalm_mom, 1)
		"spoils_x15":
			spoils_mult = maxf(spoils_mult, 1.5)
		_:
			pass
	log.append({"op": "doctrine_armed", "name": doc, "effect": effect})
	return doc


func choose_assault_ai() -> Dictionary:
	var combat := combat_in_hand()
	if combat.is_empty():
		return {"cards": [], "use_builder": false, "use_missionary": false, "ev": {"damage": 0}}

	var best_dmg := -1
	var best_cards: Array = []
	var best_b := false
	var best_y := false
	var n := combat.size()
	var limit := mini(5, n)
	var idxs: Array = []
	for i in n:
		idxs.append(i)

	for k in range(1, limit + 1):
		for comb in _combinations(idxs, k):
			var cards: Array = []
			for i in comb:
				cards.append(combat[i])
			var free_b: bool = free_builder_slot()
			var free_y: bool = free_missionary_slot()
			for use_b_i in 2:
				var use_b: bool = use_b_i == 1
				if use_b and (not charges.can_use_builder() or _unfired_blueprints().is_empty()):
					continue
				for use_y_i in 2:
					var use_y: bool = use_y_i == 1
					if use_y and (not charges.can_use_missionary() or _unfired_doctrines().is_empty()):
						continue
					if not SupportCharges.attach_ok(k, use_b, use_y, free_b, free_y):
						continue
					## Temporarily set indices to first unfired
					var old_b: int = active_blueprint_index
					var old_d: int = active_doctrine_index
					active_blueprint_index = 0
					active_doctrine_index = 0
					var ev: Dictionary = _eval_opts(cards, use_b, use_y, true)
					active_blueprint_index = old_b
					active_doctrine_index = old_d
					var score: int = int(ev["damage"])
					if use_b:
						score += 1
					if use_y:
						score += 1
					if score > best_dmg:
						best_dmg = score
						best_cards = cards
						best_b = use_b
						best_y = use_y

	return {
		"cards": best_cards,
		"use_builder": best_b,
		"use_missionary": best_y,
		"ev": {"damage": best_dmg},
	}


func should_regroup_ai() -> bool:
	if regroups_left <= 0 or assaults_left <= 0:
		return false
	var choice := choose_assault_ai()
	var dmg: int = int(choice["ev"].get("damage", 0))
	var needed := float(defence_left) / float(maxi(1, assaults_left))
	return dmg < needed * 0.45


func run_auto() -> Dictionary:
	while not is_over():
		if should_regroup_ai():
			do_regroup(choose_regroup_discard_ai())
			continue
		var choice := choose_assault_ai()
		if choice["cards"].is_empty():
			break
		do_assault(choice["cards"], choice["use_builder"], choice["use_missionary"])
	won = defence_left <= 0
	return result()


func result() -> Dictionary:
	return {
		"won": won,
		"damage": total_damage,
		"assaults_used": assaults_used,
		"defence": defence,
		"defence_left": maxi(0, defence_left),
		"scored_sci_pct": scored_sci_pct,
		"scored_faith_pct": scored_faith_pct,
		"scored_gold": scored_gold,
		"scored_faith": scored_faith,
		"doctrines_fired": doctrines_fired.duplicate(),
		"spoils_mult": spoils_mult,
		"log": log.duplicate(true),
	}


static func _combinations(items: Array, k: int) -> Array:
	var out: Array = []
	_comb_rec(items, k, 0, [], out)
	return out


static func _comb_rec(items: Array, k: int, start: int, path: Array, out: Array) -> void:
	if path.size() == k:
		out.append(path.duplicate())
		return
	for i in range(start, items.size()):
		path.append(items[i])
		_comb_rec(items, k, i + 1, path, out)
		path.pop_back()

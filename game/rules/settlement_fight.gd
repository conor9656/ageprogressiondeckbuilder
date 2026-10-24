class_name SettlementFight
extends RefCounted
## Headless Assault / Regroup loop for one settlement.
## UI (W2) will drive the same methods; AI picks plays for tests/sims.

const AgesCard := preload("res://rules/card.gd")
const AgesRules := preload("res://rules/ages_rules.gd")
const SupportCharges := preload("res://rules/support_charges.gd")
const DeckPiles := preload("res://rules/deck_piles.gd")
const CombatTables := preload("res://rules/combat_tables.gd")

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

## Equipped modifiers (minimal for W1)
var blueprints: Array = []  ## e.g. ["scaffolding"]
var doctrines: Array = []
var faith_combat_mom: int = 0  ## Industrial Revival Tent, etc.
var ignore_walls_next: bool = false
var walls_removed: bool = false

var total_damage: int = 0
var log: Array = []  ## [{op, form, dmg, left, ...}]
var won: bool = false


func setup(opts: Dictionary) -> void:
	CombatTables.ensure_loaded()
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
	blueprints = opts.get("blueprints", [])
	doctrines = opts.get("doctrines", [])
	faith_combat_mom = int(opts.get("faith_combat_mom", 0))
	ignore_walls_next = false
	walls_removed = false
	total_damage = 0
	log.clear()
	won = false

	var deck_kinds: Array = opts.get("deck", _default_deck())
	var cards: Array = []
	var cid := 1
	for k in deck_kinds:
		cards.append(AgesCard.new(str(k), cid))
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


func evaluate_kinds_now(kinds: Array) -> Dictionary:
	return AgesRules.evaluate_kinds(kinds, {
		"era": era,
		"sci_level": sci_level,
		"tiers": tiers,
		"form_levels": form_levels,
		"walls": walls,
		"garrison": garrison,
		"walls_removed": walls_removed,
		"ignore_walls": ignore_walls_next,
		"faith_combat_mom": faith_combat_mom,
	})


## --- Player / AI actions -----------------------------------------------------

func do_regroup(discard_cards: Array = []) -> bool:
	## Discard only the given cards (1–5), keep the rest, then redraw to hand_size.
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
	## Drop cards that aren't in the best Assault pick (up to max_n).
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
	var free_b: bool = blueprints.has("helping_hand")
	if not SupportCharges.attach_ok(combat_n, use_builder, use_missionary, free_b, false):
		use_builder = false
		use_missionary = false
		if not SupportCharges.attach_ok(combat_n, false, false, false, false):
			return {"ok": false, "reason": "bad_formation_size"}

	var kinds: Array = []
	for c in play_cards:
		if c.is_combat():
			kinds.append(c.kind)

	# Spend support charges + fire simple BP/Doc
	if use_builder and charges.can_use_builder():
		charges.spend_builder()
		_fire_blueprint()
	if use_missionary and charges.can_use_missionary():
		charges.spend_missionary()
		# Doctrine pays on win — recorded only
		log.append({"op": "doctrine_armed", "doctrines": doctrines.duplicate()})

	var ev := evaluate_kinds_now(kinds)
	var dmg: int = int(ev["damage"])
	defence_left -= dmg
	total_damage += dmg
	assaults_used += 1
	assaults_left -= 1

	# Consume one-shot wall ignore after scoring
	if ignore_walls_next:
		ignore_walls_next = false

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
	}
	log.append(entry)
	if defence_left <= 0:
		won = true
	return {"ok": true, "eval": ev, "entry": entry}


func _fire_blueprint() -> void:
	## Minimal W1: scaffolding / battering_ram style wall help.
	if blueprints.is_empty():
		return
	var bp: String = str(blueprints[0])
	if bp in ["scaffolding", "ignore_walls_next"]:
		ignore_walls_next = true
		log.append({"op": "blueprint", "name": bp, "effect": "ignore_walls_next"})
	elif bp in ["siege_tower", "remove_walls"]:
		walls_removed = true
		log.append({"op": "blueprint", "name": bp, "effect": "remove_walls"})
	else:
		log.append({"op": "blueprint", "name": bp, "effect": "noop"})


func choose_assault_ai() -> Dictionary:
	## Greedy: best combat subset size 1..5 by damage; attach Builder if BP + charge + helps walls.
	var combat := combat_in_hand()
	if combat.is_empty():
		return {"cards": [], "use_builder": false, "use_missionary": false, "ev": {"damage": 0}}

	var best_dmg := -1
	var best_cards: Array = []
	var best_b := false
	var n := combat.size()
	var limit := mini(5, n)
	# Cap enumeration
	var idxs: Array = []
	for i in n:
		idxs.append(i)

	for k in range(1, limit + 1):
		for comb in _combinations(idxs, k):
			var cards: Array = []
			var kinds: Array = []
			for i in comb:
				cards.append(combat[i])
				kinds.append(combat[i].kind)
			var free_b: bool = blueprints.has("helping_hand")
			for use_b_i in 2:
				var use_b: bool = use_b_i == 1
				if use_b and (not charges.can_use_builder() or blueprints.is_empty()):
					continue
				if not SupportCharges.attach_ok(k, use_b, false, free_b, false):
					continue
				var bp0: String = ""
				if use_b and not blueprints.is_empty():
					bp0 = str(blueprints[0])
				var opts_ignore: bool = ignore_walls_next
				if bp0 == "scaffolding" or bp0 == "ignore_walls_next":
					opts_ignore = true
				var walls_gone: bool = walls_removed
				if bp0 == "siege_tower" or bp0 == "remove_walls":
					walls_gone = true
				var ev: Dictionary = AgesRules.evaluate_kinds(kinds, {
					"era": era, "sci_level": sci_level, "tiers": tiers,
					"form_levels": form_levels,
					"walls": walls, "garrison": garrison,
					"walls_removed": walls_gone,
					"ignore_walls": opts_ignore,
					"faith_combat_mom": faith_combat_mom,
				})
				var score: int = int(ev["damage"])
				if use_b:
					score += 1
				if score > best_dmg:
					best_dmg = score
					best_cards = cards
					best_b = use_b

	return {"cards": best_cards, "use_builder": best_b, "use_missionary": false, "ev": {"damage": best_dmg}}


func should_regroup_ai() -> bool:
	if regroups_left <= 0 or assaults_left <= 0:
		return false
	var choice := choose_assault_ai()
	var dmg: int = int(choice["ev"].get("damage", 0))
	var needed := float(defence_left) / float(maxi(1, assaults_left))
	return dmg < needed * 0.45


func run_auto() -> Dictionary:
	## Play until win or out of Assaults (AI).
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

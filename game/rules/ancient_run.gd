extends RefCounted
## Ancient era run orchestrator — settlements, rewards, Sci/Civ picks, shop.
## UI drives player choices; `run_auto_era` plays a full era for tests.

const CombatTables := preload("res://rules/combat_tables.gd")
const AgesRules := preload("res://rules/ages_rules.gd")
const RunState := preload("res://rules/run_state.gd")
const SupportCharges := preload("res://rules/support_charges.gd")

const REWARD_GOLD := 38
const REWARD_SCIENCE := 16
const REWARD_CULTURE := 16
const REWARD_FAITH := 12
const RAZE_GOLD := 28
const CITY_YIELD := 7
const PACK_SIZE := 5
const SCIENCE_OFFER_COUNT := 4
const CIVIC_OFFER_COUNT := 3

const SCIENCE_COSTS: Array = [
	8, 12, 16, 22, 28, 36, 46, 58, 72, 88, 106, 126, 148, 172, 198,
]

const ERA_BASE := 665

## E1 drills + progression node ids
const E1_DRILLS: Array = [
	"battle_line_drill", "skirmish_drill", "combined_arms_primer", "writing", "surveying",
]

const E1_PROG: Array = [
	["edu_scribal_schools", "sci_pct", 0.10],
	["bank_markets", "gold_pct", 0.08],
	["dev_shrines", "faith_pct", 0.08],
	["art_festivals", "cul_pct", 0.08],
	["eng_apprenticeship", "eng", "draw_on_builder"],
	["pro_alms", "pro", "faith_on_missionary"],
]

## id, rarity weight proxy, family, once
const E1_CIVICS: Array = [
	["code_of_laws", "C", "slot", true],
	["craftsmanship", "C", "draft", false],
	["early_empire", "C", "slot", true],
	["theology", "C", "slot", true],
	["military_training", "C", "qol", true],
	["literacy", "U", "draft", false],
	["treasury_windfall", "U", "econ", true],
	["stall_permits", "C", "shop", true],
	["fairground_toll", "C", "shop", true],
	["corvee_exemption", "C", "works", true],
	["lay_preachers", "C", "ministry", true],
]

const BLUEPRINTS: Dictionary = {
	"battering_ram": ["C", 10],
	"scaffolding": ["C", 10],
	"supply_lines": ["C", 10],
	"watchtower": ["C", 10],
	"forge": ["U", 22],
	"siege_tower": ["U", 22],
	"roads": ["U", 22],
	"magazine": ["U", 22],
	"aqueduct": ["R", 45],
	"arsenal": ["R", 45],
}

const DOCTRINES: Dictionary = {
	"tithe": ["C", 8],
	"scriptorium": ["C", 8],
	"pilgrimage": ["C", 8],
	"alms": ["C", 8],
	"zeal": ["U", 18],
	"relic_hunt": ["U", 18],
	"crusade": ["U", 18],
	"scholastic_order": ["U", 18],
	"missionary_zeal": ["R", 35],
	"mercenaries": ["R", 35],
}

const PROMOTIONS: Dictionary = {
	"master_drill": ["C", 12],
	"skirmish_doctrine": ["C", 12],
	"shock_drill": ["U", 20],
	"banner_carrier": ["U", 22],
	"thinking_soldier": ["U", 20],
	"heroic": ["R", 40],
}

const POLICY_COMMONS: Array = [
	"agoge", "drill_manual", "horse_breeding", "sappers",
	"militia_act", "line_officers", "research_corps",
]

var state: RefCounted
var current_settlement: Dictionary = {}
var active_fight: RefCounted
var last_reward: Dictionary = {}
var shop_treasury: Array = []
var shop_synod: Array = []
var shop_rerolled: bool = false
## Pending level-up: {"kind": "science"|"civic", "cost": int, "offers": Array}
var pending_levelup: Dictionary = {}


func start(seed: int = 1) -> void:
	CombatTables.ensure_loaded()
	state = RunState.new()
	state.setup(seed)
	current_settlement = {}
	active_fight = null
	last_reward.clear()
	shop_treasury.clear()
	shop_synod.clear()
	shop_rerolled = false
	pending_levelup.clear()
	_make_next_settlement()


func _make_next_settlement() -> void:
	var kind: String = state.current_kind()
	if kind == "":
		return
	current_settlement = make_settlement(kind, state.rng, state.era)
	state.log.append({"op": "settlement", "kind": kind, "defence": current_settlement["defence"]})


static func make_settlement(kind: String, rng: RandomNumberGenerator, era: int = 1) -> Dictionary:
	CombatTables.ensure_loaded()
	var base: int = CombatTables.era_base_defence(era)
	if base <= 0:
		base = ERA_BASE
	var mult := {"village": 1.0, "town": 1.5, "capital": 2.5}
	var defence: int = int(base * float(mult.get(kind, 1.0)))
	var walls := false
	var garrison := "militia"
	if kind == "town":
		walls = rng.randf() < 0.50
		garrison = ["pikemen", "archers", "horsemen", "militia"][rng.randi() % 4]
	elif kind == "capital":
		walls = rng.randf() < 0.80
		garrison = ["pikemen", "archers", "horsemen"][rng.randi() % 3]
	var city_type: String = ["scholar", "artisan", "temple", "trade"][rng.randi() % 4]
	return {
		"kind": kind,
		"era": era,
		"defence": defence,
		"walls": walls,
		"garrison": garrison,
		"city_type": city_type,
	}


func begin_fight() -> RefCounted:
	active_fight = AgesRules.new_fight({
		"seed": state.rng.randi(),
		"defence": int(current_settlement["defence"]),
		"kind": str(current_settlement["kind"]),
		"walls": bool(current_settlement["walls"]),
		"garrison": str(current_settlement["garrison"]),
		"era": state.era,
		"sci_level": state.sci_level,
		"tiers": state.tiers.duplicate(),
		"form_levels": state.form_levels.duplicate(),
		"assaults": state.base_assaults,
		"regroups": state.base_regroups,
		"hand_size": state.hand_size,
		"deck": state.deck_kinds.duplicate(),
		"blueprints": state.blueprints.duplicate(),
		"doctrines": state.doctrines.duplicate(),
	})
	# Sync charge max from run
	active_fight.charges.builder_max = state.builder_charges_max
	active_fight.charges.missionary_max = state.missionary_charges_max
	active_fight.charges.refill()
	return active_fight


## --- Victory rewards ---------------------------------------------------------

func compute_base_rewards(assaults_used: int) -> Dictionary:
	var unused: int = maxi(0, state.base_assaults - assaults_used)
	var gold_m: float = state.income_mult("gold")
	var sci_m: float = state.income_mult("sci")
	var cul_m: float = state.income_mult("cul")
	var faith_m: float = state.income_mult("faith")
	var g: int = int((REWARD_GOLD + unused) * (1.0 + state.gold_bonus_pct) * gold_m)
	var s: int = int(REWARD_SCIENCE * (1.0 + state.sci_bonus_pct) * sci_m)
	var c: int = int(REWARD_CULTURE * (1.0 + state.cul_bonus_pct) * cul_m)
	var f: int = int(REWARD_FAITH * (1.0 + state.faith_bonus_pct) * faith_m)
	return {"gold": g, "science": s, "culture": c, "faith": f, "unused_assaults": unused}


func apply_victory_payout(assaults_used: int, choice: String) -> Dictionary:
	## choice: "raze" | "occupy". Applies base rewards + raze/occupy + interest + city yields.
	var base: Dictionary = compute_base_rewards(assaults_used)
	state.gold += int(base["gold"])
	state.science += int(base["science"])
	state.culture += int(base["culture"])
	state.faith += int(base["faith"])

	var occupied_type := ""
	var raze_gold := 0
	if choice == "raze":
		raze_gold = int(RAZE_GOLD * (1.0 + state.gold_bonus_pct))
		state.gold += raze_gold
	else:
		occupied_type = str(current_settlement.get("city_type", "trade"))
		state.occupied.append(occupied_type)

	var interest_gain: int = int(mini(state.interest_cap, state.gold / 5) * (1.0 + state.gold_bonus_pct))
	state.gold += interest_gain

	var yields: Dictionary = _apply_city_yields()

	last_reward = {
		"base": base,
		"choice": choice,
		"occupied_type": occupied_type,
		"raze_gold": raze_gold,
		"interest": interest_gain,
		"yields": yields,
		"banks": state.snapshot(),
	}
	state.log.append({"op": "victory", "reward": last_reward.duplicate(true)})
	return last_reward


func _apply_city_yields() -> Dictionary:
	var out := {"gold": 0, "science": 0, "culture": 0, "faith": 0}
	for t in state.occupied:
		var amt: int = int(CITY_YIELD)
		match str(t):
			"scholar":
				amt = int(CITY_YIELD * (1.0 + state.sci_bonus_pct) * state.income_mult("sci"))
				state.science += amt
				out["science"] += amt
			"artisan":
				amt = int(CITY_YIELD * (1.0 + state.cul_bonus_pct) * state.income_mult("cul"))
				state.culture += amt
				out["culture"] += amt
			"temple":
				amt = int(CITY_YIELD * (1.0 + state.faith_bonus_pct) * state.income_mult("faith"))
				state.faith += amt
				out["faith"] += amt
			"trade":
				amt = int(CITY_YIELD * (1.0 + state.gold_bonus_pct) * state.income_mult("gold"))
				state.gold += amt
				out["gold"] += amt
	return out


## --- Level-ups ---------------------------------------------------------------

func science_cost() -> int:
	if state.sci_level >= SCIENCE_COSTS.size():
		return 99999
	return maxi(1, int(SCIENCE_COSTS[state.sci_level]))


func civic_cost() -> int:
	if state.civ_level >= SCIENCE_COSTS.size():
		return 99999
	return maxi(1, int(SCIENCE_COSTS[state.civ_level]))


func can_afford_science() -> bool:
	return state.science >= science_cost() and state.sci_level < SCIENCE_COSTS.size()


func can_afford_civic() -> bool:
	return state.culture >= civic_cost() and state.civ_level < SCIENCE_COSTS.size()


func begin_science_levelup() -> Dictionary:
	if not can_afford_science():
		pending_levelup.clear()
		return {}
	var cost: int = science_cost()
	state.science -= cost
	var offers: Array = roll_science_offers()
	pending_levelup = {"kind": "science", "cost": cost, "offers": offers}
	return pending_levelup


func begin_civic_levelup() -> Dictionary:
	if not can_afford_civic():
		pending_levelup.clear()
		return {}
	var cost: int = civic_cost()
	state.culture -= cost
	var offers: Array = roll_civic_offers()
	pending_levelup = {"kind": "civic", "cost": cost, "offers": offers}
	return pending_levelup


func pick_levelup(offer_id: String) -> bool:
	if pending_levelup.is_empty():
		return false
	var offers: Array = pending_levelup.get("offers", [])
	if not offers.has(offer_id):
		return false
	var kind: String = str(pending_levelup["kind"])
	if kind == "science":
		apply_science(offer_id)
		state.sci_level += 1
		state.log.append({"op": "science_pick", "pick": offer_id, "offers": offers})
	else:
		apply_civic(offer_id)
		state.civ_level += 1
		state.log.append({"op": "civic_pick", "pick": offer_id, "offers": offers})
	pending_levelup.clear()
	return true


func roll_science_offers() -> Array:
	var t_count: int = 1 if state.rng.randf() < 0.55 else 2
	var troops: Array = _weighted_troop_offers(t_count)
	var pool: Array = []
	for d in E1_DRILLS:
		pool.append(d)
	for row in E1_PROG:
		var nid: String = str(row[0])
		if not state.owned_prog.has(nid):
			pool.append(nid)
	if _can_upgrade_support("B") and state.rng.randf() < 0.40:
		pool.append("support_charge_B")
	if _can_upgrade_support("Y") and state.rng.randf() < 0.40:
		pool.append("support_charge_Y")
	_shuffle(pool)
	var non: Array = []
	while troops.size() + non.size() < SCIENCE_OFFER_COUNT and not pool.is_empty():
		var n: String = str(pool.pop_back())
		if not non.has(n) and not troops.has(n):
			non.append(n)
	## Unique fillers only — never pad with duplicates
	var fillers: Array = [
		"battle_line_drill", "skirmish_drill", "combined_arms_primer",
		"writing", "surveying", "edu_scribal_schools", "bank_markets",
	]
	for f in fillers:
		if troops.size() + non.size() >= SCIENCE_OFFER_COUNT:
			break
		if not non.has(f) and not troops.has(f):
			non.append(f)
	var out: Array = troops + non
	return out.slice(0, mini(SCIENCE_OFFER_COUNT, out.size()))


func _weighted_troop_offers(n: int) -> Array:
	var soft: int = state.soft_cap()
	var weights: Array = []  ## [key, w]
	for key in ["M", "R", "C", "S", "B"]:
		var cur: int = int(state.tiers.get(key, 1))
		var hard: int = 4 if key == "B" else 6
		if cur >= hard:
			continue
		var soft_use: int = 2 if key == "B" else soft
		var gap: int = soft_use - cur
		var w: float = 0.0
		if gap >= 1:
			w = 10.0
		elif gap == 0 and cur + 1 <= mini(hard, soft_use + 1):
			w = 1.0
		else:
			continue
		if state.last_troop_upgrade == key:
			w *= 0.35
		weights.append([key, w])
	var picks: Array = []
	for _i in n:
		if weights.is_empty():
			break
		var total: float = 0.0
		for row in weights:
			total += float(row[1])
		var r: float = state.rng.randf() * total
		var acc: float = 0.0
		var chosen: String = str(weights[0][0])
		var chosen_i := 0
		for i in weights.size():
			acc += float(weights[i][1])
			if r <= acc:
				chosen = str(weights[i][0])
				chosen_i = i
				break
		picks.append("upgrade_%s" % chosen)
		weights.remove_at(chosen_i)
	return picks


func _can_upgrade_support(kind: String) -> bool:
	var cur: int = state.builder_charges_max if kind == "B" else state.missionary_charges_max
	if cur >= CombatTables.support_charge_cap():
		return false
	return state.sci_level >= 2 * cur


func apply_science(pick: String) -> void:
	if pick.begins_with("upgrade_"):
		var key: String = pick.get_slice("_", 1)
		var cap: int = 4 if key == "B" else 6
		state.tiers[key] = mini(cap, int(state.tiers.get(key, 1)) + 1)
		state.last_troop_upgrade = key
		return
	if pick == "support_charge_B":
		state.builder_charges_max = mini(CombatTables.support_charge_cap(), state.builder_charges_max + 1)
		return
	if pick == "support_charge_Y":
		state.missionary_charges_max = mini(CombatTables.support_charge_cap(), state.missionary_charges_max + 1)
		return
	for row in E1_PROG:
		if pick != str(row[0]):
			continue
		state.owned_prog[pick] = true
		var kind: String = str(row[1])
		var val = row[2]
		match kind:
			"sci_pct":
				state.sci_bonus_pct += float(val)
			"gold_pct":
				state.gold_bonus_pct += float(val)
			"faith_pct":
				state.faith_bonus_pct += float(val)
			"cul_pct":
				state.cul_bonus_pct += float(val)
			"eng":
				state.eng_flags[str(val)] = true
			"pro":
				state.pro_flags[str(val)] = true
		return
	match pick:
		"battle_line_drill":
			state.form_levels["battle_line"] = int(state.form_levels.get("battle_line", 0)) + 1
		"skirmish_drill":
			state.form_levels["skirmish"] = int(state.form_levels.get("skirmish", 0)) + 1
			state.form_levels["pair"] = int(state.form_levels.get("pair", 0)) + 1
		"combined_arms_primer":
			state.form_levels["combined_arms"] = int(state.form_levels.get("combined_arms", 0)) + 1
		"writing":
			state.writing = true
		"surveying":
			state.base_regroups += 1


func roll_civic_offers() -> Array:
	var candidates: Array = []
	var weights: Array = []
	for row in E1_CIVICS:
		var cid: String = str(row[0])
		var rarity: String = str(row[1])
		var once: bool = bool(row[3])
		if once and state.owned_civics.has(cid):
			continue
		if not _civic_legal(cid):
			continue
		var w: float = {"C": 10.0, "U": 4.0, "R": 1.0}.get(rarity, 1.0)
		candidates.append(cid)
		weights.append(w)
	if candidates.is_empty():
		return ["craftsmanship", "military_training", "fairground_toll"]
	var offers: Array = []
	while offers.size() < CIVIC_OFFER_COUNT and not candidates.is_empty():
		var total: float = 0.0
		for w in weights:
			total += float(w)
		var r: float = state.rng.randf() * total
		var acc: float = 0.0
		var chosen_i := 0
		for i in candidates.size():
			acc += float(weights[i])
			if r <= acc:
				chosen_i = i
				break
		var cid2: String = str(candidates[chosen_i])
		candidates.remove_at(chosen_i)
		weights.remove_at(chosen_i)
		if not offers.has(cid2):
			offers.append(cid2)
	while offers.size() < CIVIC_OFFER_COUNT:
		offers.append("craftsmanship")
	return offers


func _civic_legal(cid: String) -> bool:
	if cid == "code_of_laws" and state.policy_slots >= 5:
		return false
	if cid == "early_empire" and state.blueprint_slots >= 5:
		return false
	if cid == "theology" and state.doctrine_slots >= 4:
		return false
	return true


func apply_civic(pick: String) -> void:
	for row in E1_CIVICS:
		if str(row[0]) == pick and bool(row[3]):
			state.owned_civics[pick] = true
			break
	match pick:
		"code_of_laws":
			state.policy_slots = mini(5, state.policy_slots + 1)
		"early_empire":
			state.blueprint_slots = mini(5, state.blueprint_slots + 1)
		"theology":
			state.doctrine_slots = mini(4, state.doctrine_slots + 1)
		"military_training":
			state.base_regroups += 1
		"craftsmanship", "literacy":
			_draft_policy()
		"stall_permits":
			state.pack_bonus = mini(2, state.pack_bonus + 1)
		"fairground_toll":
			state.unit_cost_flat = maxi(state.unit_cost_flat, 2)
		"corvee_exemption":
			state.eng_flags["builder_free_slot"] = true
		"lay_preachers":
			state.pro_flags["missionary_free_slot"] = true
		"treasury_windfall":
			state.gold += int(22 * (1.0 + state.gold_bonus_pct))


func _draft_policy() -> void:
	if state.policies.size() >= state.policy_slots:
		return
	var pool: Array = []
	for p in POLICY_COMMONS:
		if not state.policies.has(p):
			pool.append(p)
	if pool.is_empty():
		return
	state.policies.append(str(pool[state.rng.randi() % pool.size()]))


## --- Shop --------------------------------------------------------------------

func open_shop() -> Dictionary:
	shop_rerolled = false
	var n: int = PACK_SIZE + state.pack_bonus
	shop_treasury = _roll_unique_pack(n, true)
	shop_synod = _roll_unique_pack(n, false)
	return {"treasury": shop_treasury.duplicate(true), "synod": shop_synod.duplicate(true)}


func reroll_treasury() -> bool:
	if shop_rerolled or state.gold < state.reroll_cost:
		return false
	state.gold -= state.reroll_cost
	shop_rerolled = true
	var n: int = PACK_SIZE + state.pack_bonus
	shop_treasury = _roll_unique_pack(n, true)
	return true


func _offer_key(offer: Dictionary) -> String:
	return "%s:%s" % [str(offer.get("cat", "")), str(offer.get("id", ""))]


func _roll_unique_pack(n: int, treasury: bool) -> Array:
	## No duplicate cat+id within a pack (e.g. two scaffolding, two sow_dissent).
	var out: Array = []
	var seen: Dictionary = {}
	var attempts := 0
	var max_attempts: int = n * 24
	while out.size() < n and attempts < max_attempts:
		attempts += 1
		var offer: Dictionary = roll_treasury_offer(seen) if treasury else roll_synod_offer(seen)
		var key: String = _offer_key(offer)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(offer)
	## Absolute fallback: pad with unused unit kinds / generic units
	while out.size() < n:
		var filled := false
		for kind in ["M", "R", "C", "S"]:
			var key2 := "unit:%s" % kind
			if seen.has(key2):
				continue
			var cost: int = {1: 8, 2: 12, 3: 18, 4: 28}.get(int(state.tiers.get(kind, 1)), 8)
			cost = maxi(1, cost - state.unit_cost_flat)
			var o := {"cat": "unit", "id": kind, "cost": cost, "label": "Unit %s" % kind}
			seen[key2] = true
			out.append(o)
			filled = true
			break
		if not filled:
			break
	return out


func roll_treasury_offer(exclude: Dictionary = {}) -> Dictionary:
	## exclude: set of "cat:id" keys already in the pack.
	for _try in 16:
		var r: float = state.rng.randf()
		var offer: Dictionary
		if r < 0.36:
			var kind: String = ["M", "R", "C", "S"][state.rng.randi() % 4]
			var cost: int = {1: 8, 2: 12, 3: 18, 4: 28}.get(int(state.tiers.get(kind, 1)), 8)
			cost = maxi(1, cost - state.unit_cost_flat)
			offer = {"cat": "unit", "id": kind, "cost": cost, "label": "Unit %s" % kind}
		elif r < 0.64:
			var name: String = _weighted_from(BLUEPRINTS, exclude, "blueprint")
			if name == "":
				continue
			offer = {"cat": "blueprint", "id": name, "cost": int(BLUEPRINTS[name][1]), "label": "BP %s" % name}
		elif r < 0.92:
			var pname: String = _weighted_from(PROMOTIONS, exclude, "promotion")
			if pname == "":
				continue
			offer = {"cat": "promotion", "id": pname, "cost": int(PROMOTIONS[pname][1]), "label": "Promo %s" % pname}
		else:
			var kind2: String = ["M", "R", "C", "S"][state.rng.randi() % 4]
			offer = {"cat": "unit", "id": kind2, "cost": maxi(1, 8 - state.unit_cost_flat), "label": "Unit %s" % kind2}
		if not exclude.has(_offer_key(offer)):
			return offer
	## Last resort unit not yet seen
	for kind3 in ["M", "R", "C", "S"]:
		var key := "unit:%s" % kind3
		if exclude.has(key):
			continue
		return {"cat": "unit", "id": kind3, "cost": maxi(1, 8 - state.unit_cost_flat), "label": "Unit %s" % kind3}
	return {"cat": "unit", "id": "M", "cost": 8, "label": "Unit M"}


func roll_synod_offer(exclude: Dictionary = {}) -> Dictionary:
	for _try in 16:
		var offer: Dictionary
		if state.rng.randf() < 0.55:
			var name: String = _weighted_from(DOCTRINES, exclude, "doctrine")
			if name == "":
				offer = {"cat": "prophet", "id": "sow_dissent", "cost": 15, "label": "Prophet sow_dissent"}
			else:
				offer = {"cat": "doctrine", "id": name, "cost": int(DOCTRINES[name][1]), "label": "Doc %s" % name}
		else:
			offer = {"cat": "prophet", "id": "sow_dissent", "cost": 15, "label": "Prophet sow_dissent"}
		if not exclude.has(_offer_key(offer)):
			return offer
	## Prefer any unused doctrine, then a unit-like faith stub
	var doc: String = _weighted_from(DOCTRINES, exclude, "doctrine")
	if doc != "":
		return {"cat": "doctrine", "id": doc, "cost": int(DOCTRINES[doc][1]), "label": "Doc %s" % doc}
	if not exclude.has("prophet:sow_dissent"):
		return {"cat": "prophet", "id": "sow_dissent", "cost": 15, "label": "Prophet sow_dissent"}
	## Extra prophet variants so Synod can still fill uniquely if needed
	for alt in ["tithe_collector", "street_preacher", "relic_broker"]:
		var key := "prophet:%s" % alt
		if exclude.has(key):
			continue
		return {"cat": "prophet", "id": alt, "cost": 15, "label": "Prophet %s" % alt}
	return {"cat": "prophet", "id": "sow_dissent", "cost": 15, "label": "Prophet sow_dissent"}


func _weighted_from(table: Dictionary, exclude: Dictionary, cat: String) -> String:
	var bag: Array = []
	for k in table.keys():
		var key := "%s:%s" % [cat, str(k)]
		if exclude.has(key):
			continue
		## Already owned unique gear shouldn't reappear
		if cat == "blueprint" and state.blueprints.has(str(k)):
			continue
		if cat == "doctrine" and state.doctrines.has(str(k)):
			continue
		var rar: String = str(table[k][0])
		var n: int = 3 if rar == "C" else (2 if rar == "U" else 1)
		for _i in n:
			bag.append(k)
	if bag.is_empty():
		return ""
	return str(bag[state.rng.randi() % bag.size()])


func buy_offer(pack: String, index: int) -> Dictionary:
	## pack: "treasury" | "synod"
	var list: Array = shop_treasury if pack == "treasury" else shop_synod
	if index < 0 or index >= list.size():
		return {"ok": false, "reason": "bad_index"}
	var offer: Dictionary = list[index]
	if offer.get("bought", false):
		return {"ok": false, "reason": "already_bought"}
	var cat: String = str(offer["cat"])
	var cost: int = int(offer["cost"])
	if pack == "treasury":
		if state.gold < cost:
			return {"ok": false, "reason": "no_gold"}
		state.gold -= cost
	else:
		if state.faith < cost:
			return {"ok": false, "reason": "no_faith"}
		state.faith -= cost

	match cat:
		"unit":
			state.deck_kinds.append(str(offer["id"]))
		"blueprint":
			if state.blueprints.has(offer["id"]) or state.blueprints.size() >= state.blueprint_slots:
				# Refund
				if pack == "treasury":
					state.gold += cost
				return {"ok": false, "reason": "no_bp_slot"}
			state.blueprints.append(str(offer["id"]))
		"doctrine":
			if state.doctrines.has(offer["id"]) or state.doctrines.size() >= state.doctrine_slots:
				state.faith += cost
				return {"ok": false, "reason": "no_doc_slot"}
			state.doctrines.append(str(offer["id"]))
		"promotion":
			# Greybox: no per-card stats yet — treat as free gold interest bump
			state.gold += 2
		"prophet":
			## Greybox prophets: immediate Gold payout
			state.gold += 5
	offer["bought"] = true
	list[index] = offer
	state.log.append({"op": "buy", "pack": pack, "offer": offer.duplicate()})
	return {"ok": true, "offer": offer}


## --- Advance -----------------------------------------------------------------

func advance_after_shop() -> String:
	## Returns "next" | "era_won"
	if str(current_settlement.get("kind", "")) == "capital":
		state.run_won = true
		state.log.append({"op": "era_won"})
		return "era_won"
	state.settlement_index += 1
	_make_next_settlement()
	return "next"


func mark_lost() -> void:
	state.run_lost = true
	state.log.append({"op": "era_lost", "at": current_settlement.get("kind", "?")})


## --- Autoplay for tests ------------------------------------------------------

func run_auto_era(max_settlements: int = 3) -> Dictionary:
	## AI: fight → occupy (or raze if broke) → pick first Sci/Civ → buy affordable shop → next.
	var fights: Array = []
	while not state.run_won and not state.run_lost and fights.size() < max_settlements:
		begin_fight()
		var res: Dictionary = active_fight.run_auto()
		if not bool(res["won"]):
			mark_lost()
			fights.append(res)
			break
		fights.append(res)
		var choice := "occupy"
		if state.gold < 15:
			choice = "raze"
		apply_victory_payout(int(res["assaults_used"]), choice)
		# Level-ups: always pick offers[0]
		while can_afford_science():
			var lu: Dictionary = begin_science_levelup()
			if lu.is_empty():
				break
			pick_levelup(str(lu["offers"][0]))
		while can_afford_civic():
			var cu: Dictionary = begin_civic_levelup()
			if cu.is_empty():
				break
			pick_levelup(str(cu["offers"][0]))
		open_shop()
		for i in shop_treasury.size():
			buy_offer("treasury", i)
		for i in shop_synod.size():
			buy_offer("synod", i)
		var adv: String = advance_after_shop()
		if adv == "era_won":
			break
	return {
		"won": state.run_won,
		"lost": state.run_lost,
		"fights": fights.size(),
		"snapshot": state.snapshot(),
	}


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = state.rng.randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func offer_label(id: String) -> String:
	## Short title for UI buttons.
	if id.begins_with("upgrade_"):
		var cls: String = id.get_slice("_", 1)
		var names := {"M": "Melee", "R": "Ranged", "C": "Cavalry", "S": "Siege", "B": "Builder"}
		return "Upgrade %s" % names.get(cls, cls)
	match id:
		"battle_line_drill":
			return "Battle Line drill"
		"skirmish_drill":
			return "Skirmish / Pair drill"
		"combined_arms_primer":
			return "Combined Arms primer"
		"writing":
			return "Writing"
		"surveying":
			return "Surveying"
		"support_charge_B":
			return "+1 Builder charge"
		"support_charge_Y":
			return "+1 Missionary charge"
		"edu_scribal_schools":
			return "Scribal Schools"
		"bank_markets":
			return "Markets"
		"dev_shrines":
			return "Shrines"
		"art_festivals":
			return "Festivals"
		"eng_apprenticeship":
			return "Apprenticeship"
		"pro_alms":
			return "Alms"
		"code_of_laws":
			return "Code of Laws"
		"craftsmanship":
			return "Craftsmanship"
		"literacy":
			return "Literacy"
		"early_empire":
			return "Early Empire"
		"theology":
			return "Theology"
		"military_training":
			return "Military Training"
		"treasury_windfall":
			return "Treasury Windfall"
		"stall_permits":
			return "Stall Permits"
		"fairground_toll":
			return "Fairground Toll"
		"corvee_exemption":
			return "Corvée Exemption"
		"lay_preachers":
			return "Lay Preachers"
		_:
			return id


func offer_help(id: String) -> String:
	## Plain-English explanation for the (i) button.
	if id.begins_with("upgrade_"):
		var cls: String = id.get_slice("_", 1)
		var names := {"M": "Melee", "R": "Ranged", "C": "Cavalry", "S": "Siege", "B": "Builder"}
		var cur: int = int(state.tiers.get(cls, 1))
		if cls == "B":
			return "Raises Builder tier from %d → %d. Stronger Builder charge effects." % [cur, cur + 1]
		return "Raises all %s units one tier (%d → %d). More Might (and Momentum where relevant) in every fight." % [
			names.get(cls, cls), cur, cur + 1,
		]
	match id:
		"battle_line_drill":
			return "Levels up the Battle Line formation. Battle Line scores deal more damage."
		"skirmish_drill":
			return "Levels up Skirmish and Pair. Small formations hit harder."
		"combined_arms_primer":
			return "Levels up Combined Arms (Melee+Ranged+Cavalry mix)."
		"writing":
			return "Unlocks Writing. Marks literacy progress used by later tech systems."
		"surveying":
			return "Permanently +1 Regroup per settlement (more redraws in fights)."
		"support_charge_B":
			return "Builder charges per settlement +1 (spend in fight to fire a Blueprint)."
		"support_charge_Y":
			return "Missionary charges per settlement +1 (spend in fight to arm a Doctrine)."
		"edu_scribal_schools":
			return "+10% Science from all future victory rewards (and Scholar occupy yields)."
		"bank_markets":
			return "+8% Gold from victory rewards, interest, raze, and Trade occupy yields."
		"dev_shrines":
			return "+8% Faith from victory rewards and Temple occupy yields."
		"art_festivals":
			return "+8% Culture from victory rewards and Artisan occupy yields."
		"eng_apprenticeship":
			return "Engineering perk: Builder-focused bonus (greybox flag for later BP synergy)."
		"pro_alms":
			return "Prophecy perk: Missionary-focused bonus (greybox flag for later Doctrine synergy)."
		"code_of_laws":
			return "+1 Policy slot. Lets you hold one more Policy from drafts."
		"craftsmanship", "literacy":
			return "Immediately draft one random common Policy into an empty Policy slot."
		"early_empire":
			return "+1 Blueprint slot so you can equip another Blueprint from the shop."
		"theology":
			return "+1 Doctrine slot so you can equip another Doctrine from the Synod."
		"military_training":
			return "Permanently +1 Regroup per settlement."
		"treasury_windfall":
			return "Gain 22 Gold now (scaled by any Gold percent bonuses)."
		"stall_permits":
			return "+1 offer in both Treasury and Synod packs each shop visit."
		"fairground_toll":
			return "Units in the Treasury cost 2 Gold less."
		"corvee_exemption":
			return "Builder can attach without using a formation slot (free support slot)."
		"lay_preachers":
			return "Missionary can attach without using a formation slot (free support slot)."
		_:
			return "No extra notes for this option yet."


func shop_offer_help(offer: Dictionary) -> String:
	var cat: String = str(offer.get("cat", ""))
	var id: String = str(offer.get("id", ""))
	match cat:
		"unit":
			var names := {"M": "Melee", "R": "Ranged", "C": "Cavalry", "S": "Siege"}
			return "Add one %s card to your deck at your current class tier (T%d)." % [
				names.get(id, id), int(state.tiers.get(id, 1)),
			]
		"blueprint":
			return _blueprint_help(id)
		"doctrine":
			return _doctrine_help(id)
		"promotion":
			return _promotion_help(id)
		"prophet":
			if id == "sow_dissent":
				return "Spend Faith for an immediate +5 Gold. Simple Synod cash-out."
			return "Spend Faith for a small immediate Gold payout (greybox prophet)."
		_:
			return "Shop offer."


func _blueprint_help(id: String) -> String:
	match id:
		"scaffolding":
			return "Equip Blueprint. Spend a Builder charge in fight to ignore walls on that Assault."
		"siege_tower":
			return "Equip Blueprint. Spend a Builder charge to remove walls for the rest of the fight."
		"battering_ram":
			return "Equip Blueprint. Builder spend boosts siege pressure (wall help)."
		"supply_lines":
			return "Equip Blueprint. Builder spend draws extra cards (effect stubbed in greybox)."
		"watchtower":
			return "Equip Blueprint. Builder spend buffs the next Assault’s Might (stubbed)."
		"forge":
			return "Equip Blueprint. Big next-unit Might buff when Builder is spent (stubbed)."
		"roads":
			return "Equip Blueprint. Grants an extra Regroup when fired (stubbed)."
		"magazine":
			return "Equip Blueprint. Adds Momentum to the next Assault (stubbed)."
		"aqueduct":
			return "Equip Blueprint. Grants an extra Assault when fired (stubbed)."
		"arsenal":
			return "Equip Blueprint. Next unit Might bonus when Builder is spent (stubbed)."
		_:
			return "Equip this Blueprint into an empty slot. Fire it by spending a Builder charge in fight."


func _doctrine_help(id: String) -> String:
	match id:
		"tithe":
			return "Equip Doctrine. Arm with a Missionary charge; on win, payout extra Gold."
		"scriptorium":
			return "Equip Doctrine. On win after arming, payout bonus Science %%."
		"pilgrimage":
			return "Equip Doctrine. On win after arming, payout extra Faith."
		"alms":
			return "Equip Doctrine. On win after arming, payout extra Culture."
		"zeal":
			return "Equip Doctrine. Temporary Might buff for a couple of settlements when armed."
		"relic_hunt":
			return "Equip Doctrine. Chance at prophet-style bonus when armed (stubbed)."
		"crusade":
			return "Equip Doctrine. Extra Might into Capitals when armed."
		"scholastic_order":
			return "Equip Doctrine. Science + Culture payout on win when armed."
		"missionary_zeal":
			return "Equip Doctrine. Scales Gold/Faith payouts when armed (rare)."
		"mercenaries":
			return "Equip Doctrine. Hireling Might boost when armed (rare)."
		_:
			return "Equip this Doctrine into an empty slot. Arm it by spending a Missionary charge."


func _promotion_help(id: String) -> String:
	match id:
		"master_drill":
			return "Promote a unit: +5 Might on that card (greybox: small Gold consolation until per-card stats land)."
		"skirmish_doctrine":
			return "Promote a unit: +2 Momentum on that card."
		"shock_drill":
			return "Promote a unit: +3 Might and +1 Momentum."
		"banner_carrier":
			return "Promote a unit: large banner Might aura for the formation."
		"thinking_soldier":
			return "Promote a unit: scores grant bonus Science %%."
		"heroic":
			return "Promote a unit: ×1.75 Might multiplier (rare)."
		_:
			return "Apply a permanent promotion to one combat card in your deck."

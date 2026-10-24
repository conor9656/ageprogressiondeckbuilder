extends RefCounted
## Ancient era run orchestrator — settlements, rewards, Sci/Civ picks, shop.
## UI drives player choices; `run_auto_era` plays a full era for tests.

const CombatTables := preload("res://rules/combat_tables.gd")
const AgesRules := preload("res://rules/ages_rules.gd")
const RunState := preload("res://rules/run_state.gd")
const SupportCharges := preload("res://rules/support_charges.gd")
const RunTables := preload("res://rules/run_tables.gd")

var state: RefCounted
var current_settlement: Dictionary = {}
var active_fight: RefCounted
var last_reward: Dictionary = {}
var shop_treasury: Array = []
var shop_synod: Array = []
var shop_wonder: Dictionary = {}  ## dedicated Wonder row or {}
var shop_rerolled: bool = false
## Pending level-up: {"kind": "science"|"civic", "cost": int, "offers": Array, "free": bool}
var pending_levelup: Dictionary = {}
## After era advance: {"breakthrough_sci": bool, "breakthrough_civ": bool, "toolkit": bool}
var pending_era_hooks: Dictionary = {}


func start(seed: int = 1) -> void:
	CombatTables.reload()
	RunTables.reload()
	state = RunState.new()
	state.setup(seed)
	current_settlement = {}
	active_fight = null
	last_reward.clear()
	shop_treasury.clear()
	shop_synod.clear()
	shop_wonder.clear()
	shop_rerolled = false
	pending_levelup.clear()
	pending_era_hooks.clear()
	_make_next_settlement()


func _make_next_settlement() -> void:
	var kind: String = state.current_kind()
	if kind == "":
		return
	current_settlement = make_settlement(kind, state.rng, state.era)
	state.log.append({"op": "settlement", "kind": kind, "defence": current_settlement["defence"]})


static func make_settlement(kind: String, rng: RandomNumberGenerator, era: int = 1) -> Dictionary:
	CombatTables.ensure_loaded()
	RunTables.ensure_loaded()
	var base: int = CombatTables.era_base_defence(era)
	var defence: int = int(float(base) * RunTables.kind_mult(kind))
	var sett: Dictionary = RunTables.settlement()
	var walls := false
	var garrison := "militia"
	if kind == "town":
		walls = rng.randf() < float(sett["town_walls_chance"])
		var tg: Array = sett["town_garrisons"]
		garrison = str(tg[rng.randi() % tg.size()])
	elif kind == "capital":
		walls = rng.randf() < float(sett["capital_walls_chance"])
		var cg: Array = sett["capital_garrisons"]
		garrison = str(cg[rng.randi() % cg.size()])
	var types: Array = sett["city_types"]
	var city_type: String = str(types[rng.randi() % types.size()])
	return {
		"kind": kind,
		"era": era,
		"defence": defence,
		"walls": walls,
		"garrison": garrison,
		"city_type": city_type,
	}


func begin_fight() -> RefCounted:
	var free_b: bool = bool(state.eng_flags.get("builder_free_slot", false))
	var free_y: bool = bool(state.pro_flags.get("missionary_free_slot", false))
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
		"faith_combat_mom": state.faith_combat_mom,
		"builder_free_slot": free_b,
		"missionary_free_slot": free_y,
		"builder_scale": state.builder_scale,
		"active_blueprint_index": 0,
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
	var g: int = int((RunTables.reward("gold") + unused) * (1.0 + state.gold_bonus_pct) * gold_m)
	var s: int = int(RunTables.reward("science") * (1.0 + state.sci_bonus_pct) * sci_m)
	var c: int = int(RunTables.reward("culture") * (1.0 + state.cul_bonus_pct) * cul_m)
	var f: int = int(RunTables.reward("faith") * (1.0 + state.faith_bonus_pct) * faith_m)
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
		raze_gold = int(RunTables.reward("raze_gold") * (1.0 + state.gold_bonus_pct))
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
	var y: int = RunTables.reward("city_yield")
	for t in state.occupied:
		var amt: int = y
		match str(t):
			"scholar":
				amt = int(y * (1.0 + state.sci_bonus_pct) * state.income_mult("sci"))
				state.science += amt
				out["science"] += amt
			"artisan":
				amt = int(y * (1.0 + state.cul_bonus_pct) * state.income_mult("cul"))
				state.culture += amt
				out["culture"] += amt
			"temple":
				amt = int(y * (1.0 + state.faith_bonus_pct) * state.income_mult("faith"))
				state.faith += amt
				out["faith"] += amt
			"trade":
				amt = int(y * (1.0 + state.gold_bonus_pct) * state.income_mult("gold"))
				state.gold += amt
				out["gold"] += amt
	return out


## --- Level-ups ---------------------------------------------------------------

func science_cost() -> int:
	return maxi(1, int(RunTables.science_cost(state.sci_level) * state.bar_cost_mult()))


func civic_cost() -> int:
	return maxi(1, int(RunTables.science_cost(state.civ_level) * state.bar_cost_mult()))


func can_afford_science() -> bool:
	return state.science >= science_cost() and state.sci_level < RunTables.science_cost_count()


func can_afford_civic() -> bool:
	return state.culture >= civic_cost() and state.civ_level < RunTables.science_cost_count()


func begin_science_levelup(free: bool = false) -> Dictionary:
	if not free and not can_afford_science():
		pending_levelup.clear()
		return {}
	if free and state.sci_level >= RunTables.science_cost_count():
		pending_levelup.clear()
		return {}
	var cost: int = 0 if free else science_cost()
	if not free:
		state.science -= cost
	var offers: Array = roll_science_offers()
	pending_levelup = {"kind": "science", "cost": cost, "offers": offers, "free": free}
	return pending_levelup


func begin_civic_levelup(free: bool = false) -> Dictionary:
	if not free and not can_afford_civic():
		pending_levelup.clear()
		return {}
	if free and state.civ_level >= RunTables.science_cost_count():
		pending_levelup.clear()
		return {}
	var cost: int = 0 if free else civic_cost()
	if not free:
		state.culture -= cost
	var offers: Array = roll_civic_offers()
	pending_levelup = {"kind": "civic", "cost": cost, "offers": offers, "free": free}
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
	var offer_n: int = RunTables.science_offer_count()
	var t_count: int = 1 if state.rng.randf() < RunTables.pack_float("science_one_troop_chance") else 2
	var troops: Array = _weighted_troop_offers(t_count)
	var pool: Array = []
	for d in RunTables.drills():
		pool.append(d)
	for row in RunTables.progression():
		var nid: String = str(row["id"])
		if not state.owned_prog.has(nid):
			pool.append(nid)
	var sch: float = RunTables.pack_float("support_charge_offer_chance")
	if _can_upgrade_support("B") and state.rng.randf() < sch:
		pool.append("support_charge_B")
	if _can_upgrade_support("Y") and state.rng.randf() < sch:
		pool.append("support_charge_Y")
	_shuffle(pool)
	var non: Array = []
	while troops.size() + non.size() < offer_n and not pool.is_empty():
		var n: String = str(pool.pop_back())
		if not non.has(n) and not troops.has(n):
			non.append(n)
	## Unique fillers only — never pad with duplicates
	var fillers: Array = RunTables.drills().duplicate()
	for row2 in RunTables.progression():
		fillers.append(str(row2["id"]))
	for f in fillers:
		if troops.size() + non.size() >= offer_n:
			break
		if not non.has(f) and not troops.has(f):
			non.append(f)
	var out: Array = troops + non
	return out.slice(0, mini(offer_n, out.size()))


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
		if key == "B":
			state.builder_scale = RunTables.builder_scale_for_tier(int(state.tiers["B"]))
		return
	if pick == "support_charge_B":
		state.builder_charges_max = mini(CombatTables.support_charge_cap(), state.builder_charges_max + 1)
		return
	if pick == "support_charge_Y":
		state.missionary_charges_max = mini(CombatTables.support_charge_cap(), state.missionary_charges_max + 1)
		return
	for row in RunTables.progression():
		if pick != str(row["id"]):
			continue
		state.owned_prog[pick] = true
		var kind: String = str(row["kind"])
		var val = row["value"]
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
	var offer_n: int = RunTables.civic_offer_count()
	var candidates: Array = []
	var weights: Array = []
	for row in RunTables.civics():
		var cid: String = str(row["id"])
		var rarity: String = str(row["rarity"])
		var once: bool = bool(row["once"])
		if once and state.owned_civics.has(cid):
			continue
		if not _civic_legal(cid):
			continue
		candidates.append(cid)
		weights.append(RunTables.rarity_weight(rarity))
	if candidates.is_empty():
		return ["craftsmanship", "military_training", "fairground_toll"]
	var offers: Array = []
	while offers.size() < offer_n and not candidates.is_empty():
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
	while offers.size() < offer_n:
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
	for row in RunTables.civics():
		if str(row["id"]) == pick and bool(row["once"]):
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
			state.unit_cost_flat = maxi(state.unit_cost_flat, RunTables.civic_effect_int("fairground_toll_flat"))
		"corvee_exemption":
			state.eng_flags["builder_free_slot"] = true
		"lay_preachers":
			state.pro_flags["missionary_free_slot"] = true
		"treasury_windfall":
			state.gold += int(RunTables.civic_effect_int("treasury_windfall_gold") * (1.0 + state.gold_bonus_pct))


func _draft_policy() -> void:
	if state.policies.size() >= state.policy_slots:
		return
	var pool: Array = []
	for p in RunTables.policy_commons():
		if not state.policies.has(p):
			pool.append(p)
	if pool.is_empty():
		return
	state.policies.append(str(pool[state.rng.randi() % pool.size()]))


## --- Shop --------------------------------------------------------------------

func open_shop() -> Dictionary:
	shop_rerolled = false
	var n: int = RunTables.pack_size() + state.pack_bonus
	shop_treasury = _roll_unique_pack(n, true)
	shop_synod = _roll_unique_pack(n, false)
	_roll_wonder_offer()
	return {
		"treasury": shop_treasury.duplicate(true),
		"synod": shop_synod.duplicate(true),
		"wonder": shop_wonder.duplicate(true),
	}


func _roll_wonder_offer() -> void:
	## Dedicated Wonder row while unequipped (1 Wonder / run). Sticky offer across visits until bought or skipped via leave.
	shop_wonder.clear()
	if state.wonder != "":
		return
	var catalog: Dictionary = RunTables.wonders()
	if catalog.is_empty():
		return
	if state.shop_wonder_offer == "" or not catalog.has(state.shop_wonder_offer):
		var keys: Array = catalog.keys()
		state.shop_wonder_offer = str(keys[state.rng.randi() % keys.size()])
		state.shop_wonder_rerolls_left = 1
	var wid: String = state.shop_wonder_offer
	var row: Dictionary = catalog[wid]
	shop_wonder = {
		"cat": "wonder",
		"id": wid,
		"cost": int(row.get("cost", 70)),
		"effect": str(row.get("effect", "")),
		"label": "Wonder %s" % wid.replace("_", " ").capitalize(),
		"bought": false,
	}


func reroll_treasury() -> bool:
	if shop_rerolled or state.gold < state.reroll_cost:
		return false
	state.gold -= state.reroll_cost
	shop_rerolled = true
	var n: int = RunTables.pack_size() + state.pack_bonus
	shop_treasury = _roll_unique_pack(n, true)
	return true


func reroll_wonder() -> bool:
	if state.wonder != "" or shop_wonder.is_empty():
		return false
	if state.shop_wonder_rerolls_left <= 0:
		return false
	var cost: int = RunTables.wonder_reroll_cost()
	if state.gold < cost:
		return false
	var catalog: Dictionary = RunTables.wonders()
	if catalog.size() < 2:
		return false
	state.gold -= cost
	state.shop_wonder_rerolls_left -= 1
	var keys: Array = []
	for k in catalog.keys():
		if str(k) != state.shop_wonder_offer:
			keys.append(str(k))
	state.shop_wonder_offer = str(keys[state.rng.randi() % keys.size()])
	_roll_wonder_offer()
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
			var cost: int = RunTables.unit_tier_cost(int(state.tiers.get(kind, 1)))
			cost = maxi(1, cost - state.unit_cost_flat)
			var o := {"cat": "unit", "id": kind, "cost": cost, "label": "Unit %s" % kind}
			seen[key2] = true
			out.append(o)
			filled = true
			break
		if not filled:
			break
	return out


func _unit_offer(kind: String) -> Dictionary:
	var cost: int = RunTables.unit_tier_cost(int(state.tiers.get(kind, 1)))
	cost = maxi(1, cost - state.unit_cost_flat)
	return {"cat": "unit", "id": kind, "cost": cost, "label": "Unit %s" % kind}


func _prophet_offer(id: String = "") -> Dictionary:
	var catalog: Dictionary = RunTables.prophets()
	if id == "":
		if catalog.is_empty():
			id = "sow_dissent"
		else:
			var keys: Array = catalog.keys()
			id = str(keys[state.rng.randi() % keys.size()])
	var cost: int = RunTables.pack_int("prophet_cost")
	var gold_payout: int = RunTables.pack_int("prophet_gold_payout")
	if catalog.has(id):
		cost = int(catalog[id].get("cost", cost))
		gold_payout = int(catalog[id].get("gold", gold_payout))
	return {
		"cat": "prophet", "id": id, "cost": cost,
		"gold_payout": gold_payout,
		"label": "Prophet %s" % id.replace("_", " "),
	}


func roll_treasury_offer(exclude: Dictionary = {}) -> Dictionary:
	## exclude: set of "cat:id" keys already in the pack.
	var unit_band: float = RunTables.pack_float("treasury_unit_band")
	var bp_band: float = RunTables.pack_float("treasury_blueprint_band")
	var promo_band: float = RunTables.pack_float("treasury_promo_band")
	for _try in 16:
		var r: float = state.rng.randf()
		var offer: Dictionary
		if r < unit_band:
			var kind: String = ["M", "R", "C", "S"][state.rng.randi() % 4]
			offer = _unit_offer(kind)
		elif r < bp_band:
			var name: String = _weighted_from(RunTables.blueprints(), exclude, "blueprint")
			if name == "":
				continue
			offer = {
				"cat": "blueprint", "id": name,
				"cost": RunTables.catalog_cost(RunTables.blueprints(), name),
				"label": "BP %s" % name,
			}
		elif r < promo_band:
			var pname: String = _weighted_from(RunTables.promotions(), exclude, "promotion")
			if pname == "":
				continue
			offer = {
				"cat": "promotion", "id": pname,
				"cost": RunTables.catalog_cost(RunTables.promotions(), pname),
				"label": "Promo %s" % pname,
			}
		else:
			var kind2: String = ["M", "R", "C", "S"][state.rng.randi() % 4]
			offer = _unit_offer(kind2)
		if not exclude.has(_offer_key(offer)):
			return offer
	for kind3 in ["M", "R", "C", "S"]:
		var key := "unit:%s" % kind3
		if exclude.has(key):
			continue
		return _unit_offer(kind3)
	return _unit_offer("M")


func roll_synod_offer(exclude: Dictionary = {}) -> Dictionary:
	var doc_chance: float = RunTables.pack_float("synod_doctrine_chance")
	for _try in 16:
		var offer: Dictionary
		if state.rng.randf() < doc_chance:
			var name: String = _weighted_from(RunTables.doctrines(), exclude, "doctrine")
			if name == "":
				offer = _roll_prophet_offer(exclude)
			else:
				offer = {
					"cat": "doctrine", "id": name,
					"cost": RunTables.catalog_cost(RunTables.doctrines(), name),
					"label": "Doc %s" % name,
				}
		else:
			offer = _roll_prophet_offer(exclude)
		if offer.is_empty():
			continue
		if not exclude.has(_offer_key(offer)):
			return offer
	var doc: String = _weighted_from(RunTables.doctrines(), exclude, "doctrine")
	if doc != "":
		return {
			"cat": "doctrine", "id": doc,
			"cost": RunTables.catalog_cost(RunTables.doctrines(), doc),
			"label": "Doc %s" % doc,
		}
	var prophet: Dictionary = _roll_prophet_offer(exclude)
	if not prophet.is_empty():
		return prophet
	return _prophet_offer("sow_dissent")


func _roll_prophet_offer(exclude: Dictionary) -> Dictionary:
	var catalog: Dictionary = RunTables.prophets()
	var bag: Array = []
	for k in catalog.keys():
		var key := "prophet:%s" % str(k)
		if exclude.has(key):
			continue
		var rar: String = str(catalog[k].get("rarity", "C"))
		var n: int = RunTables.rarity_bag_count(rar)
		for _i in n:
			bag.append(str(k))
	if bag.is_empty():
		return {}
	return _prophet_offer(str(bag[state.rng.randi() % bag.size()]))


func _weighted_from(table: Dictionary, exclude: Dictionary, cat: String) -> String:
	var bag: Array = []
	for k in table.keys():
		var key := "%s:%s" % [cat, str(k)]
		if exclude.has(key):
			continue
		if cat == "blueprint" and state.blueprints.has(str(k)):
			continue
		if cat == "doctrine" and state.doctrines.has(str(k)):
			continue
		var rar: String = RunTables.catalog_rarity(table, str(k))
		var n: int = RunTables.rarity_bag_count(rar)
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
			## Greybox: track owned promos for deck panel; small Gold consolation until per-card stats land
			state.owned_promotions.append(str(offer["id"]))
			state.gold += 2
		"prophet":
			_apply_prophet(str(offer["id"]), offer)
		"wonder":
			## Should go through buy_wonder(); keep path for spill offers later
			if state.wonder != "":
				state.gold += cost
				return {"ok": false, "reason": "already_have_wonder"}
			_apply_wonder(str(offer["id"]))
	offer["bought"] = true
	list[index] = offer
	state.log.append({"op": "buy", "pack": pack, "offer": offer.duplicate()})
	return {"ok": true, "offer": offer}


func buy_wonder() -> Dictionary:
	if shop_wonder.is_empty() or bool(shop_wonder.get("bought", false)):
		return {"ok": false, "reason": "no_offer"}
	if state.wonder != "":
		return {"ok": false, "reason": "already_have_wonder"}
	var cost: int = int(shop_wonder.get("cost", 0))
	if state.gold < cost:
		return {"ok": false, "reason": "no_gold"}
	state.gold -= cost
	_apply_wonder(str(shop_wonder["id"]))
	shop_wonder["bought"] = true
	state.shop_wonder_offer = ""
	state.log.append({"op": "buy_wonder", "offer": shop_wonder.duplicate()})
	return {"ok": true, "offer": shop_wonder.duplicate()}


func _apply_wonder(wid: String) -> void:
	state.wonder = wid
	var catalog: Dictionary = RunTables.wonders()
	var effect: String = str(catalog.get(wid, {}).get("effect", ""))
	match effect:
		"plus_assault":
			state.base_assaults += 1
		"builder_scale":
			state.builder_scale = maxf(state.builder_scale, state.builder_scale * 1.25)
			state.blueprint_slots = mini(5, state.blueprint_slots + 1)
		"hand_size":
			state.hand_size += 1
		"faith_burst":
			state.faith += 25
		"free_sci_level":
			state.science += maxi(8, science_cost())
		"support_free_slots":
			state.eng_flags["builder_free_slot"] = true
			state.pro_flags["missionary_free_slot"] = true
		"float_supports":
			state.eng_flags["builder_free_slot"] = true
		"sci_cost_cut":
			state.eng_flags["sci_cost_cut"] = true
		"sci_gain_pct":
			state.sci_bonus_pct += 0.12
		"occupy_x2":
			state.eng_flags["occupy_x2"] = true
		"replace_troop":
			state.deck_kinds.append("M")
			state.deck_kinds.append("R")
		"parade_grounds", "theater_of_war", "safe_conduct", "christ_clutch":
			state.eng_flags[effect] = true
		_:
			state.eng_flags["wonder_%s" % wid] = true
	state.log.append({"op": "wonder", "id": wid, "effect": effect})


func _apply_prophet(pid: String, offer: Dictionary) -> void:
	## Greybox: gold payout prophets + a few stub combat/economy flags.
	var payout: int = int(offer.get("gold_payout", RunTables.pack_int("prophet_gold_payout")))
	match pid:
		"sow_dissent", "tithe_collector", "street_preacher", "relic_broker":
			state.gold += payout
		"blessing":
			state.faith_combat_mom += 1
			state.gold += maxi(0, payout)
		"conversion":
			state.faith += 10
			state.doctrine_slots = mini(4, state.doctrine_slots + 0)  ## keep slot; mark flag
			state.pro_flags["conversion"] = true
		"holy_revolt":
			state.eng_flags["holy_revolt"] = true
			state.gold += 10
		"revelation":
			state.science += 12
			state.culture += 8
		_:
			state.gold += payout


func unequip_blueprint(index: int) -> bool:
	if index < 0 or index >= state.blueprints.size():
		return false
	var removed: String = str(state.blueprints[index])
	state.blueprints.remove_at(index)
	state.log.append({"op": "unequip_blueprint", "id": removed})
	return true


func unequip_doctrine(index: int) -> bool:
	if index < 0 or index >= state.doctrines.size():
		return false
	var removed: String = str(state.doctrines[index])
	state.doctrines.remove_at(index)
	state.log.append({"op": "unequip_doctrine", "id": removed})
	return true


func income_breakdown() -> Dictionary:
	## Testing readout: base win rates, occupy sticky yields, % bonuses, era mults.
	var y: int = RunTables.reward("city_yield")
	var occupy_counts := {"scholar": 0, "artisan": 0, "temple": 0, "trade": 0}
	for t in state.occupied:
		var k := str(t)
		if occupy_counts.has(k):
			occupy_counts[k] = int(occupy_counts[k]) + 1
	var occupy_per_fight := {
		"science": 0, "culture": 0, "faith": 0, "gold": 0,
	}
	for t in state.occupied:
		match str(t):
			"scholar":
				occupy_per_fight["science"] += int(y * (1.0 + state.sci_bonus_pct) * state.income_mult("sci"))
			"artisan":
				occupy_per_fight["culture"] += int(y * (1.0 + state.cul_bonus_pct) * state.income_mult("cul"))
			"temple":
				occupy_per_fight["faith"] += int(y * (1.0 + state.faith_bonus_pct) * state.income_mult("faith"))
			"trade":
				occupy_per_fight["gold"] += int(y * (1.0 + state.gold_bonus_pct) * state.income_mult("gold"))
	var base_raw := {
		"gold": RunTables.reward("gold"),
		"science": RunTables.reward("science"),
		"culture": RunTables.reward("culture"),
		"faith": RunTables.reward("faith"),
		"raze_gold": RunTables.reward("raze_gold"),
		"city_yield": y,
	}
	return {
		"base_raw": base_raw,
		"era_mult": {
			"gold": state.income_mult("gold"),
			"science": state.income_mult("sci"),
			"culture": state.income_mult("cul"),
			"faith": state.income_mult("faith"),
		},
		"bonus_pct": {
			"gold": state.gold_bonus_pct,
			"science": state.sci_bonus_pct,
			"culture": state.cul_bonus_pct,
			"faith": state.faith_bonus_pct,
		},
		"occupy_counts": occupy_counts,
		"occupy_total": state.occupied.size(),
		"occupy_per_fight": occupy_per_fight,
		"interest_cap": state.interest_cap,
		"builder_tier": int(state.tiers.get("B", 1)),
		"builder_scale": state.builder_scale,
		"wonder": state.wonder,
		"last_reward": last_reward.duplicate(true),
	}


func deck_summary() -> Dictionary:
	var counts := {"M": 0, "R": 0, "C": 0, "S": 0}
	for k in state.deck_kinds:
		var s := str(k)
		if counts.has(s):
			counts[s] = int(counts[s]) + 1
	return {
		"counts": counts,
		"total": state.deck_kinds.size(),
		"tiers": state.tiers.duplicate(),
		"form_levels": state.form_levels.duplicate(),
		"blueprints": state.blueprints.duplicate(),
		"blueprint_slots": state.blueprint_slots,
		"doctrines": state.doctrines.duplicate(),
		"doctrine_slots": state.doctrine_slots,
		"policies": state.policies.duplicate(),
		"policy_slots": state.policy_slots,
		"promotions": state.owned_promotions.duplicate(),
		"builder_charges": state.builder_charges_max,
		"missionary_charges": state.missionary_charges_max,
		"builder_scale": state.builder_scale,
		"wonder": state.wonder,
		"eng_flags": state.eng_flags.duplicate(),
		"pro_flags": state.pro_flags.duplicate(),
	}


## --- Advance / era hooks -----------------------------------------------------

func advance_after_shop() -> String:
	## Returns "next" | "era_advance" | "domination_won"
	if str(current_settlement.get("kind", "")) != "capital":
		state.settlement_index += 1
		_make_next_settlement()
		return "next"
	state.eras_cleared += 1
	state.log.append({"op": "era_cleared", "era": state.era, "name": state.era_label()})
	if state.era >= RunTables.max_era():
		state.run_won = true
		state.log.append({"op": "domination_won"})
		return "domination_won"
	state.era += 1
	state.settlement_index = 0
	_make_next_settlement()
	_queue_era_start_hooks()
	return "era_advance"


func _queue_era_start_hooks() -> void:
	pending_era_hooks = {
		"breakthrough_sci": state.era >= RunTables.breakthrough_era_min(),
		"breakthrough_civ": state.era >= RunTables.breakthrough_era_min(),
		"toolkit": false,
	}
	if state.era >= RunTables.industrial_era_min():
		if not state.industrial_assault_granted:
			state.base_assaults += RunTables.industrial_assault_bonus()
			state.industrial_assault_granted = true
			state.log.append({"op": "industrial_assault", "base_assaults": state.base_assaults})
		if state.era == RunTables.industrial_era_min() and state.industrial_toolkit == "":
			pending_era_hooks["toolkit"] = true
	state.log.append({"op": "era_start", "era": state.era, "hooks": pending_era_hooks.duplicate()})


func has_pending_era_hooks() -> bool:
	if pending_era_hooks.is_empty():
		return false
	return bool(pending_era_hooks.get("breakthrough_sci", false)) \
		or bool(pending_era_hooks.get("breakthrough_civ", false)) \
		or bool(pending_era_hooks.get("toolkit", false))


func begin_breakthrough_science() -> Dictionary:
	if not bool(pending_era_hooks.get("breakthrough_sci", false)):
		return {}
	pending_era_hooks["breakthrough_sci"] = false
	return begin_science_levelup(true)


func begin_breakthrough_civic() -> Dictionary:
	if not bool(pending_era_hooks.get("breakthrough_civ", false)):
		return {}
	pending_era_hooks["breakthrough_civ"] = false
	return begin_civic_levelup(true)


func toolkit_offers() -> Array:
	return RunTables.industrial_toolkit_offers().duplicate()


func toolkit_help(id: String) -> String:
	match id:
		"drill_sergeant":
			return "+2 levels on your best formation drill (Battle Line preferred)."
		"foundry_contract":
			return "Blueprint effects hit harder (×1.5 greybox flag)."
		"revival_tent":
			return "+2 Momentum on every Assault for the rest of the run."
		"seminar":
			return "Immediate free Science level-up (picks a non-troop offer when possible)."
		"powder_magazine":
			return "Extra +1 Assault per settlement (on top of Industrial’s global +1)."
		_:
			return "Industrial Toolkit pick."


func apply_industrial_toolkit(pick: String) -> bool:
	if not bool(pending_era_hooks.get("toolkit", false)):
		return false
	if not toolkit_offers().has(pick):
		return false
	pending_era_hooks["toolkit"] = false
	state.industrial_toolkit = pick
	match pick:
		"drill_sergeant":
			var form := "battle_line"
			var best_lv := -1
			for k in state.form_levels.keys():
				if int(state.form_levels[k]) > best_lv:
					best_lv = int(state.form_levels[k])
					form = str(k)
			state.form_levels[form] = int(state.form_levels.get(form, 0)) + 2
		"foundry_contract":
			state.foundry_bp_mult = maxf(state.foundry_bp_mult, 1.5)
		"revival_tent":
			state.faith_combat_mom = maxi(state.faith_combat_mom, 2)
		"seminar":
			var offers: Array = roll_science_offers()
			var pick_sci := ""
			for o in offers:
				if str(o).begins_with("edu_") or str(o) == "writing":
					pick_sci = str(o)
					break
			if pick_sci == "":
				for o2 in offers:
					if not str(o2).begins_with("upgrade_"):
						pick_sci = str(o2)
						break
			if pick_sci == "" and not offers.is_empty():
				pick_sci = str(offers[0])
			if pick_sci != "":
				apply_science(pick_sci)
				state.sci_level += 1
		"powder_magazine":
			state.base_assaults += 1
	state.log.append({"op": "industrial_toolkit", "pick": pick})
	return true


func mark_lost() -> void:
	state.run_lost = true
	state.log.append({
		"op": "run_lost",
		"era": state.era,
		"at": current_settlement.get("kind", "?"),
	})


## --- Autoplay for tests ------------------------------------------------------

func _auto_meta_after_win(assaults_used: int) -> void:
	var choice := "occupy"
	if state.gold < 15:
		choice = "raze"
	apply_victory_payout(assaults_used, choice)
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


func _auto_resolve_era_hooks() -> void:
	while has_pending_era_hooks():
		if bool(pending_era_hooks.get("breakthrough_sci", false)):
			var bs: Dictionary = begin_breakthrough_science()
			if not bs.is_empty():
				pick_levelup(str(bs["offers"][0]))
			continue
		if bool(pending_era_hooks.get("breakthrough_civ", false)):
			var bc: Dictionary = begin_breakthrough_civic()
			if not bc.is_empty():
				pick_levelup(str(bc["offers"][0]))
			continue
		if bool(pending_era_hooks.get("toolkit", false)):
			apply_industrial_toolkit("drill_sergeant")
			continue
		break


func run_auto_era(max_settlements: int = 3) -> Dictionary:
	## AI clears one era (3 settlements) or loses.
	var fights: Array = []
	var start_era: int = state.era
	while not state.run_won and not state.run_lost and fights.size() < max_settlements:
		if state.era != start_era:
			break
		begin_fight()
		var res: Dictionary = active_fight.run_auto()
		if not bool(res["won"]):
			mark_lost()
			fights.append(res)
			break
		fights.append(res)
		_auto_meta_after_win(int(res["assaults_used"]))
		var adv: String = advance_after_shop()
		if adv == "era_advance":
			_auto_resolve_era_hooks()
			break
		if adv == "domination_won":
			break
	return {
		"won": (state.eras_cleared > 0 and state.era > start_era) or state.run_won,
		"lost": state.run_lost,
		"fights": fights.size(),
		"snapshot": state.snapshot(),
	}


func run_auto_domination(max_era: int = 8) -> Dictionary:
	## Attempt full Domination (or up to max_era Capitals).
	var fights := 0
	var failed_era := 0
	while not state.run_won and not state.run_lost and state.era <= max_era:
		begin_fight()
		var res: Dictionary = active_fight.run_auto()
		fights += 1
		if not bool(res["won"]):
			failed_era = state.era
			mark_lost()
			break
		_auto_meta_after_win(int(res["assaults_used"]))
		var adv: String = advance_after_shop()
		if adv == "era_advance":
			_auto_resolve_era_hooks()
		elif adv == "domination_won":
			break
		if state.era > max_era and not state.run_won:
			break
	return {
		"won": state.run_won,
		"lost": state.run_lost,
		"fights": fights,
		"eras_cleared": state.eras_cleared,
		"failed_era": failed_era,
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
			var next_scale: float = RunTables.builder_scale_for_tier(cur + 1)
			return (
				"Raises Builder tier from %d → %d. Blueprint numbers scale ×%.1f → ×%.1f "
				+ "(not +1 charge — that is a separate Science pick)."
			) % [cur, cur + 1, state.builder_scale, next_scale]
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
			return _prophet_help(id, offer)
		"wonder":
			return _wonder_help(id)
		_:
			return "Shop offer."


func _prophet_help(id: String, offer: Dictionary = {}) -> String:
	var payout: int = int(offer.get("gold_payout", RunTables.pack_int("prophet_gold_payout")))
	match id:
		"sow_dissent":
			return "One-use Prophet. Immediate +%d Gold. Simple Synod cash-out." % payout
		"tithe_collector":
			return "One-use Prophet. Immediate +%d Gold (stronger tithe)." % payout
		"street_preacher":
			return "One-use Prophet. Cheap Faith spend for +%d Gold." % payout
		"relic_broker":
			return "One-use Prophet. Immediate +%d Gold from relics." % payout
		"blessing":
			return "One-use Prophet. +1 Faith combat Momentum for the rest of the run."
		"conversion":
			return "One-use Prophet. +10 Faith and marks Conversion (Doctrine synergy stub)."
		"holy_revolt":
			return "One-use Prophet. +10 Gold and flags Holy Revolt (combat stub)."
		"revelation":
			return "One-use Prophet. Immediate +12 Science and +8 Culture."
		_:
			return "One-use Prophet. Spend Faith for an immediate effect (greybox)."


func _wonder_help(id: String) -> String:
	var catalog: Dictionary = RunTables.wonders()
	var effect: String = str(catalog.get(id, {}).get("effect", ""))
	match effect:
		"plus_assault":
			return "Wonder (1 / run). Permanently +1 Assault per settlement."
		"builder_scale":
			return "Wonder (1 / run). +1 Blueprint slot and ×1.25 Builder scale."
		"hand_size":
			return "Wonder (1 / run). Permanently +1 hand size."
		"faith_burst":
			return "Wonder (1 / run). Immediate +25 Faith."
		"free_sci_level":
			return "Wonder (1 / run). Large Science bank toward your next Sci level."
		"support_free_slots":
			return "Wonder (1 / run). Builder and Missionary attach without using formation slots."
		"float_supports":
			return "Wonder (1 / run). Builder attaches without using a formation slot."
		"sci_cost_cut":
			return "Wonder (1 / run). Marks Science cost relief (stub flag)."
		"sci_gain_pct":
			return "Wonder (1 / run). +12% Science from victory rewards."
		"occupy_x2":
			return "Wonder (1 / run). Flags double occupy yields (stub for payout math)."
		"replace_troop":
			return "Wonder (1 / run). Adds one Melee and one Ranged to your deck."
		"parade_grounds":
			return "Wonder (1 / run). Parade Grounds combat rule (stub flag)."
		"theater_of_war":
			return "Wonder (1 / run). Theater of War combat rule (stub flag)."
		"safe_conduct":
			return "Wonder (1 / run). Safe Conduct rule (stub flag)."
		"christ_clutch":
			return "Wonder (1 / run). Clutch Faith rule (stub flag)."
		_:
			return "Unique Wonder — one per run. Dedicated shop row; rival skip not simulated yet."


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

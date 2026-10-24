class_name Formation
extends RefCounted
## Formation ranking — port of sim/era1_sim.py::best_formation (siegecraft wilds later).

const CombatTables := preload("res://rules/combat_tables.gd")

static var _best_rank: int = 0
static var _best_id: String = "none"
static var _best_sc: Array = []


static func best(combat_kinds: Array, tiers: Array, soft_cap: int) -> Dictionary:
	var n := combat_kinds.size()
	if n == 0:
		return {"form_id": "none", "rank": 0, "scoring": PackedInt32Array()}

	_best_rank = 0
	_best_id = "none"
	_best_sc = []

	var ct := _counts(combat_kinds)
	var idxs := {}
	for cls in CombatTables.classes():
		idxs[cls] = []
	for i in n:
		idxs[combat_kinds[i]].append(i)

	for cls in ct.keys():
		if int(ct[cls]) >= 5:
			_beat(10, "legion", _take(idxs, cls, 5))

	if n >= 5:
		var sc: Array = []
		var ok := true
		for i in mini(5, n):
			sc.append(i)
			if int(tiers[i]) < soft_cap:
				ok = false
				break
		if ok:
			_beat(9, "imperial_guard", sc)

	for cls in ct.keys():
		if int(ct[cls]) >= 4:
			_beat(8, "vanguard", _take(idxs, cls, 4))

	var all_four := true
	for cls in CombatTables.classes():
		if int(ct.get(cls, 0)) < 1:
			all_four = false
			break
	if all_four:
		var sc2: Array = []
		for cls in CombatTables.classes():
			sc2.append(_take(idxs, cls, 1)[0])
		_beat(7, "grand_army", sc2)

	var threes: Array = []
	var twos: Array = []
	for cls in ct.keys():
		if int(ct[cls]) >= 3:
			threes.append(cls)
		if int(ct[cls]) >= 2:
			twos.append(cls)
	for a in threes:
		for b in twos:
			if a == b and int(ct[a]) < 5:
				continue
			if a != b:
				_beat(6, "phalanx", _take(idxs, a, 3) + _take(idxs, b, 2))

	var present: Array = []
	for cls in CombatTables.classes():
		if int(ct.get(cls, 0)) >= 1:
			present.append(cls)
	if present.size() >= 3:
		var sc3: Array = []
		for i in n:
			if combat_kinds[i] in present:
				sc3.append(i)
		_beat(5, "combined_arms", sc3)

	var pair_cls: Array = []
	for cls in ct.keys():
		if int(ct[cls]) >= 2:
			pair_cls.append(cls)
	if pair_cls.size() >= 2:
		_beat(4, "battle_line", _take(idxs, pair_cls[0], 2) + _take(idxs, pair_cls[1], 2))

	for cls in ct.keys():
		var c: int = int(ct[cls])
		if c >= 3:
			_beat(3, "triple", _take(idxs, cls, 3))
		if c >= 2:
			_beat(2, "pair", _take(idxs, cls, 2))
		if c >= 1:
			_beat(1, "skirmish", _take(idxs, cls, 1))

	return {
		"form_id": _best_id,
		"rank": _best_rank,
		"scoring": _sorted_unique(_best_sc),
	}


static func _beat(rank: int, form_id: String, sc: Array) -> void:
	if rank > _best_rank:
		_best_rank = rank
		_best_id = form_id
		_best_sc = sc


static func _counts(kinds: Array) -> Dictionary:
	var ct := {}
	for k in kinds:
		ct[k] = int(ct.get(k, 0)) + 1
	return ct


static func _take(idxs: Dictionary, cls: String, need: int) -> Array:
	var src: Array = idxs[cls]
	var out: Array = []
	for i in mini(need, src.size()):
		out.append(src[i])
	return out


static func _sorted_unique(sc: Array) -> PackedInt32Array:
	var uniq: Dictionary = {}
	for i in sc:
		uniq[int(i)] = true
	var keys: Array = uniq.keys()
	keys.sort()
	var scoring := PackedInt32Array()
	for i in keys:
		scoring.append(int(i))
	return scoring

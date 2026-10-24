extends RefCounted
## Loads content/ancient_run.json once — catalogs & numbers for the run loop.


static var _data: Dictionary = {}


static func ensure_loaded() -> void:
	if not _data.is_empty():
		return
	var path := "res://content/ancient_run.json"
	var raw := FileAccess.get_file_as_string(path)
	assert(raw != "", "Missing %s" % path)
	var parsed: Variant = JSON.parse_string(raw)
	assert(typeof(parsed) == TYPE_DICTIONARY, "ancient_run.json must be object")
	_data = parsed


static func data() -> Dictionary:
	ensure_loaded()
	return _data


static func reward(key: String) -> int:
	ensure_loaded()
	return int(_data["rewards"][key])


static func pack_size() -> int:
	ensure_loaded()
	return int(_data["packs"]["size"])


static func science_offer_count() -> int:
	ensure_loaded()
	return int(_data["packs"]["science_offer_count"])


static func civic_offer_count() -> int:
	ensure_loaded()
	return int(_data["packs"]["civic_offer_count"])


static func pack_float(key: String) -> float:
	ensure_loaded()
	return float(_data["packs"][key])


static func pack_int(key: String) -> int:
	ensure_loaded()
	return int(_data["packs"][key])


static func rarity_bag_count(rarity: String) -> int:
	ensure_loaded()
	return int(_data["packs"]["rarity_bag"].get(rarity, 1))


static func science_cost(level: int) -> int:
	ensure_loaded()
	var costs: Array = _data["science_costs"]
	if level < 0 or level >= costs.size():
		return 99999
	return int(costs[level])


static func science_cost_count() -> int:
	ensure_loaded()
	return (_data["science_costs"] as Array).size()


static func unit_tier_cost(tier: int) -> int:
	ensure_loaded()
	return int(_data["unit_tier_costs"].get(str(tier), 18))


static func settlement() -> Dictionary:
	ensure_loaded()
	return _data["settlement"]


static func kind_mult(kind: String) -> float:
	ensure_loaded()
	return float(_data["settlement"]["kind_mult"].get(kind, 1.0))


static func starting_deck_counts() -> Dictionary:
	ensure_loaded()
	return _data["starting_deck"]


static func defaults() -> Dictionary:
	ensure_loaded()
	return _data["defaults"]


static func default_int(key: String) -> int:
	ensure_loaded()
	return int(_data["defaults"][key])


static func drills() -> Array:
	ensure_loaded()
	return _data["drills"]


static func progression() -> Array:
	ensure_loaded()
	return _data["progression"]


static func civics() -> Array:
	ensure_loaded()
	return _data["civics"]


static func rarity_weight(rarity: String) -> float:
	ensure_loaded()
	return float(_data["rarity_weights"].get(rarity, 1.0))


static func blueprints() -> Dictionary:
	ensure_loaded()
	return _data["blueprints"]


static func doctrines() -> Dictionary:
	ensure_loaded()
	return _data["doctrines"]


static func promotions() -> Dictionary:
	ensure_loaded()
	return _data["promotions"]


static func policy_commons() -> Array:
	ensure_loaded()
	return _data["policy_commons"]


static func catalog_rarity(table: Dictionary, id: String) -> String:
	return str(table[id]["rarity"])


static func catalog_cost(table: Dictionary, id: String) -> int:
	return int(table[id]["cost"])


static func civic_effect_int(key: String) -> int:
	ensure_loaded()
	return int(_data["civic_effects"][key])


static func era_name(era: int) -> String:
	ensure_loaded()
	return str(_data.get("eras", {}).get(str(era), "Era %d" % era))


static func max_era() -> int:
	ensure_loaded()
	return int(_data.get("max_era", 8))


static func income_mult(era: int, kind: String) -> float:
	ensure_loaded()
	if kind in ["gold", "faith"]:
		return float(_data["era_gold_faith_mult"].get(str(era), 1.0))
	return float(_data["era_income_mult"].get(str(era), 1.0))


static func midgame_bar_discount() -> float:
	ensure_loaded()
	return float(_data.get("midgame_bar_discount", 0.15))


static func breakthrough_era_min() -> int:
	ensure_loaded()
	return int(_data.get("breakthrough_era_min", 4))


static func industrial_era_min() -> int:
	ensure_loaded()
	return int(_data.get("industrial_era_min", 5))


static func industrial_assault_bonus() -> int:
	ensure_loaded()
	return int(_data.get("industrial_assault_bonus", 1))


static func industrial_toolkit_offers() -> Array:
	ensure_loaded()
	return _data.get("industrial_toolkit", [])


static func reload() -> void:
	## Drop cache so JSON edits apply (editor / tests).
	_data = {}
	ensure_loaded()

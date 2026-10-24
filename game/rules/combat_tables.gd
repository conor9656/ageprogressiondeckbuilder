class_name CombatTables
extends RefCounted
## Loads content/combat_tables.json once.


static var _data: Dictionary = {}


static func ensure_loaded() -> void:
	if not _data.is_empty():
		return
	var path := "res://content/combat_tables.json"
	var raw := FileAccess.get_file_as_string(path)
	assert(raw != "", "Missing %s" % path)
	var parsed: Variant = JSON.parse_string(raw)
	assert(typeof(parsed) == TYPE_DICTIONARY, "combat_tables.json must be object")
	_data = parsed


static func data() -> Dictionary:
	ensure_loaded()
	return _data


static func unit_might(kind: String, tier: int) -> int:
	ensure_loaded()
	var row: Array = _data["unit_might"][kind]
	return int(row[tier])


static func unit_mom(kind: String, tier: int) -> int:
	ensure_loaded()
	var row: Array = _data["unit_mom"][kind]
	return int(row[tier])


static func form_base(form_id: String) -> Vector2i:
	ensure_loaded()
	var row: Array = _data["form_base"][form_id]
	return Vector2i(int(row[0]), int(row[1]))


static func form_level_bonus(form_id: String) -> Vector2i:
	ensure_loaded()
	if not _data["form_level_bonus"].has(form_id):
		return Vector2i.ZERO
	var row: Array = _data["form_level_bonus"][form_id]
	return Vector2i(int(row[0]), int(row[1]))


static func soft_cap(era: int) -> int:
	ensure_loaded()
	return int(_data["era_soft_cap"][str(era)])


static func era_base_defence(era: int) -> int:
	ensure_loaded()
	return int(_data["era_base_defence"][str(era)])


static func tech_literacy() -> float:
	ensure_loaded()
	return float(_data["tech_literacy_per_sci"])


static func age_power() -> float:
	ensure_loaded()
	return float(_data["age_power_might_per_sci"])


static func age_power_era_min() -> int:
	ensure_loaded()
	return int(_data.get("age_power_era_min", 4))


static func walls_damage_mult() -> float:
	ensure_loaded()
	return float(_data.get("walls_damage_mult", 0.5))


static func garrison_mods() -> Dictionary:
	ensure_loaded()
	return _data.get("garrison_mods", {})


static func support_charge_gold(new_count: int) -> int:
	ensure_loaded()
	return int(_data["support_charge_gold"].get(str(new_count), 0))


static func support_charge_sci_chance() -> float:
	ensure_loaded()
	return float(_data["support_charge_sci_chance"])


static func classes() -> Array:
	ensure_loaded()
	return _data["classes"]


static func support_charge_cap() -> int:
	ensure_loaded()
	return int(_data["support_charge_cap"])


static func line_era_min() -> int:
	ensure_loaded()
	return int(_data.get("line_era_min", 5))


static func line_era_flat_mom() -> int:
	ensure_loaded()
	return int(_data.get("line_era_flat_mom", 2))


static func line_era_mom_per_form_lv() -> int:
	ensure_loaded()
	return int(_data.get("line_era_mom_per_form_lv", 1))


static func line_era_mom_form_cap() -> int:
	ensure_loaded()
	return int(_data.get("line_era_mom_form_cap", 3))


static func line_era_forms() -> Array:
	ensure_loaded()
	return _data.get("line_era_forms", [])


static func reload() -> void:
	_data = {}
	ensure_loaded()

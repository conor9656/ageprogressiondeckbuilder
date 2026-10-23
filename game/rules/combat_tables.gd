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


static func tech_literacy() -> float:
	ensure_loaded()
	return float(_data["tech_literacy_per_sci"])


static func age_power() -> float:
	ensure_loaded()
	return float(_data["age_power_might_per_sci"])


static func classes() -> Array:
	ensure_loaded()
	return _data["classes"]


static func support_charge_cap() -> int:
	ensure_loaded()
	return int(_data["support_charge_cap"])

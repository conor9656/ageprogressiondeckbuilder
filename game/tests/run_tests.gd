extends SceneTree
## Headless: bash scripts/run_game_tests.sh

const AgesRules := preload("res://rules/ages_rules.gd")
const SupportCharges := preload("res://rules/support_charges.gd")
const CombatTables := preload("res://rules/combat_tables.gd")


func _initialize() -> void:
	CombatTables.ensure_loaded()
	var failed := 0
	failed += _check("smoke_rules_tag", _test_smoke_rules_tag())
	failed += _check("support_charges_basic", _test_support_charges())
	failed += _run_fixture_file("res://tests/fixtures/combat_core.json")

	if failed == 0:
		print("AGES_TESTS_OK failed=0")
		quit(0)
	else:
		print("AGES_TESTS_FAIL failed=%d" % failed)
		quit(1)


func _check(name: String, ok: bool) -> int:
	if ok:
		print("PASS %s" % name)
		return 0
	print("FAIL %s" % name)
	return 1


func _test_smoke_rules_tag() -> bool:
	return AgesRules.engine_tag().begins_with("ages-rules/")


func _test_support_charges() -> bool:
	var sc: RefCounted = SupportCharges.new()
	if not sc.can_use_builder():
		return false
	sc.spend_builder()
	if sc.can_use_builder():
		return false
	sc.refill()
	if sc.builder_left != 1:
		return false
	if not sc.can_upgrade("B", 2):
		return false
	sc.upgrade("B")
	if sc.builder_max != 2:
		return false
	if not SupportCharges.attach_ok(4, true, false, false, false):
		return false
	if SupportCharges.attach_ok(5, true, false, false, false):
		return false
	if not SupportCharges.attach_ok(5, true, false, true, false):
		return false
	return true


func _run_fixture_file(path: String) -> int:
	var raw := FileAccess.get_file_as_string(path)
	if raw == "":
		print("FAIL fixtures_missing %s" % path)
		return 1
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		print("FAIL fixtures_parse")
		return 1
	var fixtures: Array = parsed["fixtures"]
	var failed := 0
	for fx in fixtures:
		var name: String = fx["name"]
		var kinds: Array = fx["kinds"]
		var opts := {
			"era": int(fx.get("era", 1)),
			"sci_level": int(fx.get("sci_level", 0)),
			"tiers": fx.get("tiers", {}),
			"walls": bool(fx.get("walls", false)),
			"garrison": str(fx.get("garrison", "militia")),
		}
		var got: Dictionary = AgesRules.evaluate_kinds(kinds, opts)
		var exp: Dictionary = fx["expect"]
		var ok := true
		if str(got["form"]) != str(exp["form"]):
			ok = false
			print("  form got=%s expect=%s" % [got["form"], exp["form"]])
		if int(got["rank"]) != int(exp["rank"]):
			ok = false
			print("  rank got=%s expect=%s" % [got["rank"], exp["rank"]])
		if int(got["damage"]) != int(exp["damage"]):
			ok = false
			print("  damage got=%s expect=%s" % [got["damage"], exp["damage"]])
		if abs(float(got["might"]) - float(exp["might"])) > 0.01:
			ok = false
			print("  might got=%s expect=%s" % [got["might"], exp["might"]])
		if abs(float(got["mom"]) - float(exp["mom"])) > 0.01:
			ok = false
			print("  mom got=%s expect=%s" % [got["mom"], exp["mom"]])
		failed += _check("fixture:%s" % name, ok)
	return failed

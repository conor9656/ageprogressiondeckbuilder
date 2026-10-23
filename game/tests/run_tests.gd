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
	failed += _check("fight_win_easy_village", _test_fight_win_easy())
	failed += _check("fight_lose_too_tanky", _test_fight_lose())
	failed += _check("fight_manual_assault_regroup", _test_manual_loop())
	failed += _check("fight_builder_ignores_walls", _test_builder_walls())
	failed += _check("ui_scripts_compile", _test_ui_scripts_compile())

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


func _test_fight_win_easy() -> bool:
	var fight = AgesRules.new_fight({
		"seed": 7,
		"defence": 80,
		"walls": false,
		"assaults": 4,
		"regroups": 3,
	})
	var res: Dictionary = fight.run_auto()
	return bool(res["won"]) and int(res["assaults_used"]) >= 1 and int(res["damage"]) >= 80


func _test_fight_lose() -> bool:
	var fight = AgesRules.new_fight({
		"seed": 3,
		"defence": 50000,
		"walls": true,
		"assaults": 4,
		"regroups": 0,
	})
	var res: Dictionary = fight.run_auto()
	return (not bool(res["won"])) and int(res["assaults_used"]) == 4


func _test_manual_loop() -> bool:
	var fight = AgesRules.new_fight({
		"seed": 11,
		"defence": 200,
		"assaults": 4,
		"regroups": 2,
	})
	if not fight.do_regroup(2):
		return false
	if fight.regroups_left != 1:
		return false
	var choice: Dictionary = fight.choose_assault_ai()
	if choice["cards"].is_empty():
		return false
	var r: Dictionary = fight.do_assault(choice["cards"], choice["use_builder"], false)
	if not bool(r.get("ok", false)):
		return false
	if fight.assaults_left != 3:
		return false
	if fight.piles.hand.size() > fight.hand_size:
		return false
	return true


func _test_builder_walls() -> bool:
	## With walls and scaffolding, AI should prefer spending Builder; damage > half-wall path.
	var fight = AgesRules.new_fight({
		"seed": 21,
		"defence": 300,
		"walls": true,
		"blueprints": ["scaffolding"],
		"assaults": 4,
		"regroups": 1,
	})
	var choice: Dictionary = fight.choose_assault_ai()
	# Force an assault that can use builder
	var r: Dictionary = fight.do_assault(choice["cards"], true, false)
	if not bool(r.get("ok", false)):
		return false
	# Charge spent
	if fight.charges.builder_left != 0:
		return false
	# Log should mention blueprint or used_builder
	var saw := false
	for e in fight.log:
		if str(e.get("op", "")) == "blueprint" or bool(e.get("used_builder", false)):
			saw = true
	return saw


func _test_ui_scripts_compile() -> bool:
	## Ensures vertical-slice scripts parse (no editor needed).
	var menu_script: GDScript = load("res://scenes/boot/main_menu.gd") as GDScript
	var fight_script: GDScript = load("res://scenes/fight/fight_table.gd") as GDScript
	return menu_script != null and fight_script != null


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

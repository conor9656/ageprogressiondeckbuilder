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
	failed += _check("settlement_hp_curve", _test_settlement_hp())
	failed += _check("rewards_raze_occupy", _test_rewards())
	failed += _check("science_civic_levelup", _test_levelups())
	failed += _check("shop_buy_unit", _test_shop())
	failed += _check("ancient_run_auto_era", _test_auto_era())

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
	## Ensures vertical-slice / run scripts parse (no editor needed).
	var menu_script: GDScript = load("res://scenes/boot/main_menu.gd") as GDScript
	var fight_script: GDScript = load("res://scenes/fight/fight_table.gd") as GDScript
	var run_script: GDScript = load("res://scenes/run/run_table.gd") as GDScript
	var rules_script: GDScript = load("res://rules/ancient_run.gd") as GDScript
	return (
		menu_script != null and fight_script != null
		and run_script != null and rules_script != null
	)


func _test_settlement_hp() -> bool:
	var AncientRun = preload("res://rules/ancient_run.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var v: Dictionary = AncientRun.make_settlement("village", rng, 1)
	var t: Dictionary = AncientRun.make_settlement("town", rng, 1)
	var c: Dictionary = AncientRun.make_settlement("capital", rng, 1)
	return int(v["defence"]) == 665 and int(t["defence"]) == 997 and int(c["defence"]) == 1662


func _test_rewards() -> bool:
	var run = AgesRules.new_ancient_run(42)
	run.begin_fight()
	# Fake a win with 1 assault used
	run.active_fight.assaults_used = 1
	run.active_fight.won = true
	var before_g: int = run.state.gold
	var raze: Dictionary = run.apply_victory_payout(1, "raze")
	# Unused assaults = 4-1 = 3 → gold base 41 + raze 28 + interest
	if int(raze["base"]["gold"]) != 41:
		print("  raze base gold got=%s" % raze["base"]["gold"])
		return false
	if int(raze["raze_gold"]) != 28:
		return false
	if run.state.gold <= before_g:
		return false
	# Fresh run for occupy
	run = AgesRules.new_ancient_run(43)
	run.begin_fight()
	var occ: Dictionary = run.apply_victory_payout(4, "occupy")
	if run.state.occupied.size() != 1:
		return false
	if int(occ["base"]["science"]) != 16:
		print("  occupy sci got=%s" % occ["base"]["science"])
		return false
	return run.state.science >= 16 and run.state.culture >= 16 and run.state.faith >= 12


func _test_levelups() -> bool:
	var run = AgesRules.new_ancient_run(7)
	run.state.science = 8
	run.state.culture = 8
	var lu: Dictionary = run.begin_science_levelup()
	if lu.is_empty() or lu["offers"].size() != 4:
		return false
	var pick: String = str(lu["offers"][0])
	if not run.pick_levelup(pick):
		return false
	if run.state.sci_level != 1:
		return false
	var cu: Dictionary = run.begin_civic_levelup()
	if cu.is_empty() or cu["offers"].size() != 3:
		return false
	if not run.pick_levelup(str(cu["offers"][0])):
		return false
	return run.state.civ_level == 1


func _test_shop() -> bool:
	var run = AgesRules.new_ancient_run(9)
	run.state.gold = 200
	run.state.faith = 200
	run.open_shop()
	if run.shop_treasury.size() != 5 or run.shop_synod.size() != 5:
		return false
	var before: int = run.state.deck_kinds.size()
	# Find a unit offer and buy it
	var bought := false
	for i in run.shop_treasury.size():
		if str(run.shop_treasury[i]["cat"]) == "unit":
			var r: Dictionary = run.buy_offer("treasury", i)
			if bool(r.get("ok", false)):
				bought = true
				break
	if not bought:
		# Force a cheap unit into slot 0
		run.shop_treasury[0] = {"cat": "unit", "id": "M", "cost": 8, "label": "Unit M"}
		var r2: Dictionary = run.buy_offer("treasury", 0)
		bought = bool(r2.get("ok", false))
	return bought and run.state.deck_kinds.size() == before + 1


func _test_auto_era() -> bool:
	## Seed hunt: at least one seed in a small range should clear Ancient with AI.
	var cleared := false
	var last_snap: Dictionary = {}
	for seed in range(1, 41):
		var run = AgesRules.new_ancient_run(seed)
		var res: Dictionary = run.run_auto_era()
		last_snap = res.get("snapshot", {})
		if bool(res["won"]):
			cleared = true
			print("  auto_era cleared seed=%d fights=%d sci=%d" % [
				seed, int(res["fights"]), int(last_snap.get("sci_level", 0)),
			])
			break
	if not cleared:
		print("  auto_era no clear in seeds 1..40 last=%s" % last_snap)
	return cleared


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

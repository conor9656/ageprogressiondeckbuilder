extends SceneTree
## Headless test entry: godot4 --headless --path game -s res://tests/run_tests.gd
## Exit 0 = all pass; non-zero = failures.

const AgesRulesScript := preload("res://rules/ages_rules.gd")


func _initialize() -> void:
	var failed := 0
	failed += _check("smoke_rules_tag", _test_smoke_rules_tag())
	# W1 ports will append checks here (formations, damage, charges, parity).

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
	var tag: String = AgesRulesScript.engine_tag()
	return tag.begins_with("ages-rules/")

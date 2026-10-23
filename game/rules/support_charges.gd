class_name SupportCharges
extends RefCounted
## Battlefield Builder/Missionary charges (not deck RNG).

const CombatTables := preload("res://rules/combat_tables.gd")

var builder_max: int = 1
var missionary_max: int = 1
var builder_left: int = 1
var missionary_left: int = 1


func refill() -> void:
	builder_left = builder_max
	missionary_left = missionary_max


func can_use_builder() -> bool:
	return builder_left > 0


func can_use_missionary() -> bool:
	return missionary_left > 0


func spend_builder() -> bool:
	if builder_left <= 0:
		return false
	builder_left -= 1
	return true


func spend_missionary() -> bool:
	if missionary_left <= 0:
		return false
	missionary_left -= 1
	return true


func can_upgrade(kind: String, sci_level: int) -> bool:
	var cur := builder_max if kind == "B" else missionary_max
	if cur >= CombatTables.support_charge_cap():
		return false
	return sci_level >= 2 * cur


func upgrade(kind: String) -> bool:
	var cap: int = CombatTables.support_charge_cap()
	if kind == "B":
		if builder_max >= cap:
			return false
		builder_max += 1
		builder_left = builder_max
		return true
	if missionary_max >= cap:
		return false
	missionary_max += 1
	missionary_left = missionary_max
	return true


static func attach_ok(combat_n: int, use_b: bool, use_y: bool, free_b: bool, free_y: bool) -> bool:
	if combat_n > 5 or combat_n < 1:
		return false
	var slots := combat_n
	if use_b and not free_b:
		slots += 1
	if use_y and not free_y:
		slots += 1
	var total := combat_n + (1 if use_b else 0) + (1 if use_y else 0)
	if slots > 5:
		return false
	if total > 6:
		return false
	if total > 5 and not ((use_b and free_b) or (use_y and free_y)):
		return false
	return true

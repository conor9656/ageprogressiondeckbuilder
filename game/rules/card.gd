class_name AgesCard
extends RefCounted
## Minimal combat/support card for rules evaluation.


var kind: String = "M"  ## M R C S B Y
var cid: int = 0
var bonus_might: int = 0
var bonus_mom: int = 0
var might_mult: float = 1.0
var banner_might: int = 0
var score_twice: bool = false
var plated: bool = false
var battlefield: bool = false


func _init(p_kind: String = "M", p_cid: int = 0) -> void:
	kind = p_kind
	cid = p_cid


func is_combat() -> bool:
	return kind in ["M", "R", "C", "S"]

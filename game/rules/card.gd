class_name AgesCard
extends RefCounted
## Combat card for rules evaluation + per-card Editions/Promotions.


var kind: String = "M"  ## M R C S B Y
var cid: int = 0
var edition: String = "standard"
var bonus_might: int = 0
var bonus_mom: int = 0
var might_mult: float = 1.0
var banner_might: int = 0
var score_twice: bool = false
var plated: bool = false
var battlefield: bool = false
var on_score_sci_pct: float = 0.0
var on_score_faith_pct: float = 0.0
var on_score_gold: int = 0
var on_score_faith: int = 0
var promotions: Array = []  ## ids applied (for UI); stats are baked


func _init(p_kind: String = "M", p_cid: int = 0) -> void:
	kind = p_kind
	cid = p_cid


func is_combat() -> bool:
	return kind in ["M", "R", "C", "S"]


func to_dict() -> Dictionary:
	return {
		"kind": kind,
		"cid": cid,
		"edition": edition,
		"bonus_might": bonus_might,
		"bonus_mom": bonus_mom,
		"might_mult": might_mult,
		"banner_might": banner_might,
		"score_twice": score_twice,
		"plated": plated,
		"battlefield": battlefield,
		"on_score_sci_pct": on_score_sci_pct,
		"on_score_faith_pct": on_score_faith_pct,
		"on_score_gold": on_score_gold,
		"on_score_faith": on_score_faith,
		"promotions": promotions.duplicate(),
	}


static func from_dict(d: Dictionary) -> RefCounted:
	var c = new(str(d.get("kind", "M")), int(d.get("cid", 0)))
	c.edition = str(d.get("edition", "standard"))
	c.bonus_might = int(d.get("bonus_might", 0))
	c.bonus_mom = int(d.get("bonus_mom", 0))
	c.might_mult = float(d.get("might_mult", 1.0))
	c.banner_might = int(d.get("banner_might", 0))
	c.score_twice = bool(d.get("score_twice", false))
	c.plated = bool(d.get("plated", false))
	c.battlefield = bool(d.get("battlefield", false))
	c.on_score_sci_pct = float(d.get("on_score_sci_pct", 0.0))
	c.on_score_faith_pct = float(d.get("on_score_faith_pct", 0.0))
	c.on_score_gold = int(d.get("on_score_gold", 0))
	c.on_score_faith = int(d.get("on_score_faith", 0))
	c.promotions = d.get("promotions", []).duplicate()
	return c


func to_combat_mod() -> Dictionary:
	return {
		"bonus_might": bonus_might,
		"bonus_mom": bonus_mom,
		"might_mult": might_mult,
		"banner_might": banner_might,
		"score_twice": score_twice,
		"plated": plated,
		"on_score_sci_pct": on_score_sci_pct,
		"on_score_faith_pct": on_score_faith_pct,
		"on_score_gold": on_score_gold,
		"on_score_faith": on_score_faith,
		"cid": cid,
		"edition": edition,
	}


func short_label() -> String:
	var names := {"M": "Melee", "R": "Ranged", "C": "Cavalry", "S": "Siege"}
	var bits: PackedStringArray = PackedStringArray()
	bits.append("%s#%d" % [names.get(kind, kind), cid])
	if edition != "standard":
		bits.append(edition)
	for p in promotions:
		bits.append(str(p))
	if bonus_might != 0:
		bits.append("%+dMight" % bonus_might)
	if bonus_mom != 0:
		bits.append("%+dMom" % bonus_mom)
	if might_mult > 1.001:
		bits.append("×%.2f" % might_mult)
	if score_twice:
		bits.append("2×score")
	if banner_might > 0:
		bits.append("banner+%d" % banner_might)
	return " ".join(bits)


func apply_edition(ed: String) -> void:
	edition = ed
	match ed:
		"gilded":
			bonus_might += 3
		"berserker":
			bonus_might += 4
		"hawk_eyed":
			bonus_mom += 2
		"plated":
			bonus_might += 3
			plated = true
		"scholarly":
			on_score_sci_pct += 0.10
		"devout":
			on_score_faith_pct += 0.10
		"mercantile":
			on_score_gold += 5
		"savant":
			on_score_sci_pct += 0.20
		"zealot":
			on_score_faith_pct += 0.20
		_:
			pass


func apply_promotion(pid: String, effect: String) -> void:
	if not promotions.has(pid):
		promotions.append(pid)
	match effect:
		"might5":
			bonus_might += 5
		"mom2":
			bonus_mom += 2
		"might3_mom1":
			bonus_might += 3
			bonus_mom += 1
		"banner12":
			banner_might += 12
		"sci10":
			on_score_sci_pct += 0.10
		"gold8":
			on_score_gold += 8
		"faith8":
			on_score_faith += 8
		"mult175":
			might_mult = maxf(might_mult, 1.75)
		"score_twice":
			score_twice = true
		_:
			pass

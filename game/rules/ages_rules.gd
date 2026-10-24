class_name AgesRules
extends RefCounted
## Pure rules entry (no scene tree). Port from sim/era1_sim.py during W1.
## UI (W2+) should call into this module — never own combat math.

const VERSION := "0.1.0-w1-scaffold"


static func engine_tag() -> String:
	return "ages-rules/%s" % VERSION

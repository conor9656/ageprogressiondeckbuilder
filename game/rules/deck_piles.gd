class_name DeckPiles
extends RefCounted
## Draw / hand / discard with reshuffle. Deterministic via RandomNumberGenerator.


var draw: Array = []  ## Array[AgesCard]
var hand: Array = []
var discard: Array = []
var rng: RandomNumberGenerator


func _init(p_rng: RandomNumberGenerator = null) -> void:
	rng = p_rng if p_rng != null else RandomNumberGenerator.new()


func load_deck(cards: Array) -> void:
	draw = cards.duplicate()
	hand.clear()
	discard.clear()
	shuffle_draw()


func shuffle_draw() -> void:
	if draw.is_empty() and not discard.is_empty():
		draw = discard.duplicate()
		discard.clear()
	# Fisher–Yates
	for i in range(draw.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = draw[i]
		draw[i] = draw[j]
		draw[j] = tmp


func refill_hand(hand_size: int) -> void:
	while hand.size() < hand_size:
		if draw.is_empty():
			shuffle_draw()
		if draw.is_empty():
			break
		hand.append(draw.pop_back())


func discard_from_hand(cards: Array) -> void:
	for c in cards:
		var idx := hand.find(c)
		if idx >= 0:
			hand.remove_at(idx)
			if not bool(c.battlefield):
				discard.append(c)

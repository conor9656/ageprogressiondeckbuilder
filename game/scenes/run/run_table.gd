extends Control
## Greybox Ancient era — hub → fight → raze/occupy → Sci/Civ → shop → next.
## Open game/ in Godot 4.7.2 and press Play.

const AgesRules := preload("res://rules/ages_rules.gd")
const CombatTables := preload("res://rules/combat_tables.gd")

enum Phase { HUB, FIGHT, POST, LEVELUP, SHOP, END }

var run: RefCounted
var phase: int = Phase.HUB

# Shared chrome
var _root: VBoxContainer
var _lbl_banner: Label
var _lbl_resources: Label
var _panel: VBoxContainer
var _log: RichTextLabel

# Fight state (mirrors fight_table)
var _selected: Dictionary = {}
var _card_buttons: Dictionary = {}
var _hand_row: HBoxContainer
var _lbl_defence: Label
var _lbl_preview: Label
var _chk_builder: CheckBox


func _ready() -> void:
	CombatTables.ensure_loaded()
	_build_chrome()
	_new_run()


func _unhandled_input(event: InputEvent) -> void:
	if phase != Phase.FIGHT:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A:
				_on_assault()
			KEY_R:
				_on_regroup()
			KEY_ESCAPE:
				_clear_selection()
			KEY_H:
				_on_hint()


func _new_run() -> void:
	run = AgesRules.new_ancient_run(int(Time.get_unix_time_from_system()) % 100000)
	phase = Phase.HUB
	_log.clear()
	_append("[b]Ancient era[/b] — conquer Village → Town → Capital.")
	_show_hub()


func _build_chrome() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("1a2220")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 10)
	margin.add_child(_root)

	_lbl_banner = Label.new()
	_lbl_banner.add_theme_font_size_override("font_size", 26)
	_lbl_banner.add_theme_color_override("font_color", Color("e8d5a3"))
	_root.add_child(_lbl_banner)

	_lbl_resources = Label.new()
	_lbl_resources.add_theme_color_override("font_color", Color("a8c5b5"))
	_root.add_child(_lbl_resources)

	_panel = VBoxContainer.new()
	_panel.add_theme_constant_override("separation", 10)
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(_panel)

	var log_l := Label.new()
	log_l.text = "Log"
	log_l.add_theme_color_override("font_color", Color("cfcfcf"))
	_root.add_child(log_l)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.custom_minimum_size = Vector2(0, 140)
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(_log)


func _clear_panel() -> void:
	for c in _panel.get_children():
		c.queue_free()
	_hand_row = null
	_lbl_defence = null
	_lbl_preview = null
	_chk_builder = null
	_card_buttons.clear()


func _refresh_resources() -> void:
	var s = run.state
	_lbl_resources.text = (
		"Gold %d   Sci %d   Cul %d   Faith %d   |   SciLv %d  CivLv %d   Deck %d   Occ %d"
		% [s.gold, s.science, s.culture, s.faith, s.sci_level, s.civ_level, s.deck_kinds.size(), s.occupied.size()]
	)


## --- HUB ---------------------------------------------------------------------

func _show_hub() -> void:
	phase = Phase.HUB
	_clear_panel()
	_refresh_resources()
	var sett: Dictionary = run.current_settlement
	_lbl_banner.text = "AGES — Ancient hub  (%d/3)" % (run.state.settlement_index + 1)

	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var wall := " · Walls" if bool(sett.get("walls", false)) else ""
	info.text = "Next: %s — Defence %d%s · Garrison %s · City type %s" % [
		str(sett["kind"]).capitalize(), int(sett["defence"]), wall,
		str(sett["garrison"]), str(sett["city_type"]),
	]
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", Color("f2f2f2"))
	_panel.add_child(info)

	var tip := Label.new()
	tip.text = "Win the fight, then choose Raze or Occupy, pick Science/Civics, shop, march on."
	tip.add_theme_color_override("font_color", Color("888888"))
	_panel.add_child(tip)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_panel.add_child(row)

	var btn := Button.new()
	btn.text = "March to fight"
	btn.custom_minimum_size = Vector2(200, 44)
	btn.pressed.connect(_enter_fight)
	row.add_child(btn)

	var restart := Button.new()
	restart.text = "New run"
	restart.pressed.connect(_new_run)
	row.add_child(restart)


## --- FIGHT -------------------------------------------------------------------

func _enter_fight() -> void:
	phase = Phase.FIGHT
	_selected.clear()
	run.begin_fight()
	_show_fight()
	_append("Fight — %s (Defence %d)." % [
		str(run.current_settlement["kind"]).capitalize(),
		int(run.current_settlement["defence"]),
	])


func _show_fight() -> void:
	_clear_panel()
	_refresh_resources()
	var fight = run.active_fight
	_lbl_banner.text = "Fight — %s" % str(run.current_settlement["kind"]).capitalize()

	_lbl_defence = Label.new()
	_lbl_defence.add_theme_font_size_override("font_size", 20)
	_lbl_defence.add_theme_color_override("font_color", Color("f2f2f2"))
	_panel.add_child(_lbl_defence)

	var res := Label.new()
	res.name = "FightRes"
	res.add_theme_color_override("font_color", Color("a8c5b5"))
	_panel.add_child(res)

	_lbl_preview = Label.new()
	_lbl_preview.add_theme_color_override("font_color", Color("9ec9ff"))
	_panel.add_child(_lbl_preview)

	var hand_l := Label.new()
	hand_l.text = "Hand (click to select) — A Assault · R Regroup selected only · Esc clear · H hint"
	hand_l.add_theme_color_override("font_color", Color("cfcfcf"))
	_panel.add_child(hand_l)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 110)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.add_child(scroll)
	_hand_row = HBoxContainer.new()
	_hand_row.add_theme_constant_override("separation", 8)
	scroll.add_child(_hand_row)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	_panel.add_child(actions)

	var b_a := Button.new()
	b_a.text = "Assault (A)"
	b_a.custom_minimum_size = Vector2(130, 40)
	b_a.pressed.connect(_on_assault)
	actions.add_child(b_a)

	var b_r := Button.new()
	b_r.text = "Regroup (R)"
	b_r.pressed.connect(_on_regroup)
	actions.add_child(b_r)

	var b_c := Button.new()
	b_c.text = "Clear"
	b_c.pressed.connect(_clear_selection)
	actions.add_child(b_c)

	var b_h := Button.new()
	b_h.text = "Hint"
	b_h.pressed.connect(_on_hint)
	actions.add_child(b_h)

	_chk_builder = CheckBox.new()
	_chk_builder.text = "Use Builder"
	_chk_builder.button_pressed = true
	_chk_builder.toggled.connect(func(_v): _update_preview())
	actions.add_child(_chk_builder)

	_refresh_fight()


func _refresh_fight() -> void:
	var fight = run.active_fight
	if fight == null or _lbl_defence == null:
		return
	var wall := " · Walls" if fight.walls and not fight.walls_removed else ""
	_lbl_defence.text = "Defence %d / %d%s" % [maxi(0, fight.defence_left), fight.defence, wall]
	var res: Label = _panel.get_node_or_null("FightRes") as Label
	if res:
		res.text = "Assaults %d   Regroups %d   Builder %d   Hand %d/%d" % [
			fight.assaults_left, fight.regroups_left, fight.charges.builder_left,
			fight.piles.hand.size(), fight.hand_size,
		]
	_rebuild_hand()
	_update_preview()
	_chk_builder.disabled = not fight.charges.can_use_builder()
	if not fight.charges.can_use_builder():
		_chk_builder.button_pressed = false


func _rebuild_hand() -> void:
	if _hand_row == null:
		return
	for c in _hand_row.get_children():
		c.queue_free()
	_card_buttons.clear()
	var fight = run.active_fight
	var alive: Dictionary = {}
	for card in fight.piles.hand:
		alive[card.get_instance_id()] = true
	for id in _selected.keys():
		if not alive.has(id):
			_selected.erase(id)
	for card in fight.piles.hand:
		var id: int = card.get_instance_id()
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(96, 96)
		btn.toggle_mode = true
		btn.button_pressed = _selected.has(id)
		var names := {"M": "Melee", "R": "Ranged", "C": "Cavalry", "S": "Siege"}
		btn.text = "%s\nT%d" % [names.get(card.kind, card.kind), int(fight.tiers.get(card.kind, 1))]
		btn.toggled.connect(_on_card_toggled.bind(id))
		_style_card(btn, card.kind, btn.button_pressed)
		_hand_row.add_child(btn)
		_card_buttons[id] = btn


func _style_card(btn: Button, kind: String, selected: bool) -> void:
	var colors := {
		"M": Color("c45c4a"), "R": Color("4a8fc4"), "C": Color("c4a24a"), "S": Color("7a7a7a"),
	}
	var base: Color = colors.get(kind, Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = base.darkened(0.35 if not selected else 0.1)
	style.border_color = Color("e8d5a3") if selected else base.lightened(0.2)
	style.set_border_width_all(3 if selected else 1)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_color_override("font_color", Color.WHITE)


func _on_card_toggled(pressed: bool, id: int) -> void:
	if pressed:
		if _selected_combat_count() >= 5 and not _selected.has(id):
			if _card_buttons.has(id):
				_card_buttons[id].set_pressed_no_signal(false)
			return
		_selected[id] = true
	else:
		_selected.erase(id)
	if _card_buttons.has(id):
		var card = _find_card(id)
		if card:
			_style_card(_card_buttons[id], card.kind, pressed)
	_update_preview()


func _selected_combat_count() -> int:
	var n := 0
	for id in _selected.keys():
		var c = _find_card(id)
		if c and c.is_combat():
			n += 1
	return n


func _find_card(id: int) -> Variant:
	for c in run.active_fight.piles.hand:
		if c.get_instance_id() == id:
			return c
	return null


func _selected_cards() -> Array:
	var out: Array = []
	for c in run.active_fight.piles.hand:
		if _selected.has(c.get_instance_id()):
			out.append(c)
	return out


func _clear_selection() -> void:
	_selected.clear()
	_rebuild_hand()
	_update_preview()


func _update_preview() -> void:
	if _lbl_preview == null or run.active_fight == null:
		return
	var cards := _selected_cards()
	if cards.is_empty():
		_lbl_preview.text = "Preview: select 1–5 cards…"
		return
	var kinds: Array = []
	for c in cards:
		kinds.append(c.kind)
	var fight = run.active_fight
	var use_b: bool = _chk_builder.button_pressed and fight.charges.can_use_builder()
	var opts_ignore: bool = fight.ignore_walls_next
	var walls_gone: bool = fight.walls_removed
	if use_b and not fight.blueprints.is_empty():
		var bp0: String = str(fight.blueprints[0])
		if bp0 in ["scaffolding", "ignore_walls_next"]:
			opts_ignore = true
		if bp0 in ["siege_tower", "remove_walls"]:
			walls_gone = true
	var ev: Dictionary = AgesRules.evaluate_kinds(kinds, {
		"era": fight.era, "sci_level": fight.sci_level, "tiers": fight.tiers,
		"walls": fight.walls, "garrison": fight.garrison,
		"walls_removed": walls_gone, "ignore_walls": opts_ignore,
	})
	_lbl_preview.text = "Preview: %s (rank %d) → %d damage%s" % [
		ev["form"], int(ev["rank"]), int(ev["damage"]), " + Builder" if use_b else "",
	]


func _on_assault() -> void:
	var fight = run.active_fight
	if fight == null or fight.is_over():
		return
	var cards := _selected_cards()
	if cards.is_empty():
		_append("[i]Select cards first.[/i]")
		return
	var use_b: bool = _chk_builder.button_pressed and fight.charges.can_use_builder()
	var r: Dictionary = fight.do_assault(cards, use_b, false)
	if not bool(r.get("ok", false)):
		_append("[color=#ff8888]Assault failed.[/color]")
		return
	var entry: Dictionary = r["entry"]
	_append("Assault — %s for %d · left %d" % [entry["form"], int(entry["dmg"]), int(entry["left"])])
	_selected.clear()
	_refresh_fight()
	if fight.is_over():
		if fight.won:
			_append("[color=#8dffb0]Settlement fallen.[/color]")
			_show_post()
		else:
			_append("[color=#ff8d8d]Assaults exhausted — run lost.[/color]")
			run.mark_lost()
			_show_end(false)


func _on_regroup() -> void:
	var fight = run.active_fight
	if fight == null or fight.is_over():
		return
	var cards := _selected_cards()
	if cards.is_empty():
		_append("[i]Select 1–5 cards to discard, then Regroup. Unselected cards stay.[/i]")
		return
	if cards.size() > 5:
		_append("[i]Regroup discards at most 5 cards.[/i]")
		return
	if not fight.do_regroup(cards):
		_append("[i]Regroup failed (none left, or bad selection).[/i]")
		return
	_append("Regroup — discarded %d, kept the rest. %d left" % [cards.size(), fight.regroups_left])
	_selected.clear()
	_refresh_fight()


func _on_hint() -> void:
	var fight = run.active_fight
	if fight == null or fight.is_over():
		return
	var choice: Dictionary = fight.choose_assault_ai()
	_selected.clear()
	for c in choice["cards"]:
		_selected[c.get_instance_id()] = true
	_chk_builder.button_pressed = bool(choice.get("use_builder", false)) and fight.charges.can_use_builder()
	_rebuild_hand()
	_update_preview()
	_append("[i]Hint selected %d cards.[/i]" % choice["cards"].size())


## --- POST (raze / occupy) ----------------------------------------------------

func _show_post() -> void:
	phase = Phase.POST
	_clear_panel()
	_refresh_resources()
	_lbl_banner.text = "Victory — %s" % str(run.current_settlement["kind"]).capitalize()

	var preview: Dictionary = run.compute_base_rewards(run.active_fight.assaults_used)
	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = (
		"Base payout ≈ Gold %d · Sci %d · Cul %d · Faith %d  (unused Assaults +%d Gold)\n"
		+ "City type: %s — Occupy keeps sticky +7/settlement; Raze gives +%d Gold now."
	) % [
		int(preview["gold"]), int(preview["science"]), int(preview["culture"]), int(preview["faith"]),
		int(preview["unused_assaults"]),
		str(run.current_settlement["city_type"]),
		28,
	]
	info.add_theme_color_override("font_color", Color("f2f2f2"))
	_panel.add_child(info)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_panel.add_child(row)

	var b_occ := Button.new()
	b_occ.text = "Occupy (%s)" % str(run.current_settlement["city_type"])
	b_occ.custom_minimum_size = Vector2(200, 44)
	b_occ.pressed.connect(func(): _choose_post("occupy"))
	row.add_child(b_occ)

	var b_raze := Button.new()
	b_raze.text = "Raze (+28 Gold)"
	b_raze.custom_minimum_size = Vector2(180, 44)
	b_raze.pressed.connect(func(): _choose_post("raze"))
	row.add_child(b_raze)


func _choose_post(choice: String) -> void:
	var reward: Dictionary = run.apply_victory_payout(run.active_fight.assaults_used, choice)
	_append(
		"Rewards — Gold+%d Sci+%d Cul+%d Faith+%d · %s · interest +%d" % [
			int(reward["base"]["gold"]) + int(reward["raze_gold"]),
			int(reward["base"]["science"]),
			int(reward["base"]["culture"]),
			int(reward["base"]["faith"]),
			choice,
			int(reward["interest"]),
		]
	)
	_refresh_resources()
	_continue_levelups()


## --- LEVEL UPS ---------------------------------------------------------------

func _continue_levelups() -> void:
	if run.can_afford_science():
		_show_levelup(run.begin_science_levelup())
		return
	if run.can_afford_civic():
		_show_levelup(run.begin_civic_levelup())
		return
	_show_shop()


func _show_levelup(lu: Dictionary) -> void:
	if lu.is_empty():
		_continue_levelups()
		return
	phase = Phase.LEVELUP
	_clear_panel()
	_refresh_resources()
	var kind: String = str(lu["kind"])
	_lbl_banner.text = ("%s level-up (cost %d) — pick 1" % [
		"Science" if kind == "science" else "Civics", int(lu["cost"]),
	])

	var tip := Label.new()
	tip.text = "Banks after paying: Sci %d · Cul %d" % [run.state.science, run.state.culture]
	tip.add_theme_color_override("font_color", Color("a8c5b5"))
	_panel.add_child(tip)

	var help_box := Label.new()
	help_box.name = "LevelHelp"
	help_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_box.add_theme_color_override("font_color", Color("9ec9ff"))
	help_box.text = "Tap (i) next to an option for a plain-English explanation."
	_panel.add_child(help_box)

	for offer in lu["offers"]:
		var id: String = str(offer)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_panel.add_child(row)
		var btn := Button.new()
		btn.text = run.offer_label(id)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.tooltip_text = run.offer_help(id)
		btn.pressed.connect(_on_pick_levelup.bind(id))
		row.add_child(btn)
		row.add_child(_make_info_button(run.offer_help(id), help_box))


func _on_pick_levelup(id: String) -> void:
	if not run.pick_levelup(id):
		_append("[color=#ff8888]Pick failed.[/color]")
		return
	_append("Picked [b]%s[/b]." % run.offer_label(id))
	_refresh_resources()
	_continue_levelups()


## --- SHOP --------------------------------------------------------------------

func _show_shop() -> void:
	phase = Phase.SHOP
	_clear_panel()
	_refresh_resources()
	run.open_shop()
	_lbl_banner.text = "Shop — Treasury (Gold) & Synod (Faith)"
	_rebuild_shop_panel()


func _rebuild_shop_panel() -> void:
	_clear_panel()
	_refresh_resources()
	_lbl_banner.text = "Shop — Treasury (Gold) & Synod (Faith)"

	var help_box := Label.new()
	help_box.name = "ShopHelp"
	help_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_box.add_theme_color_override("font_color", Color("9ec9ff"))
	help_box.text = "Tap (i) for what an offer does. Packs never repeat the same item."
	_panel.add_child(help_box)

	var tre_l := Label.new()
	tre_l.text = "Treasury"
	tre_l.add_theme_color_override("font_color", Color("e8d5a3"))
	_panel.add_child(tre_l)

	for i in run.shop_treasury.size():
		_add_shop_row("treasury", i, run.shop_treasury[i])

	var syn_l := Label.new()
	syn_l.text = "Synod"
	syn_l.add_theme_color_override("font_color", Color("e8d5a3"))
	_panel.add_child(syn_l)

	for i in run.shop_synod.size():
		_add_shop_row("synod", i, run.shop_synod[i])

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_panel.add_child(row)

	var reroll := Button.new()
	reroll.text = "Reroll Treasury (%d Gold)" % run.state.reroll_cost
	reroll.disabled = run.shop_rerolled or run.state.gold < run.state.reroll_cost
	reroll.pressed.connect(func():
		if run.reroll_treasury():
			_append("Rerolled Treasury.")
			_rebuild_shop_panel()
	)
	row.add_child(reroll)

	var done := Button.new()
	done.text = "Leave shop → march"
	done.custom_minimum_size = Vector2(200, 44)
	done.pressed.connect(_leave_shop)
	row.add_child(done)


func _add_shop_row(pack: String, index: int, offer: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_panel.add_child(row)
	var lbl := Label.new()
	var bought: bool = bool(offer.get("bought", false))
	var cur: String = "Gold" if pack == "treasury" else "Faith"
	lbl.text = "%s — %d %s%s" % [
		str(offer.get("label", offer.get("id", "?"))),
		int(offer.get("cost", 0)), cur,
		"  (bought)" if bought else "",
	]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color("888888") if bought else Color("f2f2f2"))
	lbl.tooltip_text = run.shop_offer_help(offer)
	row.add_child(lbl)
	var help_box: Label = _panel.get_node_or_null("ShopHelp") as Label
	row.add_child(_make_info_button(run.shop_offer_help(offer), help_box))
	var btn := Button.new()
	btn.text = "Buy"
	btn.disabled = bought
	btn.pressed.connect(func():
		var r: Dictionary = run.buy_offer(pack, index)
		if bool(r.get("ok", false)):
			_append("Bought %s." % str(offer.get("label", "")))
		else:
			_append("[i]Could not buy (%s).[/i]" % str(r.get("reason", "?")))
		_rebuild_shop_panel()
	)
	row.add_child(btn)


func _leave_shop() -> void:
	var adv: String = run.advance_after_shop()
	if adv == "era_won":
		_append("[color=#8dffb0][b]Ancient Capital conquered — era complete.[/b][/color]")
		_show_end(true)
	else:
		_append("Marching to the next settlement…")
		_show_hub()


## --- END ---------------------------------------------------------------------

func _show_end(won: bool) -> void:
	phase = Phase.END
	_clear_panel()
	_refresh_resources()
	_lbl_banner.text = "Victory — Ancient era" if won else "Defeat"
	var msg := Label.new()
	msg.text = (
		"You conquered Village, Town, and Capital. Greybox Ancient loop complete."
		if won else
		"Assaults ran out. Start a new run and try again."
	)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_color", Color("e8d5a3") if won else Color("ff8d8d"))
	_panel.add_child(msg)

	var snap = run.state.snapshot()
	var det := Label.new()
	det.text = "Final — Gold %d · SciLv %d · CivLv %d · Deck %d · BP %s · Docs %s" % [
		int(snap["gold"]), int(snap["sci_level"]), int(snap["civ_level"]),
		int(snap["deck_size"]), str(snap["blueprints"]), str(snap["doctrines"]),
	]
	det.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	det.add_theme_color_override("font_color", Color("a8c5b5"))
	_panel.add_child(det)

	var btn := Button.new()
	btn.text = "New Ancient run"
	btn.custom_minimum_size = Vector2(220, 44)
	btn.pressed.connect(_new_run)
	_panel.add_child(btn)


func _make_info_button(help: String, help_box: Label) -> Button:
	var info := Button.new()
	info.text = "i"
	info.custom_minimum_size = Vector2(36, 40)
	info.tooltip_text = help
	info.pressed.connect(func():
		if help_box:
			help_box.text = help
		_append("[color=#9ec9ff]%s[/color]" % help)
	)
	return info


func _append(bb: String) -> void:
	_log.append_text(bb + "\n")

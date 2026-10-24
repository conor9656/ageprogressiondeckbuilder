extends Control
## Greybox Domination run — 8 eras × Village/Town/Capital.
## Open game/ in Godot 4.7.2 and press Play.

const AgesRules := preload("res://rules/ages_rules.gd")
const CombatTables := preload("res://rules/combat_tables.gd")
const RunTables := preload("res://rules/run_tables.gd")

enum Phase { HUB, FIGHT, POST, LEVELUP, TOOLKIT, SHOP, END }

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
var _bp_option: OptionButton
var _lbl_builder_strip: Label


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
	_append("[b]Domination run[/b] — 8 eras × Village → Town → Capital (24 fights).")
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
	_bp_option = null
	_lbl_builder_strip = null
	_card_buttons.clear()


func _refresh_resources() -> void:
	var s = run.state
	_lbl_resources.text = (
		"%s (E%d/%d)   Gold %d   Sci %d   Cul %d   Faith %d   |   SciLv %d  CivLv %d   Deck %d   Capitals %d"
		% [
			s.era_label(), s.era, RunTables.max_era(),
			s.gold, s.science, s.culture, s.faith,
			s.sci_level, s.civ_level, s.deck_kinds.size(), s.eras_cleared,
		]
	)


## --- HUB ---------------------------------------------------------------------

func _show_hub() -> void:
	if run.has_pending_era_hooks():
		_continue_era_hooks()
		return
	phase = Phase.HUB
	_clear_panel()
	_refresh_resources()
	var sett: Dictionary = run.current_settlement
	_lbl_banner.text = "AGES — %s hub  (%d/3 this era)" % [
		run.state.era_label(), run.state.settlement_index + 1,
	]

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
	tip.text = "Clear Capitals to advance eras. Soft-caps, income, Breakthrough (E4+), Industrial Toolkit (E5) scale with the sim."
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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

	_build_builder_strip()
	_refresh_fight()


func _build_builder_strip() -> void:
	var fight = run.active_fight
	var strip := VBoxContainer.new()
	strip.name = "BuilderStrip"
	strip.add_theme_constant_override("separation", 4)
	_panel.add_child(strip)

	_lbl_builder_strip = Label.new()
	_lbl_builder_strip.add_theme_color_override("font_color", Color("e8d5a3"))
	strip.add_child(_lbl_builder_strip)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	strip.add_child(row)

	_chk_builder = CheckBox.new()
	_chk_builder.text = "Apply Builder"
	_chk_builder.button_pressed = fight != null and fight.charges.can_use_builder() and not fight.blueprints.is_empty()
	_chk_builder.toggled.connect(func(_v): _update_preview())
	row.add_child(_chk_builder)

	_bp_option = OptionButton.new()
	_bp_option.custom_minimum_size = Vector2(220, 0)
	_bp_option.item_selected.connect(func(i):
		if run.active_fight != null:
			run.active_fight.active_blueprint_index = i
		_update_preview()
	)
	row.add_child(_bp_option)

	var tip := Label.new()
	tip.text = "Toggle Builder on/off to see preview delta. Pick which Blueprint fires."
	tip.add_theme_color_override("font_color", Color("888888"))
	strip.add_child(tip)


func _refresh_builder_strip() -> void:
	var fight = run.active_fight
	if fight == null or _chk_builder == null:
		return
	var free_note := " (free slot)" if fight.free_builder_slot() else " (uses a formation slot)"
	var bps: Array = fight.blueprints
	var bp_parts: PackedStringArray = PackedStringArray()
	for b in bps:
		bp_parts.append(str(b))
	var bp_txt := "none equipped" if bp_parts.is_empty() else ", ".join(bp_parts)
	_lbl_builder_strip.text = (
		"Builder %d/%d · scale ×%.1f%s · Blueprints: %s"
		% [fight.charges.builder_left, fight.charges.builder_max, fight.builder_scale, free_note, bp_txt]
	)
	_chk_builder.disabled = (not fight.charges.can_use_builder()) or bps.is_empty()
	if _chk_builder.disabled:
		_chk_builder.button_pressed = false
	if _bp_option:
		_bp_option.clear()
		if bps.is_empty():
			_bp_option.add_item("(no Blueprint)")
			_bp_option.disabled = true
		else:
			_bp_option.disabled = false
			for i in bps.size():
				_bp_option.add_item(str(bps[i]))
			var idx: int = clampi(fight.active_blueprint_index, 0, bps.size() - 1)
			_bp_option.select(idx)
			fight.active_blueprint_index = idx


func _refresh_fight() -> void:
	var fight = run.active_fight
	if fight == null or _lbl_defence == null:
		return
	var wall := " · Walls" if fight.walls and not fight.walls_removed else ""
	_lbl_defence.text = "Defence %d / %d%s" % [maxi(0, fight.defence_left), fight.defence, wall]
	var res: Label = _panel.get_node_or_null("FightRes") as Label
	if res:
		res.text = "Assaults %d   Regroups %d   Builder %d/%d   Missionary %d/%d   Hand %d/%d" % [
			fight.assaults_left, fight.regroups_left,
			fight.charges.builder_left, fight.charges.builder_max,
			fight.charges.missionary_left, fight.charges.missionary_max,
			fight.piles.hand.size(), fight.hand_size,
		]
	_refresh_builder_strip()
	_rebuild_hand()
	_update_preview()


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


func _preview_damage(kinds: Array, use_b: bool) -> Dictionary:
	var fight = run.active_fight
	var opts_ignore: bool = fight.ignore_walls_next
	var walls_gone: bool = fight.walls_removed
	var bp0 := ""
	if use_b and not fight.blueprints.is_empty():
		bp0 = fight.selected_blueprint()
		if bp0 in ["scaffolding", "ignore_walls_next", "battering_ram"]:
			opts_ignore = true
		if bp0 in ["siege_tower", "remove_walls"]:
			walls_gone = true
	var ev: Dictionary = AgesRules.evaluate_kinds(kinds, {
		"era": fight.era, "sci_level": fight.sci_level, "tiers": fight.tiers,
		"walls": fight.walls, "garrison": fight.garrison,
		"walls_removed": walls_gone, "ignore_walls": opts_ignore,
		"faith_combat_mom": fight.faith_combat_mom,
	})
	ev["blueprint"] = bp0
	return ev


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
	var can_b: bool = _chk_builder != null and _chk_builder.button_pressed and fight.charges.can_use_builder() and not fight.blueprints.is_empty()
	var with_b: Dictionary = _preview_damage(kinds, can_b)
	var without: Dictionary = _preview_damage(kinds, false)
	var delta: int = int(with_b["damage"]) - int(without["damage"])
	var bp_note := ""
	if can_b:
		bp_note = " · BP %s ×%.1f" % [str(with_b.get("blueprint", "?")), fight.builder_scale]
		if delta != 0:
			bp_note += " (Δ %+d vs off)" % delta
		elif fight.walls and not fight.walls_removed:
			bp_note += " (wall help)"
	_lbl_preview.text = "Preview: %s (rank %d) → %d damage%s" % [
		with_b["form"], int(with_b["rank"]), int(with_b["damage"]), bp_note,
	]


func _on_assault() -> void:
	var fight = run.active_fight
	if fight == null or fight.is_over():
		return
	var cards := _selected_cards()
	if cards.is_empty():
		_append("[i]Select cards first.[/i]")
		return
	if _bp_option and not fight.blueprints.is_empty():
		fight.active_blueprint_index = _bp_option.selected
	var use_b: bool = _chk_builder != null and _chk_builder.button_pressed and fight.charges.can_use_builder() and not fight.blueprints.is_empty()
	var r: Dictionary = fight.do_assault(cards, use_b, false)
	if not bool(r.get("ok", false)):
		_append("[color=#ff8888]Assault failed.[/color]")
		return
	var entry: Dictionary = r["entry"]
	var bp_bit := ""
	if bool(entry.get("used_builder", false)):
		bp_bit = " · Builder→%s" % str(entry.get("blueprint", "?"))
	_append("Assault — %s for %d · left %d%s" % [entry["form"], int(entry["dmg"]), int(entry["left"]), bp_bit])
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
		+ 		"City type: %s — Occupy keeps sticky yield; Raze gives +%d Gold now."
	) % [
		int(preview["gold"]), int(preview["science"]), int(preview["culture"]), int(preview["faith"]),
		int(preview["unused_assaults"]),
		str(run.current_settlement["city_type"]),
		int(preload("res://rules/run_tables.gd").reward("raze_gold")),
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
	var free: bool = bool(lu.get("free", false))
	if free:
		_lbl_banner.text = "Breakthrough — free %s pick" % ("Science" if kind == "science" else "Civics")
	else:
		_lbl_banner.text = ("%s level-up (cost %d) — pick 1" % [
			"Science" if kind == "science" else "Civics", int(lu["cost"]),
		])

	var tip := Label.new()
	tip.text = (
		"Era start Breakthrough — no bank cost."
		if free else
		"Banks after paying: Sci %d · Cul %d" % [run.state.science, run.state.culture]
	)
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
	## Breakthrough free picks flow through era hooks; paid picks through shop path.
	if run.has_pending_era_hooks():
		_continue_era_hooks()
	else:
		_continue_levelups()


## --- SHOP --------------------------------------------------------------------

func _show_shop() -> void:
	phase = Phase.SHOP
	_clear_panel()
	_refresh_resources()
	run.open_shop()
	_lbl_banner.text = "Shop — Treasury · Synod · Wonder · Loadout"
	_rebuild_shop_panel()


func _rebuild_shop_panel() -> void:
	_clear_panel()
	_refresh_resources()
	_lbl_banner.text = "Shop — Treasury · Synod · Wonder · Loadout"

	## Scrollable body so Leave→march stays reachable when packs grow.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 220)
	_panel.add_child(scroll)

	var body := VBoxContainer.new()
	body.name = "ShopBody"
	body.add_theme_constant_override("separation", 8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	var help_box := Label.new()
	help_box.name = "ShopHelp"
	help_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_box.add_theme_color_override("font_color", Color("9ec9ff"))
	help_box.text = "Tap (i) for details. Unequip Blueprints/Doctrines below to free slots. Leave→march stays in the footer."
	body.add_child(help_box)

	_add_income_panel(body)
	_add_loadout_panel(body, help_box)
	_add_deck_panel(body)
	_add_wonder_panel(body, help_box)

	var tre_l := Label.new()
	tre_l.text = "Treasury (Gold)"
	tre_l.add_theme_color_override("font_color", Color("e8d5a3"))
	body.add_child(tre_l)
	for i in run.shop_treasury.size():
		_add_shop_row(body, help_box, "treasury", i, run.shop_treasury[i])

	var syn_l := Label.new()
	syn_l.text = "Synod (Faith)"
	syn_l.add_theme_color_override("font_color", Color("e8d5a3"))
	body.add_child(syn_l)
	for i in run.shop_synod.size():
		_add_shop_row(body, help_box, "synod", i, run.shop_synod[i])

	## Sticky footer — always visible under the scroll.
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	_panel.add_child(footer)

	var reroll := Button.new()
	reroll.text = "Reroll Treasury (%d Gold)" % run.state.reroll_cost
	reroll.disabled = run.shop_rerolled or run.state.gold < run.state.reroll_cost
	reroll.pressed.connect(func():
		if run.reroll_treasury():
			_append("Rerolled Treasury.")
			_rebuild_shop_panel()
	)
	footer.add_child(reroll)

	var done := Button.new()
	done.text = "Leave shop → march"
	done.custom_minimum_size = Vector2(220, 44)
	done.pressed.connect(_leave_shop)
	footer.add_child(done)


func _add_income_panel(parent: Control) -> void:
	var br: Dictionary = run.income_breakdown()
	var occ: Dictionary = br["occupy_counts"]
	var yield_pf: Dictionary = br["occupy_per_fight"]
	var bonus: Dictionary = br["bonus_pct"]
	var era_m: Dictionary = br["era_mult"]
	var base: Dictionary = br["base_raw"]

	var title := Label.new()
	title.text = "Income / bonuses (testing breakdown)"
	title.add_theme_color_override("font_color", Color("e8d5a3"))
	parent.add_child(title)

	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", Color("a8c5b5"))
	info.text = (
		"Base win (raw): Gold %d · Sci %d · Cul %d · Faith %d  (+unused Assaults to Gold; Raze +%d)\n"
		+ "Era mults: Gold×%.2f Sci×%.2f Cul×%.2f Faith×%.2f\n"
		+ "%% bonuses: Gold +%.0f%% · Sci +%.0f%% · Cul +%.0f%% · Faith +%.0f%%\n"
		+ "Occupied %d — Scholar %d · Artisan %d · Temple %d · Trade %d\n"
		+ "Sticky yield / fight from occupy: Gold %d · Sci %d · Cul %d · Faith %d\n"
		+ "Builder tier %d (scale ×%.1f) · Wonder: %s"
	) % [
		int(base["gold"]), int(base["science"]), int(base["culture"]), int(base["faith"]),
		int(base["raze_gold"]),
		float(era_m["gold"]), float(era_m["science"]), float(era_m["culture"]), float(era_m["faith"]),
		float(bonus["gold"]) * 100.0, float(bonus["science"]) * 100.0,
		float(bonus["culture"]) * 100.0, float(bonus["faith"]) * 100.0,
		int(br["occupy_total"]),
		int(occ.get("scholar", 0)), int(occ.get("artisan", 0)),
		int(occ.get("temple", 0)), int(occ.get("trade", 0)),
		int(yield_pf["gold"]), int(yield_pf["science"]),
		int(yield_pf["culture"]), int(yield_pf["faith"]),
		int(br["builder_tier"]), float(br["builder_scale"]),
		str(br["wonder"]) if str(br["wonder"]) != "" else "(none)",
	]
	parent.add_child(info)

	var last: Dictionary = br.get("last_reward", {})
	if not last.is_empty():
		var last_l := Label.new()
		last_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		last_l.add_theme_color_override("font_color", Color("9ec9ff"))
		var ylds: Dictionary = last.get("yields", {})
		last_l.text = "Last payout (%s): base G%d/S%d/C%d/F%d · raze %d · interest %d · occupy yields G%d/S%d/C%d/F%d" % [
			str(last.get("choice", "?")),
			int(last.get("base", {}).get("gold", 0)),
			int(last.get("base", {}).get("science", 0)),
			int(last.get("base", {}).get("culture", 0)),
			int(last.get("base", {}).get("faith", 0)),
			int(last.get("raze_gold", 0)), int(last.get("interest", 0)),
			int(ylds.get("gold", 0)), int(ylds.get("science", 0)),
			int(ylds.get("culture", 0)), int(ylds.get("faith", 0)),
		]
		parent.add_child(last_l)


func _add_loadout_panel(parent: Control, help_box: Label) -> void:
	var title := Label.new()
	title.text = "Loadout — Blueprints %d/%d · Doctrines %d/%d · Policies %d/%d" % [
		run.state.blueprints.size(), run.state.blueprint_slots,
		run.state.doctrines.size(), run.state.doctrine_slots,
		run.state.policies.size(), run.state.policy_slots,
	]
	title.add_theme_color_override("font_color", Color("e8d5a3"))
	parent.add_child(title)

	if run.state.blueprints.is_empty():
		var empty_bp := Label.new()
		empty_bp.text = "Blueprints: (empty — buy from Treasury)"
		empty_bp.add_theme_color_override("font_color", Color("888888"))
		parent.add_child(empty_bp)
	else:
		for i in run.state.blueprints.size():
			var id: String = str(run.state.blueprints[i])
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			parent.add_child(row)
			var lbl := Label.new()
			lbl.text = "BP %s" % id
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.add_theme_color_override("font_color", Color("f2f2f2"))
			row.add_child(lbl)
			row.add_child(_make_info_button(run._blueprint_help(id), help_box))
			var uneq := Button.new()
			uneq.text = "Unequip"
			uneq.pressed.connect(_on_unequip_blueprint.bind(i, id))
			row.add_child(uneq)

	if run.state.doctrines.is_empty():
		var empty_doc := Label.new()
		empty_doc.text = "Doctrines: (empty — buy from Synod; Theology adds slots)"
		empty_doc.add_theme_color_override("font_color", Color("888888"))
		parent.add_child(empty_doc)
	else:
		for j in run.state.doctrines.size():
			var did: String = str(run.state.doctrines[j])
			var drow := HBoxContainer.new()
			drow.add_theme_constant_override("separation", 8)
			parent.add_child(drow)
			var dlbl := Label.new()
			dlbl.text = "Doc %s" % did
			dlbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			dlbl.add_theme_color_override("font_color", Color("f2f2f2"))
			drow.add_child(dlbl)
			drow.add_child(_make_info_button(run._doctrine_help(did), help_box))
			var duneq := Button.new()
			duneq.text = "Unequip"
			duneq.pressed.connect(_on_unequip_doctrine.bind(j, did))
			drow.add_child(duneq)

	if not run.state.policies.is_empty():
		var pol := Label.new()
		pol.text = "Policies: %s" % ", ".join(PackedStringArray(run.state.policies))
		pol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pol.add_theme_color_override("font_color", Color("a8c5b5"))
		parent.add_child(pol)


func _add_deck_panel(parent: Control) -> void:
	var sum: Dictionary = run.deck_summary()
	var counts: Dictionary = sum["counts"]
	var title := Label.new()
	title.text = "Deck & promotions"
	title.add_theme_color_override("font_color", Color("e8d5a3"))
	parent.add_child(title)

	var deck_l := Label.new()
	deck_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_l.add_theme_color_override("font_color", Color("f2f2f2"))
	deck_l.text = "Deck %d — M×%d (T%d) · R×%d (T%d) · C×%d (T%d) · S×%d (T%d) · Builder charges %d · Missionary %d" % [
		int(sum["total"]),
		int(counts.get("M", 0)), int(sum["tiers"].get("M", 1)),
		int(counts.get("R", 0)), int(sum["tiers"].get("R", 1)),
		int(counts.get("C", 0)), int(sum["tiers"].get("C", 1)),
		int(counts.get("S", 0)), int(sum["tiers"].get("S", 1)),
		int(sum["builder_charges"]), int(sum["missionary_charges"]),
	]
	parent.add_child(deck_l)

	var promos: Array = sum.get("promotions", [])
	var promo_l := Label.new()
	promo_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	promo_l.add_theme_color_override("font_color", Color("a8c5b5"))
	if promos.is_empty():
		promo_l.text = "Promotions owned: (none yet — buy from Treasury; per-card attach still greybox)"
	else:
		var bits: PackedStringArray = PackedStringArray()
		for p in promos:
			bits.append("%s — %s" % [str(p), run._promotion_help(str(p))])
		promo_l.text = "Promotions owned:\n- " + "\n- ".join(bits)
	parent.add_child(promo_l)

	var forms: Dictionary = sum.get("form_levels", {})
	if not forms.is_empty():
		var fl := Label.new()
		fl.text = "Formation levels: %s" % str(forms)
		fl.add_theme_color_override("font_color", Color("888888"))
		parent.add_child(fl)


func _add_wonder_panel(parent: Control, help_box: Label) -> void:
	var title := Label.new()
	title.text = "Wonder (1 / run)"
	title.add_theme_color_override("font_color", Color("e8d5a3"))
	parent.add_child(title)

	if run.state.wonder != "":
		var owned_row := HBoxContainer.new()
		owned_row.add_theme_constant_override("separation", 8)
		parent.add_child(owned_row)
		var owned := Label.new()
		owned.text = "Owned: %s" % run.state.wonder.replace("_", " ").capitalize()
		owned.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owned.add_theme_color_override("font_color", Color("8dffb0"))
		owned_row.add_child(owned)
		owned_row.add_child(_make_info_button(run._wonder_help(run.state.wonder), help_box))
		return

	if run.shop_wonder.is_empty():
		var none := Label.new()
		none.text = "(no Wonder offer — catalog empty?)"
		none.add_theme_color_override("font_color", Color("888888"))
		parent.add_child(none)
		return

	var offer: Dictionary = run.shop_wonder
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = "%s — %d Gold" % [str(offer.get("label", "?")), int(offer.get("cost", 0))]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color("f2f2f2"))
	row.add_child(lbl)
	row.add_child(_make_info_button(run.shop_offer_help(offer), help_box))

	var buy := Button.new()
	buy.text = "Buy Wonder"
	buy.disabled = bool(offer.get("bought", false)) or run.state.gold < int(offer.get("cost", 0))
	buy.pressed.connect(func():
		var r: Dictionary = run.buy_wonder()
		if bool(r.get("ok", false)):
			_append("Built Wonder [b]%s[/b]." % str(offer.get("id", "")))
		else:
			_append("[i]Wonder buy failed (%s).[/i]" % str(r.get("reason", "?")))
		_rebuild_shop_panel()
	)
	row.add_child(buy)

	var rr := Button.new()
	var rr_cost: int = preload("res://rules/run_tables.gd").wonder_reroll_cost()
	rr.text = "Reroll Wonder (%d Gold, %d left)" % [rr_cost, run.state.shop_wonder_rerolls_left]
	rr.disabled = run.state.shop_wonder_rerolls_left <= 0 or run.state.gold < rr_cost
	rr.pressed.connect(func():
		if run.reroll_wonder():
			_append("Rerolled Wonder offer.")
			_rebuild_shop_panel()
	)
	parent.add_child(rr)


func _add_shop_row(parent: Control, help_box: Label, pack: String, index: int, offer: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var lbl := Label.new()
	var bought: bool = bool(offer.get("bought", false))
	var cur: String = "Gold" if pack == "treasury" else "Faith"
	var slot_note := ""
	if not bought and str(offer.get("cat", "")) == "blueprint" and run.state.blueprints.size() >= run.state.blueprint_slots:
		slot_note = "  [slots full — unequip first]"
	elif not bought and str(offer.get("cat", "")) == "doctrine" and run.state.doctrines.size() >= run.state.doctrine_slots:
		slot_note = "  [slots full — unequip first]"
	lbl.text = "%s — %d %s%s%s" % [
		str(offer.get("label", offer.get("id", "?"))),
		int(offer.get("cost", 0)), cur,
		"  (bought)" if bought else "",
		slot_note,
	]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color("888888") if bought else Color("f2f2f2"))
	lbl.tooltip_text = run.shop_offer_help(offer)
	row.add_child(lbl)
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


func _on_unequip_blueprint(index: int, id: String) -> void:
	if run.unequip_blueprint(index):
		_append("Unequipped Blueprint %s." % id)
		_rebuild_shop_panel()


func _on_unequip_doctrine(index: int, id: String) -> void:
	if run.unequip_doctrine(index):
		_append("Unequipped Doctrine %s." % id)
		_rebuild_shop_panel()


func _leave_shop() -> void:
	var adv: String = run.advance_after_shop()
	match adv:
		"domination_won":
			_append("[color=#8dffb0][b]Domination Victory — Information Capital fallen.[/b][/color]")
			_show_end(true)
		"era_advance":
			_append("[color=#8dffb0]Capital cleared — entering [b]%s[/b].[/color]" % run.state.era_label())
			_continue_era_hooks()
		_:
			_append("Marching to the next settlement…")
			_show_hub()


## --- ERA HOOKS (Breakthrough / Toolkit) --------------------------------------

func _continue_era_hooks() -> void:
	_refresh_resources()
	if bool(run.pending_era_hooks.get("breakthrough_sci", false)):
		var lu: Dictionary = run.begin_breakthrough_science()
		if not lu.is_empty():
			_show_levelup(lu)
			return
	if bool(run.pending_era_hooks.get("breakthrough_civ", false)):
		var cu: Dictionary = run.begin_breakthrough_civic()
		if not cu.is_empty():
			_show_levelup(cu)
			return
	if bool(run.pending_era_hooks.get("toolkit", false)):
		_show_toolkit()
		return
	_show_hub()


func _show_toolkit() -> void:
	phase = Phase.TOOLKIT
	_clear_panel()
	_refresh_resources()
	_lbl_banner.text = "Industrial Toolkit — pick 1"

	var tip := Label.new()
	tip.text = "Era 5 evening: you already gained +1 Assault. Choose a lasting toolkit bonus."
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_color_override("font_color", Color("a8c5b5"))
	_panel.add_child(tip)

	var help_box := Label.new()
	help_box.name = "ToolkitHelp"
	help_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_box.add_theme_color_override("font_color", Color("9ec9ff"))
	help_box.text = "Tap (i) for details."
	_panel.add_child(help_box)

	for id in run.toolkit_offers():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_panel.add_child(row)
		var btn := Button.new()
		btn.text = str(id).replace("_", " ").capitalize()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		btn.tooltip_text = run.toolkit_help(str(id))
		btn.pressed.connect(_on_pick_toolkit.bind(str(id)))
		row.add_child(btn)
		row.add_child(_make_info_button(run.toolkit_help(str(id)), help_box))


func _on_pick_toolkit(id: String) -> void:
	if not run.apply_industrial_toolkit(id):
		_append("[color=#ff8888]Toolkit pick failed.[/color]")
		return
	_append("Industrial Toolkit — [b]%s[/b]." % id)
	_continue_era_hooks()


## --- END ---------------------------------------------------------------------

func _show_end(won: bool) -> void:
	phase = Phase.END
	_clear_panel()
	_refresh_resources()
	var snap = run.state.snapshot()
	_lbl_banner.text = "Domination Victory" if won else "Defeat — %s" % str(snap.get("era_name", "?"))
	var msg := Label.new()
	msg.text = (
		"You conquered Capitals through Information. Greybox Domination complete — compare feel vs sim clear rates."
		if won else
		"Assaults ran out in %s. Capitals cleared: %d / 8. Try again and note where it got hard." % [
			str(snap.get("era_name", "?")), int(snap.get("eras_cleared", 0)),
		]
	)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_color", Color("e8d5a3") if won else Color("ff8d8d"))
	_panel.add_child(msg)

	var det := Label.new()
	det.text = "Final — Era %s · Gold %d · SciLv %d · CivLv %d · Deck %d · Assaults %d · Toolkit %s" % [
		str(snap.get("era_name", "?")), int(snap["gold"]), int(snap["sci_level"]), int(snap["civ_level"]),
		int(snap["deck_size"]), int(snap["base_assaults"]), str(snap.get("industrial_toolkit", "")),
	]
	det.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	det.add_theme_color_override("font_color", Color("a8c5b5"))
	_panel.add_child(det)

	var btn := Button.new()
	btn.text = "New Domination run"
	btn.custom_minimum_size = Vector2(240, 44)
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

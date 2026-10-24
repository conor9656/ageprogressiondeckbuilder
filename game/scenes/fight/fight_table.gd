extends Control
## Greybox vertical slice — one Ancient settlement fight.
## Open game/ in Godot 4.7.2 and press Play (F5).

const AgesRules := preload("res://rules/ages_rules.gd")
const CombatTables := preload("res://rules/combat_tables.gd")

var fight: RefCounted

# UI refs
var _lbl_title: Label
var _lbl_defence: Label
var _lbl_resources: Label
var _lbl_preview: Label
var _lbl_log: RichTextLabel
var _hand_row: HBoxContainer
var _btn_assault: Button
var _btn_regroup: Button
var _btn_clear: Button
var _btn_hint: Button
var _chk_builder: CheckBox
var _overlay: ColorRect
var _overlay_label: Label
var _overlay_btn: Button

var _selected: Dictionary = {}  ## card instance_id -> true
var _card_buttons: Dictionary = {}  ## id -> Button


func _ready() -> void:
	CombatTables.ensure_loaded()
	_build_ui()
	_start_new_fight()


func _unhandled_input(event: InputEvent) -> void:
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


func _start_new_fight() -> void:
	_selected.clear()
	fight = AgesRules.new_fight({
		"seed": int(Time.get_unix_time_from_system()) % 100000,
		"defence": 665,  # Ancient Village
		"kind": "village",
		"walls": false,
		"garrison": "militia",
		"era": 1,
		"assaults": 4,
		"regroups": 3,
		"blueprints": ["scaffolding"],
	})
	_overlay.visible = false
	_refresh_all()
	_append_log("[b]Ancient Village[/b] — reduce Defence to 0. Select cards, then Assault. (A / R / Esc / H)")


func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("1a2220")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	_lbl_title = Label.new()
	_lbl_title.text = "AGES — Vertical Slice"
	_lbl_title.add_theme_font_size_override("font_size", 28)
	_lbl_title.add_theme_color_override("font_color", Color("e8d5a3"))
	root.add_child(_lbl_title)

	_lbl_defence = Label.new()
	_lbl_defence.add_theme_font_size_override("font_size", 22)
	_lbl_defence.add_theme_color_override("font_color", Color("f2f2f2"))
	root.add_child(_lbl_defence)

	_lbl_resources = Label.new()
	_lbl_resources.add_theme_color_override("font_color", Color("a8c5b5"))
	root.add_child(_lbl_resources)

	_lbl_preview = Label.new()
	_lbl_preview.add_theme_color_override("font_color", Color("9ec9ff"))
	_lbl_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_lbl_preview)

	var hand_label := Label.new()
	hand_label.text = "Your hand (click to select)"
	hand_label.add_theme_color_override("font_color", Color("cfcfcf"))
	root.add_child(hand_label)

	var hand_scroll := ScrollContainer.new()
	hand_scroll.custom_minimum_size = Vector2(0, 110)
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(hand_scroll)

	_hand_row = HBoxContainer.new()
	_hand_row.add_theme_constant_override("separation", 8)
	hand_scroll.add_child(_hand_row)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)

	_btn_assault = Button.new()
	_btn_assault.text = "Assault (A)"
	_btn_assault.custom_minimum_size = Vector2(140, 40)
	_btn_assault.pressed.connect(_on_assault)
	actions.add_child(_btn_assault)

	_btn_regroup = Button.new()
	_btn_regroup.text = "Regroup (R)"
	_btn_regroup.custom_minimum_size = Vector2(140, 40)
	_btn_regroup.pressed.connect(_on_regroup)
	actions.add_child(_btn_regroup)

	_btn_clear = Button.new()
	_btn_clear.text = "Clear (Esc)"
	_btn_clear.pressed.connect(_clear_selection)
	actions.add_child(_btn_clear)

	_btn_hint = Button.new()
	_btn_hint.text = "Hint (H)"
	_btn_hint.pressed.connect(_on_hint)
	actions.add_child(_btn_hint)

	_chk_builder = CheckBox.new()
	_chk_builder.text = "Use Builder charge"
	_chk_builder.button_pressed = true
	_chk_builder.toggled.connect(func(_v): _update_preview())
	actions.add_child(_chk_builder)

	var log_label := Label.new()
	log_label.text = "Battle log"
	log_label.add_theme_color_override("font_color", Color("cfcfcf"))
	root.add_child(log_label)

	_lbl_log = RichTextLabel.new()
	_lbl_log.bbcode_enabled = true
	_lbl_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lbl_log.custom_minimum_size = Vector2(0, 220)
	_lbl_log.scroll_following = true
	root.add_child(_lbl_log)

	# Win/lose overlay
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.72)
	_overlay.set_anchors_preset(PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)

	var ov_center := CenterContainer.new()
	ov_center.set_anchors_preset(PRESET_FULL_RECT)
	_overlay.add_child(ov_center)

	var ov_box := VBoxContainer.new()
	ov_box.add_theme_constant_override("separation", 16)
	ov_center.add_child(ov_box)

	_overlay_label = Label.new()
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_label.add_theme_font_size_override("font_size", 36)
	_overlay_label.add_theme_color_override("font_color", Color("e8d5a3"))
	ov_box.add_child(_overlay_label)

	_overlay_btn = Button.new()
	_overlay_btn.text = "Fight again"
	_overlay_btn.custom_minimum_size = Vector2(180, 44)
	_overlay_btn.pressed.connect(_start_new_fight)
	ov_box.add_child(_overlay_btn)


func _refresh_all() -> void:
	_refresh_header()
	_rebuild_hand()
	_update_preview()
	_btn_assault.disabled = fight.is_over()
	_btn_regroup.disabled = fight.is_over() or fight.regroups_left <= 0
	_chk_builder.disabled = not fight.charges.can_use_builder()
	if not fight.charges.can_use_builder():
		_chk_builder.button_pressed = false


func _refresh_header() -> void:
	var wall_txt := " · Walls" if fight.walls and not fight.walls_removed else ""
	_lbl_defence.text = "Defence  %d / %d%s  (%s · %s)" % [
		maxi(0, fight.defence_left), fight.defence, wall_txt, fight.settlement_kind, fight.garrison
	]
	_lbl_resources.text = "Assaults %d   Regroups %d   Builder charges %d   Hand %d/%d" % [
		fight.assaults_left, fight.regroups_left, fight.charges.builder_left,
		fight.piles.hand.size(), fight.hand_size
	]


func _rebuild_hand() -> void:
	for c in _hand_row.get_children():
		c.queue_free()
	_card_buttons.clear()
	# Drop selections for cards no longer in hand
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
		btn.text = _card_label(card)
		btn.tooltip_text = "Class %s · click to select for Assault" % card.kind
		btn.toggled.connect(_on_card_toggled.bind(id))
		_style_card_button(btn, card.kind, btn.button_pressed)
		_hand_row.add_child(btn)
		_card_buttons[id] = btn


func _card_label(card: RefCounted) -> String:
	var names := {"M": "Melee", "R": "Ranged", "C": "Cavalry", "S": "Siege"}
	return "%s\nT%d" % [names.get(card.kind, card.kind), int(fight.tiers.get(card.kind, 1))]


func _style_card_button(btn: Button, kind: String, selected: bool) -> void:
	var colors := {
		"M": Color("c45c4a"),
		"R": Color("4a8fc4"),
		"C": Color("c4a24a"),
		"S": Color("7a7a7a"),
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
			# Cap at 5 combat selections
			if _card_buttons.has(id):
				_card_buttons[id].set_pressed_no_signal(false)
			return
		_selected[id] = true
	else:
		_selected.erase(id)
	if _card_buttons.has(id):
		var card = _find_card(id)
		if card:
			_style_card_button(_card_buttons[id], card.kind, pressed)
	_update_preview()


func _selected_combat_count() -> int:
	var n := 0
	for id in _selected.keys():
		var c = _find_card(id)
		if c and c.is_combat():
			n += 1
	return n


func _find_card(id: int) -> Variant:
	for c in fight.piles.hand:
		if c.get_instance_id() == id:
			return c
	return null


func _selected_cards() -> Array:
	var out: Array = []
	for c in fight.piles.hand:
		if _selected.has(c.get_instance_id()):
			out.append(c)
	return out


func _clear_selection() -> void:
	_selected.clear()
	_rebuild_hand()
	_update_preview()


func _update_preview() -> void:
	var cards := _selected_cards()
	if cards.is_empty():
		_lbl_preview.text = "Preview: select 1–5 cards…"
		return
	var kinds: Array = []
	for c in cards:
		kinds.append(c.kind)
	var use_b: bool = _chk_builder.button_pressed and fight.charges.can_use_builder()
	var opts_ignore: bool = fight.ignore_walls_next
	var walls_gone: bool = fight.walls_removed
	if use_b and not fight.blueprints.is_empty():
		var bp0: String = str(fight.blueprints[0])
		if bp0 == "scaffolding" or bp0 == "ignore_walls_next":
			opts_ignore = true
		if bp0 == "siege_tower" or bp0 == "remove_walls":
			walls_gone = true
	var ev: Dictionary = AgesRules.evaluate_kinds(kinds, {
		"era": fight.era,
		"sci_level": fight.sci_level,
		"tiers": fight.tiers,
		"walls": fight.walls,
		"garrison": fight.garrison,
		"walls_removed": walls_gone,
		"ignore_walls": opts_ignore,
	})
	var btxt := " + Builder" if use_b else ""
	_lbl_preview.text = "Preview: %s (rank %d) → %d damage%s" % [
		ev["form"], int(ev["rank"]), int(ev["damage"]), btxt
	]


func _on_assault() -> void:
	if fight.is_over():
		return
	var cards := _selected_cards()
	if cards.is_empty():
		_append_log("[i]Select at least one card first.[/i]")
		return
	var use_b: bool = _chk_builder.button_pressed and fight.charges.can_use_builder()
	var r: Dictionary = fight.do_assault(cards, use_b, false)
	if not bool(r.get("ok", false)):
		_append_log("[color=#ff8888]Assault failed (%s). Try fewer cards or clear selection.[/color]" % str(r.get("reason", "?")))
		return
	var entry: Dictionary = r["entry"]
	_append_log("Assault — [b]%s[/b] for [b]%d[/b] dmg · Defence left %d" % [
		entry["form"], int(entry["dmg"]), int(entry["left"])
	])
	_selected.clear()
	_refresh_all()
	_check_end()


func _on_regroup() -> void:
	if fight.is_over():
		return
	var cards := _selected_cards()
	if cards.is_empty():
		_append_log("[i]Select 1–5 cards to discard, then Regroup. Unselected cards stay.[/i]")
		return
	if cards.size() > 5:
		_append_log("[i]Regroup discards at most 5 cards.[/i]")
		return
	if not fight.do_regroup(cards):
		_append_log("[i]Regroup failed (none left, or bad selection).[/i]")
		return
	_append_log("Regroup — discarded %d, kept the rest. Regroups left %d" % [
		cards.size(), fight.regroups_left,
	])
	_selected.clear()
	_refresh_all()


func _on_hint() -> void:
	if fight.is_over():
		return
	var choice: Dictionary = fight.choose_assault_ai()
	_selected.clear()
	for c in choice["cards"]:
		_selected[c.get_instance_id()] = true
	_chk_builder.button_pressed = bool(choice.get("use_builder", false)) and fight.charges.can_use_builder()
	_rebuild_hand()
	_update_preview()
	_append_log("[i]Hint selected AI’s pick (%d cards).[/i]" % choice["cards"].size())


func _check_end() -> void:
	if not fight.is_over():
		return
	if fight.won:
		_overlay_label.text = "Victory!\nVillage conquered."
		_append_log("[color=#8dffb0][b]You won.[/b][/color]")
	else:
		_overlay_label.text = "Defeat\nAssaults exhausted."
		_append_log("[color=#ff8d8d][b]You lost.[/b][/color]")
	_overlay.visible = true
	_btn_assault.disabled = true
	_btn_regroup.disabled = true


func _append_log(bb: String) -> void:
	_lbl_log.append_text(bb + "\n")

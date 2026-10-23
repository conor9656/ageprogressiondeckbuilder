extends Control
## Tiny boot menu for the Ancient greybox.


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("14201c")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	var title := Label.new()
	title.text = "AGES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color("e8d5a3"))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Ancient era — Village → Town → Capital"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color("a8c5b5"))
	box.add_child(sub)

	var btn := Button.new()
	btn.text = "Start Ancient run"
	btn.custom_minimum_size = Vector2(240, 48)
	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/run/run_table.tscn")
	)
	box.add_child(btn)

	var solo := Button.new()
	solo.text = "Solo fight (debug)"
	solo.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/fight/fight_table.tscn")
	)
	box.add_child(solo)

	var hint := Label.new()
	hint.text = "In fight: A Assault · R Regroup · Esc clear · H hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("888888"))
	box.add_child(hint)

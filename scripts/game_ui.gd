extends CanvasLayer
var hints_per_level = 2
var enough_shapes_for_hint = true

func _ready():
	pass

func _on_buy_hint_button_down():
	if enough_shapes_for_hint and hints_per_level > 0:
		var hint_data = get_parent().activate_hint()
		enough_shapes_for_hint = hint_data[1]
		if hint_data[0]:
			hints_per_level -= 1
		
		get_node("buy_hint/AnimationPlayer").play("hint_button_clicked")
		if hints_per_level == 0 or not enough_shapes_for_hint:
			get_node("buy_hint/frame").modulate = Color(80)

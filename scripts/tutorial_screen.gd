extends CanvasLayer

var hand_texture
var anim_player

func init_hand_anim(from, to):
	anim_player = get_node("hand_canvas/hand_texture/AnimationPlayer")
	hand_texture = get_node("hand_canvas/hand_texture")
	var anim_hand = anim_player.get_animation("tutorial_hand")
	anim_hand.track_set_key_value(0,0,from)
	anim_hand.track_set_key_value(0,1,to)
	anim_hand.track_set_key_value(0,2,to)

func play_hand_anim(v):
	if v: anim_player.play("tutorial_hand")
	else: anim_player.stop()
	hand_texture.visible = v

extends TextureRect

func init(rect_position, texture):
	self.rect_position = rect_position
	self.texture = texture
	
	randomize()
	var anim = get_node("AnimationPlayer")
	anim.playback_speed = 0.1 + randf()/2
	anim.play("fade_in_out")

extends Sprite
class_name UpperField

var default_texture
var taken = false
var back_sprite
onready var animation_player = get_node("AnimationPlayer")


func init(hexa_scale, position, slot_texture, bg_slot_texture):
	self.scale *= hexa_scale
	self.position = position
	self.texture = slot_texture
	default_texture = slot_texture
	back_sprite = get_node("upper_field_back")
	back_sprite.texture = bg_slot_texture

func _on_Area2D_area_entered(area):
	if not taken and area.shape.dragging:
		area.hover_on(self)

func _on_Area2D_area_exited(area):
	if not taken and area.shape.dragging:
		if area.drop_on==self: area.hover_on(null)

func highlight_for_drop(b, hex):
	self.texture = hex.texture_sprite.texture if b else default_texture

func highlight_blink(v):
	if v:
		animation_player.play("hint_outline_upper")
	else:
		back_sprite.scale = Vector2(1,1)
		animation_player.stop()
	z_index += (2 if v else -2)

extends Area2D
class_name Hexagon

#public
var color

#private
var drop_on
var changed_hover = false
var shape
onready var texture_sprite = get_node("texture")
onready var highlight_sprite = get_node("highlight")
onready var collision_polygon = get_node("CollisionPolygon2D")
onready var animation_player = get_node("AnimationPlayer")

func _ready():
	shape = get_parent()

func make(sc, texture):
	self.position = sc
	self.connect("input_event", get_parent(), "drag")
	texture_sprite.texture = texture

func hover_on(upper_field):
	if upper_field!=drop_on:
		drop_on = upper_field
		changed_hover = true

func highlight(b, place):
	if not shape.is_hint_shape:
		highlight_sprite.visible = b
	self.z_index = 5 if b else 3
	self.collision_polygon.scale = Vector2.ONE if b or place else Vector2(1.5,1.5)

func highlight_blink(b):
	highlight_sprite.visible = b
	if b:
		animation_player.play("hint_outline_hexagon")
	else:
		highlight_sprite.scale = Vector2(1,1)
		animation_player.stop()

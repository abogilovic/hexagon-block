extends KinematicBody2D
class_name ShapeHex

#public 
export(PackedScene) var pkg_hexagon
export(AudioStreamOGGVorbis) var take_sound
export(AudioStreamOGGVorbis) var place_sound
export(AudioStreamOGGVorbis) var deny_place_sound


#private
onready var anim_player = get_node("AnimationPlayer")
onready var audio_player = get_node("AudioStreamPlayer2D")

var hexagons = []
var bottom_fitted = false
var relative_positions = []
var on_even

var dragging = false
var zoomed_hexa_scale
var hexa_scale
var selection_position
var x
var placed = false
var original_place_hexas
var is_hint_shape = false
var was_hint_shape = false

var gc

func _ready():
	gc = get_parent().get_parent()
	place_sound.loop = false
	take_sound.loop = false
	deny_place_sound.loop = false

func _process(_delta):
	if dragging:
		self.position = get_viewport().get_mouse_position()-x
		check_full_change_cycle()

func init(shape_parts_pos, original_place_hexas):
	self.original_place_hexas = original_place_hexas
	on_even = int(shape_parts_pos[0].x)%2==0
	var d = shape_parts_pos[0]
	for sp in shape_parts_pos: relative_positions.append(sp-d)

func make(screen_coordinates, texture, bottom_hexa_scale, upper_hexa_scale):
	self.zoomed_hexa_scale = upper_hexa_scale/bottom_hexa_scale
	self.hexa_scale = upper_hexa_scale #for exact position delta when dragging on different screens
	self.bottom_fitted = true
	self.position = screen_coordinates[0]
	self.selection_position = screen_coordinates[0]
	
	for sc in screen_coordinates:
		var h = pkg_hexagon.instance()
		h.scale *= bottom_hexa_scale
		self.hexagons.append(h)
		add_child(h)
		h.make(sc-self.selection_position, texture)

func drag(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and not dragging:
			dragging = true
			gc.shape_drag_tutorial(dragging)
			audio_player.stream = take_sound
			audio_player.play()
			self.scale = Vector2.ONE*self.zoomed_hexa_scale
			for h in hexagons: h.highlight(true, false)
			if not placed:
				x = hover_delta_position(true)
			else:
				x = hover_delta_position(false)
				take()

func stop_drag():
	dragging = false
	gc.shape_drag_tutorial(dragging)
	if able_to_place():
		audio_player.stream = place_sound
		audio_player.play()
		for h in hexagons: h.highlight(false, true)
		place()
	else:
		audio_player.stream = deny_place_sound
		audio_player.play()
		for h in hexagons: 
			h.highlight(false, false)
			h.drop_on = null
		self.position = self.selection_position
		self.scale = Vector2.ONE

func hover_delta_position(from_selection):
	var low_x = hexagons[0].position.x
	var high_x = hexagons[0].position.x
	var high_y = hexagons[0].position.y
	
	for hex in hexagons:
		var x = hex.position.x
		var y = hex.position.y
		if x<low_x: low_x = x
		elif x>high_x: high_x = x
		if y>high_y: high_y = y
	
	return self.zoomed_hexa_scale*Vector2((high_x+low_x)/2, high_y+self.hexa_scale*(500 if from_selection else 150))

func able_to_place():
	for h in hexagons:
		if not h.drop_on:
			return false
	return true

func check_full_change_cycle():
	for h in hexagons:
		if not h.changed_hover:
			return false

	gc.clear_highlights()
	#has to be
	for h in hexagons:
		if not h.drop_on:
			return false

	for h in hexagons:
		h.changed_hover = false
		h.drop_on.highlight_for_drop(true, h)
	return true

func place():
	position -= get_global_position() - hexagons[0].drop_on.get_global_position()
	placed = true
	for hex in hexagons:
		hex.drop_on.taken = true
	if is_hint_shape and in_desired_place():
		is_hint_shape = false
		indicate_hint(false)
	gc.check_for_game_end()

func take():
	placed = false
	for hex in hexagons:
		hex.drop_on.taken = false

func in_desired_place():
	return (get_global_position()-original_place_hexas[0].get_global_position()).length() < 1

func indicate_hint(v):
	for hex in hexagons:
		hex.highlight_blink(v)
	for hex in original_place_hexas:
		hex.highlight_blink(v)

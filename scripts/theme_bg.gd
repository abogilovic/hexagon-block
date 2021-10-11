extends CanvasLayer

export(PackedScene) var pkg_fading_element

onready var base_node = get_node("base")
onready var selection_node = get_node("selection")
onready var fading_elements_node = get_node("fading_elements")


func init(base_texture, selection_texture, fading_element_textures, new_rows_amount, bottom_start, bottom_hexa_width):
	base_node.texture = base_texture
	selection_node.texture = selection_texture
	selection_node.rect_position = Vector2(0, bottom_start.y-250-0.8*bottom_hexa_width)
	var screen_size = Vector2(ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))
	
	if new_rows_amount>0:
		selection_node.rect_scale += Vector2(0, new_rows_amount*(selection_texture.get_height())/(65.0*bottom_hexa_width))
	
	randomize()
	while len(fading_element_textures)>0:
		var fe = pkg_fading_element.instance()
		var txtr = fading_element_textures.pop_front()
		fe.init(Vector2(randf()*(screen_size.x-txtr.get_width()), randf()*(screen_size.y-txtr.get_height())), txtr)
		fading_elements_node.add_child(fe)

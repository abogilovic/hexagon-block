extends Node2D
class_name Controller

#public
export(int) var max_width_up
export(int) var max_height_up
export(int) var max_width_down
export(int) var max_height_down
export(float) var hexa_original_width
export(Array,float) var row_play_space
export(Array,float) var col_play_space
export(Array,float) var row_play_space_bottom
export(Array,float) var col_play_space_bottom
export(Array, Texture) var hexagon_textures
export(PackedScene) var pkg_upper_field
export(PackedScene) var pkg_bottom_field
export(PackedScene) var pkg_shape
export(PackedScene) var pkg_tutorial_screen
export(Array, Array, Texture) var bg_main_elements
export(Array, Array, Texture) var bg_fading_elements
export(Array, Array, Texture) var bg_hexa_slot_bg_loc

#private
var theme_id
var upper_fields = []
var shapes = []
var bottom_fields = []

var hexa_scale
var hexa_width
var bottom_hexa_scale
var bottom_hexa_width
var upper_start
var bottom_start
var hexagon_textures_pool

var mvs1 = [Vector2(0,-1), Vector2(-1,0), Vector2(-1,1), Vector2(0,1), Vector2(1,1), Vector2(1,0)]
var mvs2 = [Vector2(0,-1), Vector2(-1,-1), Vector2(-1,0), Vector2(0,1), Vector2(1,0), Vector2(1,-1)]
var tut
var shapes_amounts = [[0,1], [2,2], [5,3], [9,4], [14,5], [20,6], [27,7], [35,8], [44,9], [54,10], [65,11], [80,12]]

func _ready():
	pass

func generate_level(lvl):
	lvl -= 1
	if lvl<0: lvl = 0
	theme_id = (lvl/3)%4
	prepare_sizings()
	init_upper_field()
	random_shapes_blueprints(random_level_configuration(lvl, lvl==0))
	init_bottom_field()
	make_fit_shapes_bottom()
	refine_visibles()
	prepare_visuals()
	if lvl == 0:
		tut = pkg_tutorial_screen.instance()
		tut.init_hand_anim(shapes[0].position - Vector2(75,-100), Vector2(500, 600))
		tut.play_hand_anim(true)
		add_child(tut)


func random_level_configuration(level, tutorial):
	var max_places = max_width_up*max_height_up
	var lvl_ratio = level/80.0
	if lvl_ratio>1: lvl_ratio=1
	
	var hexagons_amount = (10.0 if not tutorial else 5.0) + round(lvl_ratio*(max_places - (10 if not tutorial else 5)))
	var shapes_amount = 12
	for t in shapes_amounts:
		if level <= t[0]:
			shapes_amount = t[1]
			break
	#var shapes_amount = (2.0 if not tutorial else 1.0) + round(lvl_ratio*(max_shapes - (2 if not tutorial else 1)))
	
	var lvl_config = []
	for i in range(shapes_amount): lvl_config.append(1)
	
	randomize()
	for i in range(hexagons_amount-shapes_amount):
		var x = int(randf()*shapes_amount)
		if x == shapes_amount: x -= 1
		lvl_config[x] += 1
	
	#print(lvl_config)
	return [lvl_config, 1+int((1.0-lvl_ratio)*5)]

func _input(event):
	if event is InputEventMouseButton and not event.pressed:
		clear_highlights()
		for shape in shapes:
			if shape.dragging: shape.stop_drag()

func prepare_sizings():
	var w_display=ProjectSettings.get_setting("display/window/size/width")
	var h_display=ProjectSettings.get_setting("display/window/size/height")
	
	var vw_size=get_viewport().size #var vw_size=OS.get_window_size()
	if vw_size.y/vw_size.x>float(h_display)/w_display: h_display=(vw_size.y/vw_size.x)*w_display
	else: w_display=h_display/(vw_size.y/vw_size.x)
	
	#####
	
	var play_width=w_display*(col_play_space[1]-col_play_space[0])
	var play_height=h_display*(row_play_space[1]-row_play_space[0])
	
	var w_hexa_field=max_width_up*hexa_original_width*3/4+hexa_original_width*1/4
	var h_hexa_field=max_height_up*hexa_original_width*sqrt(3)/2+hexa_original_width*+sqrt(3)/4
	var row_scale=play_height/(h_hexa_field)
	var col_scale=play_width/(w_hexa_field)

	if(row_scale<col_scale): hexa_scale=row_scale; else: hexa_scale=col_scale
	hexa_width=hexa_original_width*hexa_scale
	upper_start=Vector2(w_display*col_play_space[0]+hexa_width/2+(play_width-w_hexa_field*hexa_scale)/2, h_display*row_play_space[0]+hexa_width*sqrt(3)/4+(play_height-h_hexa_field*hexa_scale)/2)
	
	#####
	
	play_width=w_display*(col_play_space_bottom[1]-col_play_space_bottom[0])
	play_height=h_display*(row_play_space_bottom[1]-row_play_space_bottom[0])
	
	w_hexa_field=max_width_down*hexa_original_width*3/4+hexa_original_width*1/4
	h_hexa_field=max_height_down*hexa_original_width*sqrt(3)/2+hexa_original_width*+sqrt(3)/4
	row_scale=play_height/(h_hexa_field)
	col_scale=play_width/(w_hexa_field)

	if(row_scale<col_scale): bottom_hexa_scale=row_scale; else: bottom_hexa_scale=col_scale
	bottom_hexa_width=hexa_original_width*bottom_hexa_scale
	bottom_start=Vector2(w_display*col_play_space_bottom[0]+bottom_hexa_width/2+(play_width-w_hexa_field*bottom_hexa_scale)/2, h_display*row_play_space_bottom[0]+bottom_hexa_width*sqrt(3)/4+(play_height-h_hexa_field*bottom_hexa_scale)/2)

func prepare_visuals():
	var theme_bg_node = get_node("theme_bg")
	theme_bg_node.init(bg_main_elements[theme_id][0], 
						bg_main_elements[theme_id][1], 
						bg_fading_elements[theme_id].duplicate(),
						max_height_down-6, bottom_start, bottom_hexa_width)
	
func init_upper_field():
	for i in range(max_height_up):
		upper_fields.append([])
		for _j in range(max_width_up):
			upper_fields[i].append(null)

func can_spawn_at(i,j):
	if upper_fields[i][j]!=null: return false
	var around = mvs2 if j%2 == 0 else mvs1
	var v = 0; var h = 0
	for a in around:
		v = i+a.y; h = j+a.x
		if v>=0 and h>=0 and v<max_height_up and h<max_width_up and upper_fields[v][h]!=null: 
			return true
	return false
	
func random_shapes_blueprints(shapes_data):
	var shape_sizes = shapes_data[0]
	var sticky_level = shapes_data[1]
	var first_shape = true
	for shape_size in shape_sizes:
		randomize()
		var shape = pkg_shape.instance()
		
		var pos_to_spawn = []
		for i in range(len(upper_fields)):
			for j in range(len(upper_fields[i])):
				if first_shape and upper_fields[i][j]==null or not first_shape and can_spawn_at(i,j):
					pos_to_spawn.append(Vector2(j, i))
		first_shape = false
		var shape_parts_pos = [pos_to_spawn[randi()%len(pos_to_spawn)]]
		
		var try
		var max_tries
		for _i in range(shape_size-1):
			try = 0
			max_tries = false
			
			var pos_mvs = []
			while len(pos_mvs)==0:
				if try == len(shape_parts_pos):
					shape_sizes.append(shape_size-len(shape_parts_pos))
					max_tries = true
					break
				
				for c in shape_parts_pos:
					var around = mvs1
					if int(c.x) % 2 == 0: around = mvs2
					for a in around:
						var v = c.y+a.y
						var h = c.x+a.x
						if v>=0 and h>=0 and v<max_height_up and h<max_width_up and upper_fields[v][h]==null and not(Vector2(h,v) in shape_parts_pos):
							pos_mvs.append(Vector2(h,v))
				
				var around = mvs1
				for i in range(len(upper_fields)):
					for j in range(len(upper_fields[i])):
						if upper_fields[i][j]!=null:
							if j%2 == 0: around = mvs2
							for a in around:
								var v = i+a.y
								var h = j+a.x
								if Vector2(h,v) in pos_mvs:
									for _k in range(sticky_level):
										pos_mvs.append(Vector2(h,v))
				try+=1
			if max_tries: break
			shape_parts_pos.append(pos_mvs[randi()%len(pos_mvs)])
		
		var original_place_hexas = []
		for c in shape_parts_pos:
			var h = pkg_upper_field.instance()
			h.init(
				hexa_scale, 
				Vector2(upper_start.x + hexa_width*3/4*c.x, upper_start.y + (hexa_width*sqrt(3)/2)*c.y) if int(c.x) % 2 == 0
				else Vector2(upper_start.x + hexa_width*3/4*c.x, upper_start.y + (hexa_width*sqrt(3)/2)*c.y+(hexa_width*sqrt(3)/4)),
				bg_hexa_slot_bg_loc[theme_id][0], bg_hexa_slot_bg_loc[theme_id][1])
			upper_fields[c.y][c.x] = h
			original_place_hexas.append(h)
			get_node("upper_fields").add_child(h)
		
		shape.init(shape_parts_pos, original_place_hexas)
		get_node("shapes").add_child(shape)
		shapes.append(shape)

func init_bottom_field():
	for i in range(max_height_down):
		bottom_fields.append([])
		for _j in range(max_width_down):
			bottom_fields[i].append(null)

func can_fit_bottom(i, j, vs):
	for v in vs:
		var vert = i+v.y
		var hor = j+v.x
		if vert<0 or hor<0 or vert>=max_height_down or hor>=max_width_down or bottom_fields[vert][hor] != null:
			return false
	return true

func possible_shape_shift(vs, j, was_even):
	var now_even = j%2==0
	if was_even!=now_even:
		for i in range(len(vs)):
			if int(vs[i].x)%2 != 0:
				vs[i].y = vs[i].y + (-1 if !was_even else 1)

func make_fit_shapes_bottom():
	var avg_shape_size = 0.0
	var sum = 0.0
	for shape in shapes:
		sum += len(shape.relative_positions)
	avg_shape_size = float(sum)/len(shapes)
	
	while 1:
		while 1:
			var best_shape = null
			var best_fit_ratio = 0
			var best_i = 0
			var best_j = 0
			
			for shape in shapes:
				if shape.bottom_fitted: continue
				for i in range(max_height_down):
					for j in range(max_width_down):
						var rp = shape.relative_positions.duplicate()
						possible_shape_shift(rp, j, shape.on_even)
						if can_fit_bottom(i, j, rp):
							var stuck_around = 0.0
							for r in rp:
								var around = mvs1
								if (j+int(r.x))%2 == 0: around = mvs2
								for a in around:
									var vert = i+r.y+a.y
									var hor = j+r.x+a.x
									if vert>=0 and hor>=0 and vert<max_height_down and hor<max_width_down:
										if bottom_fields[vert][hor]==null: stuck_around+=1.0
									else: stuck_around+=1.0
							var ratio = (len(rp)/avg_shape_size)/float(stuck_around)
							if ratio>best_fit_ratio:
								best_i = i
								best_j = j
								best_fit_ratio = ratio
								best_shape = shape
			
			if best_shape!=null:
				var rp = best_shape.relative_positions.duplicate()
				possible_shape_shift(rp, best_j, best_shape.on_even)
				var screen_coordinates = []
				
				for r in rp:
					if int(best_j+r.x)%2 == 0:
						screen_coordinates.append(Vector2(bottom_start.x + bottom_hexa_width*3/4*(best_j+r.x), bottom_start.y + (bottom_hexa_width*sqrt(3)/2)*(best_i+r.y)))
					else:
						screen_coordinates.append(Vector2(bottom_start.x + bottom_hexa_width*3/4*(best_j+r.x), bottom_start.y + (bottom_hexa_width*sqrt(3)/2)*(best_i+r.y)+(bottom_hexa_width*sqrt(3)/4)))
					var bottom_field = pkg_bottom_field.instance()
					bottom_field.scale *= bottom_hexa_scale
					bottom_field.texture = bg_hexa_slot_bg_loc[theme_id][2]
					bottom_field.position = screen_coordinates[-1] + Vector2(-1,1)*35*bottom_hexa_scale
					bottom_fields[best_i+r.y][best_j+r.x] = bottom_field
					get_node("bottom_fields").add_child(bottom_field)
					
					var around = mvs1
					if (best_j+int(r.x))%2 == 0: around = mvs2
					for a in around:
						var vert = best_i+r.y+a.y
						var hor = best_j+r.x+a.x
						if vert>=0 and hor>=0 and vert<max_height_down and hor<max_width_down and bottom_fields[vert][hor]==null:
							bottom_fields[vert][hor] = Node
				
				if hexagon_textures_pool==null or len(hexagon_textures_pool)==0:
					hexagon_textures_pool = hexagon_textures.duplicate()
				hexagon_textures_pool.shuffle()
				best_shape.make(screen_coordinates, hexagon_textures_pool.pop_front(), bottom_hexa_scale, hexa_scale)
			else:
				break
		
		var resized_bottom = false
		for shape in shapes:
			if not shape.bottom_fitted:
				new_bottom_row()
				resized_bottom = true
				break
		
		if resized_bottom: continue
		else: break

func new_bottom_row():
	max_height_down += 1
	#print("NEW ROW")
	
	bottom_fields.append([])
	
	for _j in range(max_width_down):
		bottom_fields[-1].append(null)
	
	for j in range(max_width_down):
		var around = mvs2 if j%2 == 0 else mvs1
		for a in around:
			var vert = max_height_down-1+a.y
			var hor = j+a.x
			if vert>=0 and hor>=0 and vert<max_height_down and hor<max_width_down and bottom_fields[vert][hor]!=null and bottom_fields[vert][hor]!=Node:
				bottom_fields[-1][j] = Node
				break

func shape_drag_tutorial(dragging):
	if tut: tut.play_hand_anim(not dragging)

func clear_highlights():
	for row in upper_fields:
		for col in row: if col: col.highlight_for_drop(false, null)

func activate_hint():
	var shapes_not_in_place = []
	for shape in shapes:
		if not shape.in_desired_place() and not shape.was_hint_shape:
			shapes_not_in_place.append(shape)
	if len(shapes_not_in_place) > 0:
		if GJMain.BuyInGameItem(50, "hint"):
			#var hint_shape = shapes_not_in_place[randi()%len(shapes_not_in_place)]
			var hint_shape = shapes_not_in_place[0]
			for shape in shapes_not_in_place:
				if len(shape.hexagons) > len(hint_shape.hexagons):
					hint_shape = shape
			hint_shape.is_hint_shape = true
			hint_shape.was_hint_shape = true
			hint_shape.indicate_hint(true)
			return [true, len(shapes_not_in_place) > 1]
	return [false, len(shapes_not_in_place) > 0]
	
#	var shape_fits = true
#	for hex in hint_shape.original_place_hexas:
#		if hex.taken: 
#			shape_fits = false
#			break
#
#	if shape_fits:
#		hint_shape.position = hint_shape.original_place_hexas[0].get_global_position()
#		hint_shape.scale = Vector2.ONE*hint_shape.zoomed_hexa_scale
#		if hint_shape.placed:
#			for hex in hint_shape.hexagons:
#				hex.drop_on.taken = false
#
#		hint_shape.placed = true
#		for i in range(len(hint_shape.hexagons)):
#			var hex = hint_shape.original_place_hexas[i]
#			hex.taken = true
#			hint_shape.hexagons[i].drop_on = hex
#		check_for_game_end()
#	else:
#		hint_shape.indicate_hint(true)

func check_for_game_end():
	for row in upper_fields:
		for col in row:
			if col and not col.taken: return
	load_new_level()

func load_new_level():
	if has_node("tutorial_screen"):
		get_node("tutorial_screen").queue_free()

	get_node('win_screen/ctr/AnimationPlayer').play('success')
	
	var timer=Timer.new()
	timer.one_shot = true
	timer.set_wait_time(1)
	timer.connect("timeout", self, "clear_screen")
	add_child(timer)
	timer.start()
	
	var timer2=Timer.new()
	timer2.one_shot = true
	add_child(timer2)
	timer2.set_wait_time(2.6)
	timer2.connect("timeout", GJMain, "onLevelComplete", [true])
	timer2.start()

func clear_screen():
	get_node("AnimationPlayer").play("end_fade_out")
	get_node("theme_bg/selection/AnimationPlayer").play("selection_fade_out")
	get_node("game_ui/buy_hint/AnimationPlayer").play("hint_button_fade")


func refine_visibles():
	var min_w = null
	var max_w = null
	
	var min_h = null
	var max_h = null
	
	for i in range(max_height_up):
		var has_any = false
		var c_min_w = null
		var c_max_w = null
		for j in range(max_width_up):
			if upper_fields[i][j]!=null:
				has_any = true
				c_min_w = j if c_min_w==null or j<c_min_w else c_min_w
				c_max_w = j if c_max_w==null or j>c_max_w else c_max_w
		
		min_w = c_min_w if c_min_w!=null and (min_w==null or c_min_w<min_w) else min_w
		max_w = c_max_w if c_max_w!=null and (max_w==null or c_max_w>max_w) else max_w
		if min_h==null and has_any: min_h = i
		if has_any: max_h = i
	
	get_node("upper_fields").position += hexa_width*Vector2(0.75*(max_width_up-1-(max_w+min_w))/2.0, sqrt(3)/2.0*(max_height_up-1-(max_h+min_h))/2.0)

#######

	min_w = null
	max_w = null
	
	min_h = null
	max_h = null
	
	for i in range(max_height_down):
		var has_any = false
		var c_min_w = null
		var c_max_w = null
		for j in range(max_width_down):
			if bottom_fields[i][j]!=null and bottom_fields[i][j]!=Node:
				has_any = true
				c_min_w = j if c_min_w==null or j<c_min_w else c_min_w
				c_max_w = j if c_max_w==null or j>c_max_w else c_max_w
		
		min_w = c_min_w if c_min_w!=null and (min_w==null or c_min_w<min_w) else min_w
		max_w = c_max_w if c_max_w!=null and (max_w==null or c_max_w>max_w) else max_w
		if min_h==null and has_any: min_h = i
		if has_any: max_h = i
	
	var v = bottom_hexa_width*Vector2(0.75*(max_width_down-1-(max_w+min_w))/2.0, sqrt(3)/2.0*(max_height_down-1-(max_h+min_h))/2.0)
	get_node("bottom_fields").position += v
	for shape in shapes:
		shape.position += v
		shape.selection_position = shape.position

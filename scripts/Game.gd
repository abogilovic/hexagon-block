extends Node

const level = preload("res://scenes/level.tscn")
var current_level

func _ready():
	GJMain.onGameReady()
	playLevel(GJMain.getLevel())

func playLevel(lvl : int):
	var l = level.instance()
	if current_level != null:
		current_level.call_deferred("queue_free")
	current_level = l
	add_child(current_level)
	l.generate_level(lvl) #added

func stopLevel():
	current_level.set_process_input(false)
	GJMain.onLevelComplete(false)

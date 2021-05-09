extends Node

func _ready():
	randomize()	
	var level = "Test1"
	var path = 'res://levels/Level%s.tscn' % level
	var map = load(path).instance()
	add_child(map)

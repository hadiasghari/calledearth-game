extends Node

func _ready():
	var level = "Test1"
	var path = 'res://levels/Level%s.tscn' % level
	var map = load(path).instance()
	add_child(map)

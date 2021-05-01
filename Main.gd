extends Node

func _ready():
	var level = "TestJ1"
	var path = 'res://levels/Level%s.tscn' % level
	var map = load(path).instance()
	add_child(map)

extends Control

func _ready():
	randomize()	

func _input(event):
	if event.is_action_pressed('ui_select'):	
		var level = "Test1"
		var path = 'res://levels/Level%s.tscn' % level
		var _err = get_tree().change_scene(path)

	# MAYBE: use some Singleton (e.g. global) ... if our design asks for it

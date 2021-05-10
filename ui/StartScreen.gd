extends Control

func _ready():
	randomize()	

func _input(event):
	if event.is_action_pressed('ui_select'):	
		var level = "Test1"
		var path = 'res://levels/Level%s.tscn' % level
		get_tree().change_scene(path)
		# old:
		# var map = load(path).instance()
		# add_child(map)

	# MAYBE: use some Singleton (e.g. global)

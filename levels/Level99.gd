extends CanvasLayer

# Level 99 is the credits
# in future, we may also add some simple statistics scene at the end

func _ready():
	pass 
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func spawn_energy_item(_etype):
	# do nothing, shouldn't even call here :) (might due to race condition)
	# TODO: in the rare condition that this does get called, then the 
	#       energy bar would reappear, so we should disable it here :)
	pass   

extends Node2D


signal start_next


func _ready():
	# TODO: HIDE THE ButtonPlatform's Button! 
	# TODO: link to necessary signals / HUD code (ro via global)	
	
	pass
	# TODO: we will start with button activated, and no player to hide...
	# NOote: make sure ButtonPlatform is invisible!

	
func _input(event):
	# TODO: this should be set to 4x Xs!  (or SEC)
	if event.is_action_pressed('test_skip_next'):	
		emit_signal("start_next")
		
		

func _on_ButtonPlatform_activated():
	pass # Replace with function body.
	# we should be starting here 


func _on_ButtonPlatform_deactivated():
	pass # Replace with function body.
	# no camera to return, no player to restart, no music to change...
	# probably just go to ther 

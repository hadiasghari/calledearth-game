extends Area2D

# NOTE, this spike object is only used in Level1. 
#       In level 2 we have specific danger tilemaps which are a better solution.

signal hit

func _ready():
	pass

func _on_Spike_body_entered(_body):
	# (note: interesting that spikes detect this collision, not player, 
	#        despite correct masks, cause they are an 'area2D' I think)
	emit_signal("hit")	


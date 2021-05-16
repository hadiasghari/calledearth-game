extends Area2D

# NOTE, this spike object is only used in Level1. 
#       In level 2 we have specific danger tilemaps which are a better solution.

signal hit

func _ready():
	pass

func _on_Spike_body_entered(_body):
	emit_signal("hit")	


extends Area2D

signal hit

# Design notes:
# - the bags moved via a parent pathfollow object, that's why they arent kinematic bodies
# - (it might make more sense to have the path follow be part of the object itself and update the follow here)

func _ready():
	pass 

func _on_PlasticBag_body_entered(_body):	
	# print_debug("bag hit: " + str(_body))  	
	# future: if needed check body is player (not other enemies)!
	emit_signal("hit")	

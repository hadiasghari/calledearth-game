extends Node2D


# TODO:
# - have sprites for different energies
# - they should appear around where the player is, with some randomness
#   ... or move upwards or grow larger as more
# - probably with some sound (maybe even make music somehow!)
# - dissappear after soem time with some tween effect
# - also update the player's global health or sth like that :)

func init(_type, pos):
	# other params maybe: intensinity, color, ...
	position = pos

func _ready():
	$Audio.play()  # make sure not looping :)

func _on_Timer_timeout():	
	var tween = get_node("Tween")	
	tween.interpolate_property($Sprite, "scale",
			Vector2(1.5, 1.5), Vector2(0.1, 0.1), 1,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_Tween_tween_completed(object, key):
	queue_free()

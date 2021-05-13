extends Node2D


var textures = {'l': 'res://assets/art/energy/love.png',
				'f': 'res://assets/art/energy/funny.png',
				'm': 'res://assets/art/energy/mad.png',
				's': 'res://assets/art/energy/sad.png',
				'p': 'res://assets/art/energy/power.png'}


# TODO:
# - have sprites for different energies
# - they should appear around where the player is, with some randomness
#   ... or move upwards or grow larger as more
# - probably with some sound (maybe even make music somehow!)
# - dissappear after soem time with some tween effect
# - also update the player's global health or sth like that :)

func init(type, _emoji, pos):
	$Sprite.texture = load(textures[type])	
	# TOOD: decide whether to place the sender's emoji in the heart
	position = pos

func _ready():
	$Audio.play()  # make sure not looping :)

func _on_Timer_timeout():	
	var tween = get_node("Tween")	
	# TODO: also add a tween so it moves upwards before	disappearing
	tween.interpolate_property($Sprite, "scale",
			Vector2(1, 1), Vector2(0.1, 0.1), 1,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_Tween_tween_completed(_object, _key):
	queue_free()

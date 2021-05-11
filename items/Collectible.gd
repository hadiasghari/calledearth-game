extends Area2D

signal pickup


# TODO: Tweens to make pickup nicer
#func _ready():
#	$Tween.interpolate_property($Sprite, 'scale', Vector2(1, 1),
#			Vector2(3, 3), 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
#	$Tween.interpolate_property($Sprite, 'modulate', Color(1, 1, 1, 1),
#			Color(1, 1, 1, 0), 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
##func _on_Tween_tween_completed( object, key ):
#	queue_free()

var textures = {'yellow': 'res://assets/collect items/collect item yellow.png',
				'aqua': 'res://assets/art/collect items/collect_item_aqua.png',
				'switch': 'res://assets/art/collect items/Switch button.png',
				'spike': 'res://assets/art/collect items/Spikes.png',
				'victory': 'res://assets/art/collect items/Victory button .png'}

var _type = ""

func init(type, pos):
	type = type.to_lower()
	if 'aqua' in type:
		type = 'aqua'
	elif 'yellow' in type:
		type = 'yellow'
	elif 'switch' in type:
		type = 'switch'
	elif 'spike' in type:
		type = 'spike'
	elif 'victory' in type:
		type = 'victory'
	else:
		print_debug('UNKNOWN PICKUP: ' + str(type))
		return ""	
	$Sprite.texture = load(textures[type])
	# TODO: the collision shape should match the textures, which are not same size :(
	#       either have different collisionmaps, different objects, or get from tilemap...
	position = pos
	_type = type
	return type

func _on_Area2D_body_entered(_body):
	emit_signal('pickup') 	# for other pickup logic e.g. spawning words!
	$Audio.play()  # note, perhaps audio should be played in mai
	$CollisionShape2D.disabled = true  # TODO: USE DEFER()
	yield(get_tree().create_timer(0.2), "timeout")
	#$Tween.start()
	queue_free() # hide it! -- in Tween

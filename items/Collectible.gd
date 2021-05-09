extends Area2D

signal pickup

# TODO: add a tween here  (use example code)
#func _ready():
#	$Tween.interpolate_property($Sprite, 'scale', Vector2(1, 1),
#			Vector2(3, 3), 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
#	$Tween.interpolate_property($Sprite, 'modulate', Color(1, 1, 1, 1),
#			Color(1, 1, 1, 0), 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)

#func _on_Tween_tween_completed( object, key ):
#	queue_free()

func init(color, pos):
	# TODO: looking at sample code, it's better to change the sprite resource
	#       	$Sprite.texture = load(textures[_type])   with textures as dict
	if color[0] == 'y':
		$SpriteY.visible = true 
	elif color[0] == 'a':
		$SpriteB.visible = true
	else:
		print('wtf')
	# else raise/error 
	position = pos

func _on_CollisionShape2D_tree_entered():
	pass

func _on_Area2D_body_entered(_body):
	emit_signal('pickup') 	# for other pickup logic e.g. spawning words!
	$Audio.play()  # note, perhaps audio should be played in mai
	$CollisionShape2D.disabled = true
	yield(get_tree().create_timer(0.2), "timeout")
	# $Tween.start()
	queue_free() # hide it!. (note, should be moved to tween-completed)

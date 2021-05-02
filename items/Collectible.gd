extends Area2D

signal pickup

# TODO: add a tween here

func init(color, pos):
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


func _on_Area2D_body_entered(body):
	emit_signal('pickup') 	# for other pickup logic e.g. spawning words!
	$Audio.play()  # note, perhaps audio should be played in mai
	yield(get_tree().create_timer(0.2), "timeout")
	queue_free() # hide it!.

extends KinematicBody2D

export (Vector2) var velocity

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		#print_debug("collision")
		velocity = -velocity  #.bounce(collision.normal)

	#move_and_slide(velocity * delta)
	#for i in range(get_slide_count()):
	#	var c = get_slide_collision(i)
	#	print(c.collider.name)

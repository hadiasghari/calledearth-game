extends KinematicBody2D

export (Vector2) var velocity

func _physics_process(delta):	
	var collision = move_and_collide(velocity * delta)
	if collision:
		# TODO: the platform currently also switches dir when it hits the player,
		#       which is a problem for up-down moving platforms
		#       solution might be to detect the colliding body or to use `velocity.bounce(collision.normal)`
		#       (masks are already correctly set to only `environment`)
		#       (the collision.collider gives generic KinematicBody2d not player)
		velocity = -velocity 


extends KinematicBody2D


export (int) var speed = 20
export (int) var jump_speed = -1800
export (int) var gravity = 4000
#export (float, 0, 1.0) var friction = 0.1
#export (float, 0, 1.0) var acceleration = 0.25



var velocity = Vector2.ZERO


# IF STATEMACHINE (future): 
# enum {IDLE, WALKSLOW, RUN, JUMPFLY}  # DEAD, CROUCH, CLIMB, PUNCH?
# var state


func get_input():
	velocity.x = 0
	var leg_r_dir = 0
	var leg_l_dir = 0
	var moving_leg_l = false
	var moving_leg_r = false
	var moving_wings = false
	
	if Input.is_action_pressed("leg_l_right"):
		leg_l_dir = 1
		moving_leg_l = true
	if Input.is_action_pressed("leg_l_left"):
		leg_l_dir = -1
		moving_leg_l = true
	if Input.is_action_pressed("leg_r_right"):
		leg_r_dir = 1
		moving_leg_r = true
	if Input.is_action_pressed("leg_r_left"):
		leg_r_dir = -1
		moving_leg_r = true
	
	if Input.is_action_pressed("mouth_growl"):
		$mouth.animation = "growl"
		$mouth.play()
		$sound_growl.play()
		$TimerMouthReset.start()
	if Input.is_action_pressed("mouth_sing"):
		$mouth.animation = "sing"
		$mouth.play()
		$sound_singing.play()
		$TimerMouthReset.start()
	if Input.is_action_pressed("mouth_whistle"):
		$mouth.animation = "whistle"
		$mouth.play()
		$sound_whistle.play()
		$TimerMouthReset.start()
								
		
		
	# Note, could maybe make funny movement if in different direction
	velocity.x = pow(leg_r_dir + leg_l_dir, 3) * speed
	
	# friction/acceleration based speed (not in use)
	#	velocity.x = lerp(velocity.x, dir * speed, acceleration)
	#	velocity.x = lerp(velocity.x, 0, friction)		

			
	# should have state = run, idle, jump..
	if velocity.x != 0:
		if moving_leg_l:
			$leg_L.play()
		else:
			$leg_L.stop()
		if moving_leg_r:
			$leg_R.play()
		else:
			$leg_R.stop()	
	else:
		# TODO maybe reset to still frames?
		$leg_L.stop()
		$leg_R.stop()	


	if Input.is_action_pressed("wings_jump"):
		velocity.x *= 5
	
	#if moving_wings == true:
	if not is_on_floor():
		$wings.play()
	else:
		$wings.stop()
	
	if velocity.x < 0:
		#change the location of the arm!! 
		$arm_L.visible = true
		$arm_R.visible = false
		$leg_L.flip_h = true	
		$leg_R.flip_h = true						
	elif velocity.x > 0:
		$arm_L.visible = false
		$arm_R.visible = true	
		$leg_L.flip_h = false	
		$leg_R.flip_h = false			
		
			
				
func _ready():
	# idle
	pass 


func _physics_process(delta):
	get_input()
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	if Input.is_action_just_pressed("wings_jump"):
		if is_on_floor():
			velocity.y = jump_speed
			
	if position.y > 1000: 
		# player has fallen, is dead!
		# hide()
		# emit_signal('dead')
		# show on HUD 'game over!'
		yield(get_tree().create_timer(2.0), "timeout")
		get_tree().change_scene("res://Main.tscn")
		
		



func _on_TimerMouthReset_timeout():
	# reset the mouth :)
	$sound_growl.stop()
	$sound_whistle.stop()
	$sound_singing.stop()	
	$mouth.animation = "default_smile"
	$mouth.play()


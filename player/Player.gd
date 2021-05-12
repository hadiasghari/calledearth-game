extends KinematicBody2D

signal dead
signal switch
export (int) var speed = 20
export (int) var jump_speed = -1800
export (int) var gravity = 4000

var velocity = Vector2.ZERO
var devoffset = 0  # also should respond to pickup signals (later)
var mouth_action = 0

				
func _ready():
	# set sounds to be played once (not in loop)
	$mouth/growl.stream.set_loop(false)	
	$mouth/singing.stream.set_loop(false)		
	$mouth/whistle.stream.set_loop(false)		
	$mouth/yawn.stream.set_loop(false)		
	$wings/Sound.stream.set_loop(false)			
	# defaults now: $arms/arm_L.animation = "push"
	# $arms/arm_R.animation = "push"	

func get_input():
		# logic for rotating functions of four controllers
	if Input.is_action_just_pressed("rotate"):
		emit_signal('switch')  # rotate devoffset += 1 via Level to get HUD
		print_debug('device-offset: ' + str(devoffset))
	var dev0 = "dev" + str((0 + devoffset) % 4)
	var dev1 = "dev" + str((1 + devoffset) % 4)
	var dev2 = "dev" + str((2 + devoffset) % 4)
	var dev3 = "dev" + str((3 + devoffset) % 4)
	
	# I. leg movement (dev0 & dev1)	
	var motion_legl = 0
	var motion_legr = 0
	if Input.is_action_pressed(dev0 + "_right"):
		motion_legl = 1
	if Input.is_action_pressed(dev0 + "_left"):
		motion_legl = -1
	if Input.is_action_pressed(dev1 + "_right"):
		motion_legr = 1
	if Input.is_action_pressed(dev1 + "_left"):
		motion_legr = -1

	velocity.x = pow(motion_legl + motion_legr, 3) * speed	
	# friction/acceleration based speed (not in use)
	#	velocity.x = lerp(velocity.x, dir * speed, acceleration)
	#	velocity.x = lerp(velocity.x, 0, friction)		
			
	if velocity.x != 0:
		if abs(motion_legl) > 0:
			$leg_L.play()
		else:
			$leg_L.stop()
		if abs(motion_legr) > 0:
			$leg_R.play()
		else:
			$leg_R.stop()	
	else:
		# TODO maybe reset to still frames?
		# (Note, could maybe make funny movement if in different direction)
		$leg_L.stop()
		$leg_R.stop()
		
	if velocity.x < 0:	
		$leg_L.flip_h = true	
		$leg_R.flip_h = true						
	elif velocity.x > 0:
		$leg_L.flip_h = false	
		$leg_R.flip_h = false			

	# II. logic for wings (dev 2)
	if Input.is_action_pressed(dev2 + "_action"):
		velocity.x *= 5  # speed up during jump	
	if Input.is_action_just_pressed(dev2 + "_action"):
		# make sound when just pressed
		$wings/Sound.play()	
		$wings/Collision.visible = true				
	if Input.is_action_just_pressed(dev2 + "_action") or not is_on_floor():
		# flap wings when just pressed or otherwise in air
		$wings/Sprite.play()
	elif is_on_floor() and $wings/Sprite.playing:
		# if hit ground, wait a sec before stopping flapping!		
		#print('on floor, lets stop!')
		yield(get_tree().create_timer(0.1), "timeout")  # was 0.2
		$wings/Sprite.stop()
		$wings/Sprite.frame = 4
		$wings/Collision.visible = false
	
	# III. logic for arms (dev 3)
	# first show correct direction of arms re legs	
	if velocity.x < 0:
		#change the location of the arm!! 
		$arms/arm_L.visible = true
		$arms/arm_R.visible = false
	elif velocity.x > 0:
		$arms/arm_R.visible = true		
		$arms/arm_L.visible = false
				
	if Input.is_action_just_pressed(dev3 + "_action"):
		if $arms/arm_L.visible:	
			$arms/arm_L.play()
		else:
			$arms/arm_R.play()	
				
	# IV. finally, logic for mouth (all devices)
	# NOTE: if we odn't want mixing of sounds at one time, 
	#       we should have one audio2d and stop/restart it
	if Input.is_action_just_pressed(dev0 + "_mouth"):
		$mouth.animation = "growl"
		$mouth/growl.play()
	if Input.is_action_just_pressed(dev1 + "_mouth"):
		$mouth.animation = "whistle"
		$mouth/whistle.play()
	if Input.is_action_just_pressed(dev2 + "_mouth"):
		$mouth.animation = "sing"
		$mouth/singing.play()
	if Input.is_action_just_pressed(dev3 + "_mouth"):
		$mouth.animation = "yawn"
		$mouth/yawn.play()

func _physics_process(delta):
	get_input()  # sets velocity.x and motions
	
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP, 
							  false, 4, 0.785398, false)
	if abs(velocity.x) < 1:
		velocity.x = 0  # avoid very small slides for smoothness
	
	# some more of the logic for the jump
	var dev2 = "dev" + str((2 + devoffset) % 4)
	if Input.is_action_just_pressed(dev2 + "_action"):
		if is_on_floor():
			velocity.y = jump_speed
		
	# check if player has fallen, is dead!			
	if position.y > 1000: 
		# TODO: This is buggy method, it seems to get stuck repeating here while other processes/signal
		#       get postponed.... 
		#       this is a problem for the death music (which wouldn't work even played from here)
		#velocity.y = 0
		set_physics_process(false)		
		emit_signal('dead')   # for HUD plus restart game  ...

func _on_sound_growl_finished():
	$mouth.animation = "default_smile"
	$mouth.play()

func _on_sound_singing_finished():
	$mouth.animation = "default_smile"
	$mouth.play()

func _on_sound_whistle_finished():
	$mouth.animation = "default_smile"
	$mouth.play()

func _on_sound_yawn_finished():
	$mouth.animation = "default_smile"
	$mouth.play()

func _on_arm_R_animation_finished():
	$arms/Collision_R.disabled = false	
	yield(get_tree().create_timer(1), "timeout")
	$arms/Collision_R.disabled = true	
	# wouldn't retrigger not sure why, $arms/arm_R.play("", true)  
	$arms/arm_R.frame = 0
	$arms/arm_R.stop()

func _on_arm_L_animation_finished():
	$arms/Collision_L.disabled = false	
	yield(get_tree().create_timer(1), "timeout")
	$arms/Collision_L.disabled = true	
	$arms/arm_L.frame = 0
	$arms/arm_L.stop()

func _on_arms_body_entered(body):
	# This is entered when we PUSH WORDS
	# TODO: this is somewhat clunky, even with arms & wings... (learn `impulse`)
	# 	   (- maybe we also need some inertia when the creature is on top	)
	if 'RigidBody' in str(body):
		if $arms/arm_R.visible:
			print('push word left')
			body.apply_impulse(Vector2(), Vector2(3000, 0) )
		elif $arms/arm_L.visible:
			print('push word right')			
			body.apply_impulse(Vector2(), Vector2(-3000, 0) )

func _on_wings_body_entered(body):
	if 'RigidBody' in str(body):
		if $wings/Collision.visible:  # is this necessary?
			print_debug(body)
			body.apply_impulse(Vector2(), Vector2(0, -5000) )
 

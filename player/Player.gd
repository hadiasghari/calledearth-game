extends KinematicBody2D

signal dead

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
	# defaults now: $arms/arm_L.animation = "push"
	# $arms/arm_R.animation = "push"	

func get_input():
		# logic for rotating functions of four controllers
	if Input.is_action_just_pressed("rotate"):
		devoffset += 1
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
		#print_debug('jump')
		velocity.x *= 5  # speed up during jump	
	if not is_on_floor():
		$wings.play()
	else:
		$wings.stop()
	
	# III. logic for arms (dev 3)
	# first show correct direction of arms re legs	
	if velocity.x < 0:
		#change the location of the arm!! 
		$arms/arm_L.visible = true
		$arms/arm_R.visible = false
	elif velocity.x > 0:
		$arms/arm_R.visible = true		
		$arms/arm_L.visible = false
				
	if Input.is_action_pressed(dev3 + "_action"):
		#print_debug('arm-push')
		if $arms/arm_L.visible:	
			$arms/arm_L.play()
		else:
			$arms/arm_R.play()		
		$arms/CollisionShape2D.disabled = false
		$arms/arms_Timer.start()
		# TODO: turn on specific collision sheet too 
		# ALSO, SOUND?
				
	# IV. finally, logic for mouth (all devices)
	# NOTE: if we odn't want mixing of sounds at one time, 
	#       we should have one audio2d and stop/restart it
	if Input.is_action_just_pressed(dev0 + "_mouth"):
		$mouth.animation = "growl"
		#$mouth.play()
		$mouth/growl.play()
	if Input.is_action_just_pressed(dev1 + "_mouth"):
		$mouth.animation = "whistle"
		#$mouth.play()
		$mouth/whistle.play()
	if Input.is_action_just_pressed(dev2 + "_mouth"):
		$mouth.animation = "sing"
		#$mouth.play()
		$mouth/singing.play()
	if Input.is_action_just_pressed(dev3 + "_mouth"):
		$mouth.animation = "yawn"
		#$mouth.play()
		$mouth/yawn.play()


func _physics_process(delta):
	get_input()  # sets velocity.x and motions
	
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	if abs(velocity.x) < 1:
		velocity.x = 0  # avoid very small slides for smoothness
	
	# some more of the logic for the jump
	var dev2 = "dev" + str((2 + devoffset) % 4)
	if Input.is_action_just_pressed(dev2 + "_action"):
		if is_on_floor():
			velocity.y = jump_speed
		
	# check if player has fallen, is dead!			
	if position.y > 1000: 
		emit_signal('dead')   # for HUD plus restart game  ...
		yield(get_tree().create_timer(1.0), "timeout")  # Take a moment :)
		get_tree().change_scene("res://Main.tscn")  # TODO move to level/main (signal)


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

func _on_arms_Timer_timeout():
	$arms/CollisionShape2D.disabled = true
	if $arms/arm_L.visible:
		$arms/arm_L.play("", true)
	elif $arms/arm_R.visible:
		$arms/arm_R.play("", true)
	

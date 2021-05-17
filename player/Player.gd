extends KinematicBody2D

signal dead(why)
signal energy(value)  # to update energy
signal switched(offset)   # just for HUD

export (int) var speed = 20
export (int) var jump_speed = -1800
export (int) var gravity = 4000
export (int) var pos_y_dead = 2000

var velocity = Vector2.ZERO
var devoffset = 0  # responds to rotate and limb_switch

				
func _ready():
	# set sounds to be played once (not in loop)
	$mouth/growl.stream.set_loop(false)	
	$mouth/singing.stream.set_loop(false)		
	$mouth/whistle.stream.set_loop(false)		
	$mouth/yawn.stream.set_loop(false)		
	$wings/Sound.stream.set_loop(false)			
	# (defaults already: $arms/arm_L.animation = "push")
	

func freeze_player(is_dead):
	if is_dead == true:
		set_physics_process(false)  # necessary to avoid hogging system, plus dramatic effects
		$TimerEnergy.stop()
		$wings/Sprite.speed_scale = 0.2
		$mouth.animation = "dies"
		$leg_L.stop()
		$leg_R.stop()
		velocity = Vector2()
	else:
		set_physics_process(true) 
		$wings/Sprite.speed_scale = 1
		$mouth.animation = "default_smile"
		$mouth.play()
		$TimerEnergy.start()
	# visual effects too
	var filter = Color(0, 1, 0 ) if is_dead else Color(1, 1, 1)		
	$wings/Sprite.self_modulate = filter
	$arms/arm_R.self_modulate = filter
	$arms/arm_L.self_modulate = filter
	$leg_L.self_modulate = filter
	$leg_R.self_modulate = filter
	$mouth.self_modulate = filter


func get_input():
		# logic for rotating functions of four controllers
	if Input.is_action_just_pressed("rotate"):
		limb_switch()

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
		# Notes: - maybe reset to still frames?
		#        - could maybe make funny movement if in different direction?
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
		emit_signal("energy", -1)		
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
		
	# process collisions
	 # TODO: we could emit dead signal multiple times, not sure if that's a problem, perhaps it's better to be patient and to it once? :)
	for i in range(get_slide_count()):
		var collision = get_slide_collision(i)
		var s = collision.collider.name.to_lower()
		if s.begins_with("tilemap_world"):
			continue  # normal
		elif s == "words" or s == "platform":
			# words, platforms, ingore 			
			continue  
		elif s == "plasticbag":
			# TODO: we should stop this particular plastic bag too!
			#print_debug('Hit PlasticBag')
			freeze_player(true)
			emit_signal('dead', 'bag')
		elif s == "tilemap_danger":
			# TODO: move the word lower
			#print_debug('Hit Map Danger')
			freeze_player(true)
			emit_signal('dead', 'mapdanger')
		else: 
			print("player collision: " + s)  # also is_in_group('enemies'):
		# note (re godot collisions): 
		#        nothing here when hand touches button, we hit collectible item, or fall on Spikes in L1 
	
	# some more of the logic for the jump
	var dev2 = "dev" + str((2 + devoffset) % 4)
	if Input.is_action_just_pressed(dev2 + "_action"):
		if is_on_floor():
			velocity.y = jump_speed
		
	# check if player has fallen, is dead!			
	if position.y > pos_y_dead: 
		freeze_player(true)
		emit_signal('dead', 'fall')


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
	# wouldn't retrigger, not sure why: $arms/arm_R.play("", true)  
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
		if $wings/Collision.visible:  # why is this necessary?
			print_debug(body)
			body.apply_impulse(Vector2(), Vector2(0, -5000) )
 

func limb_switch():
	devoffset += 1		
	print_debug('device-offset: ' + str(devoffset))
	emit_signal('switched', devoffset%4)  # inform eg for HUD


func _on_TimerEnergy_timeout():
	emit_signal("energy", -1) 

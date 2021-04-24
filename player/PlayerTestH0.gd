extends KinematicBody2D


export (int) var speed = 20
export (int) var jump_speed = -1800
export (int) var gravity = 4000
export (float, 0, 1.0) var friction = 0.1
export (float, 0, 1.0) var acceleration = 0.25

var velocity = Vector2.ZERO

enum {IDLE, RUN, JUMP, HURT, DEAD, CROUCH, CLIMB}
var state
var anim_l1
var anim_l2
var moving_l1
var moving_l2

func get_input():
	velocity.x = 0
	var leg1 = 0
	var leg2 = 0
	moving_l1 = false
	moving_l2 = false
	
	if Input.is_action_pressed("walk_right"):
		leg1 = 1
		$LegL.flip_h = true
		moving_l1 = true
	if Input.is_action_pressed("walk_left"):
		leg1 = -1
		$LegL.flip_h = false	
		moving_l1 = true
	if Input.is_action_pressed("walk2_right"):
		leg2 = 1
		$LegR.flip_h = false
		moving_l2 = true
	if Input.is_action_pressed("walk2_left"):
		leg2 = -1
		$LegR.flip_h = true
		moving_l2 = true
	
	# could make funny movement if in different direction
	velocity.x = pow(leg1 + leg2, 3) * speed
	
	
	#	velocity.x = lerp(velocity.x, dir * speed, acceleration)
	#else:
	#	velocity.x = lerp(velocity.x, 0, friction)		

			
	# should have state = run, idle, jump..
	if moving_l1 == true:
		$LegL.play()
	else:
		$LegL.stop()
	if moving_l2 == true:
		$LegR.play()
	else:
		$LegR.stop()	
		

		
				
func _ready():
	# idle
	pass # Replace with function body.


func _physics_process(delta):
	get_input()
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	#if Input.is_action_just_pressed("jump"):
	#    if is_on_floor():
	#        velocity.y = jump_speed

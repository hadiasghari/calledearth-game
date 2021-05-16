tool
extends Node2D

var Words = preload('./Words.tscn')
#can't use this: onready var GLOBAL ... re `tool`

export var prompt_key = 99999
export var platform_off_x = 0
export var platform_off_y = 0
export var platform_length = 500
export var exitarea_off_x = 80  # could also add exit_height
export var prompt_off_y = -200
export var camera_off_y = 0
export var already_pressed = false
export var fake_data = false

var _last_text_pk = -1
var _color_ix = randi()

signal activated
signal deactivated


# TODO: we need additional deactivation collision map for the failsafe
# TODO: above gives error, suggests to use set_deferred to change monitoring state

# FUTURE: what's the best way so that the platform offset/position change dynamically in the editor? 
#         (combo of `tool` and codes below update it once scene opened only)
# FUTURE: (Design Q): should the HTTP communication be removed from this class fully?


func _ready():
	if already_pressed and not Engine.editor_hint:
		web_prompt()	
	
	
func _on_tree_entered():
	$Platform.position = Vector2(platform_off_x, platform_off_y)
	$Platform/CollisionShape2D.shape.extents[0] = platform_length/2
	$Label.set_size(Vector2(platform_length, 50)) 
	$Label.rect_position[0] = platform_off_x - platform_length/2 - 20
	$Label.rect_position[1] += prompt_off_y  
	$ExitArea.position[0] = platform_length + exitarea_off_x 
	$Platform/Camera2D.position[1] += camera_off_y
	if already_pressed:
		$Button/AnimatedSprite.frame = 5
		$Button/CollisionShape2D.disabled = true  
		# ? shall we ? $Platform/CollisionShape2D.disabled = false			
	
	
func _process(_delta):
	if not Engine.editor_hint:
		if Input.is_action_just_pressed("test_skip_next"):
			# use the ESC key only if we are already activated
			if $Button/CollisionShape2D.disabled:
				_on_ExitArea_bodyentered("fakeKinematicBody2D")
		

func _on_HTTPTimer_timeout():
	if not Engine.editor_hint:
		var request = HTTPRequest.new()
		add_child(request)  # might be better to add these to a subnode, so we can free them
		request.connect("request_completed", self, "_on_HTTPRequest_texts_completed")
		var GLOBAL = get_node("/root/Global")		
		request.request(GLOBAL.server_url + "/earth/gogettexts/" + GLOBAL.game_id + "/" + str(prompt_key)) 

func _on_HTTPRequest_texts_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		if response:
			#print("DBG HTTP prompt " + str(prompt_key) + ": " + str(len(response)))
			for r in response:
				# we are assuming this is ordered by pk, this is to show only new texts
				# if goal is replay, time should be compared with game_time instead.
				if r.pk > _last_text_pk:
					spawn_words(r.text, r.parti_code)
					_last_text_pk = r.pk
					yield(get_tree().create_timer(0.3), "timeout")
		else:
			print_debug("Error parsing: " + body.get_string_from_utf8())
		

func spawn_words(text, ecode):
	var w = Words.instance()
	var pos = $Platform.position - Vector2(platform_length/2, 50)        
	w.init(pos, text, ecode, platform_length, _color_ix)
	_color_ix += 1
	add_child(w)


func _on_Button_area_entered(_area):
	if not Engine.editor_hint:
		$Button/CollisionShape2D.disabled = true  # so not to trigger again -- some error 
		$Button/Audio.play()
		$Button/AnimatedSprite.play()


func _on_Button_animation_finished():
	# the mechanism button has been pressed! activate!
	yield(get_tree().create_timer(1), "timeout")
	$Platform/CollisionShape2D.disabled = false
	$Platform/Camera2D.current = true  # Q: can we pan to it?
	emit_signal('activated') 
	web_prompt()


func web_prompt():		
	# set DB to this prompt!  (no timeout needed, we assume success)		
	if fake_data:
		var test_strings = ["There were many words for her.", "Zoinks", 
		"Crikey", "None of them were more than sound.", "Oh my God", "WTF",
		"By coincidence, or by choice, or by miraculous design, " \
		+ "she settled into such a particular orbit around the sun that after the moon had been knocked from her belly " \
		+ "and pulled the water into sapphire blue oceans " \
		+ "the fire and brimstone had simmered, and the land had stopped buckling and heaving with such relentless vigor, " \
		+ "she whispered a secret code amongst the atoms, and life was born.",
		"She rocked her new creation and spun and danced around the bright sun as her children multiplied in number, wisdom, and beauty." ,
		"The End!"]
		for s in test_strings:
			if get_tree():  # in case we escaped before completion here
				spawn_words(s, 127913)
				yield(get_tree().create_timer(0.8), "timeout")	
	else:	
		var request = HTTPRequest.new()
		add_child(request)
		request.connect("request_completed", self, "_on_HTTPRequest_prompt_completed")	
		var GLOBAL = get_node("/root/Global")				
		var err = request.request(GLOBAL.server_url + "/earth/gosetprompt/" + GLOBAL.game_id + "/" + str(prompt_key)) 	
		print("Button sent prompt " + str(prompt_key) + " → " + str(err))
		$HTTPTimer.start()	


func _on_HTTPRequest_prompt_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		print("DBG prompt " + str(response))
		$Label.text = str(response)

	
func _on_ExitArea_bodyentered(body):
	if 'KinematicBody2D' in str(body):
		emit_signal('deactivated') 
		if not fake_data:
			var request = HTTPRequest.new()
			add_child(request)
			var GLOBAL = get_node("/root/Global")					
			var err = request.request(GLOBAL.server_url + "/earth/gosavegame/" + GLOBAL.game_id + "/btn" + str(prompt_key)) 	
			print("Mechanism deactivated " + str(prompt_key) + " → " + str(err))

tool  
extends Node2D

# Notes: 
# 1. The `tool` at top of this script means its code runs in the editor
#     we want this so the platform size/offset changes can be visually scene
#    - However, the scene doesn't fully refresh in editor on the fly still
#      and needs to be closed/opened (to figure out in future)!
#    - Also FYI because of `tool` mode, we cannot use `onready var GLOBAL`		 

# 2. The scene also handles communications with Django re saving prompts
#    - Future design Q: should the HTTP communications be moved outside this scene?

export var prompt_key = 99999
export var platform_offset = Vector2()
export var platform_length = 500
export var prompt_offset = Vector2(0, 0)  # length same as platform
export var prompt_length = 500
export var exitarea_offset = Vector2()  
#export var exitarea_length = 500  # use platform_length for now (sync)
export var exitarea_hitcount = 3
export var camera_offset = Vector2(0, -100)
export var already_pressed = false
export var test_fake_data = false

signal activated
signal deactivated

var Words = preload('./Words.tscn')
var _last_text_pk = -1
var _color_ix = randi()
var _is_activated = false
var words_in_exit = {}


func _ready():
	if not Engine.editor_hint and not test_fake_data:
		$PromptLabel.text = ""  # remove 'provocation'
	if already_pressed and not Engine.editor_hint:
		# note, we don't activate the camera for `alread pressed`		
		#       also, we give wait a few seconds to ensure we have a gameid
		yield(get_tree().create_timer(2), "timeout") 		
		_is_activated = true	
		set_web_prompt()	
	
func _on_tree_entered():
	# position platform on offset, set its length (via its collisionshape)
	$Platform.position = platform_offset
	$Platform.position[0] += platform_length/2
	$Platform/CollisionShape2D.shape.extents[0] = platform_length/2	
	# position prompt label
	$PromptLabel.set_size(Vector2(prompt_length, 100)) 
	$PromptLabel.rect_position = prompt_offset
	# position ExitArea	
	$ExitArea.position = exitarea_offset  
	$ExitArea.position[0] += platform_length/2  # should be close to platform length anyway
	$ExitArea/CollisionShape2D.shape.extents[0] = platform_length/2
	# position camera 
	$Platform/Camera2D.position = camera_offset
	if already_pressed:
		$Button/AnimatedSprite.frame = 5
		$Button/CollisionShape2D.disabled = true  
	
func _process(_delta):
	# use the ESC key as failsafe to deactivate ... if we are already `activated`	
	if not Engine.editor_hint:
		if Input.is_action_just_pressed("test_skip_next"):
			if _is_activated:
				deactivate_prompt()
		
func _on_Button_area_entered(_area):
	# activated
	if not Engine.editor_hint:
		$Button/CollisionShape2D.disabled = true  
			# so not to trigger again 
			# TODO: FIX THE `defer` error raised below by Godot (see TODO notes for story)
		if not _is_activated:
			$Button/Audio.play()
		$Button/AnimatedSprite.play()
		emit_signal('activated')  # immediately freeze player (via level)
		_is_activated = true  # this must be here so it can be deactivated

func _on_Button_animation_finished():
	# the mechanism button has been pressed! activate!
	yield(get_tree().create_timer(1), "timeout")
	$Platform/CollisionShape2D.disabled = false
	$Platform/Camera2D.current = true
	set_web_prompt()

func set_web_prompt():		
	# set DB to this prompt!  
	if test_fake_data:
		var test_strings = ["There were many words for her.", "Zoinks", 
		"Crikey", "None of them were more than sound.", "Oh my God", "WTF",
		"By coincidence, or by choice, or by miraculous design, " \
		+ "she settled into such a particular orbit around the sun that after the moon had been knocked from her belly " \
		+ "and pulled the water into sapphire blue oceans " \
		+ "the fire and brimstone had simmered, and the land had stopped buckling and heaving with such relentless vigor, " \
		+ "she whispered a secret code amongst the atoms, and life was born.",
		"She rocked her new creation and spun and danced around the bright sun as her children multiplied in number, wisdom, and beauty." ,
		"The End!"]
		for _i in range(3):  
			for s in test_strings:
				if get_tree():  # check, in case we escape scene before spawing all words
					spawn_words(s, 127913)
					yield(get_tree().create_timer(0.8), "timeout")	
	else:	
		# also, hopefully we already have the new gameid...
		var GLOBAL = get_node("/root/Global")				
		if GLOBAL and GLOBAL.game_id:
			var request = HTTPRequest.new()
			add_child(request)
			request.connect("request_completed", self, "_on_HTTPRequest_prompt_completed")	
			var url = GLOBAL.server_url + "/earth/gosetprompt/" + GLOBAL.game_id + "/" + str(prompt_key)
			var _err = request.request(url) 	
			print("WriteButton sent prompt " + str(prompt_key))
			$HTTPTimer.start()	
		else:
			print_debug("Error, no GLOBAL.game_id!")			

func _on_HTTPRequest_prompt_completed(_result, _response_code, _headers, body):
	# Set label to prompt text (from server)
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		$PromptLabel.text = str(response)

func _on_HTTPTimer_timeout():
	# periodically check for new words by users
	if not Engine.editor_hint:
		var request = HTTPRequest.new()
		add_child(request)  # might be better to add these to a subnode, so we can free them
		request.connect("request_completed", self, "_on_HTTPRequest_texts_completed")
		var GLOBAL = get_node("/root/Global")		
		if GLOBAL:
			var url = GLOBAL.server_url + "/earth/gogettexts/" + GLOBAL.game_id + "/" + str(prompt_key)
			#print_debug(url)
			request.request(url) 

func _on_HTTPRequest_texts_completed(_result, _response_code, _headers, body):
	# the call finished, lets show it if it actually includes something :)
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		if response:
			for r in response:
				# Note, we are assuming DB orders thisby pk, and this is how we show only new texts
				if r.pk > _last_text_pk:
					spawn_words(r.text, r.parti_code)
					_last_text_pk = r.pk
					yield(get_tree().create_timer(0.3), "timeout")
		
func spawn_words(text, ecode):
	var w = Words.instance()
	var pos = $Platform.position - Vector2(platform_length/2, 50)        
	# position is changed to left/right of this middle in the word init
	w.init(pos, text, ecode, platform_length, _color_ix)
	_color_ix += 1
	add_child(w)

func _on_ExitArea_bodyentered(body):
	# Deactivation mechanism. 
	# note: key is to make sure one word hasn't accidently flung through
	#       i now check this by count new words that pass (+ area dampens word movement)
	#       (alt ideas are to calc overlap % or have multiple hit areas)
	var name = str(body)
	if "RigidBody2D" in name:
		words_in_exit[name] = words_in_exit.get(name, 0) + 1
	else:
		print_debug("unexpected collision detection: ", name)	
	if len(words_in_exit) >= exitarea_hitcount:
		#print_debug("WriteButton met hit count: " + str(len(words_in_exit)))
		$ExitArea/CollisionShape2D.disabled = true  # avoid further collisions (same `defer` error, ignore)
		deactivate_prompt()
		
func deactivate_prompt():
	if _is_activated:  
		# check since this function can hit multiple times!
		_is_activated = false
		emit_signal('deactivated') 
		if not test_fake_data:
			var request = HTTPRequest.new()
			add_child(request)
			var GLOBAL = get_node("/root/Global")	# shouldn't be null (i.e. this func won't call if we are unloaded)
			var url = GLOBAL.server_url + "/earth/gosetprompt/" + GLOBAL.game_id + "/0"	  # unset prompt		
			var _err = request.request(url) 	
		print("WriteButton deactivated for prompt " + str(prompt_key))
	#print_debug(words_in_exit)

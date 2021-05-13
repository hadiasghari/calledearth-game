extends Node2D

var Words = preload('./Words.tscn')

export var prompt_key = 99999
export var platform_off_x = 0
export var platform_off_y = 0
export var platform_length = 500
export var exitarea_off_x = 80  # could also add exit_height
export var prompt_off_y = -200
export var camera_off_y = 0
#export var camera_zoom = 2  # this cannot really be changed it seems?
export var test_mode = false
signal activated
signal deactivated

var _gameid = ""
var _server_url = ""
var _last_text_pk = -1
var _color_ix = randi()

# TODO: how can the platform offset shape/place show in the editor too? 
# TODO: possibly needs redo ability (words load from database)

func init(server_url, gameid):
	_gameid = gameid
	_server_url = server_url
	#print("Mechanism got gameid:" + _gameid)
	
func _on_Mechanism_tree_entered():
	$Platform.position = Vector2(platform_off_x, platform_off_y)
	$Platform/CollisionShape2D.shape.extents[0] = platform_length/2
	$Label.set_size(Vector2(platform_length, 50)) 
	$Label.rect_position[0] = platform_off_x - platform_length/2 - 20
	$Label.rect_position[1] += prompt_off_y  
	$AreaExit.position[0] = platform_length + exitarea_off_x 
	$Platform/Camera2D.position[1] += camera_off_y
	#$Platform/Camera2D.zoom = Vector2(camera_zoom, camera_zoom)  # does wierd things
	
func _ready():
	pass	
	
func _process(delta):
	if Input.is_action_just_pressed("button_failsafe"):
		_on_AreaExit_body_entered("fakeKinematicBody2D")
		# TODO we need addition deactivations but this is failsafe
		

func _on_HTTPTimer_timeout():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_texts_completed")
	http_request.request(_server_url + "/earth/gogettexts/" + _gameid + "/" + str(prompt_key)) 
	#print_debug(_server_url + "/earth/gogettexts/" + _gameid + "/" + str(prompt_key))

var _last_dbg = 0

func _http_request_texts_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		# TODO: 'error parsing json unexpected chracter. hmmm. 
		if response:
			if len(response) != _last_dbg:
				print("DBG HTTP prompt " + str(prompt_key) + ": " + str(len(response)))
				_last_dbg = len(response)
			for r in response:
				# we are assuming this is ordered by pk, this is to show only new texts
				# if goal is replay, time should be compared with game_time instead.
				if r.pk > _last_text_pk:
					spawn_words(r.text, r.parti_code)
					_last_text_pk = r.pk
					yield(get_tree().create_timer(0.3), "timeout")

func spawn_words(text, ecode):
	var w = Words.instance()
	var pos = $Platform.position - Vector2(platform_length/2, 50)        
	w.init(pos, text, ecode, platform_length, _color_ix)
	_color_ix += 1
	add_child(w)

func _on_Button_area_entered(_area):
	$Button/CollisionShape2D.disabled = true  # so not to trigger again
	# TODO: above gives error, suggests to use set_deferred to change monitoring state
	$Button/Audio.play()
	$Button/AnimatedSprite.play()

func _on_AnimatedSprite_animation_finished():
	# the mechanism button has been pressed! activate!
	yield(get_tree().create_timer(1), "timeout")
	$Platform/Camera2D.current = true  # Q: can we pan to it?
	$Platform/CollisionShape2D.disabled = false
	emit_signal('activated') 
	# set DB to this prompt!  (no timeout needed, we assume success)
	
	if test_mode:
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
			spawn_words(s, 127913)
			yield(get_tree().create_timer(1), "timeout")	
	else:	
		var http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.connect("request_completed", self, "_http_request_prompt_completed")	
		var err = http_request.request(_server_url + "/earth/gosetprompt/" + _gameid + "/" + str(prompt_key)) 	
		print("Mechanism sent prompt " + str(prompt_key) + " → " + str(err))
		$HTTPTimer.start()	

func _http_request_prompt_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		print("DBG prompt " + str(response))
		$Label.text = str(response)
		
func _on_AreaExit_body_entered(body):
	if 'KinematicBody2D' in str(body):
		#print('enter')
		emit_signal('deactivated') 
		if 	not test_mode:
			var http_request = HTTPRequest.new()
			add_child(http_request)
			var err = http_request.request(_server_url + "/earth/gosavegame/" + _gameid + "/btn" + str(prompt_key)) 	
			print("Mechanism deactivated " + str(prompt_key) + " → " + str(err))
			


extends Node2D

var Words = preload('./Words.tscn')

export var prompt_key = 99999

export var platform_off_x = 0
export var platform_off_y = 0
export var platform_length = 500

var _gameid = ""
var _server_url = ""
var _last_text_pk = -1

var _color_ix = randi()

signal activated


# design notes: 1. it seems logical to have the prompt-key tied to the button
#         on the button, instead of having to infer it from the DB
#         2. when the button is activated and we enter text-provocation-mode,
#         then these words need to fill somehwere up. I think that could also be an object
#         with an area/shape, and that object should belinked here to the button then...
#         (or some other way for code ot know where to spawn new words then) 

	# TODO: PLACE WPRDS IN PROPER PLACE
	# TODO: needs some fulfil condition (i.e. got enough words), set inside AND OUTISDE of it (thus by a signal too!)

func init(server_url, gameid):
	_gameid = gameid
	_server_url = server_url
	print("Mechanism got gameid:" + _gameid)
	# TODO two godot design qs:
	# - what's the best way to call this, should this receive signals?
	# - how can the platform offset shape/place show in the editor too? 

func _ready():
	$Platform.position = Vector2(platform_off_x, platform_off_y)
	$Platform/CollisionShape2D.shape.extents[0] = platform_length/2
	# TODO: if we are replaying, then we need to give current sate of this button and have all the words loaded immediately :)	
	
	# TEMP test mode
	var testmode = ["There were many words for her.", 
	"None of them were more than sound.", 
	"By coincidence, or by choice, or by miraculous design, " \
	+ "she settled into such a particular orbit around the sun that after the moon had been knocked from her belly " \
	+ "and pulled the water into sapphire blue oceans " \
	+ "the fire and brimstone had simmered, and the land had stopped buckling and heaving with such relentless vigor, " \
	+ "she whispered a secret code amongst the atoms, and life was born.",
	"She rocked her new creation and spun and danced around the bright sun as her children multiplied in number, wisdom, and beauty." 
	]
	for s in testmode:
		spawn_words(s, 127913)
		yield(get_tree().create_timer(1), "timeout")	
		
	$Platform/Camera2D.current = true
	

func _on_HTTPTimer_timeout():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_completed")
	http_request.request(_server_url + "/earth/gogettexts/" + _gameid + "/" + str(prompt_key)) 
	print_debug(_server_url + "/earth/gogettexts/" + _gameid + "/" + str(prompt_key))

func _http_request_completed(_result, _response_code, _headers, body):
	#print_debug("http-requst-complete")	
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		print("DBG HTTP prompt " + str(prompt_key) + ": ", response)   
		for r in response:
			# we are assuming this is ordered by pk, this is to show only new texts
			# if goal is replay, time should be compared with game_time instead.
			if r.pk > _last_text_pk:
				spawn_words(r.text, r.parti_code)
				_last_text_pk = r.pk
				#yield(get_tree().create_timer(0.4), "timeout")
	

func spawn_words(text, ecode):
	var w = Words.instance()
	var pos = $Platform.position - Vector2(platform_length/2, 50)        
	w.init(pos, text, ecode, platform_length, _color_ix)
	_color_ix += 1
	add_child(w)


func _on_Button_area_entered(area):
	$Button/CollisionShape2D.disabled = true  # so not to trigger again
	$Button/AnimatedSprite.play()

func _on_AnimatedSprite_animation_finished():
	# TODO: SOUND	
	yield(get_tree().create_timer(1), "timeout")
	emit_signal('activated') 
	$Platform/Camera2D.current = true  # TODO: can we pan to it?
	
	# set DB to this prompt!  (no timeout needed, we assume success)
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var err = http_request.request(_server_url + "/earth/gosetprompt/" + _gameid + "/" + str(prompt_key)) 	
	#print_debug(_server_url + "/earth/gosetprompt/" + _gameid + "/" + str(prompt_key))
	print("Mechanism sent prompt " + str(prompt_key) + " → " + str(err))
	$HTTPTimer.start()	


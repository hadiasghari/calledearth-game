extends Node2D

var Words = preload('./Words.tscn')

export var prompt_key = 0

export var platform_offset_x = 0
export var platform_offset_y = 0
export var platform_len = 500

var _gameid = ""
var _server_url = ""
var _last_text_pk = -1

signal pressed


# design notes: 1. it seems logical to have the prompt-key tied to the button
#         on the button, instead of having to infer it from the DB
#         2. when the button is activated and we enter text-provocation-mode,
#         then these words need to fill somehwere up. I think that could also be an object
#         with an area/shape, and that object should belinked here to the button then...
#         (or some other way for code ot know where to spawn new words then) 


# TODO 1: add proper button sprite + animation + sound (+ maybe tween)
# TODO 2: have the text-shape area offset/size/shape be settable via exports
# TODO 3: set appropriate colision sprite for the second collision-shape-2d


func init(server_url, gameid):
	_gameid = gameid
	_server_url = server_url
	print("Mechanism got gameid:" + _gameid)


func _ready():
	# here or in init? set positions with offset
	var pos = Vector2(platform_offset_x, platform_offset_y)
	$Platform.position = pos
	$Platform/CollisionShape2D.shape.extents[0] = platform_len
	print($Platform/Sprite.scale)  # 2.114
	
	# TODO: get gameID too

func _on_Button_body_entered(body):
	print("entered button" + str(prompt_key)) 
	emit_signal('pressed') 
	$Button/CollisionShape2D.disabled = true
	#$FillBox/Sprite.visible = true  # TODO: remove after debug tests 
	$Platform/CollisionShape2D.disabled = false
	$Platform/Camera2D.current = true  # TODO: also center it

	# set DB to this prompt!  (no timeout needed, we assume success)
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var err = http_request.request(_server_url + "/earth/gosetprompt/" + _gameid + "/" + str(prompt_key)) 	
	print("Mechanism sent prompt " + str(prompt_key) + " → " + str(err))
	$HTTPTimer.start()	
	# TODO: get the words from the DB directly here!


func _on_HTTPTimer_timeout():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_completed")
	http_request.request(_server_url + "/earth/gogettexts/" + _gameid + "/" + str(prompt_key)) 
	
	
# TODO: needs some fulfil condition, set inside AND OUTISDE of it (thus by a signal too!)
# TODO: if we are replaying, then we need to give current sate of this button and have all the words loaded immediately :)



func _http_request_completed(result, response_code, headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		print("DBG HTTP prompt " + str(prompt_key) + ": ", response)   
		for r in response:
			# we are assuming this is ordered by pk, this is to show only new texts
			# if goal is replay, time should be compared with game_time instead.
			if r.pk > _last_text_pk:
				spawn_words(r.text, r.parti_code)
				_last_text_pk = r.pk
				yield(get_tree().create_timer(0.4), "timeout")
	



func spawn_words(text, ecode):
	# TODO: PLACE THESE IN PROPER PLACE / ORDER
	# TODO: DECIDE TYPE OF THESE WORDS (KINEMATIC/RIGID/STATIC)
	var w = Words.instance()
	var pos = $Platform.position      # perhaps have on 
	w.init(Vector2(pos[0]-platform_len/2, pos[1]-50), text, ecode, platform_len)
	add_child(w)

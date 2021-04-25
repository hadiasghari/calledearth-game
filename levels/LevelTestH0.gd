extends Node2D

var Words = preload('res://words/Words.tscn')

var last_text_pk = -1

var gameid = ""

func _ready():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_newgame_completed")
	http_request.request("https://calledearth.herokuapp.com/earth/gonewgame") 
	# TODO: 1. assert error == ok, 2. wait for gameID!


func _http_request_newgame_completed(result, response_code, headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		gameid = str(response)
		print(gameid)  		# TODO: for debug put this on HUD
		$Timer.start()		# start other timer only now :)
		

func _on_Timer_timeout():
	var http_request1 = HTTPRequest.new()
	add_child(http_request1)
	http_request1.connect("request_completed", self, "_http_request1_completed")
	http_request1.request("https://calledearth.herokuapp.com/earth/gogettexts/" + gameid) 
		 # TODO 1. update URL with game ID 2. add last time to only get new messages 
	# assert error = OK
	#if error != OK:
	#	push_error("An error occurred in the HTTP request.")
	#	print("An error occurred in the HTTP request.")  
		# NOTE wierd, no error here when server unavailable

	var http_request2 = HTTPRequest.new()
	add_child(http_request2)
	http_request2.connect("request_completed", self, "_http_request2_completed")
	http_request2.request("https://calledearth.herokuapp.com/earth/gogetstats/" + gameid) 
	
		
	# NOTE timer already repeats. maybe will need code to stop reentry
	
	# Temp code for pushing if we need it... 
	# HA code below from: https://docs.godotengine.org/en/stable/classes/class_httprequest.html
	# var body = {"name": "Godette"}
	# error = http_request.request("https://httpbin.org/post", [], true, HTTPClient.METHOD_POST, body)


func _http_request1_completed(result, response_code, headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		#print("DBG HTTP:", response)   
		for r in response:
			# we are assuming this is ordered by pk, this is to show only new texts
			# if goal is replay, time should be compared with game_time instead.
			if r.pk > last_text_pk:
				spawn_words(r.location, r.text)
				last_text_pk = r.pk
		# NOTE wierd when server unavailable, body is not null, but parse_json fails
	#else:
	#	push_error("Empty HTTP response.") 
	#	print("Empty HTTP response.")


func _http_request2_completed(result, response_code, headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		print("GAME STATS:", response)   
		$LiveInfo.set_text(str(len(response['participants'])))



func spawn_words(location, text):
	var w = Words.instance()
	location = location if location else 0
	w.init(Vector2(location, 0), text)
	add_child(w)


	

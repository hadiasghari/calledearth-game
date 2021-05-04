extends Node2D

var Words = preload('res://words/Words.tscn')

var last_text_pk = -1

var gameid = ""

#var server_url = "https://calledearth.herokuapp.com"
var server_url = "http://127.0.0.1:8000"


func _ready():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_newgame_completed")
	http_request.request(server_url + "/earth/gonewgame") 
	# TODO: 1. assert error == ok, 2. wait for gameID! ... 
	#       if neither come, give an error message [or don't unpause]


func _http_request_newgame_completed(result, response_code, headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		gameid = str(response)
		print(gameid)  		
		$Timer.start()		# start other timer only now :)
		# TODO: put gameid this on HUD
		# TODO : possibly unfreeze player only now
		
		$Mechanism1.init(server_url, gameid)  
			# TODO: do this for all child button-mechanisms... or perhaps emit signal
		
		

func _on_Timer_timeout():
	#var http_request1 = HTTPRequest.new()
	#add_child(http_request1)
	#http_request1.connect("request_completed", self, "_http_request1_completed")
	#http_request1.request(server_url + "/earth/gogettexts/" + gameid + "/0") 
		 # TODO 1. update URL with game ID 2. add last time to only get new messages 
	# assert error = OK
	#if error != OK:
	#	push_error("An error occurred in the HTTP request.")
	#	print("An error occurred in the HTTP request.")  
		# NOTE wierd, no error here when server unavailable

	var http_request2 = HTTPRequest.new()
	add_child(http_request2)
	http_request2.connect("request_completed", self, "_http_request2_completed")
	http_request2.request(server_url + "/earth/gogetstats/" + gameid) 
	
		
	# NOTE timer already repeats. maybe will need code to stop reentry
	
	# Temp code for pushing if we need it... 
	# HA code below from: https://docs.godotengine.org/en/stable/classes/class_httprequest.html
	# var body = {"name": "Godette"}
	# error = http_request.request("https://httpbin.org/post", [], true, HTTPClient.METHOD_POST, body)


func _http_request1_completed(result, response_code, headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		print("DBG HTTP:", response)   
		for r in response:
			# we are assuming this is ordered by pk, this is to show only new texts
			# if goal is replay, time should be compared with game_time instead.
			if r.pk > last_text_pk:
				spawn_words(r.text, r.parti_code)
				last_text_pk = r.pk
		# NOTE wierd when server unavailable, body is not null, but parse_json fails
	#else:
	#	push_error("Empty HTTP response.") 
	#	print("Empty HTTP response.")


func _http_request2_completed(result, response_code, headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		#print("GAME STATS:", response)   
		# $LiveInfo.set_text(str(len(response['participants'])))



func spawn_words(text, ecode):
	var w = Words.instance()
	#var pos = 0  # TODO: $Player.position  
	w.init(Vector2(0, -500), text, ecode)
	add_child(w)


	
func _on_Button1_pressed():
	print("signal button1-pressed intercepted")  #pass # Replace with function body. # Replace with function body.
	# TODO: send a signal to player to ignore buttons until unfreeze. also set sprites niece.
	#       note `$Player.get_tree().paused = true` freezes also mechanism timers, so not that!
	# TODO: unfreeze signal on player (which also resets camera) shall also be called somehow :)
	

extends Node2D

var Words = preload('res://words/Words.tscn')
var Collectible = preload('res://items/Collectible.tscn')

var last_text_pk = -1
var gameid = ""

var nprompt = 1
var last_location = 0

var server_url = "https://calledearth.herokuapp.com"
#var server_url = "http://127.0.0.1:8000"



func _ready():
	$Tilemap_pickups.hide()
	spawn_pickups()
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_newgame_completed")
	http_request.request(server_url + "/earth/gonewgame") 
	# TODO: assert error==ok AND wait for gameID! ... else give error / don't unpause


func spawn_pickups():
	var pickups = $Tilemap_pickups 
	for cell in pickups.get_used_cells():
		var id = pickups.get_cellv(cell)
		var type = pickups.tile_set.tile_get_name(id)
		if 'aqua' in type or 'yellow' in type:
			var c = Collectible.instance()
			var pos = pickups.map_to_world(cell)
			c.init(type[13], pos + pickups.cell_size/2)
			add_child(c)
			c.connect('pickup', self, '_on_Collectible_pickup') 


func _on_Collectible_pickup():
	var request = HTTPRequest.new()
	add_child(request)
	# TODO: POST doesn't work yet. (easier to also send location)
	#request.connect("request_completed", self, "_http_request3_completed")
	#print($player.position)
	last_location = $player.position[0]
	var err = request.request(server_url + "/earth/gosetprompt/" + gameid + "/" + str(nprompt)) 	
	#var data = {"prompt": str(nprompt), "location": "0"}  # str(position)}
	#var body = {"name": "Godette"}
	#var error = request.request(server_url + "/earth/gosetprompt/" + gameid, [], true, 
	#						HTTPClient.METHOD_POST, data)
	print("Sent Prompt " + str(nprompt) + "@" + str(last_location))
	nprompt += 1
	


func _http_request_newgame_completed(result, response_code, headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		gameid = str(response)
		print("GAMEID:", gameid)  		# TODO: for debug put this on HUD
		$Timer.start()		# start other timer only now :)
		

func _on_Timer_timeout():
	var request1 = HTTPRequest.new()
	add_child(request1)
	request1.connect("request_completed", self, "_http_request1_completed")
	request1.request(server_url + "/earth/gogettexts/" + gameid + "/" + str(nprompt-1)) 
	# note: if necessary, add last time to only get new messages  
	# note: wierd, no error here when server unavailable
	#if error != OK:
	#	push_error("An error occurred in the HTTP request.")
	
	# LATER:
	#var request2 = HTTPRequest.new()
	#add_child(request2)
	#request2.connect("request_completed", self, "_http_request2_completed")
	#request2.request(server_url + "/earth/gogetstats/" + gameid) 	
	# NOTE timer already repeats. maybe will need code to stop reentry
	
	# Temp code for pushing if we need it... 


func _http_request1_completed(result, response_code, headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		# NOTE: wierd when server unavailable, body is not null, but parse_json fails
		print("DBG HTTP:", response)   
		for r in response:
			# we are assuming this is ordered by pk, this is to show only new texts
			# if goal is replay, time should be compared with game_time instead.
			if r.pk > last_text_pk:
				spawn_words(r.text, r.parti_code)
				last_text_pk = r.pk
	#else:
	#	push_error("Empty HTTP response.") 

func _http_request2_completed(result, response_code, headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		#print("GAME STATS:", response)   
		# $LiveInfo.set_text(str(len(response['participants'])))

func spawn_words(text, ecode):
	var w = Words.instance()
	# TODO: either get location of collectible, or place it in front of avatar
	#       (in which case see which way it's facing, and add +/- 100)
	var pos = $player.position  
	w.init(Vector2(pos[0], pos[1]-500), text, ecode, 300)
	add_child(w)


	

extends Node2D

var Collectible = preload('res://items/Collectible.tscn')
var gameid = ""
var server_url = "https://calledearth.herokuapp.com"
#var server_url = "http://127.0.0.1:8000"

func _ready():
	$Tilemap_pickups.hide()
	spawn_pickups()
	$Player.connect("dead", self, "gameover")
	$Player.connect("switch", self, "_on_pickup_switch")

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_newgame_completed")
	http_request.request(server_url + "/earth/gonewgame") 
	# TODO/Q: assert error==ok AND wait for gameID! ... else error / pause

func gameover():
	$HUD.show_message("Game Over!")
	yield(get_tree().create_timer(2.0), "timeout")  # Take a moment :)
	get_tree().change_scene("res://ui/StartScreen.tscn") 
	# TODO: MUSIC GAMEOVER

func spawn_pickups():
	var pickups = $Tilemap_pickups 
	for cell in pickups.get_used_cells():
		var id = pickups.get_cellv(cell)
		var type = pickups.tile_set.tile_get_name(id)
		var pos = pickups.map_to_world(cell)
		var c = Collectible.instance()
		type = c.init(type, pos + pickups.cell_size/2)
		if type:
			add_child(c)
			c.connect('pickup', self, '_on_pickup_' + type) 

func _on_pickup_switch():
	$Player.devoffset += 1	
	$HUD.show_message("Limb Switch!")

func _http_request_newgame_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		gameid = str(response)
		print("GAMEID:", gameid)  
		$HUD.update_server(server_url)
		$TimerStats.start()		# start other timer only now :)
		$MusicSegue.play()		# TODO: doesn't work
		
		# TODO/Q: what's a better way to do this for all child button-mechanisms? perhaps emit signal?
		$Mechanism1.init(server_url, gameid)  
		$Mechanism2.init(server_url, gameid)  

func _on_Timer_timeout():
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_http_request_getstats_completed")
	request.request(server_url + "/earth/gogetstats/" + gameid) 	
	# TODO/Q: do we need to free these nodes?

func _http_request_getstats_completed(result, response_code, headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		var s = ""
		for p in response['participants']:
			s += char(p)
		$HUD.update_users(s)


var last_entered = 0

func _on_MusicShift_body_entered(body):
	# TODO/Q only respond if body is KinematicBody2D?
	last_entered = body.position[0]

func _on_MusicShift_body_exited(body):
	print_debug(body.position[0] - last_entered)
	# TODO: if positive, play SEGUE, else play LEVEL
	# TODO: use tweens later for fade


func _on_Mechanism1_deactivated():
	$Player/Camera2D.current = true  # return camera!

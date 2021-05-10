extends Node2D

var Collectible = preload('res://items/Collectible.tscn')
var gameid = ""
var server_url = "https://calledearth.herokuapp.com"
var _last_save = ""
#var server_url = "http://127.0.0.1:8000"

func _ready():
	$Tilemap_pickups.hide()
	spawn_pickups()
	var _err = $Player.connect("dead", self, "gameover")
	_err = $Spikes.connect("hit", self, "gameover")
	_err = $Player.connect("switch", self, "_on_pickup_switch")

	var http_request = HTTPRequest.new()
	add_child(http_request)
	_err = http_request.connect("request_completed", self, "_http_request_newgame_completed")
	http_request.request(server_url + "/earth/gonewgame") 
	# TODO/Q: assert error==ok AND wait for gameID! ... else error / pause

func gameover():
	  # TODO: 1. use animation object  2. should gameover music be here or elsewhere or in singleton..?
	$MusicLevel1.stop()
	$MusicOver.stream.set_loop(false) 
	$MusicOver.play()
	$HUD.show_message("Game Over!", 5)	
	yield(get_tree().create_timer(5), "timeout")
	# IF GAME IS SAVED DONT RESTART ALL OVER BUT GO TO LAST SAVE
	if _last_save == "btn1":
		# TODO/Q this kinda logic should be in global/singleton 
		$Player.position = $Button1.position + $Button1/AreaExit.position + Vector2(300, -400)
		$MusicLevel1.play()
		# nothign else needs to be reset, right?
	else:
		var _err = get_tree().change_scene("res://ui/TitleScreen.tscn") 

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
	# This should probably be moved into the player itself, if we can connect their signals
	$Player.devoffset += 1	
	if $Player.devoffset % 4 != 0:
		$HUD.show_message("Limb Switch!")
	else:
		$HUD.show_message("Limb Switch!*")
		

func _on_pickup_victory():
	# TODO we probably need to signal/call globla/signleton ehre for next level etc
	# (also 	send server level 2)
	$HUD.show_message(char(127881) + "Let's Dance!", -1)
	$MusicLevel1.stop()
	$MusicVictory.play()
	

func _http_request_newgame_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		gameid = str(response)
		print("GAMEID:", gameid)  
		$HUD.update_server(server_url)
		$TimerStats.start()		# start other timer only now :)		
		# TODO/Q: what's a better way to do this for all child button-mechanisms? 
		#         this grouping thingie? or perhaps emit signal?
		$Button1.init(server_url, gameid)  
		$Button2.init(server_url, gameid)  

func _on_Timer_timeout():
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_http_request_getstats_completed")
	request.request(server_url + "/earth/gogetstats/" + gameid) 	
	# TODO/Q: do we need to free these nodes?

func _http_request_getstats_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		_last_save = response['lastsave']
		var s = ""		
		for p in response['participants']:
			s += char(p)
		$HUD.update_users(s)

#var _last_entered = 0
#func _on_MusicShift_body_entered(body):
#	if 'KinematicBody2D' in str(body):	
#		_last_entered = body.position
#func _on_MusicShift_body_exited(body):
#	if 'KinematicBody2D' in str(body):		
#		var shift = body.position - _last_entered
#		print_debug(shift)
#		if shift[0] + shift[1] >= 0:  # TODO: this is very hacky logic :)			
#			$MusicSegue.volume_db = -10  # the normal blast
#			$MusicSegue.play()  # TODO: FADE THIS STUFF (needs tweens)
#			$MusicLevel1.stop()
#		else:
#			$MusicLevel1.play()
#			$MusicSegue.stop()
			
func _on_Buttons_deactivated():
	$Player/Camera2D.current = true  # return camera!
	$MusicSegue.stop()
	$MusicLevel1.play()

func _on_Buttons_activated():
	# lower volume
	$MusicSegue.volume_db = -15
	$MusicLevel1.stop()	
	if not $MusicSegue.playing:
		$MusicSegue.play()
	

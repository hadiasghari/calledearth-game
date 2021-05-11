extends Node2D

var Collectible = preload('res://items/Collectible.tscn')

onready var GLOBAL = get_node("/root/Global")

func _ready():

	spawn_pickups()
	var _err = $Player.connect("dead", self, "gameover")
	_err = $Spikes.connect("hit", self, "gameover")
	_err = $Player.connect("switch", self, "_on_pickup_switch")
	
	$HUD.update_server(GLOBAL.server_url)	
	$Button1.init(GLOBAL.server_url, GLOBAL.game_id)  
	$Button2.init(GLOBAL.server_url, GLOBAL.game_id)  
	# TODO error if immediate _on_Timer_timeout()  # updates stats
	$TimerStats.start()		# periodically...

func gameover():
	  # TODO: 1. use animation object  2. should gameover music be here or elsewhere or in singleton..?
	$MusicLevel1.stop()
	$MusicOver.stream.set_loop(false) 
	$MusicOver.play()
	$HUD.show_message("Game Over!", 5)	
	yield(get_tree().create_timer(5), "timeout")
	# IF GAME IS SAVED DONT RESTART ALL OVER BUT GO TO LAST SAVE
	if GLOBAL.last_save == "btn1":
		# TODO/Q this kinda logic should be in global/singelton scene too
		$Player.position = $Button1.position + $Button1/AreaExit.position + Vector2(300, -400)
		$MusicLevel1.play()
		# nothign else needs to be reset, right? => collectibles maybe?
	elif GLOBAL.last_save == "":
		# TODO: reset player direction :) ... what about limbs?
		# TODO: respawn collectibles but only for thoes that are gone!
		$Player.position = Vector2(300, -400)
		$MusicLevel1.play()
	else:
		var _err = get_tree().change_scene("res://ui/TitleScreen.tscn") 

func spawn_pickups():
	$Tilemap_pickups.hide()	
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
	$HUD.show_message(char(127881) + "Let's Dance!", 1000000000)
	# change prompt to dance too!
	# TODO: these request creations should be sent to a factory method
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var err = http_request.request(GLOBAL.server_url + "/earth/gosavegame/" + GLOBAL.game_id + "/dance1") 		
	$MusicLevel1.stop()
	$MusicVictory.play()
	
func _on_Timer_timeout():
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_http_request_getstats_completed")
	request.request(GLOBAL.server_url + "/earth/gogetstats/" + GLOBAL.game_id) 	
	# TODO/Q: do we need to free these nodes?

func _http_request_getstats_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		GLOBAL.last_save = response['lastsave'] 
		var s = ""		
		for p in response['participants']:
			s += char(p)
		$HUD.update_users(s)
		
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
	

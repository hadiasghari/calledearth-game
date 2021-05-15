extends Node2D

# This scene controls the gamestate logic (which scenes to load/unload)

# TODO MAYBE some sound/music files cna be moved here.  (e.g. gameover music)
# TODO MAYBE 

onready var GLOBAL = get_node("/root/Global")

#enum GameStates {LEVEL00, LEVEL01A, LEVEL01B, CONTIINUE, LEVEL02A, LEVEL02B, CREDITS,
#				 L1_Revival, L1_Dance, L2_Dance, L2_Revival, }

# TODO: interim states are part of the main screen now! :)
#       (so they would for instance hide the main scenes or sth 

#var gameState = GameStates.LEVEL00

export var TestStartLevel = 0  # game level, 0/1/2/99
export var TestStartLevelSub = 0  # TODO we should also define multiple save points in levels

# currently Continue & Revival Screens are handled by main. not yet fully sure of that :)
# 		- well revival technicalyl should be a message on top of the level that just reached GameOver
#         so it should be in coordination with the level (signal-wise) but not done by the level (re HUD + logic extraction + server etc)
#      - Continue is also an HUD message. to decide where it should happen. needs voting. 


var scene_level00 = preload("res://levels/Level00.tscn").instance()  # title
var scene_level01 = preload("res://levels/Level01.tscn").instance()
var scene_level02 = preload("res://levels/Level02.tscn").instance()
var scene_level99 = preload("res://levels/Level99.tscn").instance()  # credits

func _ready():
	randomize()		
	
	scene_level00.connect("start_next", self, "next_level")
	# TODO:
	#scene_level01.connect("playerdead", self, "_on_level_playerdead")
	#scene_level01.connect("limbswitched", self, "_on_level_limbswitched")
	#scene_level01.connect("letsdance", self, "_on_level_letsdance")
	
	GLOBAL.currentLevel = TestStartLevel
	GLOBAL.currentLevelSub = TestStartLevelSub
		
	$Audio/MusicOver.stream.set_loop(false) 
	$HTTP/HTTPRequestGame.request(GLOBAL.server_url + "/earth/gonewgame") 
	reload_level()	
	


func next_level():	
	match GLOBAL.currentLevel:
		0:
			GLOBAL.currentLevel = 1
			GLOBAL.currentLevelSub = 0
			reload_level()

	# TODO: probably we want to send/log the new state to Django Server too
	

func reload_level():
	# based on https://docs.godotengine.org/en/latest/tutorials/scripting/change_scenes_manually.html (option 3,)
	#         
	for c in $CurrentScene.get_children():
		$CurrentScene.remove_child(c)  # we could keep existing node if we wish
	
	match GLOBAL.currentLevel:				
		0:
			$CurrentScene.add_child(scene_level00)
	
		1:
			$CurrentScene.add_child(scene_level01)
			
			
			# TODO: also connect two signals


func _on_level_playerdead():
	# TODO: 1. this should check if we have enough energy to revive or not (hopefulyl we do otherwise mssages to get energy)
		# (re TODO: revival code will be part of this scene!)
	# TODO: 2. then decide where to RESTART. BASED ON GAMESTATE. 
	
	# IF GAME IS SAVED DONT RESTART ALL OVER BUT GO TO LAST SAVE
	#if GLOBAL.last_save == "btn1":
		# TODO/Q this kinda logic should be in global/singelton scene too
		#$Player.position = $Button1.position + $Button1/AreaExit.position + Vector2(300, -400)
		# nothign else needs to be reset, right? => collectibles maybe?
	#elif GLOBAL.last_save == "":
		# TODO: reset player direction :) ... what about limbs?
		# TODO: respawn collectibles but only for thoes that are gone!
		#$Player.position = Vector2(300, -400)
	#else:
	#	var _err = get_tree().change_scene("res://ui/TitleScreen.tscn") 
	
	# MUSIC GAMEOVER HERE, NO?
	$Audio/MusicOver.play()
	$HUD.show_message("Game Over!", 5)		
	yield(get_tree().create_timer(5), "timeout")

	# TODO: this should test revival or not :)
   # TODO: 1. use animation object  2. should gameover music be here or elsewhere or in singleton..?


func _on_level_dancenext():
	# TODO: this will have singleton for (i) change prompts on HUD & mobile (ii) timeout at some point (iii) eventually next level logic

	$Audio/MusicVictory.play()
	$HUD.show_message(char(127881) + "Let's Dance!", 1000000000)	
	# TODO: this should end at some point, 
	#  and then we move to the scene asking whether to continue game or not! (or they are the same)

	
	# TODO UPDATE STATE TO SERVER PROPERLY
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var _err = http_request.request(GLOBAL.server_url + "/earth/gosavegame/" + GLOBAL.game_id + "/dance1")  




func _on_level_limbswitch(offset):
	match offset:
		0: $HUD.show_message("Limb Switch!*")
		_: $HUD.show_message("Limb Switch!")


func _on_HTTPRequestGame_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		GLOBAL.game_id = str(response)
		print_debug("GAMEID:", GLOBAL.game_id)  
		$HUD.update_server(GLOBAL.server_url)
		$HUD.update_gameid(GLOBAL.game_id)
		$HTTP/TimerOnlineUsers.start()


func _on_TimerOnlineUsers_timeout():
	var request = HTTPRequest.new()
	$HTTP.add_child(request)
	request.connect("request_completed", self, "_on_HTTPRequestOnlineUsers_completed")
	request.request(GLOBAL.server_url + "/earth/gogetstats/" + GLOBAL.game_id) 	
	# Q: do we need to free the node now that the request is done? if so how/where? 
	#    (after completion?) (netstat shows a slow build up of closed state ports)
	#    (we could reuse, but I am worried if a request doesn't complete, comms will block)	
	
	
func _on_HTTPRequestOnlineUsers_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		if response:
			#print(response)
			#GLOBAL.last_save = response['lastsave']   # MAY 15 unnecssary since here
			var s = ""		
			for emoji in response['participants']:
				s += char(emoji)
			$HUD.update_users(s)
			# q_lastk = response['q_lastk']
			for energy in response['q_energy']:
				# TODO: 1. update EnergyBar!
				# TODO: 2. instanciate these somehow [to current scene, or better a signal, or global]
				pass
				#var ei = Energy.instance()  				
				#var pos = $Player.position + Vector2(-300+randi()%600, -200-randi()%100)  # TODO: position this only above player, smalelr
				#ei.init(energy, "?", pos)
				#add_child(ei)				
		else:
			print_debug('parsing error: ' + str(body.get_string_from_utf8()) )






func _on_MusicDance_finished():
	pass # Replace with function body.
	# TODO: ready to advance level :D

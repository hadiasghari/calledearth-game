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

export var start_level = 0  # game level, 0/1/2/99
export var start_sublevel = ""  # TODO we should also define multiple save points in levels
export var start_energy = 90


# currently Continue & Revival Screens are handled by main. not yet fully sure of that :)
# 		- well revival technicalyl should be a message on top of the level that just reached GameOver
#         so it should be in coordination with the level (signal-wise) but not done by the level (re HUD + logic extraction + server etc)
#      - Continue is also an HUD message. to decide where it should happen. needs voting. 


var scene_level00 = preload("res://levels/Level00.tscn").instance()  # title
var scene_level01 = preload("res://levels/Level01.tscn").instance()
var scene_level02 = preload("res://levels/Level02.tscn").instance()
var scene_level99 = preload("res://levels/Level99.tscn").instance()  # credits
var current_scene  # updated to whatever current scene is


func _ready():
	randomize()		
	
	var _err
	_err = scene_level00.connect("start_next", self, "next_level")
	_err = scene_level01.connect("player_dead", self, "_on_player_dead")
	_err = scene_level01.connect("player_switched", self, "_on_player_switched")
	_err = scene_level01.connect("player_energy", self, "_on_player_energychange")
	_err = scene_level01.connect("dance_next", self, "_on_level_dancenext")
	# TODO: connect level02	
	GLOBAL.current_level = start_level
	GLOBAL.current_sublevel = start_sublevel
	GLOBAL.energy = start_energy
	$HTTP/HTTPRequestGame.request(GLOBAL.server_url + "/earth/gonewgame") 
	reload_level()	
	
	
	# NOTE: Design point (cons/pros) re whether player should be in this scene or in levels
	# - to test levels standalone, it needs to be in those scenes. (but can they be tested without the gameover logic etc?)
	# - also, it makes sense that player doesn't directly access HUD re `(de)coupling` (so uses signals/functions)
	# - now, only wierdness is this piping of signals... (we need to capture them and resubmit them and vice-versa)


func next_level():	
	match GLOBAL.current_level:
		0:
			GLOBAL.current_level = 1
			#GLOBAL.currentLevelSub = 0
			reload_level()
		1:
			GLOBAL.current_level = 2
			# TODO: ASK IF PEOPLE WANT TO CONTINUE
			reload_level()
		2: 
			GLOBAL.current_level = 99
			reload_level()
	
	# TODO: probably we want to send/log the new state to Django Server too


#func update_game_state(state):
	# TODO: state is various locations in ganem, plus revival, prompts, dancing.
	#       actually dancing is a signal, prompt gets set elsewehre, and revival will be a state here
#	pass
# TODO: should we log to DB also playerdead, limbswitch, dance....? (at least two are necessary for prompts!)


func reload_level():
	# based on https://docs.godotengine.org/en/latest/tutorials/scripting/change_scenes_manually.html (option 3,)
	# the form of removal we use should keep the node data
	for c in $CurrentScene.get_children():
		$CurrentScene.remove_child(c)
	
	match GLOBAL.current_level:				
		0: 
			current_scene = scene_level00			
			$HUD.hide_energy()
		1: 
			current_scene = scene_level01
			$HUD.update_energy(GLOBAL.energy)
		2: 
			current_scene = scene_level02
			$HUD.update_energy(GLOBAL.energy)
		99: 
			current_scene = scene_level99
			$HUD.hide_energy()
			
	$CurrentScene.add_child(current_scene)	

func _on_player_switched(offset):
	# simply update HUD (see design notes at top)
	# (we could log this even to db too but unnecessary) 
	match offset:
		0: $HUD.show_message("Limb Switch!*")
		_: $HUD.show_message("Limb Switch!")


func _on_player_energychange(value):
	# TODO: reduce energy-level
	update_energy(value)
	

func update_energy(value):
	GLOBAL.energy += value
	GLOBAL.energy = min(max(0, GLOBAL.energy), 100)  # 0 to 100
	$HUD.update_energy(GLOBAL.energy)


func _on_player_dead():
	$HUD.show_message("Uh-oh!", 5)		
	update_energy(-30)
	$Audio/MusicDead.stream.set_loop(false) 	
	$Audio/MusicDead.play()
	# revival will happen  once the dead music finishes playing


func _on_level_dancenext():
	# TODO: this will have singleton for (i) change prompts on HUD & mobile (ii) timeout at some point (iii) eventually next level logic
	print_debug("dance")
	$Audio/MusicDance.stream.set_loop(false) 	
	$Audio/MusicDance.play()
	$HUD.show_message(char(127881) + "Let's Dance!", 1000000000)	
	# TODO: this should end at some point, 
	#  and then we move to the scene asking whether to continue game or not! (or they are the same)
	
	# TODO UPDATE DANCE STATE TO SERVER PROPERLY! NEED NEW FUNCTION
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var _err = http_request.request(GLOBAL.server_url + "/earth/gosavegame/" + GLOBAL.game_id + "/dance1")  


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
			var s = ""		
			for emoji in response['participants']:
				s += char(emoji)
			$HUD.update_users(s)
			for e in response['q_energy']:
				current_scene.spawn_energy(e) 
				if e == "m" or e == "s":
					update_energy(-1)
				else:
					update_energy(1)
		else:
			print_debug('parsing error: ' + str(body.get_string_from_utf8()) )






func _on_MusicDance_finished():
	pass # Replace with function body.
	# TODO: ready to advance level :D


func _on_MusicDead_finished():
	# REVIVAL LOGIC SCENE
	# TODO: check if we have enough energy to revive or not (hopefulyl we do otherwise mssages to get energy)
	
	# TESTING CODE, NEED MORE LOGIC HERE		

	$Audio/MusicHeart.play()  # MusicHeart set to loop and +5db vol via Inspector
	$HUD.show_message("Energy critical, recharge!!", 5)		
	yield(get_tree().create_timer(10), "timeout")  # for dramatic effect now....
	$Audio/MusicHeart.stop()
	current_scene.reposition("0")  # TODO SET CORRECT REPOSITIONING! from sublevel saved earlier
	

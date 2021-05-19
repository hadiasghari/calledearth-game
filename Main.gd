extends Node2D

# This Main scene controls the game state logic (which levels to load/unload)
# it also includes the logic for Heroku communications plus player revival/continue

onready var GLOBAL = get_node("/root/Global")
var scene_level00 = preload("res://levels/Level00.tscn").instance()  # title
var scene_level01 = preload("res://levels/Level01.tscn").instance()
var scene_level02 = preload("res://levels/Level02.tscn").instance()
var scene_level99 = preload("res://levels/Level99.tscn").instance()  # credits
var scene_contq   = preload("res://ui/ContinueQ.tscn").instance()  

export var server = "heroku"
export var start_level = 0  # game level, currently 0/1/2/99
export var start_sublevel = ""  # define multiple save/status points in levels
export var energy_start = 100
export var energy_loss_fall = -30

# internal state:
var current_scene  # updated to whatever current scene is (for func calls)
var is_dead = false


func _ready():
	randomize()				
	# connect signals all around
	# NOTE: Design point (cons/pros) re whether player should be in this scene or in levels
	# - to test levels standalone, it needs to be in those scenes. (but can they be tested without the gameover logic etc?)
	# - also, it makes sense that player doesn't directly access HUD re `(de)coupling` (so uses signals/functions)
	# - now, only wierdness is this piping of signals... (we need to capture them and resubmit them and vice-versa)
	var _err
	_err = scene_level00.connect("start_game", self, "_on_start_game")
	_err = scene_level01.connect("player_dead", self, "_on_player_dead")
	_err = scene_level01.connect("player_switched", self, "_on_player_switched")
	_err = scene_level01.connect("player_energy", self, "_on_player_energy")
	_err = scene_level01.connect("milestone", self, "_on_level_milestone")
	_err = scene_level02.connect("player_dead", self, "_on_player_dead")
	_err = scene_level02.connect("player_switched", self, "_on_player_switched")
	_err = scene_level02.connect("player_energy", self, "_on_player_energy")
	_err = scene_level02.connect("milestone", self, "_on_level_milestone")
	_err = scene_contq.connect("answer", self, "_on_contq_answer")
	# get a new gameid, also give server a bit of time to respond
	if server == 'heroku' or server == 'local':
		GLOBAL.server_url = {'heroku': 'https://calledearth.herokuapp.com',
				  'local': "http://127.0.0.1:8000"}[server]	
	else:
		GLOBAL.server_url = "http://" + server
	$HTTP/HTTPRequestGame.request(GLOBAL.server_url + "/earth/gonewgame") 
	yield(get_tree().create_timer(2), "timeout") 
	# set levels & start	
	GLOBAL.current_level = start_level
	GLOBAL.current_sublevel = start_sublevel
	GLOBAL.energy = energy_start
	load_level_scene() 
	

func _on_start_game():	
	# this is called only within level00/titlepage; 
	GLOBAL.current_level = 1
	GLOBAL.current_sublevel = "0"
	load_level_scene()


func load_level_scene():
	# scene loads are based on:
	#  https://docs.godotengine.org/en/latest/tutorials/scripting/change_scenes_manually.html (option 3,)
	#  this form of removal we use keeps the node data in case we want it
	for c in $CurrentScene.get_children():
		$CurrentScene.remove_child(c)
	
	match GLOBAL.current_level:				
		0: 
			current_scene = scene_level00			
			$HUD.hide_energy()
			# game just started, no additional server log needed 
		1: 
			$HUD.update_energy(0)
			if GLOBAL.current_sublevel != "contq": 
				current_scene = scene_level01
				current_scene.reposition(GLOBAL.current_sublevel)  # current save
				set_web_state("level", "L1." + GLOBAL.current_sublevel)
			else:
				current_scene = scene_contq
				set_web_state("contq", "")
		2: 
			current_scene = scene_level02
			current_scene.reposition(GLOBAL.current_sublevel)
			$HUD.update_energy(0)
			set_web_state("level", "L2." + GLOBAL.current_sublevel)
		99: 
			current_scene = scene_level99
			$HUD.hide_energy()
			$HUD.hide_users()
			set_web_state("credits", "")
			
	$CurrentScene.add_child(current_scene)	
	# log to server new scene load (also resets prompts from camera, dance, etc)	



func _on_player_switched(offset):
	# simply update HUD (see design notes at top)
	# (we could log this even to db too but unnecessary) 
	set_web_state('event', 'limb_switch')
	match offset:
		0: $HUD.show_message("Limb Switch!*")
		_: $HUD.show_message("Limb Switch!")


func _on_player_energy(value):
	$HUD.update_energy(value)
	if GLOBAL.energy < 1:
		if not is_dead:
			# freeze's level music too. don't do this stuff if 
			current_scene.freeze_player(true)  
		$Audio/MusicHeart.play()
		while GLOBAL.energy < 10:  # note 10 vs 1
			$HUD.show_message("Energy critical, recharge!!", 1)	
			yield(get_tree().create_timer(1), "timeout")   # does this cause crazy bug?
		#print_debug(GLOBAL.energy)  
		$Audio/MusicHeart.stop() 
		# TEMP sleep-timeout to avoid unfreeze before repositioning after fall doesn't work
		if not is_dead:
			# the dead need to be unfrozen after repositioning
			current_scene.freeze_player(false)
	
	
func _on_HTTPRequestGame_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		GLOBAL.game_id = str(response)
		print("GAMEID:", GLOBAL.game_id)  
		$HUD.update_server(GLOBAL.server_url)
		$HUD.update_gameid(GLOBAL.game_id)
		$HTTP/TimerOnlineInfo.start()


func _on_TimerOnlineInfo_timeout():
	var request = HTTPRequest.new()
	$HTTP.add_child(request)
	request.connect("request_completed", self, "_on_HTTPRequestOnlineInfo_completed")
	request.request(GLOBAL.server_url + "/earth/gogetstats/" + GLOBAL.game_id) 	
	# DESIGNQ: do we need to free the node now that the request is done? 
	#         (if so how/where?) (netstat shows a slow build up of closed state ports)
	#         (we could reuse, but I am worried if a request doesn't complete, comms will block)	

	
func _on_HTTPRequestOnlineInfo_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		if response:
			var s = ""		
			for emoji in response['participants']:
				s += char(emoji)
			$HUD.update_users(s)
			for etyp in response['q_energy']:
				current_scene.spawn_energy_item(etyp) 
				var eval = -1 if etyp == "m" or etyp == "s" else 1
				_on_player_energy(eval)
		else:
			print_debug('parsing error: ' + str(body.get_string_from_utf8()) )




func _on_player_dead(_why):
	#print_debug("player dead: " + _why)
	is_dead = true  # player already frozen by itself, state for here 
	$HUD.show_message("Uh-oh!", 5)		
	$HUD.update_energy(energy_loss_fall)	
	$Audio/MusicDead.stream.set_loop(false) 	
	$Audio/MusicDead.play()
	set_web_state("event", "dead-" + _why)	
	# revival will happen once this dead music finishes playing!	


func _on_MusicDead_finished():
	# REVIVAL LOGIC! (check if we have energy or need some to revive)
	if GLOBAL.energy < 1:
		#print_debug('revival state')
		set_web_state("revival", "")
		_on_player_energy(0)  # this will start the heart music & HUD message... 
		while GLOBAL.energy < 10:  # 
			yield(get_tree().create_timer(1), "timeout")   #  
	#print_debug('repositioning...')
	current_scene.reposition(GLOBAL.current_sublevel)
	current_scene.freeze_player(false)
	is_dead = false
	set_web_state("play", "")
	

func _on_level_milestone(what):
	# mielstones are: save points, button finished points (also saved points), 
	#                 and dancing (which advanced to next level)
	# main task is to update web-server and GLOBAL
	print_debug("milestone: " + str(what))
	if what == "dance":
		# dancing. nice. :)
		$Audio/MusicDance.stream.set_loop(false) 	
		$Audio/MusicDance.play()
		$HUD.show_message(char(127881) + "Let's Dance!", 1000000000)			
		# On Dance Music Finished, we shall go to next level!		
		set_web_state("dance", "L" + str(GLOBAL.current_level))
	elif what.begins_with("btn") or what.begins_with("sav"):
		# milestone reached, save it to globa, inform server 
		GLOBAL.current_sublevel = what
		set_web_state("milestone", "L" + str(GLOBAL.current_level) + "_" + what)		
	else:
		print_debug("UNKNOWN milestone?!!!" )


func _on_MusicDance_finished():	
	$HUD.hide_message()  # stop the let's dance
	# now choose next level... 	
	if GLOBAL.current_level == 1:
		GLOBAL.current_sublevel = "contq"
	elif GLOBAL.current_level == 2:
		GLOBAL.current_level = 99
		GLOBAL.current_sublevel = ""
	else:
		print_debug('unexpected logic')
		
	load_level_scene()  # also informs server 	
	
	
func _on_contq_answer(value):
	match value:
		"y":
			GLOBAL.current_level = 2
			GLOBAL.current_sublevel = ""
		"n":
			GLOBAL.current_level = 99
			GLOBAL.current_sublevel = ""
		var other:
			print_debug('impossible answer!' + str(other))
	
	load_level_scene()	


func set_web_state(state, extra_info):
	var request = HTTPRequest.new() 
	# (Q ever, should we create a new request each time or reuse; if new, should we free it somewhere?)
	add_child(request)   
	var url = GLOBAL.server_url + "/earth/gosetstate/" + GLOBAL.game_id + "/" + state
	if extra_info and extra_info != "":
		url += "?info=" + extra_info
	var _err = request.request(url)  
	



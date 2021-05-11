extends Control

onready var GLOBAL = get_node("/root/Global")

func _ready():
	randomize()		
	# request a new gameid
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var _err = http_request.connect("request_completed", self, "_http_request_newgame_completed")
	http_request.request(GLOBAL.server_url + "/earth/gonewgame") 
	
func _input(event):
	if event.is_action_pressed('ui_select'):	
		var level = "Test1"
		var path = 'res://levels/Level%s.tscn' % level
		var _err = get_tree().change_scene(path)

func _http_request_newgame_completed(_result, _response_code, _headers, body):
	if body.get_string_from_utf8():
		var response = parse_json(body.get_string_from_utf8())
		GLOBAL.game_id = str(response)
		print("GAMEID:", GLOBAL.game_id)  
		$HUD.update_server(GLOBAL.server_url)
		$HUD.show_gameid(GLOBAL.game_id)

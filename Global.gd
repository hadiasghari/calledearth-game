extends Node

# This Singleton class STORES GLOBAL VALUES for other scenes to set/get
# (set to Project>AutoLoad)
# ref: https://docs.godotengine.org/en/stable/getting_started/step_by_step/singletons_autoload.html

var game_id = ""
#export var server_url = "https://calledearth.herokuapp.com"
export var server_url = "http://127.0.0.1:8000"

var last_save = ""

func _ready():
	pass

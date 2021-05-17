extends Node

# This Singleton class Stores Global Values for all scenes (set to Project>AutoLoad)
# ref: https://docs.godotengine.org/en/stable/getting_started/step_by_step/singletons_autoload.html

var game_id = ""
#export var server_url = "https://calledearth.herokuapp.com"
export var server_url = "http://127.0.0.1:8000"

var energy = 0  # between 0 to 100
var current_level = -1
var current_sublevel = ""

func _ready():
	pass

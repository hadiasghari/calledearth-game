extends Node

# This Singleton class Stores Global Values for all scenes (set to Project>AutoLoad)
# ref: https://docs.godotengine.org/en/stable/getting_started/step_by_step/singletons_autoload.html

var game_id = ""
var server_url = ""
var energy = 100  # between 0 to 100, start level is 100!
var current_level = -1
var current_sublevel = ""

func _ready():
	pass

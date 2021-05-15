extends Node2D

# This scene controls the gamestate logic (which scenes to load/unload)

# TODO MAYBE some sound/music files cna be moved here.  (e.g. gameover music)
# TODO MAYBE 

enum GameStates {TITLE, LEVEL00, LEVEL01A, LEVEL01B, LEVEL02A, LEVEL02B, CREDITS,
				 Revival_inL1, Revival_inL2, Continue_L1to2}

export var GameState = GameStates.TITLE

# currently Continue & Revival Screens are handled by main. not yet fully sure of that :)
# 		- well revival technicalyl should be a message on top of the level that just reached GameOver
#         so it should be in coordination with the level (signal-wise) but not done by the level (re HUD + logic extraction + server etc)
#      - Continue is also an HUD message. 


func _ready():
	# TODO: HUD could be just sth showing server status.
	# TODO: server control should be here indeed, no?
	
	# TODO: revival code will be part of this scene!
	
	var levels = ['res://levels/Level1.tscn',
			  'res://levels/Level2.tscn']




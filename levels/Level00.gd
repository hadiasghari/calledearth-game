extends Node2D

# `Level00` is the title scene. 
# - It starts with a writing prompt. 
# - We proceed to next scene when all controllers press X (or the ESC failsafe)
# - The WriteButton is partially hidden by putting it out of the scene bounds

signal start_game
var dev0_x = 0
var dev1_x = 0
var dev2_x = 0
var dev3_x = 0

func _ready():
	pass

func _input(event):
	if event.is_action_pressed('dev0_action'):	
		dev0_x = 1
	if event.is_action_pressed('dev1_action'):	
		dev1_x = 1
	if event.is_action_pressed('dev2_action'):	
		dev2_x = 1
	if event.is_action_pressed('dev3_action'):	
		dev3_x = 1		
	
	var s = "Press "	
	s += "+" if dev0_x else "-"
	s += "+" if dev1_x else "-"
	s += "X" 
	s += "+" if dev2_x else "-"
	s += "+" if dev3_x else "-"
	s += " to Start"
	$LabelStart.text = s
	
	if dev0_x + dev1_x + dev2_x + dev3_x == 4:
		emit_signal("start_game")
	
	#if event.is_action_pressed('test_skip_next'):	
	#	emit_signal("start_game")


func spawn_energy_item(etype):
	# empty function, placed to avoid crash if energy sent to this screen (due to a race condition)
	pass   

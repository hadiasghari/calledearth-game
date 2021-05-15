extends Node2D

signal start_next
var dev0_x = 0
var dev1_x = 0
var dev2_x = 0
var dev3_x = 0

func _ready():
	# Note: the ButtonPlatform's button is hidden by putting it out of screne
	#       it is already activated... so nothing else to do here
	pass

func _input(event):
	# TODO: this should be set to 4x Xs!  (or SEC)
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
		emit_signal("start_next")
	
	if event.is_action_pressed('test_skip_next'):	
		emit_signal("start_next")
	

extends Control

signal answer(value)
export var max_wait = 90
export var min_energy_cond = 50 

var Energy = preload('res://items/Energy.tscn')
onready var GLOBAL = get_node("/root/Global")
var secs_left = 0
var dev0_x = 0
var dev1_x = 0
var dev2_x = 0
var dev3_x = 0

func _ready():
	secs_left = max_wait
	$LabelTimeLeft.text = str(secs_left) + "s"
	$LabelCondEP.text = "Plus >" + str(min_energy_cond) + " EPs" 

func _on_Timer_timeout():
	secs_left = max(secs_left-1, 0)
	$LabelTimeLeft.text = str(secs_left) + "s"
	if secs_left == 0:
		emit_signal("answer", "n")

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
	s += " to Continue"
	$LabelCondX.text = s
	
	if dev0_x+dev1_x+dev2_x+dev3_x == 4 and GLOBAL.energy >= min_energy_cond:
		print_debug("condition met")
		emit_signal("answer", "y")

func spawn_energy_item(etype):
	#print_debug("energy", etype)
	var ei = Energy.instance()  				
	# position randomly
	var pos = Vector2(randi()%1900, randi()%1000)
	ei.init(etype, "?", pos)
	add_child(ei)	

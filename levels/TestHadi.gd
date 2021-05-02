extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var ch = 127913  #128521 #9757  #   # 127913  # 9743 # 
	var ch2 = "" # "⛑⛑⚅♕→♐"
	print(char(ch),char(ch).to_utf8(), char(ch).to_utf8().size())
	#print(ord(ch2))
	$Label.text = "!" + char(ch) + ch2 + "!"
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

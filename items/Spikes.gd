extends Area2D

signal hit


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _on_Spike_body_entered(body):
	emit_signal("hit")
	# TODO : something gruseome here...


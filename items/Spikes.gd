extends Area2D

signal hit

# TODO: REPLACE SPIKES WITH TILEMAP

func _ready():
	pass # Replace with function body.


func _on_Spike_body_entered(_body):
	emit_signal("hit")
	# TODO : something gruseome here...


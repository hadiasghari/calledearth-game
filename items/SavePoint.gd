extends Area2D


export var make_sound = true


func _ready():
	$Audio.stream.set_loop(false)	


func _on_SavePoint_body_entered(body):
	if make_sound:
		$Audio.play()
		make_sound = false

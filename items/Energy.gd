extends Node2D

var textures = {'l': 'res://assets/art/energy/love.png',
				'f': 'res://assets/art/energy/funny.png',
				'm': 'res://assets/art/energy/mad.png',
				's': 'res://assets/art/energy/sad.png',
				'p': 'res://assets/art/energy/power.png'}

func init(type, _emoji, pos):
	$Sprite.texture = load(textures[type])	
	position = pos
	if type == "s" or type == "m":
		$LabelPoints.text = "-1"
		$LabelPoints.add_color_override("font_color", "#ff0000")

func _ready():
	$Audio.play()  # make sure not looping!

func _on_Timer_timeout():	
	$LabelPoints.visible = false
	$Tween1.interpolate_property($Sprite, "scale",
			Vector2(0.3, 0.3), Vector2(0.01, 0.01), 1,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween1.start()

func _on_tween_all_completed():
	queue_free()


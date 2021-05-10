extends CanvasLayer


func _ready():
	pass

func show_message(text):
	$Message.text = text
	$Message.visible = true
	$TimerHideMessage.start()
	# TODO: follow this link for an animation player 
	# https://kidscancode.org/godot_recipes/games/circle_jump/circle_jump_05/
	#$AnimationPlayer.play("show_message")

func update_server(url):
	$OnlineInfo/HBox/VBox/LabelServer.text = url
	update_users("")

func update_users(users):
	$OnlineInfo/HBox/VBox/LabelUsers1.text = "Online Users: " + str(len(users))
	$OnlineInfo/HBox/VBox/LabelUsers2.text = users

func _on_TimerHideMessage_timeout():
	$Message.visible = false

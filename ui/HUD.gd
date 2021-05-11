extends CanvasLayer


func _ready():
	pass

func show_message(text, timeout=2):
	$Message.text = text
	$Message.visible = true
	if timeout != -1:
		$TimerHideMessage.wait_time = timeout
		$TimerHideMessage.start()
	# TODO: follow this link for an animation player 
	# https://kidscancode.org/godot_recipes/games/circle_jump/circle_jump_05/
	#$AnimationPlayer.play("show_message")

func update_server(url):
	$OnlineInfo/HBox/VBox/LabelServer.text = url
	update_users("")

func update_users(users):
	# func run from levels
	$OnlineInfo/HBox/VBox/LabelUsers1.text = "Online Users: " + str(len(users))
	$OnlineInfo/HBox/VBox/LabelUsers2.text = users

func show_gameid(gameid):
	# func run from titlescreen
	$OnlineInfo/HBox/VBox/LabelUsers1.text = "Game " + str(gameid)
	$OnlineInfo/HBox/VBox/LabelUsers2.text = ""
	
func _on_TimerHideMessage_timeout():
	$Message.visible = false

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

func update_energy(value):
	#print_debug('update energy called: ' + str(value))
	$EBar/Number.text = str(value)
	$EBar/TextureProgress.value = value
	$EBar.show()
	
func hide_energy():
	$EBar.hide()

func update_server(url):
	$OnlineInfo/HBox/VBox/LabelServer.text = url

func update_users(users):
	# func run from levels
	$OnlineInfo/HBox/VBox/LabelUsers1.text = "Online Users: " + str(len(users))
	$OnlineInfo/HBox/VBox/LabelUsers2.text = users

func update_gameid(gameid):
	$OnlineInfo/HBox/VBox/LabelGame.text = "Game " + str(gameid)

#func update_controllers(n):
#	$OnlineInfo/HBox/VBox/LabelControllers.text = "Controllers: " + str(n)
	
func _on_TimerHideMessage_timeout():
	$Message.visible = false

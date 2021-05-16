extends CanvasLayer


func show_message(text, timeout=2):
	$Message.text = text
	$Message.visible = true
	if timeout != -1:
		$TimerHideMessage.wait_time = timeout
		$TimerHideMessage.start()
	# NOTE: could add an animation player (or tween) to make message hide nicer

func update_energy(value):
	$EnergyBar.update_energy(value)
	$EnergyBar.show()
	
func hide_energy():
	$EnergyBar.hide()

func update_server(url):
	$OnlineInfo/HBox/VBox/LabelServer.text = url

func update_users(users):
	$OnlineInfo/HBox/VBox/LabelUsers1.text = "Online Users: " + str(len(users))
	$OnlineInfo/HBox/VBox/LabelUsers2.text = users

func update_gameid(gameid):
	$OnlineInfo/HBox/VBox/LabelGame.text = "Game " + str(gameid)

func _on_TimerHideMessage_timeout():
	$Message.visible = false
